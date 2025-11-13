# Quick Start Guide

## For Urgent Machines (Immediate Fix)

1. **Copy the script to the target machine**
   ```
   Copy: Restore-AutoUpdates-QuickFix.ps1
   ```

2. **Run as Administrator**
   - Right-click PowerShell
   - Select "Run as Administrator"
   - Navigate to the script location
   - Run: `.\Restore-AutoUpdates-QuickFix.ps1`

3. **Restart the machine**

4. **Verify updates work**
   - Open Chrome: `chrome://settings/help`
   - Check if it says "Checking for updates..." or shows update available

## For Intune Deployment (Planned Rollout)

> **Note**: If you don't have access to "Remediations" in Intune, use the **Platform Scripts** option instead.
> See `PLATFORM-SCRIPTS-DEPLOYMENT.md` for detailed instructions on deploying via **Devices > Scripts**.

### Prerequisites

**Licensing Requirements:**
Intune Remediations (Proactive Remediations) is included with:
- Microsoft 365 Business Premium [OK]
- Microsoft 365 E3 or E5
- Microsoft 365 F3 with Intune Plan 1 add-on
- Enterprise Mobility + Security E3 or E5

**Permissions Required:**
- Intune Administrator or Global Administrator role

### Step 1: Create Remediation Package

1. Log into **Intune admin center** (https://intune.microsoft.com)

2. Navigate to: **Devices > Remediations**

3. Click **+ Create script package**

4. **Basics tab**:
   - Name: `Restore Auto-Updates - PatchMyPC Cleanup`
   - Description: `Removes PatchMyPC update blocks and restores auto-update functionality`
   - Publisher: `[Your IT Department]`

5. **Settings tab**:
   - **Detection script**: Upload `Detect-AutoUpdateStatus.ps1`
   - **Remediation script**: Upload `Remediate-AutoUpdates.ps1`
   - **Run this script using the logged-on credentials**: No (use system account)
   - **Enforce script signature check**: No (unless you sign your scripts)
   - **Run script in 64-bit PowerShell**: Yes

6. **Scope tags**: Select appropriate tags (if used in your environment)

7. **Assignments tab**:
   - **Pilot Phase**:
     - Click **+ Add group**
     - Select your pilot group (10-20 test machines)
     - Schedule: Daily

   - **Full Deployment** (after pilot success):
     - Assign to "All devices" or specific groups
     - Schedule: Daily (runs once per day to catch any new issues)

8. **Review + create**

### Step 2: Monitor Results

1. Go to **Intune > Devices > Remediations**
2. Click on your remediation package
3. View the **Device status** tab:
   - **Without issues**: Auto-updates already enabled (green)
   - **With issues**: Blocks detected, remediation running (yellow)
   - **Failed**: Remediation had errors (red)

### Step 3: After 24-48 Hours

1. Verify pilot machines:
   - RDP into a test machine
   - Open Chrome/Firefox and check for updates
   - Verify services are running: `Get-Service *update*`

2. If successful, expand to wider deployment

### Step 4: Clean Up Intune Configs

Follow the guide in `Intune-Configuration-Cleanup.md` to remove:
- PatchMyPC configuration profiles
- Update suppression policies
- Old app assignments

## Verification Commands

Run these on any machine to check status:

```powershell
# Check update services
Get-Service gupdate, gupdatem, edgeupdate, MozillaMaintenance | Format-Table Name, Status, StartType

# Check for policy blocks
Test-Path "HKLM:\SOFTWARE\Policies\Google\Update"
Test-Path "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"

# Check scheduled tasks
Get-ScheduledTask *GoogleUpdate*, *EdgeUpdate*, *Mozilla* | Format-Table TaskName, State

# Test Chrome update
Start-Process "chrome://settings/help"
```

## Timeline

| Day | Action |
|-----|--------|
| Day 1 | Run quick fix on urgent machines |
| Day 1-2 | Set up Intune remediation for pilot group |
| Day 3-7 | Monitor pilot group results |
| Week 2 | Deploy to 25% of devices |
| Week 3 | Deploy to remaining 75% |
| Week 4+ | Remove PatchMyPC Intune configurations |

## Troubleshooting

**Script won't run - "cannot be loaded because running scripts is disabled"**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Restore-AutoUpdates-QuickFix.ps1
```

**Services won't start**
- Check Windows Event Viewer > Windows Logs > System
- Look for service-related errors
- May need to repair/reinstall the application

**Updates still blocked**
- Check for domain-level GPOs: `gpresult /h report.html`
- If GPOs are blocking, you'll need to address at the domain level
- Contact Active Directory team to remove update suppression policies

**Intune remediation shows as failed**
- Click on the device to see detailed logs
- Common causes:
  - Insufficient permissions (ensure running as SYSTEM)
  - Application not installed on that device (not an actual error)
  - GPO overriding the changes

## Support

For issues or questions:
1. Review the full documentation in `README.md`
2. Check Intune device diagnostics logs
3. Review `Intune-Configuration-Cleanup.md` for detailed cleanup steps
