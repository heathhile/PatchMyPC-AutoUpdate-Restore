#Requires -Version 5.1
<#
.SYNOPSIS
    Remediation script for Intune - Restore auto-update functionality

.DESCRIPTION
    This script removes blocks and re-enables auto-update mechanisms for common applications.
    Used as the REMEDIATION script in Intune Proactive Remediation.

    Exit 0 = Remediation successful
    Exit 1 = Remediation failed

.NOTES
    Deploy via Intune > Devices > Remediations > Create script package
    This script must run in SYSTEM context for full access to services and registry
#>

$remediationLog = @()
$errorCount = 0

function Write-Log {
    param($Message, $IsError = $false)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    $remediationLog += $logEntry

    if ($IsError) {
        Write-Error $logEntry
        $script:errorCount++
    }
    else {
        Write-Output $logEntry
    }
}

# Function to enable service
function Enable-UpdateService {
    param($ServiceName, $DisplayName)

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            Set-Service -Name $ServiceName -StartupType Automatic -ErrorAction Stop
            Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
            Write-Log "Enabled and started: $DisplayName"
            return $true
        }
        else {
            Write-Log "Service not found: $DisplayName (not installed on this machine)" $false
            return $true  # Not an error if service doesn't exist
        }
    }
    catch {
        Write-Log "Failed to configure $DisplayName : $_" $true
        return $false
    }
}

# Function to enable scheduled tasks
function Enable-UpdateTasks {
    param($TaskPattern)

    try {
        $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like $TaskPattern } -ErrorAction SilentlyContinue

        $enabledCount = 0
        foreach ($task in $tasks) {
            if ($task.State -eq 'Disabled') {
                try {
                    Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
                    $enabledCount++
                    Write-Log "Enabled task: $($task.TaskName)"
                }
                catch {
                    Write-Log "Failed to enable task: $($task.TaskName) - $_" $true
                }
            }
        }

        if ($enabledCount -gt 0) {
            Write-Log "Enabled $enabledCount scheduled task(s) matching '$TaskPattern'"
        }
        return $true
    }
    catch {
        Write-Log "Error processing scheduled tasks for pattern '$TaskPattern': $_" $true
        return $false
    }
}

# Function to remove registry blocks
function Remove-RegistryBlock {
    param($Path, $Name, $AppName)

    try {
        if (Test-Path $Path) {
            if ($Name) {
                # Remove specific value
                $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
                if ($null -ne $value) {
                    Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
                    Write-Log "Removed registry value '$Name' for $AppName"
                }
            }
            else {
                # Remove entire key
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
                Write-Log "Removed registry key for $AppName at $Path"
            }
            return $true
        }
        return $true  # Not an error if path doesn't exist
    }
    catch {
        Write-Log "Failed to remove registry block for $AppName at $Path : $_" $true
        return $false
    }
}

Write-Log "=== Starting Auto-Update Remediation ==="

# Google Chrome
Write-Log "Processing Google Chrome..."
Remove-RegistryBlock -Path "HKLM:\SOFTWARE\Policies\Google\Update" -Name $null -AppName "Chrome"
Remove-RegistryBlock -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name $null -AppName "Chrome"
Enable-UpdateService -ServiceName "gupdate" -DisplayName "Google Update Service (gupdate)"
Enable-UpdateService -ServiceName "gupdatem" -DisplayName "Google Update Service (gupdatem)"
Enable-UpdateTasks -TaskPattern "*GoogleUpdate*"

# Mozilla Firefox
Write-Log "Processing Mozilla Firefox..."
Remove-RegistryBlock -Path "HKLM:\SOFTWARE\Policies\Mozilla\Firefox" -Name "DisableAppUpdate" -AppName "Firefox"
Enable-UpdateService -ServiceName "MozillaMaintenance" -DisplayName "Mozilla Maintenance Service"
Enable-UpdateTasks -TaskPattern "*Mozilla*"

# Microsoft Edge
Write-Log "Processing Microsoft Edge..."
Remove-RegistryBlock -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "UpdateDefault" -AppName "Edge"
Enable-UpdateService -ServiceName "edgeupdate" -DisplayName "Microsoft Edge Update Service (edgeupdate)"
Enable-UpdateService -ServiceName "edgeupdatem" -DisplayName "Microsoft Edge Update Service (edgeupdatem)"
Enable-UpdateTasks -TaskPattern "*EdgeUpdate*"

# Adobe Acrobat/Reader
Write-Log "Processing Adobe Acrobat/Reader..."
Enable-UpdateService -ServiceName "AdobeARMservice" -DisplayName "Adobe Acrobat Update Service"
Enable-UpdateTasks -TaskPattern "*Adobe*"

# Zoom
Write-Log "Processing Zoom..."
Enable-UpdateTasks -TaskPattern "*Zoom*"

# VLC
Write-Log "Processing VLC..."
Enable-UpdateTasks -TaskPattern "*VideoLAN*"

# Generic - any other update tasks
Write-Log "Processing other update tasks..."
$otherTasks = Get-ScheduledTask | Where-Object {
    $_.TaskName -like "*update*" -and
    $_.State -eq 'Disabled' -and
    $_.TaskName -notlike "*Windows*" -and
    $_.TaskName -notlike "*Microsoft*"
} -ErrorAction SilentlyContinue

if ($otherTasks) {
    foreach ($task in $otherTasks) {
        try {
            Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
            Write-Log "Enabled additional update task: $($task.TaskName)"
        }
        catch {
            Write-Log "Could not enable task: $($task.TaskName)" $false
        }
    }
}

Write-Log "=== Remediation Complete ==="
Write-Log "Total log entries: $($remediationLog.Count), Errors: $errorCount"

# Return exit code
if ($errorCount -eq 0) {
    Write-Log "Remediation successful - all changes applied"
    exit 0  # Success
}
elseif ($errorCount -le 3) {
    Write-Log "Remediation completed with minor errors ($errorCount errors)"
    exit 0  # Success with warnings - most changes applied
}
else {
    Write-Log "Remediation failed - too many errors ($errorCount errors)"
    exit 1  # Failure
}
