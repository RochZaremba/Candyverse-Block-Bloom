# ADR-0009: Offline Android feedback and presentation preferences

**Status:** Accepted  
**Date:** 2026-10-14

## Context

T-005 needs short original sound effects, independent mute/haptics controls and reduced motion without introducing network SDKs. V1 targets Android only. Gameplay remains pure Dart; feedback is optional presentation.

## Decision

Use a small `candyverse/feedback` MethodChannel and Android SoundPool with at most three concurrent streams, `USAGE_GAME`/`CONTENT_TYPE_SONIFICATION`, and original bundled mono PCM WAV cues. WAV assets are explicitly uncompressed for `AssetManager.openFd`; public FlutterLoader resolves bundle paths. Audio and Flutter haptics are independently gated by session SettingsModel. Mute/background stop streams; background blocks new cues; engine cleanup/activity destruction releases native resources. Missing channels or playback errors cannot block moves. No permissions, plugins or network dependencies are added.

SettingsScope combines the user preference with OS disableAnimations. Board-local FxLayer has a token-capped particle budget, no input capture, and stops on reduced motion/background without replay on resume. Token timings distinguish placement from clears. Preferences remain session-only until the T-008 application snapshot persists them. This is explicitly communicated in the current settings sheet.

## Consequences

Small offline implementation with no external audio SDK; APK packaging and Kotlin compilation are required checks. MethodChannel widget tests validate gating and lifecycle, but they do not replace an Android listening/haptics smoke test or FPS profiling. Other platforms have silent optional audio; supporting them would need a new adapter. T-008 must store and restore preferences in the one save snapshot.

## Alternatives rejected

A cross-platform audio plugin now adds an unnecessary runtime dependency for Android-only V1. Flutter SystemSound cannot supply the original candy cues. Background audio and looping music are unnecessary for this task.
