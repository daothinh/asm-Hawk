# ASM-Hawk Tool Container Sync Script (PowerShell)
# Syncs tool containers from ars0n-framework-v2

param(
    [Parameter(Mandatory = $false)]
    [string]$Source,
    
    [string]$Destination = "",
    
    [string]$Tool,
    
    [switch]$DryRun,
    
    [switch]$NoBackup,
    
    [switch]$Rebuild,
    
    [switch]$List
)

# Tool list
$TOOLS = @(
    "subfinder", "httpx", "nuclei", "katana", "ffuf", "dnsx",
    "gospider", "waybackurls", "shuffledns", "cewl", "assetfinder",
    "metabigor", "sublist3r", "subdomainizer", "github-recon",
    "cloud_enum", "linkfinder"
)

if ($List) {
    Write-Host ""
    Write-Host "Available tools:" -ForegroundColor Cyan
    foreach ($t in $TOOLS) {
        Write-Host "  - $t"
    }
    exit 0
}

# Set default destination if not provided
if ([string]::IsNullOrEmpty($Destination)) {
    $ScriptDir = Split-Path -Parent $PSScriptRoot
    if ([string]::IsNullOrEmpty($ScriptDir)) {
        $ScriptDir = Get-Location
    }
    $Destination = $ScriptDir
}

# Validate source
if ([string]::IsNullOrEmpty($Source)) {
    Write-Host "Error: Source directory is required. Use -Source parameter" -ForegroundColor Red
    Write-Host "Example: .\Sync-Ars0nTools.ps1 -Source 'C:\path\to\ars0n-framework-v2'" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $Source)) {
    Write-Host "Error: Source directory not found: $Source" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "$Source\docker")) {
    Write-Host "Error: No docker directory in source" -ForegroundColor Red
    exit 1
}

# Tools to sync
if (-not [string]::IsNullOrEmpty($Tool)) {
    $ToolsToSync = @($Tool)
}
else {
    $ToolsToSync = $TOOLS
}

# Header
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Blue
Write-Host "         ASM-Hawk Tool Container Sync (PowerShell)                " -ForegroundColor Blue
Write-Host "==================================================================" -ForegroundColor Blue
Write-Host "Source: $Source" -ForegroundColor Yellow
Write-Host "Dest:   $Destination" -ForegroundColor Yellow
Write-Host "Tools:  $($ToolsToSync.Count)" -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "Mode:   DRY RUN" -ForegroundColor Yellow
}
Write-Host "==================================================================" -ForegroundColor Blue

# Backup
if (-not $NoBackup -and -not $DryRun) {
    $BackupDir = Join-Path $Destination "docker\.backup\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host ""
    Write-Host "Creating backup..." -ForegroundColor Blue
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    
    foreach ($t in $ToolsToSync) {
        $ToolPath = Join-Path $Destination "docker\$t"
        if (Test-Path $ToolPath) {
            Copy-Item -Recurse -Force $ToolPath $BackupDir
        }
    }
    Write-Host "Backup saved to: $BackupDir" -ForegroundColor Green
}

# Sync
Write-Host ""
Write-Host "Syncing tool containers..." -ForegroundColor Blue
$Synced = 0
$Skipped = 0
$Errors = 0

foreach ($t in $ToolsToSync) {
    $SourcePath = Join-Path $Source "docker\$t"
    $DestPath = Join-Path $Destination "docker\$t"
    
    if (-not (Test-Path $SourcePath)) {
        Write-Host "   [SKIP] $t - Not found in source" -ForegroundColor Yellow
        $Skipped++
        continue
    }
    
    if ($DryRun) {
        Write-Host "   [DRY] $t - Would sync from $SourcePath" -ForegroundColor Cyan
    }
    else {
        try {
            if (Test-Path $DestPath) {
                Remove-Item -Recurse -Force $DestPath
            }
            Copy-Item -Recurse -Force $SourcePath $DestPath
            Write-Host "   [OK] $t - Synced" -ForegroundColor Green
            $Synced++
        }
        catch {
            Write-Host "   [ERR] $t - Failed: $_" -ForegroundColor Red
            $Errors++
        }
    }
}

# Summary
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Blue
Write-Host "Summary:"
Write-Host "  Synced: $Synced" -ForegroundColor Green
Write-Host "  Skipped: $Skipped" -ForegroundColor Yellow
Write-Host "  Errors: $Errors" -ForegroundColor Red
Write-Host "==================================================================" -ForegroundColor Blue

# Rebuild
if ($Rebuild -and -not $DryRun -and $Errors -eq 0) {
    Write-Host ""
    Write-Host "Rebuilding containers..." -ForegroundColor Blue
    Push-Location $Destination
    
    if (-not [string]::IsNullOrEmpty($Tool)) {
        docker-compose build $Tool
    }
    else {
        $toolsString = $ToolsToSync -join ' '
        Invoke-Expression "docker-compose build $toolsString"
    }
    
    Pop-Location
    Write-Host "Containers rebuilt" -ForegroundColor Green
}

Write-Host ""
Write-Host "Sync complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Review changes in docker\ directory"
Write-Host "  2. Test containers: docker-compose up -d subfinder httpx nuclei"
Write-Host "  3. Run integration tests"
Write-Host ""
