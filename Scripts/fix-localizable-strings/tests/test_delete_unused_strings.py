"""Tests for the delete_unused_strings module."""

import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from delete_unused_strings import delete_unused, delete_unused_content, find_used_keys


class TestFindUsedKeysBasic(unittest.TestCase):
    """Basic identifier extraction from Swift source content."""

    def test_empty_source_returns_empty_set(self):
        result = find_used_keys([""])
        self.assertEqual(result, set())

    def test_no_sources_returns_empty_set(self):
        result = find_used_keys([])
        self.assertEqual(result, set())

    def test_simple_identifier_returned_lowercase(self):
        result = find_used_keys(["Localizations.about"])
        self.assertEqual(result, {"about"})

    def test_camel_case_identifier_returned_lowercase(self):
        result = find_used_keys(["Localizations.valueHasBeenCopied"])
        self.assertEqual(result, {"valuehasbeencopied"})

    def test_all_caps_identifier_returned_lowercase(self):
        # "OK" in the strings file becomes Localizations.ok in Swift.
        result = find_used_keys(["Localizations.ok"])
        self.assertEqual(result, {"ok"})

    def test_no_localizations_reference_returns_empty_set(self):
        result = find_used_keys(["let x = 42\nprint(x)"])
        self.assertEqual(result, set())

    def test_identifier_on_next_line_is_matched(self):
        # SwiftUI sometimes splits long chains: `Localizations\n    .identifier`
        source = "message: Localizations\n    .shareFilesAndData,"
        result = find_used_keys([source])
        self.assertEqual(result, {"sharefilesanddata"})


class TestFindUsedKeysFiltering(unittest.TestCase):
    """The `tr` identifier must be excluded; other enum prefixes must not match."""

    def test_tr_identifier_is_excluded(self):
        result = find_used_keys(['Localizations.tr("About", tableName: "Localizable")'])
        self.assertEqual(result, set())

    def test_tr_and_real_identifier_together(self):
        source = 'let x = Localizations.tr("key")\nlet label = Localizations.about'
        result = find_used_keys([source])
        self.assertEqual(result, {"about"})

    def test_other_enum_prefix_does_not_match(self):
        result = find_used_keys(["OtherEnum.about"])
        self.assertEqual(result, set())


class TestFindUsedKeysParameterizedCalls(unittest.TestCase):
    """Multiple identifiers on a line or in nested calls are all captured."""

    def test_nested_call_captures_both_identifiers(self):
        source = "Localizations.valueHasBeenCopied(Localizations.password)"
        result = find_used_keys([source])
        self.assertEqual(result, {"valuehasbeencopied", "password"})

    def test_multiple_identifiers_on_same_line(self):
        source = "let a = Localizations.alpha; let b = Localizations.beta"
        result = find_used_keys([source])
        self.assertEqual(result, {"alpha", "beta"})


class TestFindUsedKeysMultipleFiles(unittest.TestCase):
    """Identifiers are unioned across all provided file contents."""

    def test_union_across_two_files(self):
        result = find_used_keys(["Localizations.alpha", "Localizations.beta"])
        self.assertEqual(result, {"alpha", "beta"})

    def test_same_key_in_both_files_appears_once(self):
        result = find_used_keys(["Localizations.about", "Localizations.about"])
        self.assertEqual(result, {"about"})


class TestDeleteUnusedContent(unittest.TestCase):
    """Unit tests for the pure delete_unused_content function."""

    def test_empty_content_and_empty_used_keys(self):
        result, removed = delete_unused_content("", set())
        self.assertEqual(result, "")
        self.assertEqual(removed, [])

    def test_all_keys_used_content_unchanged(self):
        content = (
            '"About" = "About";\n'
            '"Cancel" = "Cancel";\n'
        )
        result, removed = delete_unused_content(content, {"about", "cancel"})
        self.assertEqual(result, content)
        self.assertEqual(removed, [])

    def test_all_caps_key_matched_case_insensitively(self):
        # "OK" in the strings file is accessed as Localizations.ok in Swift,
        # so find_used_keys returns "ok". The lookup must match "OK" to "ok".
        content = (
            '"OK" = "OK";\n'
            '"UnusedKey" = "Unused";\n'
        )
        expected = '"OK" = "OK";\n'
        result, removed = delete_unused_content(content, {"ok"})
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["UnusedKey"])

    def test_key_with_trailing_punctuation_matched(self):
        # SwiftGen strips non-identifier characters: "NeedSomeInspiration?"
        # becomes Localizations.needSomeInspiration in Swift.
        content = (
            '"NeedSomeInspiration?" = "Need some inspiration?";\n'
            '"UnusedKey" = "Unused";\n'
        )
        expected = '"NeedSomeInspiration?" = "Need some inspiration?";\n'
        result, removed = delete_unused_content(content, {"needsomeinspiration"})
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["UnusedKey"])

    def test_unused_key_removed_sentinel_preserved(self):
        content = (
            '"About" = "About";\n'
            '"UnusedKey" = "Unused";\n'
            '"Cancel" = "Cancel";\n'
        )
        expected = (
            '"About" = "About";\n'
            '"Cancel" = "Cancel";\n'
        )
        result, removed = delete_unused_content(content, {"about", "cancel"})
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["UnusedKey"])

    def test_removed_list_is_in_file_order(self):
        content = (
            '"About" = "About";\n'
            '"UnusedAlpha" = "A";\n'
            '"Cancel" = "Cancel";\n'
            '"UnusedBeta" = "B";\n'
            '"Done" = "Done";\n'
        )
        _, removed = delete_unused_content(content, {"about", "cancel", "done"})
        self.assertEqual(removed, ["UnusedAlpha", "UnusedBeta"])


class TestDeleteUnusedFileIO(unittest.TestCase):
    """Integration tests for the file I/O wrapper."""

    def setUp(self):
        self._tmp_dirs: list[str] = []
        self._tmp_files: list[str] = []

    def tearDown(self):
        for path in self._tmp_files:
            try:
                os.unlink(path)
            except FileNotFoundError:
                pass
        for path in self._tmp_dirs:
            shutil.rmtree(path, ignore_errors=True)

    def _write_strings(self, content: str) -> str:
        f = tempfile.NamedTemporaryFile(
            mode="w", suffix=".strings", delete=False, encoding="utf-8"
        )
        f.write(content)
        f.close()
        self._tmp_files.append(f.name)
        return f.name

    def _make_swift_dir(self, files: dict[str, str]) -> str:
        """Create a temp directory with the given filename→content mapping."""
        d = tempfile.mkdtemp()
        self._tmp_dirs.append(d)
        for filename, content in files.items():
            filepath = os.path.join(d, filename)
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(content)
        return d

    def test_file_modified_when_unused_keys_found(self):
        strings_path = self._write_strings(
            '"About" = "About";\n'
            '"UnusedKey" = "Unused";\n'
        )
        swift_dir = self._make_swift_dir({"View.swift": "Localizations.about"})
        delete_unused(strings_path, [swift_dir])
        with open(strings_path, encoding="utf-8") as f:
            content = f.read()
        self.assertNotIn('"UnusedKey"', content)

    def test_file_mtime_unchanged_when_all_keys_used(self):
        strings_path = self._write_strings('"About" = "About";\n')
        swift_dir = self._make_swift_dir({"View.swift": "Localizations.about"})
        mtime_before = os.path.getmtime(strings_path)
        delete_unused(strings_path, [swift_dir])
        mtime_after = os.path.getmtime(strings_path)
        self.assertEqual(mtime_before, mtime_after)

    def test_returns_correct_list_of_removed_keys(self):
        strings_path = self._write_strings(
            '"About" = "About";\n'
            '"UnusedKey" = "Unused";\n'
        )
        swift_dir = self._make_swift_dir({"View.swift": "Localizations.about"})
        removed = delete_unused(strings_path, [swift_dir])
        self.assertEqual(removed, ["UnusedKey"])

    def test_returns_empty_list_when_all_keys_used(self):
        strings_path = self._write_strings('"About" = "About";\n')
        swift_dir = self._make_swift_dir({"View.swift": "Localizations.about"})
        removed = delete_unused(strings_path, [swift_dir])
        self.assertEqual(removed, [])

    def test_all_caps_key_preserved_when_referenced(self):
        strings_path = self._write_strings('"OK" = "OK";\n')
        swift_dir = self._make_swift_dir({"View.swift": "Localizations.ok"})
        removed = delete_unused(strings_path, [swift_dir])
        self.assertEqual(removed, [])

    def test_scans_swift_files_recursively(self):
        strings_path = self._write_strings(
            '"About" = "About";\n'
            '"Cancel" = "Cancel";\n'
        )
        swift_dir = self._make_swift_dir({
            "Views/AboutView.swift": "Localizations.about",
            "Views/Nested/CancelView.swift": "Localizations.cancel",
        })
        removed = delete_unused(strings_path, [swift_dir])
        self.assertEqual(removed, [])

    def test_ignores_non_swift_files(self):
        strings_path = self._write_strings('"About" = "About";\n')
        swift_dir = self._make_swift_dir({
            "notes.txt": "Localizations.about",
        })
        # The .txt file should not count as a usage source
        removed = delete_unused(strings_path, [swift_dir])
        self.assertEqual(removed, ["About"])


if __name__ == "__main__":
    unittest.main()
