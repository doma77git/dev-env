```mermaid
flowchart TD
    START(["irm gist/bootstrap.ps1 | iex"]) --> PH00[PHASE 00: CORE CHECK<br/>scripts/00-core-check.ps1<br/>PS7, git, connectivity<br/>→ exit 1 if missing (no install)]
    
    PH00 --> PS7{PS version?}
    PS7 -->|PS5.x| PS5_EXIT[❌ PowerShell 5.x<br/>→ winget install Microsoft.PowerShell<br/>→ exit 1]
    PS5_EXIT --> EXIT1([exit 1])
    PS7 -->|PS7+| PS7OK[✅ PS7 OK]
    PS7OK --> GIT{git?}
    
    GIT -->|no| GIT_EXIT[❌ Git not found<br/>→ winget install Git.Git<br/>→ exit 1]
    GIT_EXIT --> EXIT1
    GIT -->|yes| GIT_OK[✅ git OK]
    GIT_OK --> NET{github.com reachable?}
    
    NET -->|offline| OFFLINE[⚠ Offline<br/>→ Warning only<br/>→ Continue]
    NET -->|online| ONLINE[✅ online]
    
    OFFLINE --> PH30
    ONLINE --> PH30
    
    subgraph "ALWAYS RUNS (read-only)"
        PH30[PHASE 30: CLONE<br/>scripts/30-clone.ps1<br/>git clone/pull<br/>Remove-Item scripts/ + checkout<br/>→ always runs (read-only)]
        PH10[PHASE 10: DETECT<br/>scripts/10-detect.ps1<br/>fingerprint, OS, tools,<br/>PATH, OneDrive, corporate<br/>Compare with history]
        PH20[PHASE 20: REPORT<br/>scripts/20-report.ps1<br/>JSON display + save<br/>→ report-*.json + machines.json]
        PH40[PHASE 40: PROFILE<br/>scripts/40-profile.ps1<br/>home/work/lab/server<br/>git, GitHub, SSH]
    end
    
    PH30 --> PH10
    PH10 --> PH20
    PH20 --> PH40
    
    PH40 --> WHATIF{WhatIf?<br/>dry-run mode?}
    
    WHATIF -->|YES| DRYRUN[⚠ DRY-RUN<br/>→ 50-60 all dry-run<br/>→ confirm timeout → skip<br/>→ 70 runs normally]
    
    WHATIF -->|NO| PH50
    
    subgraph "MODIFICATION (ShouldProcess)"
        PH50[PHASE 50: SETUP<br/>scripts/50-setup-{profile}.ps1<br/>Packages, dirs, git config<br/>ShouldProcess: -WhatIf, -Confirm]
        PH50 --> PH50_WHATIF{Shows dry-run<br/>then confirm?}
        PH50_WHATIF -->|WhatIf only| PH50_DONE[done]
        PH50_WHATIF -->|no switch| PH50_CONFIRM{{"❓ Apply changes? [y/N] 10s"}}
        PH50_CONFIRM -->|Y / -Force| PH50_APPLY[Apply]
        PH50_CONFIRM -->|N / timeout| PH50_SKIP[Skip]
        PH50_APPLY --> PH60
        PH50_SKIP --> PH60
        
        PH60[PHASE 60: REPAIR<br/>scripts/60-repair.ps1<br/>PATH, HOME, OneDrive, SSH<br/>ShouldProcess: -WhatIf, -Confirm]
        PH60 --> PH60_WHATIF{Shows issues<br/>then confirm?}
        PH60_WHATIF -->|WhatIf only| PH60_DONE[done]
        PH60_WHATIF -->|no switch| PH60_CONFIRM{{"❓ Apply repairs? [y/N] 10s"}}
        PH60_CONFIRM -->|Y / -Force| PH60_APPLY[Apply]
        PH60_CONFIRM -->|N / timeout| PH60_SKIP[Skip]
        PH60_APPLY --> PH70
        PH60_SKIP --> PH70
    end
    
    DRYRUN --> PH70
    
    PH70[PHASE 70: TEST<br/>scripts/70-test.ps1<br/>14 checks → automatic]
    
    PH70 --> PH70_RESULT{Results}
    PH70_RESULT -->|0 fail| PASS([✅ EXIT 0])
    PH70_RESULT -->|>0 fail| FAIL([⚠ EXIT 1<br/>print summary])
    
    style EXIT1 fill:#ff4444,color:white
    style PASS fill:#44aa44,color:white
    style FAIL fill:#ff8800,color:white
    style PH50_CONFIRM fill:#8888ff,color:white
    style PH60_CONFIRM fill:#8888ff,color:white
```