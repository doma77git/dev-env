#!/usr/bin/env pwsh
# === .github/hooks/scripts/check-ps1-format.ps1 ===============
# ROLE:   PreToolUse hook — checks .ps1 content before write
#         Kontrola formátování PowerShell skriptů před zápisem
# INPUT:  JSON on stdin with tool_name + tool_input
# OUTPUT: JSON on stdout with permissionDecision
# EXIT:   0 = allow, 2 = block (malformed input)
# ==============================================================
$ErrorActionPreference = "Stop"

$input = $input | Out-String
if ([string]::IsNullOrWhiteSpace($input)) {
    Write-Output '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow" } }'
    exit 0
}

try {
    $hookData = $input | ConvertFrom-Json
} catch {
    Write-Output '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow" } }'
    exit 0
}

# Only check file-writing tools
$writeTools = @('create_file', 'replace_string_in_file', 'insert_edit_into_file')
$toolName = $hookData.tool_name

if ($toolName -notin $writeTools) {
    Write-Output '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow" } }'
    exit 0
}

# Check if target is a .ps1 file
$filePath = $hookData.tool_input.filePath
if (-not $filePath -or $filePath -notmatch '\.ps1$') {
    Write-Output '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow" } }'
    exit 0
}

$fileName = Split-Path $filePath -Leaf

# Extract the proposed content
$content = ''
if ($toolName -eq 'create_file') {
    $content = $hookData.tool_input.content
} elseif ($toolName -eq 'replace_string_in_file') {
    $content = $hookData.tool_input.newString
} elseif ($toolName -eq 'insert_edit_into_file') {
    $content = $hookData.tool_input.code
}

if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Output '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow" } }'
    exit 0
}

# --- Checks ---
$warnings = @()

# 1. Shebang check (new files only — create_file)
if ($toolName -eq 'create_file') {
    if ($content -notmatch '#!/usr/bin/env pwsh') {
        $warnings += 'Missing shebang: #!/usr/bin/env pwsh'
    }
}

# 2. Alias usage
$aliases = @{
    'ls' = 'Get-ChildItem'
    'gc' = 'Get-Content'
    'sc' = 'Set-Content'
    'sl' = 'Set-Location'
    'gi' = 'Get-Item'
    'gci' = 'Get-ChildItem'
    'gl' = 'Get-Location'
    'fl' = 'Format-List'
    'ft' = 'Format-Table'
    'select' = 'Select-Object'
    'sort' = 'Sort-Object'
    'where' = 'Where-Object'
    '%' = 'ForEach-Object'
    '?' = 'Where-Object'
    'iex' = 'Invoke-Expression'
    'irm' = 'Invoke-RestMethod'
    'sleep' = 'Start-Sleep'
    'diff' = 'Compare-Object'
    'curl' = 'Invoke-WebRequest'
    'wget' = 'Invoke-WebRequest'
    'echo' = 'Write-Output'
    'ps' = 'Get-Process'
    'kill' = 'Stop-Process'
    'cd' = 'Set-Location'
    'cp' = 'Copy-Item'
    'mv' = 'Move-Item'
    'rm' = 'Remove-Item'
    'del' = 'Remove-Item'
    'mkdir' = 'New-Item -ItemType Directory'
    'rmdir' = 'Remove-Item -Recurse'
    'cat' = 'Get-Content'
    'pwd' = 'Get-Location'
    'man' = 'Get-Help'
    'clear' = 'Clear-Host'
}

foreach ($alias in $aliases.Keys) {
    if ($content -match "\b$alias\b") {
        $warnings += "Alias '$alias' → use '$($aliases[$alias])' instead"
    }
}

# 3. Path anti-patterns
if ($content -match '\$HOME\b') {
    $warnings += "Use `$env:USERPROFILE instead of `$HOME"
}
if ($content -match "'[^']*\+[^']*'|""[^""]*\+[^""]*""") {
    $warnings += 'String concatenation for paths → use Join-Path instead'
}

# 4. Global ErrorActionPreference
if ($content -match '\$ErrorActionPreference\s*=\s*"Stop"') {
    $warnings += 'Global $ErrorActionPreference="Stop" → use "Continue"'
}

# 5. Missing [CmdletBinding] for mutation scripts
if ($content -match 'SupportsShouldProcess|ShouldProcess' -and $content -notmatch '\[CmdletBinding') {
    $warnings += 'Uses ShouldProcess but missing [CmdletBinding(SupportsShouldProcess)]'
}

if ($warnings.Count -eq 0) {
    $msg = '✓ formatting OK'
    $json = @{
        hookSpecificOutput = @{
            hookEventName = 'PreToolUse'
            permissionDecision = 'allow'
        }
        systemMessage = $msg
    } | ConvertTo-Json -Compress
    Write-Output $json
    exit 0
} else {
    $warnList = ($warnings | ForEach-Object { "  • $_" }) -join "`n"
    $msg = "Formatting issues in $fileName before write — consider fixing:`n$warnList"
    $json = @{
        hookSpecificOutput = @{
            hookEventName = 'PreToolUse'
            permissionDecision = 'ask'
            permissionDecisionReason = $msg
        }
        systemMessage = $msg
    } | ConvertTo-Json -Compress
    Write-Output $json
    exit 0
}
