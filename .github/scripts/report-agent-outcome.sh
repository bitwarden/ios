#!/usr/bin/env bash
#
# Guarantees that an agentic evaluation leaves a terminal report on the pull request, and that an
# incomplete one is visibly red.
#
# claude-code-action's own post-run step appends a "Claude finished" header to whatever body the
# agent last wrote and never copies the agent's final message in. An agent that stops mid-work
# therefore leaves an in-progress checklist under a header claiming completion, on a green job, with
# its actual findings stranded in the execution log that dies with the runner. This script closes
# that gap: it publishes the run's diagnostics, checks the comment against the report contract, and
# recovers the final message into the comment when the contract is unmet.
#
# Every input arrives by environment variable and nothing about a specific repository, path or
# platform is baked in, so this is portable as-is.
#
#   EXECUTION_FILE     claude-code-action's execution_file output. May be empty; see below.
#   COMMENT_ID         claude-code-action's claude_comment_id output.
#   REPO               owner/name.
#   JOB_URL            Link used in the backfilled comment.
#   GH_TOKEN           Token with pull-requests: write.
#   REQUIRED_HEADINGS  Newline-separated headings the report must contain.
#   SUMMARY_FILE       Optional; defaults to GITHUB_STEP_SUMMARY.

set -euo pipefail

SUMMARY_FILE="${SUMMARY_FILE:-${GITHUB_STEP_SUMMARY:-/dev/null}}"

summary() {
  printf '%s\n' "$1" >> "$SUMMARY_FILE"
}

for _var in REPO JOB_URL REQUIRED_HEADINGS; do
  if [ -z "${!_var:-}" ]; then
    echo "::error::$_var is required."
    exit 1
  fi
done

# --- Diagnostics -------------------------------------------------------------------------------
#
# The only surface that makes a denied tool call visible. show_full_output and display_report both
# stay off deliberately: this repository is public, and the raw transcript carries private
# sdk-internal diffs and file contents that must not be published to a step summary.

summary "## Agent run diagnostics"
summary ""

final_message=""

# Every extraction below tolerates failure. A truncated or malformed log must not abort the script,
# because the heading check and the backfill are the parts that matter and they do not depend on it.
if [ -n "${EXECUTION_FILE:-}" ] && [ -f "$EXECUTION_FILE" ]; then
  stats=$(jq -r '
    [.[] | select(.type == "result")] | last
    | if . == null then "- No result message; the agent did not reach a normal stop."
      else "- Stop reason: `\(.subtype)`" +
           "\n- Turns: \(.num_turns)" +
           "\n- Duration: \((.duration_ms / 1000 | floor))s" +
           "\n- Permission denials: \(.permission_denials | length)"
      end
  ' "$EXECUTION_FILE" 2>/dev/null) || stats=""
  summary "${stats:-"- The run log could not be parsed."}"
  summary ""

  denials=$(jq -r '
    [.[] | select(.type == "result")] | last | .permission_denials // []
    | .[] | "- `\(.tool_name)` — `\((.tool_input.command // (.tool_input | tostring)) | .[0:300])`"
  ' "$EXECUTION_FILE" 2>/dev/null) || denials=""

  if [ -n "$denials" ]; then
    summary "### Denied tool calls"
    summary ""
    summary "$denials"
    summary ""
    summary "Each of these is a command the agent tried and could not run. Any that it legitimately"
    summary "needed belongs in the workflow's \`--allowedTools\`."
    summary ""
  fi

  final_message=$(jq -r '
    [.[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text]
    | last // ""
  ' "$EXECUTION_FILE" 2>/dev/null) || final_message=""
else
  # A hard failure inside the action itself looks exactly like this, and it is also the case where
  # the comment is most likely stranded mid-checklist, so the heading check must still run.
  summary "No run log was available, so the stop reason and denied tool calls are unknown."
  summary ""
fi

# Runtime-supplied, unlike the variables checked above, and legitimately empty when the action failed
# before it could create a comment. That is a missing audit trail, so it fails, but it says why.
if [ -z "${COMMENT_ID:-}" ]; then
  summary "The action created no comment, so there is no report to check."
  echo "::error::No comment was created, so the evaluation left no audit trail."
  exit 1
fi

# --- Contract check ---------------------------------------------------------------------------

body=$(gh api "repos/$REPO/issues/comments/$COMMENT_ID" --jq '.body')

missing=""
while IFS= read -r heading; do
  [ -z "$heading" ] && continue
  if ! printf '%s' "$body" | grep -qF "$heading"; then
    missing="${missing:+$missing, }$heading"
  fi
done <<< "$REQUIRED_HEADINGS"

if [ -z "$missing" ]; then
  summary "The agent posted a complete report."
  echo "Report contract satisfied; comment $COMMENT_ID is complete."
  exit 0
fi

# --- Backfill ---------------------------------------------------------------------------------
#
# The body is rebuilt rather than surgically edited. Splitting on the action's `---` to preserve its
# header is fragile against an upstream format change, and the banner has to displace the misleading
# "Claude finished" line regardless.

if [ -n "$final_message" ]; then
  recovery_note="The text below is its final message, recovered from the run log."
  recovery_outcome="Its final message was recovered into the pull request comment."
else
  final_message="_No final message was recoverable from the run log._"
  recovery_note="No final message was recoverable."
  recovery_outcome="No final message was recoverable, so the comment records only that the run failed."
fi

backfilled=$(cat <<EOF
**SDK bump evaluation did not complete** — [View job]($JOB_URL)

---
> [!WARNING]
> The agent ended without posting a complete report. Missing sections: $missing.
> $recovery_note The stop reason and any denied tool calls are in the job summary.

$final_message
EOF
)

jq -n --arg body "$backfilled" '{body: $body}' \
  | gh api --method PATCH "repos/$REPO/issues/comments/$COMMENT_ID" --input - > /dev/null

summary "The agent did not post a complete report. Missing sections: $missing."
summary "$recovery_outcome"

echo "::error::The evaluation did not post a complete report. Missing sections: $missing"
exit 1
