#!/usr/bin/env python3
"""
fix-localizable-strings

A collection of tools for maintaining Localizable.strings files.

Usage:
    python Scripts/fix-localizable-strings/main.py delete-duplicates \\
        --strings <path/to/Localizable.strings> \\
        [--dry-run]
"""

import argparse
import sys

from delete_duplicate_strings import delete_duplicates, deduplicate


def _pluralize(count: int, singular: str, plural: str) -> str:
    return singular if count == 1 else plural


def cmd_delete_duplicates(args: argparse.Namespace) -> None:
    if args.dry_run:
        with open(args.strings, encoding="utf-8") as f:
            content = f.read()
        _, removed = deduplicate(content)
        if not removed:
            print("  No duplicate strings found.")
            return
        noun = _pluralize(len(removed), "occurrence", "occurrences")
        print(f"  Found {len(removed)} duplicate {noun}:")
        for key in removed:
            print(f"    {key}")
        print("\n  Dry run — no changes written.")
        return

    removed = delete_duplicates(args.strings)
    if not removed:
        print("  No duplicate strings found.")
        return
    noun = _pluralize(len(removed), "occurrence", "occurrences")
    print(f"  Removed {len(removed)} duplicate {noun}:")
    for key in removed:
        print(f"    {key}")


def build_parser():
    parser = argparse.ArgumentParser(
        description="Tools for maintaining Localizable.strings files."
    )
    subparsers = parser.add_subparsers(dest="command")

    dup_parser = subparsers.add_parser(
        "delete-duplicates",
        help="Remove duplicate string keys, preserving the first occurrence.",
    )
    dup_parser.add_argument(
        "--strings",
        required=True,
        metavar="PATH",
        help="Path to the Localizable.strings file to process.",
    )
    dup_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report duplicates without modifying the strings file.",
    )

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "delete-duplicates":
        cmd_delete_duplicates(args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
