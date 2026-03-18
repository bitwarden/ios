"""
delete_unused_strings

Finds and removes string entries from a Localizable.strings file whose keys are
never referenced in Swift source code. Keys are assumed to be accessed via
``Localizations.X``, where ``X`` is the SwiftGen-generated identifier for the
key (first character lowercased). Any comment block immediately preceding a
removed entry (with no blank lines between them) is also removed.
"""

import os
import re

from strings_file_utils import filter_entries

# Matches any `Localizations.identifier` reference in Swift source, including
# cases where the identifier is on the next line (e.g. `Localizations\n    .foo`).
_LOCALIZATIONS_RE = re.compile(r'Localizations\s*\.([a-zA-Z_][a-zA-Z0-9_]*)')

# Matches any character that is not valid in a Swift identifier.
_NON_IDENTIFIER_RE = re.compile(r'[^a-zA-Z0-9_]')


def _normalize_key(key: str) -> str:
    """Normalize a ``.strings`` key for comparison against a SwiftGen identifier.

    SwiftGen strips characters that are not valid in Swift identifiers when
    generating property names (e.g. ``"NeedSomeInspiration?"`` becomes
    ``needSomeInspiration``). This function applies the same stripping and then
    lowercases the result, matching the treatment applied to identifiers found
    in Swift source via ``find_used_keys``.

    Args:
        key: A raw ``.strings`` key, possibly containing trailing punctuation.

    Returns:
        The normalized, lowercased key suitable for comparison.
    """
    return _NON_IDENTIFIER_RE.sub('', key).lower()


def find_used_keys(swift_sources: list[str]) -> set[str]:
    """Scan Swift file contents for ``Localizations.X`` references.

    Returns a set of identifiers found in the sources, converted to lowercase
    for comparison with the keys from the strings file. While this does mean
    that keys differing only in case (e.g. ``"OK"`` vs. ``"Ok"``) will be
    treated as the same key, in practice we're not likely to have keys that
    only differ by case.

    The internal helper ``Localizations.tr(...)`` is excluded.

    Args:
        swift_sources: A list of strings, each being the full text of a Swift
            source file.

    Returns:
        A set of lowercased identifiers referenced in the given sources,
        e.g. ``{"about", "ok", "valuehasbeencopied"}``.
    """
    result: set[str] = set()
    for content in swift_sources:
        for identifier in _LOCALIZATIONS_RE.findall(content):
            if identifier == "tr":
                continue
            result.add(identifier.lower())
    return result


def delete_unused_content(
    strings_content: str, used_keys: set[str]
) -> tuple[str, list[str]]:
    """Remove unused key entries from Localizable.strings content.

    Processes content line by line. Any key not present in ``used_keys`` is
    removed. Any comment block (``/* */`` or ``//``) immediately preceding a
    removed entry — with no intervening blank lines — is also removed.

    Args:
        strings_content: The full text of the ``.strings`` file.
        used_keys: The set of lowercased identifiers (as returned by
            ``find_used_keys``) that are considered in-use. Each key from the
            strings file is lowercased before lookup to match.

    Returns:
        A tuple of ``(new_content, removed_keys)`` where ``new_content`` is the
        filtered file text and ``removed_keys`` is a list of keys that were
        removed, in file order.
    """
    return filter_entries(strings_content, lambda key: _normalize_key(key) in used_keys)


def delete_unused(strings_path: str, swift_dirs: list[str]) -> list[str]:
    """Remove unused entries from a Localizable.strings file in place.

    Walks each directory in ``swift_dirs`` recursively for ``.swift`` files,
    reads them, determines which keys are referenced, then removes any
    unreferenced keys from the strings file.

    Args:
        strings_path: Path to the ``.strings`` file to process.
        swift_dirs: List of directory paths to search recursively for Swift
            source files.

    Returns:
        A list of keys that were removed, in file order. Returns an empty list
        if no unused keys were found.
    """
    swift_sources: list[str] = []
    for swift_dir in swift_dirs:
        for dirpath, _, filenames in os.walk(swift_dir):
            for filename in filenames:
                if filename.endswith(".swift"):
                    filepath = os.path.join(dirpath, filename)
                    with open(filepath, encoding="utf-8") as f:
                        swift_sources.append(f.read())

    used_keys = find_used_keys(swift_sources)

    with open(strings_path, encoding="utf-8") as f:
        content = f.read()

    new_content, removed = delete_unused_content(content, used_keys)

    if removed:
        with open(strings_path, "w", encoding="utf-8") as f:
            f.write(new_content)

    return removed
