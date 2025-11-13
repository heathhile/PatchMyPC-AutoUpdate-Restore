# Intune Platform Scripts Deployment Guide

Use this guide if you have access to **Intune > Devices > Scripts** but NOT **Remediations**.

## What are Platform Scripts?

Platform Scripts (formerly called PowerShell Scripts) allow you to deploy and run PowerShell scripts on Windows devices managed by Intune. Unlike Remediations, these are single scripts that run once when deployed (or on a schedule you define).

## Prerequisites

**Licensing Requirements:**
- Microsoft 365 Business Premium
- Microsoft 365 E3 or E5
- Microsoft Intune (standalone)

**Permissions Required:**
- Intune Administrator or Global Administrator role

## Deployment Steps

### Step 1: Add the Script to Intune

1. **Log into Intune admin center**: https://intune.microsoft.com

2. **Navigate to Scripts**:
   - Go to: **Devices > Scripts and remediations > Platform scripts**
   - Click **+ Add > Windows 10 and later**

3. **Basics Tab**:
   - Name: `Restore Auto-Updates - PatchMyPC Cleanup`
   - Description: `Detects and removes PatchMyPC update blocks, restores auto-update functionality for Chrome, Firefox, Edge, Adobe, and other applications`

4. **Script settings Tab**:
   - **Script location**: Upload `Restore-AutoUpdates-PlatformScript.ps1`
   - **Run this script using the logged on credentials**: **No** (runs as SYSTEM)
   - **Enforce script signature check**: **No** (unless you sign your scripts)
   - **Run script in 64-bit PowerShell host**: **Yes**

5. **Assignments Tab**:

   **Pilot Deployment (Recommended First)**:
   - Click **+ Add group**
   - Select a pilot group with 10-20 test devices
   - This allows you to verify the script works before wider deployment

   **Full Deployment (After Pilot Success)**:
   - Click **+ Add group**
   - Select **All devices** or specific device groups
   - Apply to all affected machines

6. **Review + Add**:
   - Review all settings
   - Click **Add** to deploy

### Step 2: Monitor Deployment

1. **Navigate to the Script**:
   - Go to: **Devices > Scripts and remediations > Platform scripts**
   - Click on your script: `Restore Auto-Updates - PatchMyPC Cleanup`

2. **Check Device Status**:
   - Click **Device status** tab
   - View deployment progress:
     - **Success**: Script ran successfully
     - **Pending**: Waiting to run on device
     - **Failed**: Script encountered an error

3. **View Output Logs**:
   - Click on a specific device
   - View **Output** to see the script's log messages
   - Look for `[FIXED]` entries showing what was remediated

### Step 3: Verify on Test Machines

After 1-2 hours, verify on pilot machines:

```powershell
# Check update services are enabled
Get-Service gupdate, gupdatem, edgeupdate, MozillaMaintenance -ErrorAction SilentlyContinue |
    Format-Table Name, Status, StartType

# Check policy blocks are removed
Test-Path "HKLM:\SOFTWARE\Policies\Google\Update"      # Should be False
Test-Path "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"    # Should be False or no DisableAppUpdate value

# Check scheduled tasks are enabled
Get-ScheduledTask *GoogleUpdate*, *EdgeUpdate*, *Mozilla* |
    Where-Object State -eq 'Disabled'  # Should return nothing
```

**Test Browser Updates**:
- Chrome: Navigate to `chrome://settings/help`
- Firefox: Help > About Firefox
- Edge: Navigate to `edge://settings/help`

### Step 4: Expand Deployment

If pilot is successful after 24-48 hours:
1. Return to **Devices > Scripts and remediations > Platform scripts**
2. Click your script
3. Go to **Assignments**
4. Add more groups or assign to **All devices**

## Understanding Script Output

The script logs everything it does. Look for these indicators:

**No Issues Found**:
```
STATUS: No issues found - Auto-updates are properly configured
```

**Issues Found and Fixed**:
```
[FIXED] Re-enabled service: Google Update Service
[FIXED] Removed registry value for Chrome
STATUS: Remediation performed - Auto-update blocks were found and removed
```

## Re-running the Script

Platform Scripts typically run **once** when assigned. To re-run:

**Option 1: Manual Sync**
- On the device: Settings > Accounts > Access work or school > Info > Sync

**Option 2: Intune Remote Action**
- Intune > Devices > All devices > [Select device] > Sync

**Option 3: Wait for Check-in**
- Devices check in every ~8 hours by default
- Script will run again if you re-assign it

## Differences from Remediations

| Feature | Platform Scripts | Remediations |
|---------|------------------|--------------|
| Detect + Remediate | Single script | Separate detect/remediate scripts |
| Schedule | Runs once when deployed | Runs on schedule (daily, weekly, etc.) |
| Reporting | Success/Fail only | Detailed compliance reporting |
| Use Case | One-time fixes | Ongoing monitoring |

## Troubleshooting

**Script shows as "Pending" for a long time**
- Devices may be offline or not checking in
- Wait 8-12 hours for next check-in cycle
- Or manually sync the device

**Script failed on some devices**
- Click the device to view error output
- Common causes:
  - Application not installed (not an actual error)
  - Permissions issue (ensure running as SYSTEM)
  - Device offline during execution

**Updates still not working after script runs**
- Check for Group Policy Objects (GPOs) from domain
- Run: `gpresult /h C:\gporeport.html` on the device
- If domain GPOs are blocking, address at AD level

**Need to run script again**
- Edit the script (add a comment)
- Save the script
- This triggers re-deployment to assigned devices

## Timeline Recommendation

| Timeframe | Action |
|-----------|--------|
| Day 1 | Deploy to pilot group (10-20 devices) |
| Day 2-3 | Monitor pilot results, verify updates work |
| Day 4 | Deploy to 25% of remaining devices |
| Week 2 | Deploy to 50% of remaining devices |
| Week 3 | Deploy to 100% of devices |
| Week 4+ | Clean up PatchMyPC Intune configurations |

## Next Steps

After successful deployment:
1. Follow the guide in `Intune-Configuration-Cleanup.md`
2. Remove PatchMyPC configuration profiles
3. Clean up old app assignments
4. Document changes for your records

## Support

For issues:
- Check device-specific logs in Intune portal
- Review script output for error messages
- Verify device can reach update servers
- Consult `README.md` for additional troubleshooting
