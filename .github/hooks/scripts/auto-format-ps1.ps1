#!/usr/bin/env pwsh
# === .github/hooks/scripts/auto-format-ps1.ps1 =================
# ROLE:   PostToolUse hook — auto-format .ps1 after write
#         Automatické formátování .ps1 po zápisu
# INPUT:  JSON on stdin with tool_name + tool_input
# OUTPUT: JSON on stdout
# ==============================================================
$ErrorActionPreference = "Continue"

$input = $input | Out-String
if ([string]::IsNullOrWhiteSpace($input)) {
    Write-Output '{}'
    exit 0
}

try {
    $hookData = $input | ConvertFrom-Json
} catch {
    Write-Output '{}'
    exit 0
}

$writeTools = @('create_file', 'replace_string_in_file', 'insert_edit_into_file')
$toolName = $hookData.tool_name

if ($toolName -notin $writeTools) {
    Write-Output '{}'
    exit 0
}

$filePath = $hookData.tool_input.filePath
if (-not $filePath -or $filePath -notmatch '\.ps1$') {
    Write-Output '{}'
    exit 0
}

# Try PSScriptAnalyzer first
$analyzer = Get-Command Invoke-Formatter -ErrorAction SilentlyContinue
if ($analyzer) {
    try {
        $settings = @{
            'IncludeRules' = @(
                'PSPlaceOpenBrace',
                'PSPlaceCloseBrace',
                'PSUseConsistentWhitespace',
                'PSUseConsistentIndentation',
                'PSAlignAssignmentStatement',
                'PSUseCorrectCasing'
            )
            'Rules' = @{
                'PSPlaceOpenBrace' = @{ 'OnSameLine' = $true }
                'PSPlaceCloseBrace' = @{ 'OnSameLine' = $false }
                'PSUseConsistentIndentation' = @{ 'IndentationSize' = 4 }
                'PSUseCorrectCasing' = @{ 'Severity' = 'Warning' }
            }
        }
        $formatted = Invoke-Formatter -ScriptDefinition (Get-Content $filePath -Raw) -Settings $settings
        if ($formatted) {
            Set-Content -Path $filePath -Value $formatted -NoNewline
            $formatted = $null
        }
    } catch {
        # PSScriptAnalyzer failed — not critical
    }
    $analyzer = $null
} else {
    # Fallback: basic cleanup
    try {
        $lines = Get-Content $filePath
        $newLines = @()
        foreach ($line in $lines) {
            # Trim trailing whitespace
            $line = $line -replace '\s+$', ''
            $newLines += $line
        }
        # Ensure trailing newline
        $content = ($newLines -join "`n") + "`n"
        Set-Content -Path $filePath -Value $content -NoNewline
        $lines = $null
        $newLines = $null
        $content = $null
    } catch {
        # Non-critical
    }
}

Write-Output '{}'
exit 0
