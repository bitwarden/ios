"""Tests for the delete_duplicate_strings module."""

import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from delete_duplicate_strings import deduplicate, delete_duplicates


class TestDeduplicateNoDuplicates(unittest.TestCase):
    """Cases where the file has no duplicates and should be unchanged."""

    def test_empty_file_is_unchanged(self):
        content = ""
        result, removed = deduplicate(content)
        self.assertEqual(result, content)
        self.assertEqual(removed, [])

    def test_single_entry_is_unchanged(self):
        content = '"greeting" = "Hello";\n'
        result, removed = deduplicate(content)
        self.assertEqual(result, content)
        self.assertEqual(removed, [])

    def test_multiple_unique_entries_are_unchanged(self):
        content = (
            '"greeting" = "Hello";\n'
            '"farewell" = "Goodbye";\n'
            '"thanks" = "Thank you";\n'
        )
        result, removed = deduplicate(content)
        self.assertEqual(result, content)
        self.assertEqual(removed, [])

    def test_comment_only_file_is_unchanged(self):
        content = "/* This file is intentionally left blank. */\n"
        result, removed = deduplicate(content)
        self.assertEqual(result, content)
        self.assertEqual(removed, [])

    def test_file_with_only_blank_lines_is_unchanged(self):
        content = "\n\n\n"
        result, removed = deduplicate(content)
        self.assertEqual(result, content)
        self.assertEqual(removed, [])


class TestDeduplicateRemovesDuplicates(unittest.TestCase):
    """Cases where duplicates are removed."""

    def test_removes_all_occurrences_beyond_first(self):
        content = (
            '"key" = "first";\n'
            '"key" = "second";\n'
            '"key" = "third";\n'
        )
        expected = '"key" = "first";\n'
        result, removed = deduplicate(content)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["key", "key"])

    def test_removes_multiple_distinct_duplicate_keys(self):
        content = (
            '"alpha" = "A";\n'
            '"beta" = "B";\n'
            '"alpha" = "A again";\n'
            '"beta" = "B again";\n'
        )
        expected = (
            '"alpha" = "A";\n'
            '"beta" = "B";\n'
        )
        result, removed = deduplicate(content)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["alpha", "beta"])

    def test_non_duplicate_entries_are_preserved(self):
        content = (
            '"alpha" = "A";\n'
            '"beta" = "B";\n'
            '"alpha" = "A again";\n'
            '"gamma" = "G";\n'
        )
        expected = (
            '"alpha" = "A";\n'
            '"beta" = "B";\n'
            '"gamma" = "G";\n'
        )
        result, removed = deduplicate(content)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["alpha"])


class TestDeduplicatePreservesFirstOccurrencePosition(unittest.TestCase):
    """The first occurrence stays exactly where it is in the file."""

    def test_first_occurrence_remains_at_original_position(self):
        content = (
            '"other" = "Other";\n'
            '"key" = "first";\n'
            '"more" = "More";\n'
            '"key" = "second";\n'
        )
        expected = (
            '"other" = "Other";\n'
            '"key" = "first";\n'
            '"more" = "More";\n'
        )
        result, _ = deduplicate(content)
        self.assertEqual(result, expected)


class TestDeduplicateCommentHandling(unittest.TestCase):
    """Comment blocks are removed together with their duplicate entry."""

    def test_preserves_comment_on_first_occurrence(self):
        content = (
            '/* This comment belongs to the first occurrence */\n'
            '"greeting" = "Hello";\n'
            '"greeting" = "Hi";\n'
            '"farewell" = "Goodbye";\n'
        )
        expected = (
            '/* This comment belongs to the first occurrence */\n'
            '"greeting" = "Hello";\n'
            '"farewell" = "Goodbye";\n'
        )
        result, removed = deduplicate(content)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["greeting"])

    def test_preserves_comment_on_non_duplicate_entry(self):
        content = (
            '"greeting" = "Hello";\n'
            '"greeting" = "Hi";\n'
            '/* This belongs to farewell */\n'
            '"farewell" = "Goodbye";\n'
            '"done" = "Done";\n'
        )
        expected = (
            '"greeting" = "Hello";\n'
            '/* This belongs to farewell */\n'
            '"farewell" = "Goodbye";\n'
            '"done" = "Done";\n'
        )
        result, removed = deduplicate(content)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["greeting"])


class TestDeduplicateReturnedRemovedKeys(unittest.TestCase):
    """Verify the removed keys list is correct."""

    def test_removed_list_is_empty_when_no_duplicates(self):
        content = '"a" = "A";\n"b" = "B";\n'
        _, removed = deduplicate(content)
        self.assertEqual(removed, [])

    def test_removed_list_contains_each_removal_separately(self):
        # "a" appears three times, so it should appear twice in removed
        content = '"a" = "1";\n"a" = "2";\n"a" = "3";\n'
        _, removed = deduplicate(content)
        self.assertEqual(removed, ["a", "a"])

    def test_removed_list_is_in_encounter_order(self):
        content = (
            '"x" = "1";\n'
            '"y" = "1";\n'
            '"x" = "2";\n'
            '"y" = "2";\n'
        )
        _, removed = deduplicate(content)
        self.assertEqual(removed, ["x", "y"])


class TestDeleteDuplicatesFileIO(unittest.TestCase):
    """Integration tests for the file I/O wrapper."""

    def _write(self, content: str) -> str:
        f = tempfile.NamedTemporaryFile(
            mode="w", suffix=".strings", delete=False, encoding="utf-8"
        )
        f.write(content)
        f.close()
        self.addCleanup(os.unlink, f.name)
        return f.name

    def test_modifies_file_in_place(self):
        path = self._write('"a" = "A";\n"a" = "A again";\n')
        delete_duplicates(path)
        with open(path) as f:
            result = f.read()
        self.assertNotIn('"a" = "A again";', result)

    def test_returns_removed_keys(self):
        path = self._write('"a" = "A";\n"a" = "A again";\n')
        removed = delete_duplicates(path)
        self.assertEqual(removed, ["a"])

    def test_does_not_write_file_when_no_duplicates(self):
        path = self._write('"a" = "A";\n')
        mtime_before = os.path.getmtime(path)
        removed = delete_duplicates(path)
        mtime_after = os.path.getmtime(path)
        self.assertEqual(removed, [])
        self.assertEqual(mtime_before, mtime_after)

    def test_returns_empty_list_when_no_duplicates(self):
        path = self._write('"a" = "A";\n"b" = "B";\n')
        removed = delete_duplicates(path)
        self.assertEqual(removed, [])


if __name__ == "__main__":
    unittest.main()
