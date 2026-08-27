#!/usr/bin/env bash
#
# Diff the generated Swift binding surface of bitwarden/sdk-swift between two revisions.
# See ./SKILL.md for how the output is meant to be read.
#
#   sdk-surface-diff.sh <sdk-swift-path> <old-rev> <new-rev>              RANGE/REMOVED/ADDED/MUTATED
#   sdk-surface-diff.sh <sdk-swift-path> <old-rev> <new-rev> --type <T>   one type's members
#   sdk-surface-diff.sh <sdk-swift-path> <old-rev> <new-rev> --decls      whole surface, line level
#
# Comparisons are keyed by symbol name tree-wide, never per file: the Swift module is flat, so a type
# moving between generated files would otherwise read as a removal. Every mode fails loudly rather
# than emitting an empty result, since "nothing changed" from a broken extractor reads as safe.

set -euo pipefail

# sort/comm/join collation must not vary with the runner locale, or set differences go silently wrong.
export LC_ALL=C

usage () {
  echo "usage: sdk-surface-diff.sh <sdk-swift-path> <old-rev> <new-rev> [--type <TypeName> | --decls]" >&2
  exit 1
}

[ $# -ge 3 ] || usage
SDK_SWIFT=$1
OLD=$2
NEW=$3
MODE=${4-}
TYPE_NAME=${5-}

case "$MODE" in
  ""|"--decls") [ -z "$TYPE_NAME" ] || usage ;;
  "--type") [ -n "$TYPE_NAME" ] || { echo "error: --type requires a type name" >&2; exit 1; } ;;
  *) echo "error: unknown option '$MODE'" >&2; usage ;;
esac

TAB=$(printf '\t')
SRC=Sources/BitwardenSdk

for rev in "$OLD" "$NEW"; do
  git -C "$SDK_SWIFT" rev-parse --verify --quiet "$rev^{commit}" >/dev/null || {
    echo "error: revision $rev not found in $SDK_SWIFT." >&2
    echo "       Pinned revisions live on 'unstable' and v<version> tags, not on 'main'. CI does a" >&2
    echo "       full clone, so a genuinely missing revision means the wrong path or repository was" >&2
    echo "       supplied. Stop and report rather than fetching." >&2
    exit 1
  }
  git -C "$SDK_SWIFT" cat-file -e "$rev:$SRC" 2>/dev/null || {
    echo "error: $rev in $SDK_SWIFT has no $SRC directory — this does not look like bitwarden/sdk-swift." >&2
    echo "       Check the path; the sdk-internal clone is a common mix-up and has no generated Swift." >&2
    exit 1
  }
done

# git grep and grep -v both exit 1 to mean "no match", which pipefail would otherwise treat as a
# hard failure and abort before assert_surface can report the empty surface. Tolerate exactly 1 and
# let anything worse propagate.
no_match_ok () { "$@" || [ $? -eq 1 ]; }

# uniffi 0.32.0 started emitting the access modifier alone on its own line before some declarations
# (observed: a lone "public " before every enum in one revision, none before struct/class/protocol,
# "open" never split) instead of "public enum Foo {" on one line. Every regex below requires the
# modifier and the keyword on the same line, so a split declaration silently vanishes from the
# extracted surface — read downstream as REMOVED, the one verdict this tool exists to get right.
# Joining here, once, keeps every regex below written for the single-line form permanently, rather
# than chasing whichever combination uniffi splits next.
join_split_modifiers () {
  awk '
    /^[[:space:]]*(public|open)[[:space:]]*$/ { pending = $0; sub(/[[:space:]]+$/, "", pending); next }
    pending { print pending " " $0; pending = ""; next }
    { print }
    END { if (pending) print pending }
  '
}

# Flattens one revision's $SRC tree to a single file, modifier-split lines joined. Per file, via
# git show, so a trailing modifier at the end of one generated file is never joined with the first
# line of the next — join_split_modifiers has no file-boundary awareness of its own.
tree_content () {
  local rev=$1
  git -C "$SDK_SWIFT" ls-tree -r --name-only "$rev" -- "$SRC" | while IFS= read -r f; do
    git -C "$SDK_SWIFT" show "$rev:$f" | join_split_modifiers
  done
}

# Every consumer-facing declaration line, tree-wide, with FFI plumbing filtered out. Takes a
# tree_content file, not a revision — see the WORK setup below.
decls () {
  no_match_ok grep -E '^[[:space:]]*(public|open) (final )?(struct|enum|protocol|class|func|var|let) ' "$1" \
  | sed -E 's/^[[:space:]]+//' \
  | { no_match_ok grep -vE 'FfiConverter|Uniffi|uniffi'; } \
  | sort -u
}

# "<kind> <name>" for each declaration. Existence only, never signature comparison.
names () {
  decls "$1" | sed -E 's/^(public|open) (final )?(struct|enum|protocol|class|func|var|let) ([A-Za-z0-9_]+).*/\3 \4/' | sort -u
}

# Type declarations keyed by type name. Type names are unique in the flat module, so a name join is
# exact here. Function names are NOT unique — `decrypt` alone is overloaded across many types, and
# joining functions on name yields a meaningless cross product — so this is types only.
type_decls () {
  no_match_ok grep -E '^(public|open) (final )?(struct|enum|protocol|class) ' "$1" \
  | { no_match_ok grep -vE 'FfiConverter|Uniffi|uniffi'; } \
  | sed -E "s/^(public|open) (final )?(struct|enum|protocol|class) ([A-Za-z0-9_]+)/\4$TAB&/" \
  | sort -t"$TAB" -k1,1 -u
}

type_exists () {
  grep -q -E "^(public|open) (final )?(struct|enum|protocol|class) $2[:{ ]" "$1"
}

# One type's declaration through its closing brace, comments and blank lines stripped.
# Anchored with [:{ ] rather than \b, which grep -E does not support and which silently matches
# nothing. The awk drains stdin after the closing brace instead of exiting, so grep never takes
# SIGPIPE — an early exit here would make pipefail report failure on a successful run. The
# truncation warning is gated on non-empty input and goes to stderr so it can never be mistaken
# for surface content or diffed as a member line.
type_block () {
  grep -A2000 -E "^(public|open) (final )?(struct|enum|protocol|class) $2[:{ ]" "$1" \
  | awk 'finished {next}
         NR==1 {print; next}
         /^}/ {print; found=1; finished=1; next}
         {print}
         END {if (NR > 0 && !found) print "WARNING: closing brace not found within the context window; output is truncated" > "/dev/stderr"}' \
  | { no_match_ok grep -vE '^[[:space:]]*(/\*|\*|//|$)'; }
}

# A broken extractor must never look like a clean surface. `decls` requires public/open to be the
# first token, so if the generator starts prepending something to *every* declaration — an attribute,
# `nonisolated`, `public actor`, `indirect public enum` — the surface empties and reads as "no change".
assert_surface () {
  [ -s "$2" ] || {
    echo "error: no public declarations extracted at $1." >&2
    echo "       The generated Swift no longer matches the expected declaration form (a leading" >&2
    echo "       'public' or 'open'). Do not read this as 'nothing changed' — update the decls" >&2
    echo "       regex in this script before trusting any output." >&2
    exit 1
  }
}

# assert_surface only catches a total extraction failure. A partial one — a new prefix on some subset
# of declarations — leaves the surface large enough to pass while silently dropping exactly those
# declarations from REMOVED, ADDED and MUTATED. Between two adjacent revisions a steep drop is far
# more likely to be that than a genuine removal, so say so rather than reporting it as one.
assert_no_collapse () {
  local old_count new_count
  old_count=$(wc -l < "$1" | tr -d ' ')
  new_count=$(wc -l < "$2" | tr -d ' ')
  if [ "$new_count" -lt $((old_count / 2)) ]; then
    echo "warning: the extracted surface fell from $old_count to $new_count declarations." >&2
    echo "         A drop this steep across one bump usually means the extractor stopped matching a" >&2
    echo "         declaration form, not that the API halved. Compare against the raw count," >&2
    echo "         git -C <sdk-swift> grep -c '^ *\\(public\\|open\\) ' <rev> -- Sources/BitwardenSdk," >&2
    echo "         at both revisions before trusting REMOVED." >&2
  fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Materialized once per revision, up front, so every mode below reads the same modifier-joined
# content rather than re-flattening the tree per call.
tree_content "$OLD" > "$WORK/old.tree"
tree_content "$NEW" > "$WORK/new.tree"

if [ "$MODE" = "--type" ]; then
  echo "## MEMBERS: $TYPE_NAME"
  old_has=false; new_has=false
  type_exists "$WORK/old.tree" "$TYPE_NAME" && old_has=true
  type_exists "$WORK/new.tree" "$TYPE_NAME" && new_has=true
  # Without this, a misspelled name yields two empty blocks and reports "(unchanged)" — a typo would
  # read as "verified safe", which is the worst possible failure for this tool.
  if [ "$old_has" = false ] && [ "$new_has" = false ]; then
    echo "error: no public type named '$TYPE_NAME' at either revision — check the spelling." >&2
    echo "       ADDED lists members as well as types; 'var', 'let' and 'func' entries have no" >&2
    echo "       block of their own, so take those to --decls instead." >&2
    exit 1
  fi
  if [ "$old_has" = true ] && [ "$new_has" = true ]; then
    if diff <(type_block "$WORK/old.tree" "$TYPE_NAME") <(type_block "$WORK/new.tree" "$TYPE_NAME"); then
      echo "(unchanged)"
    fi
  elif [ "$new_has" = true ]; then
    echo "(added in this range — not present at $OLD)"
    type_block "$WORK/new.tree" "$TYPE_NAME"
  else
    echo "(removed in this range — not present at $NEW)"
    type_block "$WORK/old.tree" "$TYPE_NAME"
  fi
  exit 0
fi

if [ "$MODE" = "--decls" ]; then
  decls "$WORK/old.tree" > "$WORK/old.decls"
  decls "$WORK/new.tree" > "$WORK/new.decls"
  assert_surface "$OLD" "$WORK/old.decls"
  assert_surface "$NEW" "$WORK/new.decls"
  assert_no_collapse "$WORK/old.decls" "$WORK/new.decls"
  echo "## DECLARATIONS: line-level diff of the whole surface"
  echo "Both sides are sorted, so '<' and '>' lines inside a hunk are alphabetical neighbours and"
  echo "not necessarily counterparts — match them by symbol name, not by position. A changed"
  echo "argument label, return type, optionality, throws or async marker appears here and in no"
  echo "other section."
  echo
  if diff "$WORK/old.decls" "$WORK/new.decls"; then
    echo "(no declaration text changed)"
  fi
  exit 0
fi

names "$WORK/old.tree" > "$WORK/old.names"
names "$WORK/new.tree" > "$WORK/new.names"
assert_surface "$OLD" "$WORK/old.names"
assert_surface "$NEW" "$WORK/new.names"
assert_no_collapse "$WORK/old.names" "$WORK/new.names"
type_decls "$WORK/old.tree" > "$WORK/old.types"
type_decls "$WORK/new.tree" > "$WORK/new.types"
# An empty `mutated` is legitimate; an empty type surface is not. Without this, MUTATED reports
# nothing whether no type declaration changed or the type extractor stopped matching, and the
# names-based assertions above would still pass. `type_decls` anchors at column 0 deliberately:
# indented matches are nested UniFFI plumbing whose names repeat, which would break the name join.
assert_surface "$OLD" "$WORK/old.types"
assert_surface "$NEW" "$WORK/new.types"
comm -23 "$WORK/old.names" "$WORK/new.names" > "$WORK/removed"
comm -13 "$WORK/old.names" "$WORK/new.names" > "$WORK/added"
join -t"$TAB" -j1 -o 1.1,1.2,2.2 "$WORK/old.types" "$WORK/new.types" \
| awk -F"$TAB" '$2 != $3 {print $1; print "  OLD: " $2; print "  NEW: " $3}' > "$WORK/mutated"

count () { wc -l < "$1" | tr -d ' '; }

echo "## RANGE"
echo "sdk-swift $OLD..$NEW"
# The base commit is excluded from OLD..NEW, so print it separately: its subject carries the old
# sdk-internal SHA, which the uniffi.toml step needs and which appears nowhere else. --reverse makes
# the listing chronological, so the last line is the newest commit and carries the new SHA.
echo "base: $(git -C "$SDK_SWIFT" log -1 --format='%h %s' "$OLD")"
git -C "$SDK_SWIFT" log --reverse --format='%h %s' "$OLD".."$NEW"
echo "commits: $(git -C "$SDK_SWIFT" log --format='%h' "$OLD".."$NEW" | wc -l | tr -d ' ')"

echo
echo "## REMOVED — name absent at NEW anywhere in the tree; these are hard compile breaks"
cat "$WORK/removed"
echo "count: $(count "$WORK/removed")"

echo
echo "## ADDED — new declarations, including record fields; only a pre-existing owner is a break"
cat "$WORK/added"
echo "count: $(count "$WORK/added")"

echo
echo "## MUTATED — type survives but its declaration changed (conformances, generics)"
cat "$WORK/mutated"
echo "count: $(grep -cE '^[A-Za-z0-9_]+$' "$WORK/mutated" || true)"

echo
echo "MUTATED covers type declarations only. For a type's members run --type <TypeName>; for free"
echo "functions, for methods of types not listed above, and for ADDED entries that are var/let/func"
echo "rather than types, run --decls."
echo
echo "Enum cases and protocol requirements take no access modifier, so neither the sections above nor"
echo "--decls can list them. A case added to an enum that already existed is visible only through"
echo "--type <TypeName>, and it compiles clean at any call site with a 'default:' clause, so run"
echo "--type against every enum and protocol the RANGE commits touch before calling a range safe."
