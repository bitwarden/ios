"""Tests for the fix_ellipsis module."""

import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fix_ellipsis import fix_ellipsis, fix_ellipsis_file


class TestFixEllipsisNoOp(unittest.TestCase):
    """Cases where the file has no three-dot sequences and should be unchanged."""

    def test_empty_file_is_unchanged(self):
        content = ""
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, content)
        self.assertEqual(changed, [])

    def test_file_with_no_ellipsis_is_unchanged(self):
        content = '"greeting" = "Hello";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, content)
        self.assertEqual(changed, [])

    def test_multiple_entries_without_ellipsis_are_unchanged(self):
        content = (
            '"alpha" = "First";\n'
            '"beta" = "Second";\n'
            '"gamma" = "Third";\n'
        )
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, content)
        self.assertEqual(changed, [])

    def test_comment_only_file_is_unchanged(self):
        content = "/* This file is intentionally left blank. */\n"
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, content)
        self.assertEqual(changed, [])

    def test_file_with_only_blank_lines_is_unchanged(self):
        content = "\n\n\n"
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, content)
        self.assertEqual(changed, [])

    def test_already_unicode_ellipsis_is_unchanged(self):
        content = '"loading" = "Loading…";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, content)
        self.assertEqual(changed, [])


class TestFixEllipsisConverts(unittest.TestCase):
    """Cases where three-dot sequences are converted."""

    def test_single_entry_with_ellipsis_is_converted(self):
        content = '"loading" = "Loading...";\n'
        expected = '"loading" = "Loading…";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, expected)
        self.assertEqual(changed, ["loading"])

    def test_multiple_entries_only_affected_ones_change(self):
        content = (
            '"title" = "Title";\n'
            '"loading" = "Loading...";\n'
            '"done" = "Done";\n'
        )
        expected = (
            '"title" = "Title";\n'
            '"loading" = "Loading…";\n'
            '"done" = "Done";\n'
        )
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, expected)
        self.assertEqual(changed, ["loading"])

    def test_multiple_affected_entries_all_converted(self):
        content = (
            '"a" = "First...";\n'
            '"b" = "Second...";\n'
        )
        expected = (
            '"a" = "First…";\n'
            '"b" = "Second…";\n'
        )
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, expected)
        self.assertEqual(changed, ["a", "b"])

    def test_ellipsis_in_middle_of_value_is_converted(self):
        content = '"message" = "Wait...done";\n'
        expected = '"message" = "Wait…done";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, expected)
        self.assertEqual(changed, ["message"])

    def test_value_that_is_only_ellipsis_is_converted(self):
        content = '"placeholder" = "...";\n'
        expected = '"placeholder" = "…";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, expected)
        self.assertEqual(changed, ["placeholder"])


class TestFixEllipsisBoundary(unittest.TestCase):
    """Boundary cases for dot sequences."""

    def test_four_dots_becomes_ellipsis_plus_dot(self):
        content = '"key" = "....";\n'
        expected = '"key" = "….";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, expected)
        self.assertEqual(changed, ["key"])

    def test_six_dots_becomes_two_ellipses(self):
        content = '"key" = "......";\n'
        expected = '"key" = "……";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, expected)
        self.assertEqual(changed, ["key"])

    def test_two_dots_is_unchanged(self):
        content = '"key" = "..";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, content)
        self.assertEqual(changed, [])

    def test_one_dot_is_unchanged(self):
        content = '"key" = ".";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, content)
        self.assertEqual(changed, [])


class TestFixEllipsisKeyPreservation(unittest.TestCase):
    """The key side of an entry is never modified."""

    def test_key_containing_dots_is_not_converted(self):
        # The key itself looks like it has dots, but the value does not.
        # The key should pass through unchanged.
        content = '"key...name" = "Value";\n'
        result, changed = fix_ellipsis(content)
        self.assertEqual(result, content)
        self.assertEqual(changed, [])

    def test_key_with_dots_and_value_with_dots_only_value_changes(self):
        content = '"key...name" = "Value...";\n'
        result, changed = fix_ellipsis(content)
        self.assertIn('"key...name"', result)
        self.assertIn('"Value…"', result)
        self.assertEqual(changed, ["key...name"])


class TestFixEllipsisReturnedKeys(unittest.TestCase):
    """Verify the changed keys list is correct."""

    def test_changed_keys_are_in_encounter_order(self):
        content = (
            '"x" = "X...";\n'
            '"y" = "Y";\n'
            '"z" = "Z...";\n'
        )
        _, changed = fix_ellipsis(content)
        self.assertEqual(changed, ["x", "z"])

class TestFixEllipsisFileIO(unittest.TestCase):
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
        path = self._write('"loading" = "Loading...";\n')
        fix_ellipsis_file(path)
        with open(path, encoding="utf-8") as f:
            result = f.read()
        self.assertEqual(result, '"loading" = "Loading…";\n')

    def test_returns_changed_keys(self):
        path = self._write('"loading" = "Loading...";\n')
        changed = fix_ellipsis_file(path)
        self.assertEqual(changed, ["loading"])

    def test_does_not_write_file_when_no_ellipsis_found(self):
        path = self._write('"greeting" = "Hello";\n')
        mtime_before = os.path.getmtime(path)
        changed = fix_ellipsis_file(path)
        mtime_after = os.path.getmtime(path)
        self.assertEqual(changed, [])
        self.assertEqual(mtime_before, mtime_after)

    def test_returns_empty_list_when_no_changes(self):
        path = self._write('"a" = "A";\n"b" = "B";\n')
        changed = fix_ellipsis_file(path)
        self.assertEqual(changed, [])


if __name__ == "__main__":
    unittest.main()
