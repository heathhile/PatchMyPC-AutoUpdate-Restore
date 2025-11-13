# PatchMyPC Auto-Update Restoration Guide

This folder contains scripts and documentation for restoring automatic updates after PatchMyPC Enterprise Plus license expiration.

## Files

- `Restore-AutoUpdates-QuickFix.ps1` - Quick fix for urgent machines
- `Restore-AutoUpdates-PlatformScript.ps1` - Combined script for Intune Platform Scripts deployment
- `Detect-AutoUpdateStatus.ps1` - Detection script for Intune Remediations
- `Remediate-AutoUpdates.ps1` - Remediation script for Intune Remediations
- `PLATFORM-SCRIPTS-DEPLOYMENT.md` - Guide for deploying via Intune Platform Scripts
- `Intune-Configuration-Cleanup.md` - Guide for removing PatchMyPC Intune configurations

## Quick Fix (Urgent Machines)

### Usage
1. Copy `Restore-AutoUpdates-QuickFix.ps1` to the target machine
2. Run PowerShell as Administrator
3. Execute: `.\Restore-AutoUpdates-QuickFix.ps1`
4. Restart the machine
5. Verify updates work (chrome://settings/help, etc.)

### What it does
- Removes registry blocks for Chrome, Firefox, Edge, Adobe
- Enables update services (Google Update, Mozilla Maintenance, etc.)
- Re-enables scheduled update tasks
- Removes Group Policy registry settings

## Planned Rollout (Intune)

### Option A: Platform Scripts (Most Common)
Use if you have access to **Devices > Scripts** but not **Remediations**.

1. See detailed guide: `PLATFORM-SCRIPTS-DEPLOYMENT.md`
2. Upload `Restore-AutoUpdates-PlatformScript.ps1` to Intune
3. Assign to device groups
4. Monitor deployment in Intune portal

### Option B: Remediations (Advanced Monitoring)
Use if you have access to **Devices > Remediations**.

1. See detailed guide: `QUICK-START.md`
2. Upload `Detect-AutoUpdateStatus.ps1` as detection script
3. Upload `Remediate-AutoUpdates.ps1` as remediation script
4. Configure schedule (daily recommended during transition)
5. Assign to target groups

### Deployment Strategy
1. **Pilot Group** (10-20 machines) - Deploy first, monitor for 1 week
2. **Phase 1** (25% of machines) - Deploy if pilot successful
3. **Phase 2** (50% remaining) - Deploy after Phase 1 stable
4. **Phase 3** (All remaining) - Final rollout

## Intune Configuration Cleanup

See `Intune-Configuration-Cleanup.md` for detailed steps to remove:
- PatchMyPC configuration profiles
- Application deployments
- Update policies
- Proactive remediations

## Applications Covered

- Google Chrome
- Mozilla Firefox
- Microsoft Edge
- Adobe Acrobat/Reader
- Zoom
- VLC Media Player
- And other common applications with scheduled update tasks

## Verification

After running scripts, verify updates work:
- **Chrome**: Navigate to `chrome://settings/help`
- **Firefox**: Help > About Firefox
- **Edge**: Navigate to `edge://settings/help`
- **Adobe**: Help > Check for Updates

## Troubleshooting

### Updates still not working?
1. Check if Group Policy Objects (GPOs) from domain are blocking updates
   - Run: `gpresult /h gpreport.html` and review
2. Verify services are actually running: `Get-Service *update* | Format-Table`
3. Check scheduled tasks: `Get-ScheduledTask | Where {$_.TaskName -like "*update*"}`
4. May need to reinstall the application to restore update components

### Common Issues
- **Chrome still won't update**: Reinstall Chrome from google.com/chrome
- **Scheduled tasks won't enable**: Check if disabled via GPO
- **Services won't start**: Check Windows Event Viewer for service errors
