# ADR-0012: Explicit Android backup exclusion

**Status:** Accepted  
**Date:** 2026-10-15

## Context

V1 stores progression, preferences and a malformed-save diagnostic copy locally.
Android enables automatic backup by default, which would make statements about
local storage and reset incomplete. Android 12 separates cloud backup from device
transfer; `allowBackup=false` alone does not exclude all OEM transfer behavior.

## Decision

Set `android:allowBackup=false`. Declare legacy `fullBackupContent` exclusions and
Android 12+ `dataExtractionRules` exclusions for cloud backup and device transfer.
Exclude every documented credential/device protected data domain, including root,
files (covering DataStore), preferences, databases and app external files. No custom
backup agent, cloud restore or cross-platform transfer is provided by Candyverse.

## Consequences

Progress stays local through the application APIs and is not deliberately included
in standard Android backup or transfer. Reset removes the canonical save and local
diagnostic copy. Uninstall can remove progress. This is a configuration contract,
not a guarantee about privileged, rooted or manufacturer-specific device tools;
privacy text must not claim every possible system copy is erased by reset.
Verify the final merged manifest and packaged rules on the release artifact.
Actual restore/transfer behavior on OEM hardware remains part of release QA.

## Alternatives rejected

Implicit defaults or `allowBackup=false` alone — inconsistent device transfer
behavior. Adding a cloud save — outside frozen V1 scope.

## Source checked 2026-10-15

[Android Auto Backup documentation](https://developer.android.com/identity/data/autobackup?hl=en)
provides the legacy/new rule formats and OEM limitation.
