#!/usr/bin/env sh
# Installs shim hooks into the shared git hooks directory. Each shim execs
# the repository-owned .githooks/<hook> of the current checkout, so the
# versioned hooks stay the source of truth while a checkout that lacks
# .githooks fails closed instead of silently skipping the gate.
set -eu

common_dir=$(cd "$(git rev-parse --git-common-dir)" >/dev/null && pwd)
hooks_dir="$common_dir/hooks"
mkdir -p "$hooks_dir"

for hook in pre-commit pre-push; do
  # An existing hook that is not one of our shims (user hooks, template hooks,
  # other tools) must not be silently overwritten: move it aside once and say
  # so. It is not chained because pre-push hooks consume stdin.
  if { [ -e "$hooks_dir/$hook" ] || [ -L "$hooks_dir/$hook" ]; } \
      && ! grep -qF "channel-contract gate unavailable: .githooks/" "$hooks_dir/$hook" 2>/dev/null; then
    if [ -e "$hooks_dir/$hook.pre-kosmos" ] || [ -L "$hooks_dir/$hook.pre-kosmos" ]; then
      echo "install-hooks: foreign $hook hook exists but $hook.pre-kosmos is already taken" >&2
      echo "Resolve it manually under $hooks_dir, then re-run." >&2
      exit 1
    fi
    mv "$hooks_dir/$hook" "$hooks_dir/$hook.pre-kosmos"
    echo "install-hooks: preserved existing $hook hook as hooks/$hook.pre-kosmos" >&2
  fi
  cat > "$hooks_dir/$hook" <<EOF
#!/usr/bin/env sh
set -eu
repo_hook="\$(git rev-parse --show-toplevel)/.githooks/$hook"
if [ -x "\$repo_hook" ]; then
  exec "\$repo_hook" "\$@"
fi
echo "channel-contract gate unavailable: .githooks/$hook missing from this checkout" >&2
exit 1
EOF
  chmod +x "$hooks_dir/$hook"
done

# A relative core.hooksPath (e.g. ".githooks" from earlier installs) resolves
# per-checkout and silently disables hooks whenever the checkout lacks that
# directory; drop it so the real hooks dir is used. The removal is reported
# because the value may also be a deliberate absolute path.
for cfg in "$common_dir/config" "$(git rev-parse --git-dir)/config.worktree"; do
  if [ -f "$cfg" ] && git config --file "$cfg" --get core.hooksPath >/dev/null 2>&1; then
    echo "install-hooks: removing core.hooksPath=$(git config --file "$cfg" --get core.hooksPath) from $cfg" >&2
    git config --file "$cfg" --unset-all core.hooksPath
  fi
done

# Any core.hooksPath still resolving after the cleanup above comes from a
# scope this script cannot edit (global, system, included config files, or
# the environment). Git resolves hooks only through that path, so the shims
# just installed would never run and the gate would be silently skipped.
# Refuse to report success instead of leaving that bypass undetected.
if shadow=$(git config --show-scope --show-origin --get core.hooksPath 2>/dev/null) \
   || shadow=$(git config --get core.hooksPath 2>/dev/null); then
  {
    echo "install-hooks: core.hooksPath is still set at a scope outside this repository:"
    echo "  $shadow"
    echo "Git will load hooks from that path and the installed shims will never run."
    echo "Unset it (e.g. git config --global --unset core.hooksPath) or merge these"
    echo "hooks into that directory, then re-run: sh scripts/install-hooks.sh"
  } >&2
  exit 1
fi
