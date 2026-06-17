#!/usr/bin/env python3
import argparse
import re
import subprocess
import sys
from pathlib import Path


def parse_issues(path: Path):
    text = path.read_text(encoding="utf-8")
    blocks = re.split(r"\n---\n", text)
    issues = []

    for block in blocks:
        title_match = re.search(r"^##\s+\d+\.\s+(.+)$", block, re.MULTILINE)
        if not title_match:
            continue

        labels_match = re.search(r"^Labels:\s+(.+)$", block, re.MULTILINE)
        labels = []
        if labels_match:
            labels = [label.strip(" `") for label in labels_match.group(1).split(",")]

        body = re.sub(r"^##\s+\d+\.\s+.+\n+", "", block, count=1, flags=re.MULTILINE).strip()
        issues.append(
            {
                "title": title_match.group(1).strip(),
                "labels": [label for label in labels if label],
                "body": body,
            }
        )

    return issues


def run(command, *, dry_run=False):
    if dry_run:
        print("+", " ".join(command))
        return

    subprocess.run(command, check=True)


def ensure_label(repo: str, label: str, dry_run: bool):
    run(
        [
            "gh",
            "label",
            "create",
            label,
            "--repo",
            repo,
            "--force",
            "--color",
            "6f42c1",
        ],
        dry_run=dry_run,
    )


def main():
    parser = argparse.ArgumentParser(description="Create GitHub issues from docs/GITHUB_ISSUES.md")
    parser.add_argument("--repo", default="miguel-garcia-marques/financialTracker")
    parser.add_argument("--file", default="docs/GITHUB_ISSUES.md")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-labels", action="store_true")
    args = parser.parse_args()

    issues = parse_issues(Path(args.file))
    if not issues:
        print(f"No issues found in {args.file}", file=sys.stderr)
        return 1

    labels = sorted({label for issue in issues for label in issue["labels"]})
    if not args.skip_labels:
        for label in labels:
            ensure_label(args.repo, label, args.dry_run)

    for issue in issues:
        command = ["gh", "issue", "create", "--repo", args.repo, "--title", issue["title"]]
        if issue["labels"]:
            command.extend(["--label", ",".join(issue["labels"])])
        command.extend(["--body", issue["body"]])
        run(command, dry_run=args.dry_run)

    print(f"Created {len(issues)} issues for {args.repo}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
