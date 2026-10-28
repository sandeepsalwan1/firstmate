#!/usr/bin/env bash
# Live guard for the codex crewmate launch's hook posture.
#
# Replay FirstMate launch flags against the installed Codex CLI without model calls.
set -u

# shellcheck source=tests/fixtures.sh
. "$(dirname "${BASH_SOURCE[0]}")/fixtures.sh"

fm_live_gate default-on FM_CODEX_HOOK_LAYER_LIVE codex

CODEX_VERSION=$(codex --version 2>&1)
TMP_ROOT=$(fm_test_tmproot fm-codex-hook-layer-live)

# capture_codex_launch <name> <extra fm-spawn args...>: spawns a codex crewmate
# against a fake pane and echoes the literal launch command firstmate sent.
capture_codex_launch() {
  local name=$1
  shift
  local case_dir home proj wt fakebin launchlog id
  case_dir="$TMP_ROOT/$name"
  home="$case_dir/home"
  proj="$case_dir/project"
  wt="$case_dir/wt"
  launchlog="$case_dir/launch.log"
  id="codex-hook-layer-$name"
  fakebin=$(fm_test_make_spawn_fakebin "$case_dir/fake")
  fm_test_spawn_home "$home" codex
  printf 'approve-for-me\n' > "$home/config/codex-approval-mode"
  fm_test_spawn_brief "$home" "$id"
  fm_git_worktree "$proj" "$wt" "wt-$name"
  : > "$launchlog"
  FM_FAKE_LAUNCH_LOG="$launchlog" \
    fm_test_run_spawn "$home" "$wt" "$fakebin" "$id" "$proj" "$@" >/dev/null 2>&1 ||
    fail "codex $CODEX_VERSION: fm-spawn could not build a crewmate launch"
  cat "$launchlog"
}

# codex_global_flags <launch command>: the flags between the codex executable
# and the positional brief, which is everything codex itself is configured by.
codex_global_flags() {
  local launch=$1 flags
  flags=${launch#*codex }
  flags=${flags%%\"\$(*}
  printf '%s' "$flags"
}

test_installed_codex_accepts_requested_hook_trust_for_the_captured_crewmate_launch() {
  local launch flags listing
  launch=$(capture_codex_launch ship --mode no-mistakes --yolo off)
  flags=$(codex_global_flags "$launch")
  case " $flags " in
    *' --dangerously-bypass-hook-trust '*) ;;
    *) fail "captured Codex launch omitted hook trust" ;;
  esac
  case " $flags " in
    *' --disable hooks '*) fail "captured Codex launch disabled authorized hooks" ;;
  esac
  case " $flags " in
    *' --approve-for-me '*) ;;
    *) fail "codex $CODEX_VERSION captured launch omitted --approve-for-me" ;;
  esac
  case " $flags " in
    *' --dangerously-bypass-approvals-and-sandbox '*)
      fail "codex $CODEX_VERSION captured launch retained the complete-bypass posture"
      ;;
  esac

  listing=$(eval "codex $flags features list" 2>&1) ||
    fail "codex $CODEX_VERSION rejected firstmate's crewmate launch flags: $listing"
  case "$listing" in
    *"Unknown feature flag"*)
      fail "codex $CODEX_VERSION no longer knows the hook feature Firstmate uses: $listing"
      ;;
  esac
  printf '%s\n' "$listing" | awk '{ print $1 }' | grep -qx hooks ||
    fail "codex $CODEX_VERSION omitted the hook feature from the captured crewmate launch"

  printf 'ok - codex %s accepts requested hook trust for a firstmate crewmate launch\n' "$CODEX_VERSION"
}

test_installed_codex_still_reports_the_hook_feature() {
  local listing
  listing=$(codex features list 2>&1) ||
    fail "codex $CODEX_VERSION could not list its feature flags: $listing"
  printf '%s\n' "$listing" | awk '{ print $1 }' | grep -qx hooks ||
    fail "codex $CODEX_VERSION no longer publishes a hook feature flag; firstmate's crewmate launch needs a new control"

  printf 'ok - codex %s still publishes the hook feature flag Firstmate uses\n' "$CODEX_VERSION"
}

test_installed_codex_still_reports_the_hook_feature
test_installed_codex_accepts_requested_hook_trust_for_the_captured_crewmate_launch

echo "# all fm-codex-hook-layer-live-e2e tests passed"
