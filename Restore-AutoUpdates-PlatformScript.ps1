#Requires -Version 5.1
<#
.SYNOPSIS
    Intune Platform Script - Restore auto-update functionality

.DESCRIPTION
    This script detects and remediates auto-update blocks left by PatchMyPC.
    Designed for deployment via Intune > Devices > Scripts.

    This script will:
    1. Check if auto-updates are blocked
    2. If blocked, remove the blocks and restore functionality
    3. Log results for Intune reporting

.NOTES
    Deploy via Intune > Devices > Scripts > Add > Windows 10 and later
    Run this script using the logged on credentials: No (run as SYSTEM)
    Enforce script signature check: No (unless you sign scripts)
    Run script in 64-bit PowerShell: Yes
#>

$ErrorActionPreference = "Continue"
$logEntries = @()
$remediationPerformed = $false

function Write-Log {
    param($Message, $Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    $script:logEntries += $logEntry

    switch ($Level) {
        "Error" { Write-Error $logEntry }
        "Warning" { Write-Warning $logEntry }
        default { Write-Output $logEntry }
    }
}

Write-Log "=== Auto-Update Restoration Script Started ===" "Info"

# Function to check and fix services
function Repair-UpdateService {
    param($ServiceName, $DisplayName)

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.StartType -eq 'Disabled') {
                Write-Log "Found disabled service: $DisplayName" "Warning"
                Set-Service -Name $ServiceName -StartupType Automatic -ErrorAction Stop
                Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
                Write-Log "[FIXED] Re-enabled service: $DisplayName" "Info"
                $script:remediationPerformed = $true
            }
            else {
                Write-Log "Service OK: $DisplayName" "Info"
            }
        }
    }
    catch {
        Write-Log "Could not configure $DisplayName : $_" "Error"
    }
}

# Function to check and fix scheduled tasks
function Repair-UpdateTasks {
    param($TaskPattern)

    try {
        $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like $TaskPattern } -ErrorAction SilentlyContinue

        foreach ($task in $tasks) {
            if ($task.State -eq 'Disabled') {
                Write-Log "Found disabled task: $($task.TaskName)" "Warning"
                try {
                    Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
                    Write-Log "[FIXED] Re-enabled task: $($task.TaskName)" "Info"
                    $script:remediationPerformed = $true
                }
                catch {
                    Write-Log "Failed to enable task: $($task.TaskName) - $_" "Error"
                }
            }
        }
    }
    catch {
        Write-Log "Error processing tasks for pattern '$TaskPattern': $_" "Error"
    }
}

# Function to check and remove registry blocks
function Remove-RegistryBlock {
    param($Path, $Name, $AppName)

    try {
        if (Test-Path $Path) {
            if ($Name) {
                # Check and remove specific value
                $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
                if ($null -ne $value) {
                    Write-Log "Found registry block for $AppName at $Path\$Name" "Warning"
                    Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
                    Write-Log "[FIXED] Removed registry value for $AppName" "Info"
                    $script:remediationPerformed = $true
                }
            }
            else {
                # Remove entire key if it exists
                Write-Log "Found policy key for $AppName at $Path" "Warning"
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
                Write-Log "[FIXED] Removed policy key for $AppName" "Info"
                $script:remediationPerformed = $true
            }
        }
    }
    catch {
        Write-Log "Failed to remove registry block for $AppName : $_" "Error"
    }
}

# Google Chrome
Write-Log "--- Checking Google Chrome ---" "Info"
Remove-RegistryBlock -Path "HKLM:\SOFTWARE\Policies\Google\Update" -Name $null -AppName "Chrome Updates"
Remove-RegistryBlock -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name $null -AppName "Chrome Policies"
Repair-UpdateService -ServiceName "gupdate" -DisplayName "Google Update Service (gupdate)"
Repair-UpdateService -ServiceName "gupdatem" -DisplayName "Google Update Service (gupdatem)"
Repair-UpdateTasks -TaskPattern "*GoogleUpdate*"

# Mozilla Firefox
Write-Log "--- Checking Mozilla Firefox ---" "Info"
Remove-RegistryBlock -Path "HKLM:\SOFTWARE\Policies\Mozilla\Firefox" -Name "DisableAppUpdate" -AppName "Firefox"
Repair-UpdateService -ServiceName "MozillaMaintenance" -DisplayName "Mozilla Maintenance Service"
Repair-UpdateTasks -TaskPattern "*Mozilla*"

# Microsoft Edge
Write-Log "--- Checking Microsoft Edge ---" "Info"
Remove-RegistryBlock -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "UpdateDefault" -AppName "Edge"
Repair-UpdateService -ServiceName "edgeupdate" -DisplayName "Microsoft Edge Update (edgeupdate)"
Repair-UpdateService -ServiceName "edgeupdatem" -DisplayName "Microsoft Edge Update (edgeupdatem)"
Repair-UpdateTasks -TaskPattern "*EdgeUpdate*"

# Adobe Acrobat/Reader
Write-Log "--- Checking Adobe Acrobat/Reader ---" "Info"
Repair-UpdateService -ServiceName "AdobeARMservice" -DisplayName "Adobe Acrobat Update Service"
Repair-UpdateTasks -TaskPattern "*Adobe*"

# Zoom
Write-Log "--- Checking Zoom ---" "Info"
Repair-UpdateTasks -TaskPattern "*Zoom*"

# VLC
Write-Log "--- Checking VLC ---" "Info"
Repair-UpdateTasks -TaskPattern "*VideoLAN*"

# Summary
Write-Log "=== Script Completion Summary ===" "Info"
if ($remediationPerformed) {
    Write-Log "STATUS: Remediation performed - Auto-update blocks were found and removed" "Info"
    Write-Log "RECOMMENDATION: Restart may be required for all changes to take effect" "Info"
}
else {
    Write-Log "STATUS: No issues found - Auto-updates are properly configured" "Info"
}

Write-Log "Total log entries: $($logEntries.Count)" "Info"

# Exit with success
# Intune Platform Scripts: Exit 0 = success, Exit 1 = failure
exit 0
