#!/usr/bin/env python3
"""Pre-pass for the Sprint A proofreader (stdlib only, read-only).

Finds *candidates* for language and consistency problems in the Sprint A Markdown files.
Every line it prints must be re-read and confirmed by the reviewer before it is reported.

Usage: python check_text.py [--root PATH] [--facts-only]
Always exits 0: nothing here is a blocker, it is feedback.
"""
from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

FENCE = re.compile(r"^\s*(```|~~~)")
HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
LIST_ITEM = re.compile(r"^(\s*)(?:[-*]|\d+\.)\s+(?!\[[ x]\])(.*)")

# Unambiguous Brazilian Portuguese forms (the project writes PT-PT).
BRAZILIAN = re.compile(
    r"\b(usu[aá]rios?|tela|telas|celular(?:es)?|equipes?|gerenciar|gerenciamento|deletar|salvar|rodar|"
    r"contatos?|voc[eê]s?|a gente|mouse|baixar|se conectar|compartilhar|"
    r"(?:estou|est[aá]|estamos|est[aã]o|estava|estavam)\s+\w+ndo)\b",
    re.I,
)
# Spellings from before the 1990 Orthographic Agreement. The project uses the post-AO90 forms.
PRE_AO90 = re.compile(
    r"\b(ac[cç][aã]o|ac[cç][oõ]es|actua\w*|actividade\w*|aspecto\w*|projecto\w*|direc[cç]\w+|"
    r"directo\w*|correct[oa]s?|colect\w*|[oó]ptim\w*|objectiv\w*|recep[cç]\w+|perspectiv\w*|"
    r"retrospectiv\w*|excepto)\b",
    re.I,
)
POST_AO90 = re.compile(r"\b(a[cç][aã]o|a[cç][oõ]es|atual|atuais|projeto\w*|objetivo\w*|retrospetiva\w*|receção)\b", re.I)
ENGLISH_WORDS = re.compile(r"\b(the|and|with|should|will|because|however|which|this|that|are)\b")

# Groups of words that name the same thing. More than one variant in the same text is worth a look.
VARIANTS = {
    "quadro de avisos / mural": [r"quadro de avisos", r"\bmural\b"],
    "assembleia / reunião": [r"assembleias?", r"reuni(?:ão|ões)"],
    "condómino / residente / morador": [r"cond[oó]min[oa]s?", r"residentes?", r"moradores?"],
    "utilizador / usuário": [r"utilizadores?", r"\busu[aá]rios?"],
    "telemóvel / smartphone": [r"telem[oó]ve(?:l|is)", r"smartphones?"],
    "reporte / report": [r"\breportes?\b", r"\breports?\b"],
    "app / aplicação": [r"\bapps?\b", r"aplica[cç][aã]o|aplica[cç][oõ]es"],
    "DomusCast / Domus Cast": [r"DomusCast", r"Domus Cast"],
    "Product Backlog / product backlog": [r"Product Backlog", r"product backlog"],
    "Walking Skeleton / walking skeleton": [r"Walking Skeleton", r"walking skeleton"],
    "e-mail / email": [r"e-mail", r"\bemail\b"],
    "online / on-line": [r"\bonline\b", r"on-line"],
    "offline / off-line": [r"\boffline\b", r"off-line"],
    "retrospetiva / retrospective": [r"retrospetiva", r"retrospective"],
    "ata / minuta": [r"\batas?\b", r"minutas?"],
}
COMMON_ACRONYMS = {
    "API", "QR", "IA", "UI", "UX", "CI", "CD", "PR", "SQL", "HTTP", "HTTPS", "JSON", "REST", "APK", "OK", "ID",
    "URL", "TLS", "VM", "CPU", "RAM", "GB", "MB", "MVP", "NFR", "RGPD", "WCAG", "STRIDE", "DFD", "ADR", "DoR",
    "DoD", "MoSCoW", "RF", "RNF", "US", "TM", "TB", "PM", "BA", "QA", "SAST", "SCA", "WER", "SLI", "SLA",
    "OWASP", "IDOR", "EXIF", "PWA", "CRUD", "ORM", "SSH", "DNS", "PDF", "GHCR", "OSV", "HTML", "CSS", "ISEP",
    "CPX", "CX", "AA", "EUR", "USD", "BCE", "UTC",
}


def sprint_a_files(root: Path) -> list[Path]:
    out = []
    for md in sorted((root / "docs").rglob("*.md")):
        parts = md.relative_to(root).parts
        if parts[:3] == ("docs", "sprintB", "sprintB.md") or parts[:2] == ("docs", "sprintC"):
            continue
        out.append(md)
    for extra in (root / "README.md", root / "DomusCast" / "README.md"):
        if extra.exists():
            out.append(extra)
    return out


def find_root(start: Path) -> Path:
    for p in [start, *start.parents]:
        if (p / ".git").exists() or (p / "docs").is_dir():
            return p
    return start


def prose_lines(path: Path):
    """Yield (lineno, raw, prose, is_table) skipping fenced code; prose has code, links and markup removed."""
    fenced = False
    for i, raw in enumerate(path.read_text(encoding="utf-8-sig", errors="replace").splitlines(), 1):
        if FENCE.match(raw):
            fenced = not fenced
            continue
        if fenced:
            continue
        is_table = raw.lstrip().startswith("|")
        if is_table and re.fullmatch(r"[\s|:\-]+", raw):
            continue
        t = re.sub(r"`[^`]*`", "CODE", raw)
        t = re.sub(r"!\[[^\]]*\]\([^)]*\)", " ", t)
        t = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", t)
        t = re.sub(r"<[^>]+>", " ", t)
        t = re.sub(r"https?://\S+", " ", t)
        t = re.sub(r"(\*\*|__|\*|~~)", "", t)
        if is_table:
            t = t.replace("|", " ¦ ")
        yield i, raw, re.sub(r"\s+", " ", t).strip(), is_table


def excerpt(text: str, m: re.Match | None = None, width: int = 90) -> str:
    if m is None:
        return text[:width] + ("..." if len(text) > width else "")
    a = max(0, m.start() - 30)
    b = min(len(text), m.end() + 30)
    return ("..." if a else "") + text[a:b] + ("..." if b < len(text) else "")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=None)
    ap.add_argument("--facts-only", action="store_true")
    args = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    root = (args.root or find_root(Path.cwd())).resolve()
    files = sprint_a_files(root)
    print("Scope: Sprint A only. Excluded: docs/sprintB/sprintB.md, docs/sprintC/.")
    print("Files: " + ", ".join(f.relative_to(root).as_posix() for f in files) + "\n")

    findings: list[tuple[str, str, int, str]] = []
    corpus: dict[Path, str] = {}
    seen_long: dict[str, tuple[Path, int]] = {}

    def add(cat: str, path: Path, line: int, msg: str) -> None:
        findings.append((cat, path.relative_to(root).as_posix(), line, msg))

    for path in files:
        rows = list(prose_lines(path))
        corpus[path] = "\n".join(p for _, _, p, _ in rows)
        heading_dot: list[int] = []
        heading_nodot: list[int] = []
        prev_level = 0
        list_block: list[tuple[int, str]] = []

        def flush_list() -> None:
            if len(list_block) >= 3:
                n = len(list_block)
                ends = sum(1 for _, t in list_block if t.rstrip().endswith((".", "!", "?")))
                ups = sum(1 for _, t in list_block if re.match(r"^\W*[A-ZÀ-Ú]", t))
                if 0 < ends < n:
                    add("list-style", path, list_block[0][0], f"list of {n} items: {ends} end with a full stop and {n - ends} do not")
                if 0 < ups < n:
                    add("list-style", path, list_block[0][0], f"list of {n} items: {ups} start with a capital and {n - ups} do not")
            list_block.clear()

        for i, raw, t, is_table in rows:
            m_list = LIST_ITEM.match(raw)
            if m_list and not is_table and not m_list.group(1):
                list_block.append((i, re.sub(r"(\*\*|__|\*)", "", m_list.group(2)).strip()))
            else:
                flush_list()

            h = HEADING.match(raw)
            if h:
                level, title = len(h.group(1)), h.group(2)
                if prev_level and level > prev_level + 1:
                    add("heading", path, i, f"heading level jumps from {prev_level} to {level}: {title[:60]}")
                prev_level = level
                if re.match(r"^\d+(\.\d+)+\.\s", title):
                    heading_dot.append(i)
                elif re.match(r"^\d+(\.\d+)+\s", title):
                    heading_nodot.append(i)
                if title.rstrip().endswith("."):
                    add("heading", path, i, f"heading ends with a full stop: {title[:60]}")
                continue

            if not t:
                continue
            if len(t) >= 100:
                if t in seen_long and seen_long[t][0] != path:
                    other = seen_long[t]
                    add("duplicate", path, i, f"same text as {other[0].relative_to(root).as_posix()}:{other[1]}: {excerpt(t)}")
                else:
                    seen_long.setdefault(t, (path, i))

            if not is_table and re.search(r"(?<=\S)  +(?=\S)", re.sub(r"`[^`]*`", "X", raw).strip()):
                add("spacing", path, i, f"double space: {excerpt(t)}")
            for m in re.finditer(r"\b(\w{2,})\s+\1\b", t, re.I):
                if not m.group(1).isdigit():
                    add("repeated-word", path, i, f"'{m.group(0)}': {excerpt(t, m)}")
            for m in BRAZILIAN.finditer(t):
                add("brazilian", path, i, f"'{m.group(0)}' looks Brazilian: {excerpt(t, m)}")
            for m in PRE_AO90.finditer(t):
                add("pre-AO90", path, i, f"'{m.group(0)}' uses the pre-1990 spelling: {excerpt(t, m)}")
            if len(ENGLISH_WORDS.findall(t)) >= 2:
                add("english-leak", path, i, f"possible English sentence: {excerpt(t)}")
            for m in re.finditer(r"\s[,;:!?](?=\s|$)", t):
                add("punctuation", path, i, f"space before punctuation: {excerpt(t, m)}")
            for m in re.finditer(r"[a-zà-ú],[A-Za-zÀ-ú]", t):
                add("punctuation", path, i, f"missing space after comma: {excerpt(t, m)}")
            for m in re.finditer(r"[a-zà-ú]\.[A-ZÀ-Ú][a-zà-ú]", t):
                add("punctuation", path, i, f"missing space after full stop: {excerpt(t, m)}")
            if not re.match(r"^\d+\)", t):
                for o, c in (("(", ")"), ("«", "»"), ("[", "]")):
                    if t.count(o) != t.count(c):
                        add("brackets", path, i, f"unbalanced '{o}{c}': {excerpt(t)}")
                        break
            if not is_table:
                for s in re.split(r"(?<=[.!?])\s+(?=[A-ZÀ-Ú])", t):
                    n = len(s.split())
                    if n > 45:
                        add("long-sentence", path, i, f"{n} words: {excerpt(s, None, 100)}")
        flush_list()
        if heading_dot and heading_nodot:
            add(
                "heading",
                path,
                heading_dot[0],
                f"numbered headings mix 'N.N.' ({len(heading_dot)}, first at line {heading_dot[0]}) and 'N.N' "
                f"({len(heading_nodot)}, first at line {heading_nodot[0]})",
            )

    if not args.facts_only:
        order = ["brazilian", "pre-AO90", "english-leak", "repeated-word", "punctuation", "spacing", "brackets",
                 "heading", "list-style", "long-sentence", "duplicate"]
        print("== Candidates (confirm each one by re-reading the line before reporting it)")
        for cat in order:
            items = [f for f in findings if f[0] == cat]
            if not items:
                continue
            print(f"\n[{cat}] {len(items)}")
            for _, p, ln, msg in items[:40]:
                print(f"  {p}:{ln}: {msg}")
            if len(items) > 40:
                print(f"  ... and {len(items) - 40} more")

    print("\n== Facts")
    print("  words per file:")
    for path, text in corpus.items():
        print(f"    {len(text.split()):>6}  {path.relative_to(root).as_posix()}")
    all_text = "\n".join(corpus.values())
    print("  orthography (AO90 forms vs pre-AO90 forms): "
          f"{len(POST_AO90.findall(all_text))} vs {len(PRE_AO90.findall(all_text))}")
    print("  terminology variants (occurrences; more than one variant may be intentional, confirm):")
    for name, patterns in VARIANTS.items():
        flags = 0 if any(re.search(r"[A-Z]", p) for p in patterns) else re.I
        counts = [len(re.findall(p, all_text, flags=flags)) for p in patterns]
        if sum(1 for c in counts if c) > 1:
            print(f"    {name}: " + "; ".join(f"{p}={c}" for p, c in zip(patterns, counts) if c))
    acr = Counter(
        m.group(0) for m in re.finditer(r"\b[A-Z][A-Z0-9]{1,5}\b", all_text) if not re.search(r"\d", m.group(0))
    )
    undefined = []
    for a, n in acr.most_common():
        if a in COMMON_ACRONYMS:
            continue
        if re.search(rf"\({re.escape(a)}\)|\({re.escape(a)}[,;:]|\b{re.escape(a)}\s*\(", all_text):
            continue
        undefined.append(f"{a} ({n})")
    print("  acronyms with no expansion found (candidates): " + (", ".join(undefined[:25]) or "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
