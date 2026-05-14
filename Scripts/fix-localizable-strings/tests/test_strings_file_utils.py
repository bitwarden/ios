"""Tests for the strings_file_utils module."""

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from strings_file_utils import filter_entries

# Keys accepted by the test predicate. "sentinel" is always kept to confirm
# that filter_entries does not over-delete.
_KEEP = {"kept", "about", "cancel", "sentinel"}


def _should_keep(key: str) -> bool:
    return key in _KEEP


class TestFilterEntriesEmptyAndCommentOnly(unittest.TestCase):
    """Degenerate inputs produce empty or unchanged output."""

    def test_empty_content(self):
        result, removed = filter_entries("", _should_keep)
        self.assertEqual(result, "")
        self.assertEqual(removed, [])

    def test_comment_only_content_is_unchanged(self):
        content = "/* This file is intentionally left blank. */\n"
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, content)
        self.assertEqual(removed, [])


class TestFilterEntriesCommentRemoval(unittest.TestCase):
    """Comments immediately before a removed entry are discarded with it."""

    def test_single_line_block_comment_removed_with_entry(self):
        content = (
            '"sentinel" = "S";\n'
            '/* This key is unused */\n'
            '"unused" = "Unused";\n'
            '"cancel" = "Cancel";\n'
        )
        expected = (
            '"sentinel" = "S";\n'
            '"cancel" = "Cancel";\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["unused"])

    def test_line_comment_removed_with_entry(self):
        content = (
            '"sentinel" = "S";\n'
            '// unused\n'
            '"unused" = "Unused";\n'
            '"cancel" = "Cancel";\n'
        )
        expected = (
            '"sentinel" = "S";\n'
            '"cancel" = "Cancel";\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["unused"])

    def test_multiline_block_comment_removed_with_entry(self):
        content = (
            '"sentinel" = "S";\n'
            '/* This comment\n'
            '   spans multiple lines */\n'
            '"unused" = "Unused";\n'
            '"cancel" = "Cancel";\n'
        )
        expected = (
            '"sentinel" = "S";\n'
            '"cancel" = "Cancel";\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["unused"])

    def test_stacked_comments_removed_with_entry(self):
        content = (
            '"sentinel" = "S";\n'
            '/* Comment one */\n'
            '// Comment two\n'
            '"unused" = "Unused";\n'
            '"cancel" = "Cancel";\n'
        )
        expected = (
            '"sentinel" = "S";\n'
            '"cancel" = "Cancel";\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["unused"])

    def test_comment_on_kept_entry_is_preserved(self):
        content = (
            '/* Section header */\n'
            '"about" = "About";\n'
            '"unused" = "Unused";\n'
            '"sentinel" = "S";\n'
        )
        expected = (
            '/* Section header */\n'
            '"about" = "About";\n'
            '"sentinel" = "S";\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["unused"])


class TestFilterEntriesBlankLines(unittest.TestCase):
    """Blank lines break comment-entry association and are preserved in output."""

    def test_blank_line_between_comment_and_removed_entry_preserves_comment(self):
        content = (
            '"sentinel" = "S";\n'
            '/* Orphaned comment */\n'
            '\n'
            '"unused" = "Unused";\n'
            '"cancel" = "Cancel";\n'
        )
        expected = (
            '"sentinel" = "S";\n'
            '/* Orphaned comment */\n'
            '\n'
            '"cancel" = "Cancel";\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["unused"])

    def test_blank_lines_between_kept_entries_are_preserved(self):
        content = (
            '"about" = "About";\n'
            '\n'
            '"cancel" = "Cancel";\n'
            '\n'
            '"sentinel" = "S";\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, content)
        self.assertEqual(removed, [])


class TestFilterEntriesCommentSyntaxInValue(unittest.TestCase):
    """Entry values containing comment-like syntax must not be misclassified."""

    def test_block_comment_syntax_in_value_does_not_suppress_filtering(self):
        content = (
            '"kept" = "Use /* to start a block comment";\n'
            '"unused" = "Unused";\n'
            '"sentinel" = "S";\n'
        )
        expected = (
            '"kept" = "Use /* to start a block comment";\n'
            '"sentinel" = "S";\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["unused"])

    def test_closing_comment_syntax_in_value_does_not_corrupt_output(self):
        content = (
            '"kept" = "Use /* to start a block comment";\n'
            '"unused" = "Unused";\n'
            '"about" = "This */ ends nothing";\n'
            '"sentinel" = "S";\n'
        )
        expected = (
            '"kept" = "Use /* to start a block comment";\n'
            '"about" = "This */ ends nothing";\n'
            '"sentinel" = "S";\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, expected)
        self.assertEqual(removed, ["unused"])


class TestFilterEntriesTrailingPending(unittest.TestCase):
    """Trailing comment with no following entry is flushed to output."""

    def test_trailing_comment_without_entry_is_preserved(self):
        content = (
            '"sentinel" = "S";\n'
            '/* Trailing comment */\n'
        )
        result, removed = filter_entries(content, _should_keep)
        self.assertEqual(result, content)
        self.assertEqual(removed, [])


if __name__ == "__main__":
    unittest.main()
