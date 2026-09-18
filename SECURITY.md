# Security

## Report a vulnerability privately

Please use [GitHub's private vulnerability reporting](https://github.com/Tam-mas/ZendGarden/security/advisories/new) for vulnerabilities or accidentally exposed credentials. Include the affected URL or commit, reproduction steps, and expected impact. Do not post credentials or other sensitive details in a public issue.

Only the current `main` branch and latest production deployment receive fixes. Please keep Godot, your browser, and local build tools updated.

## Security boundaries

Zend Garden is a static browser game. It does not have user accounts, a server-side game API, payment processing, or a player-upload service. Garden saves stay in browser storage and are not encrypted or synchronized to a server. Treat a downloaded Godot project or Blender generator as executable code; inspect untrusted forks and pull requests before running them locally.

The public repository and exported game assets are intended to be downloadable. Asset hashes detect incomplete or inconsistent downloads; they are not protection against someone who can modify the repository or deployment itself.

Build tools have pinned versions and archive checksums in `tools/build_checksums.json`. GitHub Actions are pinned to commit SHAs and use read-only repository permission. Updates to tool versions must also update their verified checksums. Existing locally installed Godot and Git LFS binaries remain part of the developer's trusted environment.

Never add credentials to the repository or client-side game code. Any future backend, multiplayer feature, analytics integration, third-party script, or save-upload feature needs a fresh security review.
