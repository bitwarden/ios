"""
delete_duplicate_strings

Finds and removes duplicate key entries from a Localizable.strings file,
preserving the first occurrence of each key. Any comment block immediately
preceding a removed duplicate (with no blank lines between them) is also
removed.
"""

import re

# Matches a complete key/value entry line.
_ENTRY_RE = re.compile(
    r'^\s*"(?P<key>(?:[^"\\]|\\.)*)"\s*=\s*"(?:[^"\\]|\\.)*"\s*;\s*$'
)


def deduplicate(content: str) -> tuple[str, list[str]]:
    """Remove duplicate key entries from Localizable.strings content.

    Processes content line by line. The first occurrence of each key is kept;
    subsequent occurrences are removed. Any comment block (``/* */`` or ``//``)
    immediately preceding a removed duplicate — with no intervening blank lines
    — is also removed.

    - Parameters:
        - content: The full text of the `.strings` file.

    - Returns: A tuple of ``(new_content, removed_keys)`` where ``new_content``
      is the deduplicated file text and ``removed_keys`` is a list of keys that
      were removed, in the order they were encountered.
    """
    lines = content.splitlines(keepends=True)
    output: list[str] = []
    # Lines buffered since the last blank line; these are candidate comments
    # for the next entry. Flushed to output on a blank line or non-entry line.
    pending: list[str] = []
    seen: set[str] = set()
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
            if key not in seen:
                seen.add(key)
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


def delete_duplicates(strings_path: str) -> list[str]:
    """Remove duplicate entries from a Localizable.strings file in place.

    - Parameters:
        - strings_path: Path to the `.strings` file to process.

    - Returns: A list of keys that were removed, in the order they were
      encountered. Returns an empty list if no duplicates were found.
    """
    with open(strings_path, encoding="utf-8") as f:
        content = f.read()

    new_content, removed = deduplicate(content)

    if removed:
        with open(strings_path, "w", encoding="utf-8") as f:
            f.write(new_content)

    return removed
