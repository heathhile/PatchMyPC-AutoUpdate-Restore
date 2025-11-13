#Requires -Version 5.1
<#
.SYNOPSIS
    Detection script for Intune Remediation - Check if auto-updates are properly enabled

.DESCRIPTION
    This script checks if application auto-update mechanisms are blocked or disabled.
    Used as the DETECTION script in Intune Proactive Remediation.

    Exit 0 = Compliant (auto-updates are enabled, no remediation needed)
    Exit 1 = Non-compliant (auto-updates are blocked, remediation needed)

.NOTES
    Deploy via Intune > Devices > Remediations > Create script package
#>

$issues = @()

# Check Chrome update policies
$chromePolicyPaths = @(
    "HKLM:\SOFTWARE\Policies\Google\Update",
    "HKLM:\SOFTWARE\Policies\Google\Chrome"
)

foreach ($path in $chromePolicyPaths) {
    if (Test-Path $path) {
        $issues += "Chrome update policy exists at $path"
    }
}

# Check Chrome update services
$chromeServices = @("gupdate", "gupdatem")
foreach ($svc in $chromeServices) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.StartType -eq 'Disabled') {
            $issues += "Chrome update service '$svc' is disabled"
        }
    }
}

# Check Firefox update policies
$firefoxPolicyPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"
if (Test-Path $firefoxPolicyPath) {
    $disableUpdate = Get-ItemProperty -Path $firefoxPolicyPath -Name "DisableAppUpdate" -ErrorAction SilentlyContinue
    if ($disableUpdate) {
        $issues += "Firefox auto-update is disabled via policy"
    }
}

# Check Mozilla Maintenance service
$mozService = Get-Service -Name "MozillaMaintenance" -ErrorAction SilentlyContinue
if ($mozService -and $mozService.StartType -eq 'Disabled') {
    $issues += "Mozilla Maintenance service is disabled"
}

# Check Edge update policies
$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (Test-Path $edgePolicyPath) {
    $updateDefault = Get-ItemProperty -Path $edgePolicyPath -Name "UpdateDefault" -ErrorAction SilentlyContinue
    if ($updateDefault -and $updateDefault.UpdateDefault -eq 0) {
        $issues += "Edge updates are disabled via policy"
    }
}

# Check Edge update services
$edgeServices = @("edgeupdate", "edgeupdatem")
foreach ($svc in $edgeServices) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.StartType -eq 'Disabled') {
            $issues += "Edge update service '$svc' is disabled"
        }
    }
}

# Check Adobe update service
$adobeService = Get-Service -Name "AdobeARMservice" -ErrorAction SilentlyContinue
if ($adobeService -and $adobeService.StartType -eq 'Disabled') {
    $issues += "Adobe update service is disabled"
}

# Check for disabled scheduled tasks (common update tasks)
$criticalTaskPatterns = @(
    "*GoogleUpdate*",
    "*Mozilla*",
    "*Adobe*",
    "*EdgeUpdate*"
)

foreach ($pattern in $criticalTaskPatterns) {
    $tasks = Get-ScheduledTask -TaskName $pattern -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Disabled' }
    if ($tasks) {
        foreach ($task in $tasks) {
            $issues += "Scheduled task disabled: $($task.TaskName)"
        }
    }
}

# Determine compliance
if ($issues.Count -eq 0) {
    Write-Output "Compliant: Auto-updates are properly enabled"
    exit 0  # Compliant - no remediation needed
}
else {
    Write-Output "Non-compliant: Found $($issues.Count) issue(s):"
    $issues | ForEach-Object { Write-Output "  - $_" }
    exit 1  # Non-compliant - remediation needed
}
