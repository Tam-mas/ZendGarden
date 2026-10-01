# Zend Garden execution notes

## Player update history

- For each meaningful player-visible change, add a short, non-technical entry at the top of `GardenUpdates.RELEASES` in `scripts/player_updates.gd` and use the next integer version. Keep existing numbers stable.
- Describe the experience players will notice. Omit internal refactors, tooling, dependency maintenance and other invisible work from this history; continue recording those in the root `CHANGELOG.md` as required.
- The latest entry determines the version shown in Settings and the dismissible What’s new panel. Preserve saved dismissal state and existing garden save compatibility.

## Blender on this Mac

- Blender executable: `/Applications/Blender.app/Contents/MacOS/Blender`.
- A restricted Codex shell launch on 2026-09-14 at 09:56:32 exited with SIGSEGV during startup, before asset generation. The same binary subsequently started and generated assets successfully with approved normal OS access. This is evidence for an execution-environment issue, not proof of a general Blender or MCP defect.
- For Blender subprocesses launched by Codex, use the tool's approved execution outside the restricted sandbox (`sandbox_permissions: require_escalated`). Follow the tool's approval result. Do not retry a failed restricted Blender launch in a loop.
- Run heavy Blender exports sequentially. Preserve the interactive Blender scene and user preferences.
- Do not reset preferences, remove add-ons, or downgrade Blender based only on that startup crash report.
- `tests/check_blender_sources.py` opens the source libraries read-only and verifies meshes and external images. It must run inside Blender. It does not test interactive GPU rendering.
- The game uses exported GLB assets and does not require Blender to run.
