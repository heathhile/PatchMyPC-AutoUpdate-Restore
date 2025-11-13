# Quick Fix Script - Restore Auto-Updates After PatchMyPC
# Run with administrator privileges on urgent machines

Write-Host "=== Restoring Auto-Updates - Quick Fix ===" -ForegroundColor Cyan

# Function to enable service
function Enable-UpdateService {
    param($ServiceName, $DisplayName)

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-Host "Enabling $DisplayName..." -ForegroundColor Yellow
            Set-Service -Name $ServiceName -StartupType Automatic -ErrorAction Stop
            Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
            Write-Host "  ✓ $DisplayName enabled and started" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  ! Could not configure $DisplayName : $_" -ForegroundColor Red
    }
}

# Function to enable scheduled tasks
function Enable-UpdateTasks {
    param($TaskPath)

    Write-Host "Enabling scheduled tasks in $TaskPath..." -ForegroundColor Yellow
    $tasks = Get-ScheduledTask -TaskPath $TaskPath -ErrorAction SilentlyContinue

    foreach ($task in $tasks) {
        if ($task.State -eq 'Disabled') {
            try {
                Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
                Write-Host "  ✓ Enabled: $($task.TaskName)" -ForegroundColor Green
            }
            catch {
                Write-Host "  ! Failed to enable: $($task.TaskName)" -ForegroundColor Red
            }
        }
    }
}

# Function to remove registry blocks
function Remove-RegistryBlock {
    param($Path, $Name, $AppName)

    if (Test-Path $Path) {
        try {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $value) {
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
                Write-Host "  ✓ Removed update block for $AppName" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  ! Could not remove registry block for $AppName" -ForegroundColor Red
        }
    }
}

Write-Host "`n--- Google Chrome ---" -ForegroundColor Cyan

# Remove Chrome update policies
$chromePolicyPaths = @(
    "HKLM:\SOFTWARE\Policies\Google\Update",
    "HKLM:\SOFTWARE\Policies\Google\Chrome"
)

foreach ($path in $chromePolicyPaths) {
    if (Test-Path $path) {
        Write-Host "Removing Chrome policy blocks..." -ForegroundColor Yellow
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed policies at $path" -ForegroundColor Green
    }
}

# Enable Google Update services
Enable-UpdateService -ServiceName "gupdate" -DisplayName "Google Update Service (gupdate)"
Enable-UpdateService -ServiceName "gupdatem" -DisplayName "Google Update Service (gupdatem)"

# Enable Google scheduled tasks
Enable-UpdateTasks -TaskPath "\GoogleUpdateTaskMachine*"

Write-Host "`n--- Mozilla Firefox ---" -ForegroundColor Cyan

# Remove Firefox update policies
$firefoxPolicyPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"
if (Test-Path $firefoxPolicyPath) {
    Remove-RegistryBlock -Path $firefoxPolicyPath -Name "DisableAppUpdate" -AppName "Firefox"
}

# Enable Mozilla maintenance service
Enable-UpdateService -ServiceName "MozillaMaintenance" -DisplayName "Mozilla Maintenance Service"

# Enable Firefox scheduled tasks
Enable-UpdateTasks -TaskPath "\Mozilla\*"

Write-Host "`n--- Adobe Acrobat/Reader ---" -ForegroundColor Cyan

# Enable Adobe update services
Enable-UpdateService -ServiceName "AdobeARMservice" -DisplayName "Adobe Acrobat Update Service"

# Enable Adobe scheduled tasks
Enable-UpdateTasks -TaskPath "\Adobe*"

Write-Host "`n--- Microsoft Edge ---" -ForegroundColor Cyan

# Remove Edge update policies
$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (Test-Path $edgePolicyPath) {
    Remove-RegistryBlock -Path $edgePolicyPath -Name "UpdateDefault" -AppName "Edge"
}

# Enable Edge update services
Enable-UpdateService -ServiceName "edgeupdate" -DisplayName "Microsoft Edge Update Service (edgeupdate)"
Enable-UpdateService -ServiceName "edgeupdatem" -DisplayName "Microsoft Edge Update Service (edgeupdatem)"

# Enable Edge scheduled tasks
Enable-UpdateTasks -TaskPath "\MicrosoftEdgeUpdate*"

Write-Host "`n--- Zoom ---" -ForegroundColor Cyan

# Enable Zoom scheduled tasks
Enable-UpdateTasks -TaskPath "\Zoom\*"

Write-Host "`n--- Other Common Apps ---" -ForegroundColor Cyan

# VLC
Enable-UpdateTasks -TaskPath "\VideoLAN\*"

# Enable other update-related tasks
Write-Host "Enabling other update-related scheduled tasks..." -ForegroundColor Yellow
$allTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like "*update*" -and $_.State -eq 'Disabled' }
foreach ($task in $allTasks) {
    try {
        Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
        Write-Host "  ✓ Enabled: $($task.TaskName)" -ForegroundColor Green
    }
    catch {
        Write-Host "  ! Failed to enable: $($task.TaskName)" -ForegroundColor Red
    }
}

Write-Host "`n=== Restoration Complete ===" -ForegroundColor Green
Write-Host "Recommended: Restart the computer to ensure all changes take effect." -ForegroundColor Yellow
Write-Host "`nTo verify updates are working:" -ForegroundColor Cyan
Write-Host "  - Chrome: chrome://settings/help" -ForegroundColor White
Write-Host "  - Firefox: Help > About Firefox" -ForegroundColor White
Write-Host "  - Edge: edge://settings/help" -ForegroundColor White
