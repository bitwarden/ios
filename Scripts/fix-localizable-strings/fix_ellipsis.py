"""
fix_ellipsis

Converts literal three-dot sequences (...) to the Unicode ellipsis character (…)
in the values of Localizable.strings entries.
"""

import re

# Matches a complete key/value entry line, capturing key and value separately.
_ENTRY_VALUE_RE = re.compile(
    r'^\s*"(?P<key>(?:[^"\\]|\\.)*)"'
    r'\s*=\s*"'
    r'(?P<value>(?:[^"\\]|\\.)*)'
    r'"\s*;\s*$'
)


def fix_ellipsis(content: str) -> tuple[str, list[str]]:
    """Replace three-dot sequences (...) with the Unicode ellipsis character (…)
    in the values of Localizable.strings content.

    Only the value portion of each entry is modified. Keys, comments, and blank
    lines are passed through unchanged. Replacement is performed via character-
    position slicing so the rest of each line (indentation, spacing, newline) is
    preserved exactly.

    Args:
        content: The full text of the ``.strings`` file.

    Returns:
        A tuple of ``(new_content, changed_keys)`` where ``new_content`` is the
        updated file text and ``changed_keys`` is a list of keys whose values
        were modified, in the order they were encountered.
    """
    lines = content.splitlines(keepends=True)
    output: list[str] = []
    changed_keys: list[str] = []

    for line in lines:
        m = _ENTRY_VALUE_RE.match(line)
        if m and "..." in m.group("value"):
            start = m.start("value")
            end = m.end("value")
            new_value = m.group("value").replace("...", "…")
            output.append(line[:start] + new_value + line[end:])
            changed_keys.append(m.group("key"))
        else:
            output.append(line)

    return "".join(output), changed_keys


def fix_ellipsis_file(strings_path: str) -> list[str]:
    """Replace three-dot sequences with … in a Localizable.strings file in place.

    Reads the file, applies the conversion, and writes back only if changes were
    made (preserving the original file modification time when there is nothing to
    change).

    Args:
        strings_path: Path to the ``.strings`` file to process.

    Returns:
        A list of keys whose values were modified, in the order they were
        encountered. Returns an empty list if no changes were made.
    """
    with open(strings_path, encoding="utf-8") as f:
        content = f.read()

    new_content, changed = fix_ellipsis(content)

    if changed:
        with open(strings_path, "w", encoding="utf-8") as f:
            f.write(new_content)

    return changed
