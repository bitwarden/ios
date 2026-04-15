"""
strings_file_utils

Shared utilities for parsing and filtering Localizable.strings file content.
"""

import re
from collections.abc import Callable

# Matches a complete key/value entry line.
_ENTRY_RE = re.compile(
    r'^\s*"(?P<key>(?:[^"\\]|\\.)*)"\s*=\s*"(?:[^"\\]|\\.)*"\s*;\s*$'
)


def filter_entries(
    content: str, should_keep: Callable[[str], bool]
) -> tuple[str, list[str]]:
    """Filter key/value entries in Localizable.strings content by a predicate.

    Processes content line by line using a comment state machine. For each
    matched entry, calls ``should_keep(key)``. If the predicate returns
    ``True``, the entry and any immediately preceding comment block are
    written to output. If ``False``, the entry and its preceding comment block
    are discarded and the key is appended to the removed list.

    A blank line breaks the association between a comment and the following
    entry, so comments separated from an entry by a blank line are always
    preserved regardless of whether the entry is kept.

    Args:
        content: The full text of the ``.strings`` file.
        should_keep: A callable that receives a raw key string and returns
            ``True`` if the entry should be kept, ``False`` if it should be
            removed.

    Returns:
        A tuple of ``(new_content, removed_keys)`` where ``new_content`` is
        the filtered file text and ``removed_keys`` is a list of keys that
        were removed, in the order they were encountered.
    """
    lines = content.splitlines(keepends=True)
    output: list[str] = []
    # Lines buffered since the last blank line; these are candidate comments
    # for the next entry. Flushed to output on a blank line or non-entry line.
    pending: list[str] = []
    removed: list[str] = []
    in_block_comment = False

    for line in lines:
        stripped = line.strip()

        # --- Multi-line block comment continuation ---
        if in_block_comment:
            pending.append(line)
            if "*/" in line:
                in_block_comment = False
            continue

        # --- Blank line: break comment-entry association ---
        if not stripped:
            output.extend(pending)
            pending = []
            output.append(line)
            continue

        # --- Block comment start (does not end on the same line) ---
        if stripped.startswith("/*") and "*/" not in stripped:
            in_block_comment = True
            pending.append(line)
            continue

        # --- Single-line comment (// or /* ... */ on one line) ---
        if stripped.startswith("//") or (
            stripped.startswith("/*") and stripped.endswith("*/")
        ):
            pending.append(line)
            continue

        # --- Key/value entry ---
        m = _ENTRY_RE.match(line)
        if m:
            key = m.group("key")
            if should_keep(key):
                output.extend(pending)
                output.append(line)
            else:
                removed.append(key)
                # pending (the preceding comment) is discarded
            pending = []
            continue

        # --- Anything else (should be rare in a well-formed .strings file) ---
        output.extend(pending)
        pending = []
        output.append(line)

    # Flush any trailing pending content (e.g. trailing comment with no entry after it)
    output.extend(pending)

    return "".join(output), removed
