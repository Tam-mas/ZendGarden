# Security review — 19 September 2026

## Result and scope

No exposed credentials or exploitable remote application vulnerability was identified in the reviewed surface. Several defence-in-depth and build supply-chain gaps were found and hardened. This is a targeted source/configuration review and browser validation, not a guarantee that the game, engine, host, or accounts are vulnerability-free.

Reviewed the public `Tam-mas/ZendGarden` repository, reachable Git history, generated Pages files, `https://zendgarden.pages.dev`, GitHub repository security settings available through the authenticated API, and official Godot/Git LFS advisory information. The starting application revision was `2458275`.

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| Medium, build hardening | GitHub Actions used mutable version tags; checkout retained its read-only token in Git configuration. | Pinned all three actions to full upstream commit SHAs and disabled persisted checkout credentials. Workflow permissions remain read-only. |
| Medium, build hardening | The fallback Git LFS download lacked checksum verification; an arbitrary preinstalled LFS version was accepted. Godot's expected archive checksums were downloaded at build time. | Committed reviewed archive checksums, verify LFS before extraction, select pinned LFS 3.8.0 on Linux builders, and reject local LFS versions older than 3.7.1. Godot release archives are checked against committed SHA-512 values. |
| Low, browser hardening | No CSP, framing restriction, explicit HSTS header, or permissions policy. No actual XSS entry point was found. | Added same-origin CSP, framing denial, HTTPS persistence, and disabled unnecessary sensitive browser features. Moved generated inline JavaScript into an external file. |
| Medium, detection gap | GitHub secret scanning and push protection were disabled. | Enabled both and verified the settings. Enabled private vulnerability reporting and added `SECURITY.md`. |
| Low, maintenance gap | No automated action-update configuration. | Added weekly Dependabot updates for GitHub Actions. This does not enable Dependabot vulnerability alerts by itself. |
| Remaining, repository governance | `main` has no branch protection or rulesets. | Recommend a rule requiring passing build checks and pull requests, plus blocking force pushes and branch deletion. Not imposed automatically because this changes the owner's direct-push workflow. |
| Remaining, detection gap | Dependabot vulnerability alerts are disabled. | Enable in GitHub repository Settings → Security / Advanced Security. The current API credential lacks the additional scope needed to manage this setting; no credential permissions were expanded. |

## Evidence and checks

- Gitleaks 8.30.1 was downloaded from its official release and checksum-verified. Its redacted Git-history scan found no leaks (9 commits with scanned content, approximately 746 KB). A separate generated-site scan found no leaks (approximately 307 KB of scannable content). Binary assets, compressed packs, and compiled WASM are not comprehensively audited by this text-oriented scan.
- GitHub secret-scanning alerts returned an empty list after activation. Detection can change as GitHub completes scans and adds patterns.
- HTTP redirects to HTTPS. Requests for `/.git/config`, `/.env`, `/project.godot`, and `/build/import.log` returned 404 rather than file contents.
- Browser test loaded the game with the proposed CSP, observed only same-origin network requests during startup, and recorded no CSP violations from normal startup. An intentionally injected inline script was blocked.
- Web export integrity and loader tests passed. A new CI check verifies policy directives, absence of inline executable scripts, pinned action SHAs, and checksum format.
- Official Git LFS advisories include fixes in 3.6.1 and 3.7.1; the cloud build selects 3.8.0. Godot's repository advisory endpoint returned no published advisories; that is not proof of engine security.

## Application boundaries

The game is a static client application. The repository contains no Pages Functions/backend API, account system, payments, user-file upload endpoint, or server database. Names and local saves are used by Godot; the browser wrapper does not insert user content as HTML or evaluate URL parameters. There is no application credential or server secret required by the Pages build.

Saves live in the browser's IndexedDB-backed filesystem. They are neither encrypted nor cloud-synchronized. A person with access to that browser profile can read or alter them. Malformed local save JSON is only lightly validated and can break that user's game; no remote save-import endpoint was found. This is a local resilience limitation, not a demonstrated cross-user exploit.

Public assets and their permissive CORS response are intentional; they contain no authenticated data. SHA-256 pack checks catch corruption/inconsistency, not a malicious actor with control over both the deployment and its manifest.

CSP allows `wasm-unsafe-eval` for Godot's WebAssembly and inline **styles** for the engine/UI. It does not allow arbitrary inline **scripts** or general JavaScript `unsafe-eval`. Framing is denied, so embedding this game in another website's iframe would require a deliberate policy change.

## Owner follow-up and review limits

1. Enable Dependabot vulnerability alerts; action version-update PRs are already configured separately.
2. Consider protecting `main` before accepting outside contributions. Public visibility alone does not let visitors push code to the repository.
3. Confirm passkeys or 2FA on GitHub and Cloudflare, review collaborators and installed GitHub Apps, and keep Cloudflare build variables free of unrelated secrets. These account settings and Cloudflare environment secrets were not audited through an authenticated Cloudflare session.
4. Review Cloudflare preview-branch/build settings before inviting outside contributions; do not run untrusted PR builds with sensitive account credentials. GitHub's reviewed workflow uses `pull_request`, read-only permissions, no injected application secrets, and first-time-contributor approval.
5. Only execute trusted source projects locally. Godot editor imports and Blender generators are executable code. The build-tool cache and preinstalled developer tools remain trusted local inputs.

This review did not include a native Godot engine code audit, independent binary reproducibility analysis, Cloudflare infrastructure penetration test, exhaustive gameplay-input fuzzing, or a review of other Workers/custom domains in the account.

## References

- [GitHub Actions secure use](https://docs.github.com/en/actions/reference/security/secure-use)
- [Cloudflare Pages headers](https://developers.cloudflare.com/pages/configuration/headers/)
- [Git LFS security advisories](https://github.com/git-lfs/git-lfs/security/advisories)
- [Godot security policy and advisories](https://github.com/godotengine/godot/security)
