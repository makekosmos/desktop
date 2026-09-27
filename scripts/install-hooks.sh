#!/usr/bin/env sh
# Installs shim hooks into the shared git hooks directory. Each shim execs
# the repository-owned .githooks/<hook> of the current checkout, so the
# versioned hooks stay the source of truth while a checkout that lacks
# .githooks fails closed instead of silently skipping the gate.
set -eu

common_dir=$(cd "$(git rev-parse --git-common-dir)" && pwd)
hooks_dir="$common_dir/hooks"
mkdir -p "$hooks_dir"

for hook in pre-commit pre-push; do
  cat > "$hooks_dir/$hook" <<EOF
#!/usr/bin/env sh
set -eu
repo_hook="\$(git rev-parse --show-toplevel)/.githooks/$hook"
if [ -x "\$repo_hook" ]; then
  exec "\$repo_hook"
fi
echo "channel-contract gate unavailable: .githooks/$hook missing from this checkout" >&2
exit 1
EOF
  chmod +x "$hooks_dir/$hook"
done

# A relative core.hooksPath (e.g. ".githooks" from earlier installs) resolves
# per-checkout and silently disables hooks whenever the checkout lacks that
# directory; drop it so the real hooks dir is used.
for cfg in "$common_dir/config" "$(git rev-parse --git-dir)/config.worktree"; do
  if [ -f "$cfg" ] && git config --file "$cfg" --get core.hooksPath >/dev/null 2>&1; then
    git config --file "$cfg" --unset-all core.hooksPath
  fi
done
