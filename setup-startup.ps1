# setup-startup.ps1
# Run this ONCE to register the merge task in Task Scheduler.
# After that, merge.ps1 will run automatically every time you log in to Windows.
#
# Usage:
#   Right-click setup-startup.ps1 -> "Run with PowerShell"
#   (or run from a PowerShell terminal)

$TaskName = "AI Instructions Merge"

# Ask for paths interactively
Write-Host ""
Write-Host "=== AI Instructions Merge - Startup Setup ==="
Write-Host ""

$MergeScript = Read-Host "Path to merge.ps1"
$MergeScript = $MergeScript.Trim('"').Trim("'")

if (-not (Test-Path $MergeScript)) {
    Write-Error "File not found: $MergeScript"
    exit 1
}

$DestRoot = Read-Host "Destinations root folder (-All argument)"
$DestRoot = $DestRoot.Trim('"').Trim("'")

if (-not (Test-Path $DestRoot)) {
    Write-Error "Folder not found: $DestRoot"
    exit 1
}

Write-Host ""

# Build the command Task Scheduler will run
$argument = "-NonInteractive -ExecutionPolicy RemoteSigned -Command " +
            "& '$MergeScript' -All '$DestRoot'"

$action    = New-ScheduledTaskAction `
                 -Execute "powershell.exe" `
                 -Argument $argument

$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

$principal = New-ScheduledTaskPrincipal `
                 -UserId $env:USERNAME `
                 -LogonType Interactive `
                 -RunLevel Limited

$settings  = New-ScheduledTaskSettingsSet `
                 -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
                 -StartWhenAvailable `
                 -DontStopIfGoingOnBatteries `
                 -AllowStartIfOnBatteries

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed existing task: $TaskName"
}

Register-ScheduledTask `
    -TaskName    $TaskName `
    -Action      $action `
    -Trigger     $trigger `
    -Principal   $principal `
    -Settings    $settings `
    -Description "Fetches and merges AI instruction files from GitHub on login." | Out-Null

Write-Host "[OK] Task registered: '$TaskName'"
Write-Host "     Runs at logon for user: $env:USERNAME"
Write-Host "     Script      : $MergeScript"
Write-Host "     Destinations: $DestRoot"
Write-Host ""
Write-Host "To run it right now without logging out:"
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host ""
Write-Host "To remove it later:"
Write-Host "  Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
Write-Host ""
Read-Host "Press Enter to close"