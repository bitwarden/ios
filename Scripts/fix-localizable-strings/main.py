#!/usr/bin/env python3
"""
fix-localizable-strings

A collection of tools for maintaining Localizable.strings files.

Usage:
    python Scripts/fix-localizable-strings/main.py delete-duplicates \\
        --strings <path/to/Localizable.strings> \\
        [--dry-run]

    python Scripts/fix-localizable-strings/main.py delete-unused \\
        --strings <path/to/Localizable.strings> \\
        --swift-source <dir> [--swift-source <dir> ...] \\
        [--dry-run]
"""

import argparse
import os
import sys

from delete_duplicate_strings import delete_duplicates, deduplicate
from delete_unused_strings import delete_unused, delete_unused_content, find_used_keys


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


def cmd_delete_unused(args: argparse.Namespace) -> None:
    if args.dry_run:
        with open(args.strings, encoding="utf-8") as f:
            content = f.read()
        swift_sources = []
        for swift_dir in args.swift_sources:
            for dirpath, _, filenames in os.walk(swift_dir):
                for filename in filenames:
                    if filename.endswith(".swift"):
                        with open(os.path.join(dirpath, filename), encoding="utf-8") as f:
                            swift_sources.append(f.read())
        used_keys = find_used_keys(swift_sources)
        _, removed = delete_unused_content(content, used_keys)
        if not removed:
            print("  No unused strings found.")
            return
        noun = _pluralize(len(removed), "key", "keys")
        print(f"  Found {len(removed)} unused {noun}:")
        for key in removed:
            print(f"    {key}")
        print("\n  Dry run — no changes written.")
        return

    removed = delete_unused(args.strings, args.swift_sources)
    if not removed:
        print("  No unused strings found.")
        return
    noun = _pluralize(len(removed), "key", "keys")
    print(f"  Removed {len(removed)} unused {noun}:")
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

    unused_parser = subparsers.add_parser(
        "delete-unused",
        help="Remove string keys that are never referenced in Swift source code.",
    )
    unused_parser.add_argument(
        "--strings",
        required=True,
        metavar="PATH",
        help="Path to the Localizable.strings file to process.",
    )
    unused_parser.add_argument(
        "--swift-source",
        required=True,
        action="append",
        dest="swift_sources",
        metavar="DIR",
        help="Directory to search recursively for Swift source files. May be repeated.",
    )
    unused_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report unused keys without modifying the strings file.",
    )

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "delete-duplicates":
        cmd_delete_duplicates(args)
    elif args.command == "delete-unused":
        cmd_delete_unused(args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
