#!/usr/bin/env python3
"""Fast, dependency-free integrity checks for the static landing page."""

from __future__ import annotations

import html.parser
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / "site"
INDEX = SITE / "index.html"

REQUIRED_FILES = (
    "index.html",
    "assets/css/site.css",
    "assets/js/site.js",
    "assets/fonts/vazirmatn-regular.woff2",
    "assets/fonts/vazirmatn-bold.woff2",
    "assets/img/favicon-32.png",
    "assets/img/og.png",
)
REQUIRED_TEXT = (
    "github.com/imdanialrashidi/gym-log/releases/download/v0.2.1/gym-log-v0.2.1.apk",
    "c233692d3bb5225449d369c31841f33559e163a6c326092e0586406fc6693bf5",
    "<main",
    "<h1",
    'lang="fa"',
    'dir="rtl"',
)
# External links are allowed; local references are checked on disk.
REMOTE_SCHEMES = {"http", "https", "mailto", "tel", "data"}


class Refs(html.parser.HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.refs: list[tuple[str, str]] = []
        self.img_without_alt = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if "src" in values:
            self.refs.append(("src", values["src"] or ""))
        if "href" in values:
            self.refs.append(("href", values["href"] or ""))
        if tag == "img" and "alt" not in values:
            self.img_without_alt += 1


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if not SITE.is_dir():
        fail("site/ directory is missing")
    for relative in REQUIRED_FILES:
        if not (SITE / relative).is_file():
            fail(f"required file is missing: site/{relative}")

    text = INDEX.read_text(encoding="utf-8")
    for needle in REQUIRED_TEXT:
        if needle not in text:
            fail(f"index.html is missing required content: {needle[:70]}")

    parser = Refs()
    parser.feed(text)
    parser.close()

    if parser.img_without_alt:
        fail(f"{parser.img_without_alt} <img> element(s) have no alt attribute")

    checked = 0
    for _kind, ref in parser.refs:
        if not ref or ref.startswith("#"):
            continue
        parts = urlsplit(ref)
        if parts.scheme in REMOTE_SCHEMES or ref.startswith("//"):
            continue
        if parts.scheme:
            fail(f"unexpected reference scheme in {ref!r}")
        path = unquote(parts.path)
        if not path:
            continue
        target = (SITE / path).resolve()
        try:
            target.relative_to(SITE.resolve())
        except ValueError:
            fail(f"reference escapes site/: {ref!r}")
        if not target.exists():
            fail(f"broken local reference: {ref!r}")
        checked += 1

    css = (SITE / "assets/css/site.css").read_text(encoding="utf-8")
    for font in re.findall(r'url\("([^"]+)"\)', css):
        if not font.startswith("data:"):
            target = (SITE / "assets/css" / font).resolve()
            if not target.is_file():
                fail(f"CSS font reference is missing: {font!r}")

    print(f"OK: {checked} local references, {len(REQUIRED_FILES)} required files, HTML integrity passed.")


if __name__ == "__main__":
    main()
