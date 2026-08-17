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
#   REPO               owner/name.
#   PR_NUMBER          Pull request the comment lives on.
#   COMMENT_AUTHOR     Login that authors the action's comment, e.g. bw-ghapp[bot].
#   JOB_URL            Link used in the backfilled comment.
#   GH_TOKEN           Token with pull-requests: write.
#   REQUIRED_HEADINGS  Newline-separated headings the report must contain.
#   GITHUB_RUN_ID      Supplied by Actions; used to identify this run's comment.
#   SUMMARY_FILE       Optional; defaults to GITHUB_STEP_SUMMARY.

set -euo pipefail

SUMMARY_FILE="${SUMMARY_FILE:-${GITHUB_STEP_SUMMARY:-/dev/null}}"

summary() {
  printf '%s\n' "$1" >> "$SUMMARY_FILE"
}

for _var in REPO PR_NUMBER COMMENT_AUTHOR JOB_URL REQUIRED_HEADINGS GITHUB_RUN_ID; do
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

# --- Locate this run's comment -----------------------------------------------------------------
#
# claude-code-action writes the comment id to GITHUB_OUTPUT from inside its own composite, but
# action.yml re-exports only execution_file, branch_name, github_token, structured_output and
# session_id, so `steps.<id>.outputs.claude_comment_id` is always empty (upstream
# anthropics/claude-code-action#465). Resolve it from the API instead.
#
# The action's header carries `actions/runs/<run id>`, which scopes the match to this run. Re-running
# a run reuses the id and yields one comment per attempt, hence newest-wins. Unpaginated on purpose:
# an SDK bump PR has a handful of comments, and a page limit that silently drops the newest one is a
# worse failure than a page limit that cannot be reached.

comment=$(gh api "repos/$REPO/issues/$PR_NUMBER/comments?per_page=100" \
  | jq -r --arg author "$COMMENT_AUTHOR" --arg marker "actions/runs/$GITHUB_RUN_ID" '
      [.[] | select(.user.login == $author) | select(.body | contains($marker))]
      | sort_by(.created_at) | last
      | if . == null then "" else "\(.id)\n\(.body)" end
    ') || comment=""

comment_id="${comment%%$'\n'*}"

if [ -z "$comment_id" ]; then
  # Only reachable if the action died before writing its header, which is also the case where a
  # stranded comment is most likely. There is no reliable way to tell that comment from an unrelated
  # one by the same bot, so report the gap rather than guess and overwrite the wrong comment.
  summary "No comment for this run could be found, so there is no report to check."
  echo "::error::No comment for run $GITHUB_RUN_ID was found on #$PR_NUMBER; the evaluation left no audit trail."
  exit 1
fi

body="${comment#*$'\n'}"

# --- Contract check ---------------------------------------------------------------------------

missing=""
while IFS= read -r heading; do
  [ -z "$heading" ] && continue
  # A `case` rather than `grep`: under `pipefail`, `printf | grep -q` exits 141 when grep closes the
  # pipe on its first match, which would report a heading that is present as missing.
  case "$body" in
    *"$heading"*) ;;
    *) missing="${missing:+$missing, }$heading" ;;
  esac
done <<< "$REQUIRED_HEADINGS"

if [ -z "$missing" ]; then
  summary "The agent posted a complete report."
  echo "Report contract satisfied; comment $comment_id is complete."
  exit 0
fi

# --- Backfill ---------------------------------------------------------------------------------
#
# Additive. The body the agent left is preserved in a disclosure rather than discarded, so a report
# rejected over one heading, or over a heading whose punctuation drifted, is never destroyed by this
# script. The banner still has to displace the misleading "Claude finished" line above it.

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

<details>
<summary>What the agent had posted when it stopped</summary>

$body

</details>
EOF
)

jq -n --arg body "$backfilled" '{body: $body}' \
  | gh api --method PATCH "repos/$REPO/issues/comments/$comment_id" --input - > /dev/null

summary "The agent did not post a complete report. Missing sections: $missing."
summary "$recovery_outcome"

echo "::error::The evaluation did not post a complete report. Missing sections: $missing"
exit 1
