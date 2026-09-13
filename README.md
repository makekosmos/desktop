# Kosmos Desktop

**Lifecycle: active release channel.** Source of truth and ownership remain in
[`makekosmos/cortex`](https://github.com/makekosmos/cortex).

- Owner: Cortex maintainer
- Artifact: public Windows installers and updater metadata
- Release unit: one Kosmos Desktop release
- Source changes and issues: `makekosmos/cortex`

This repository does not accept product source or a duplicate issue tracker.

## Channel contract

[`release-channel.json`](release-channel.json) records the public channel
boundary and delegates installer integrity verification to
`cortex/desktop/scripts/verify-release-channel.mjs`. This repository does not
build, sign, publish, or re-verify installer bytes.

Run `pnpm --config.lockfile=false install` and `pnpm run check` before pushing
channel-governance changes. Installation also configures the repository-owned
pre-commit and pre-push hooks. The
repository has no third-party package dependencies, so dependency audit is not
applicable; CI instead runs the channel contract, secret scan, and Actionlint.
