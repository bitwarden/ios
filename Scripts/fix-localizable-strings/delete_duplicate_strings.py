"""
delete_duplicate_strings

Finds and removes duplicate key entries from a Localizable.strings file,
preserving the first occurrence of each key. Any comment block immediately
preceding a removed duplicate (with no blank lines between them) is also
removed.
"""

from strings_file_utils import filter_entries


def deduplicate(content: str) -> tuple[str, list[str]]:
    """Remove duplicate key entries from Localizable.strings content.

    Processes content line by line. The first occurrence of each key is kept;
    subsequent occurrences are removed. Any comment block (``/* */`` or ``//``)
    immediately preceding a removed duplicate — with no intervening blank lines
    — is also removed.

    Args:
        content: The full text of the `.strings` file.

    Returns:
        A tuple of ``(new_content, removed_keys)`` where ``new_content`` is the
        deduplicated file text and ``removed_keys`` is a list of keys that were
        removed, in the order they were encountered.
    """
    seen: set[str] = set()

    def should_keep(key: str) -> bool:
        if key in seen:
            return False
        seen.add(key)
        return True

    return filter_entries(content, should_keep)


def delete_duplicates(strings_path: str) -> list[str]:
    """Remove duplicate entries from a Localizable.strings file in place.

    Args:
        strings_path: Path to the `.strings` file to process.

    Returns:
        A list of keys that were removed, in the order they were encountered.
        Returns an empty list if no duplicates were found.
    """
    with open(strings_path, encoding="utf-8") as f:
        content = f.read()

    new_content, removed = deduplicate(content)

    if removed:
        with open(strings_path, "w", encoding="utf-8") as f:
            f.write(new_content)

    return removed
