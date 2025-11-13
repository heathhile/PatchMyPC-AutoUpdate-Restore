# Intune Configuration Cleanup Guide

Steps to remove PatchMyPC Enterprise Plus configurations from Intune after license expiration.

## 1. Identify PatchMyPC Configurations

### Applications
Navigate to: **Intune > Apps > All apps**

Look for applications with these characteristics:
- Publisher: "PatchMyPC" or managed by PatchMyPC
- Description containing "PatchMyPC" or "PMPC"
- Application names that were deployed via PatchMyPC catalog

**Action**: Take inventory before removal
```
Apps > All apps > Export to CSV
```

### Configuration Profiles
Navigate to: **Intune > Devices > Configuration profiles**

Look for profiles created by or related to PatchMyPC:
- Profiles that disable auto-updates
- Registry settings for application update suppression
- Custom OMA-URI settings related to updates

**Common profile names**:
- "PatchMyPC - Disable Auto Updates"
- "PMPC - Application Update Control"
- Profiles with update suppression policies

### Update Rings / Policies
Navigate to: **Intune > Devices > Update policies for Windows 10 and later**

Check for any custom policies related to third-party updates.

### Scripts & Remediations
Navigate to: **Intune > Devices > Scripts and remediations**

Look for:
- PatchMyPC detection/remediation scripts
- Update suppression scripts
- Application management scripts

## 2. Removal Order (Important!)

Follow this order to avoid disruption:

### Phase 1: Deploy Remediation FIRST
1. Deploy the auto-update restoration remediation scripts (from this folder)
2. Let them run for 1-2 days to restore auto-updates on machines
3. Monitor compliance before proceeding

### Phase 2: Remove Update Suppression Policies
Navigate to: **Intune > Devices > Configuration profiles**

For each PatchMyPC-related profile:
1. Click the profile
2. Go to **Properties > Assignments**
3. Note current assignments for your records
4. Remove assignments or delete the profile
5. Monitor for 24-48 hours

### Phase 3: Remove or Reassign Applications
Navigate to: **Intune > Apps > All apps**

For each PatchMyPC-managed application:

**Option A: Keep installed, remove Intune management**
1. Change assignment intent from "Required" to "Available"
2. Eventually remove assignment entirely
3. Apps will stay installed but won't be managed

**Option B: Replace with new deployment**
1. Create new app deployment (Win32 or Store app)
2. Assign to same groups
3. Let new deployment install
4. Remove old PatchMyPC assignment

**Option C: Complete removal**
1. Change assignment to "Uninstall" (if needed)
2. Or remove assignment and let users manage

### Phase 4: Clean Up Scripts
Navigate to: **Intune > Devices > Scripts and remediations**

1. Disable any PatchMyPC-related proactive remediations
2. Delete old scripts after 30-day retention period

### Phase 5: Remove PatchMyPC Publisher Integration
If you had PatchMyPC Publisher integrated with Intune:
1. In PatchMyPC Publisher console, remove Intune connection
2. Delete the Azure AD app registration used by PatchMyPC
   - Navigate to: **Azure AD > App registrations**
   - Search for "PatchMyPC" or "PMPC"
   - Delete the app registration

## 3. Common PatchMyPC Configuration Items

### Registry Keys to Check (via Configuration Profiles)
PatchMyPC commonly sets these registry locations:

```
HKLM\SOFTWARE\Policies\Google\Update
HKLM\SOFTWARE\Policies\Google\Chrome
HKLM\SOFTWARE\Policies\Mozilla\Firefox
HKLM\SOFTWARE\Policies\Microsoft\Edge
HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader
```

**Action**: Check for configuration profiles that set these registry paths and remove them.

### Scheduled Tasks
PatchMyPC may have disabled or modified:
- `\Google\GoogleUpdateTaskMachine*`
- `\Mozilla\Firefox*`
- `\Adobe\*`
- `\Microsoft\EdgeUpdate*`

**Action**: The remediation scripts will re-enable these.

## 4. Monitoring & Validation

### Create a Monitoring Dashboard
In Intune > Devices > Monitor, track:
1. Application installation status changes
2. Policy compliance changes
3. Script execution results

### Validation Checklist
After cleanup:
- [ ] Remediation scripts deployed and running
- [ ] Update suppression policies removed
- [ ] Applications installing/updating correctly
- [ ] No orphaned configurations remain
- [ ] User impact minimal
- [ ] Help desk tickets monitored

## 5. Documentation

Document the following for your records:
1. List of all applications previously managed by PatchMyPC
2. Configuration profiles removed (with dates)
3. Assignments changed or removed
4. Any issues encountered and resolutions
5. Final state of each application (managed/unmanaged)

## 6. Alternative Going Forward

Consider these options for application management:

### Native Intune Win32 Apps
- Deploy .intunewin packages
- More control over deployments
- No third-party dependency

### Microsoft Store for Business (deprecated) / Windows Package Manager
- Use `winget` integration with Intune
- PowerShell scripts with winget commands

### Chocolatey / Ninite / Other Solutions
- Evaluate alternative third-party tools
- Consider costs vs. benefits

### Hybrid Approach
- Let users manage their own updates for some apps
- Only manage critical/security-sensitive apps via Intune
- Use auto-updates for everything else

## Timeline Recommendation

| Week | Action |
|------|--------|
| Week 1 | Deploy remediation scripts to pilot group |
| Week 2 | Monitor pilot, deploy remediations to all |
| Week 3 | Begin removing configuration profiles (25% at a time) |
| Week 4-5 | Continue profile removal, monitor compliance |
| Week 6 | Remove application assignments (if needed) |
| Week 7-8 | Clean up remaining scripts, document final state |

## Support

If you encounter issues during cleanup:
1. Check Intune device logs: Devices > [Device] > Device diagnostics
2. Review user/device assignments carefully before removal
3. Test removals on pilot group first
4. Keep PatchMyPC configurations backed up (export) for 90 days
