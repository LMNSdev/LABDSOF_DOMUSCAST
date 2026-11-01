#!/usr/bin/env python3
"""Mechanical checks for the Sprint A documentation (stdlib only).

Usage: python check_docs.py [--root PATH] [--pptx FILE] [--no-pptx]
Exit code 1 when at least one ERROR is found.
"""
from __future__ import annotations

import argparse
import html
import re
import sys
import zipfile
from pathlib import Path

# Upper-case tokens are case-sensitive: "todo" is a normal Portuguese word.
PLACEHOLDER = re.compile(
    r"\b(TODO|TBC|TBD|FIXME|XXX)\b|A PREENCHER|(?i:por definir|por confirmar|a definir)"
)
MERGE_MARKER = re.compile(r"^(<{7}|={7}|>{7})(\s|$)")
LINK = re.compile(r"(!?)\[([^\]]*)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
US_ID = re.compile(r"\bUS-\d+\b")
FENCE = re.compile(r"^\s*(```|~~~)")

findings: list[tuple[str, str, str, int, str]] = []


def add(level: str, cat: str, path: Path, line: int, msg: str) -> None:
    findings.append((level, cat, str(path), line, msg))


def find_root(start: Path) -> Path:
    for p in [start, *start.parents]:
        if (p / ".git").exists() or (p / "docs").is_dir():
            return p
    return start


def read_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8-sig", errors="replace").splitlines()


def slug(text: str) -> str:
    text = re.sub(r"`", "", text)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"[*_~]{1,3}(?=\S)|(?<=\S)[*~]{1,3}", "", text)
    text = text.strip().lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


def outside_code(lines: list[str]):
    """Yield (lineno, line) skipping fenced code blocks."""
    fenced = False
    for i, line in enumerate(lines, 1):
        if FENCE.match(line):
            fenced = not fenced
            continue
        if not fenced:
            yield i, line


def anchors_of(path: Path, cache: dict[Path, set[str]]) -> set[str]:
    if path in cache:
        return cache[path]
    seen: dict[str, int] = {}
    out: set[str] = set()
    for _, line in outside_code(read_lines(path)):
        m = HEADING.match(line)
        if not m:
            continue
        s = slug(m.group(2))
        n = seen.get(s, 0)
        out.add(s if n == 0 else f"{s}-{n}")
        seen[s] = n + 1
    cache[path] = out
    return out


def split_cells(line: str) -> list[str]:
    """Split a markdown table row on unescaped pipes outside code spans."""
    s = line.strip()
    cells, cur, in_code, i = [], [], False, 0
    while i < len(s):
        ch = s[i]
        if ch == "\\" and i + 1 < len(s):
            cur.append(s[i : i + 2])
            i += 2
            continue
        if ch == "`":
            in_code = not in_code
        if ch == "|" and not in_code:
            cells.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
        i += 1
    cells.append("".join(cur))
    if cells and cells[0].strip() == "":
        cells = cells[1:]
    if cells and cells[-1].strip() == "":
        cells = cells[:-1]
    return [c.strip() for c in cells]


def check_markdown(path: Path, root: Path, cache: dict[Path, set[str]]) -> None:
    lines = read_lines(path)
    for i, line in enumerate(lines, 1):
        if MERGE_MARKER.match(line):
            add("ERROR", "merge-marker", path, i, line.strip())

    for i, line in outside_code(lines):
        # Sprint B backlog rows are reported once per story by check_backlogs (category 'dor').
        m_ph = PLACEHOLDER.search(line)
        if m_ph and not (path.parent.name == "sprintB" and line.lstrip().startswith("| US-")):
            start = max(0, m_ph.start() - 60)
            add("WARN", "placeholder", path, i, f"'{m_ph.group(0)}' in: ...{line[start:m_ph.end() + 60].strip()}...")
        for m in LINK.finditer(line):
            is_img, text, target = m.group(1), m.group(2), m.group(3)
            if is_img and not text.strip():
                add("WARN", "image-alt", path, i, f"image without alt text: {target}")
            if re.match(r"^(https?:|mailto:|tel:)", target):
                continue
            file_part, _, anchor = target.partition("#")
            file_part = file_part.replace("%20", " ")
            dest = path if not file_part else (path.parent / file_part).resolve()
            if file_part and not dest.exists():
                add("ERROR", "broken-link", path, i, f"missing file: {target}")
                continue
            if anchor and dest.suffix.lower() == ".md":
                if anchor.lower() not in anchors_of(dest, cache):
                    add("ERROR", "broken-anchor", path, i, f"no heading for #{anchor} in {dest.name}")

    # tables: consistent column counts and glued rows
    block: list[tuple[int, str]] = []
    for i, line in list(outside_code(lines)) + [(len(lines) + 1, "")]:
        if line.lstrip().startswith("|"):
            block.append((i, line))
            continue
        if block:
            expected = len(split_cells(block[0][1]))
            for n, row in block:
                if re.match(r"^\s*\|\|", row):
                    add("ERROR", "table", path, n, "row starts with '||' (glued row)")
                elif len(split_cells(row)) != expected:
                    add("ERROR", "table", path, n, f"{len(split_cells(row))} columns, header has {expected}")
            block = []


def parse_us_table(path: Path):
    """Return {US-id: cells} for rows whose first cell is US-nn."""
    rows: dict[str, list[str]] = {}
    for i, line in outside_code(read_lines(path)):
        if re.match(r"^\s*\|\s*US-\d+\s*\|", line):
            cells = split_cells(line)
            rows.setdefault(cells[0], cells + [str(i)])
    return rows


def sprint_a_docs(root: Path) -> list[Path]:
    """Markdown files in scope: everything under docs/ except the Sprint B/C deliverables.

    docs/sprintB/backlog.md stays in scope because the Sprint #B backlog is a Sprint A deliverable.
    """
    out = []
    for md in sorted((root / "docs").rglob("*.md")):
        parts = md.relative_to(root).parts
        if parts[:3] == ("docs", "sprintB", "sprintB.md") or parts[:2] == ("docs", "sprintC"):
            continue
        out.append(md)
    return out


def check_backlogs(root: Path) -> None:
    product = root / "docs" / "backlog.md"
    sprint_b = root / "docs" / "sprintB" / "backlog.md"
    if not product.exists():
        add("ERROR", "backlog", product, 1, "docs/backlog.md not found")
        return
    lines = read_lines(product)
    stories: dict[str, list[str]] = {}
    for i, line in outside_code(lines):
        if re.match(r"^\s*\|\s*US-\d+\s*\|", line):
            cells = split_cells(line)
            if len(cells) >= 6:
                stories.setdefault(cells[0], cells + [str(i)])
    if not stories:
        add("ERROR", "backlog", product, 1, "no user-story table rows found")
    for uid, c in stories.items():
        ln = int(c[-1])
        story, prio, pts, status, crit = c[1], c[2], c[3], c[4], c[5]
        if not re.match(r"^Como\b", story) or "quero" not in story.lower():
            add("ERROR", "story-format", product, ln, f"{uid}: not 'Como ... quero ... para ...'")
        elif " para " not in f" {story.lower()} ":
            add("WARN", "story-format", product, ln, f"{uid}: no 'para' (benefit) clause")
        if prio.strip().upper() not in {"M", "S", "C", "W"}:
            add("ERROR", "priority", product, ln, f"{uid}: priority '{prio}' is not M/S/C/W")
        if not re.fullmatch(r"\d+", pts.strip()):
            add("ERROR", "points", product, ln, f"{uid}: points '{pts}' is not a number")
        n_crit = len(re.findall(r"- \[[ x]\]", crit))
        if n_crit == 0:
            add("ERROR", "acceptance", product, ln, f"{uid}: no acceptance criteria")
        elif n_crit < 2:
            add("WARN", "acceptance", product, ln, f"{uid}: only {n_crit} acceptance criterion")
        if not status.strip():
            add("WARN", "status", product, ln, f"{uid}: empty validation state")

    text = "\n".join(lines)
    desc_ids = set()
    for i, line in outside_code(lines):
        m = re.match(r"^\s*\|\s*(US-\d+)\s*\|", line)
        if m and len(split_cells(line)) == 3:
            desc_ids.add(m.group(1))
    for uid in sorted(set(stories) - desc_ids):
        add("WARN", "backlog", product, 1, f"{uid} has no entry in the story/endpoint description table")

    all_ids = set(stories)
    for md in sprint_a_docs(root):
        for i, line in outside_code(read_lines(md)):
            for uid in US_ID.findall(line):
                if uid not in all_ids:
                    add("ERROR", "undefined-us", md, i, f"{uid} is not defined in docs/backlog.md")

    # release plan vs Sprint B backlog
    plan_b: set[str] = set()
    for line in lines:
        if re.match(r"^\s*\|\s*Sprint B\s*\|", line):
            plan_b = set(US_ID.findall(line))
    if not sprint_b.exists():
        add("ERROR", "sprint-b", sprint_b, 1, "docs/sprintB/backlog.md not found")
        return
    sb = parse_us_table(sprint_b)
    if plan_b and set(sb) != plan_b:
        add(
            "ERROR",
            "sprint-b",
            sprint_b,
            1,
            f"stories differ from release plan: only in plan {sorted(plan_b - set(sb))}, "
            f"only in sprint backlog {sorted(set(sb) - plan_b)}",
        )
    tbc = 0
    for uid, c in sb.items():
        ln = int(c[-1])
        if uid in stories and len(c) > 3:
            product_pts = stories[uid][3].strip()
            if c[2].strip() != product_pts:
                add("ERROR", "points-mismatch", sprint_b, ln, f"{uid}: {c[2]} points vs {product_pts} in docs/backlog.md")
        n = len(re.findall(r"\bTBC\b", " | ".join(c[:-1])))
        tbc += n
        if n:
            add("WARN", "dor", sprint_b, ln, f"{uid}: {n} DoR cell(s) still TBC")
    if tbc:
        add("WARN", "dor", sprint_b, 1, f"{tbc} TBC cells in total: Definition of Ready not demonstrated")


COVERAGE = {
    "vision": r"vision|vis[ãa]o",
    "personas": r"persona",
    "workflow": r"workflow|jornada|journey",
    "domain model": r"domain model|modelo de dados|modelo de dom[ií]nio",
    "architecture": r"arquitet|architecture",
    "assumptions": r"pressupost|assumption|depend[êe]ncias",
    "costs": r"custo|cost",
    "backlog/priorities": r"backlog|moscow|prioridade",
    "NFRs": r"nfr|n[ãa]o funcionais|rnf",
    "next sprint scope": r"sprint b|scope|[âa]mbito",
    "methodology": r"scrum|metodologia|methodology",
    "DoR": r"\bdor\b|definition of ready",
    "DoD": r"\bdod\b|definition of done",
}
STATUS_WORDS = re.compile(r"Por iniciar|Em curso|A fazer|\bTBC\b|\bTODO\b")


def pptx_dump(path: Path) -> None:
    print(f"\n== Slides: {path.name} (full text, one line per slide)")
    all_text: dict[int, str] = {}
    with zipfile.ZipFile(path) as z:
        slides = sorted(
            (n for n in z.namelist() if re.fullmatch(r"ppt/slides/slide\d+\.xml", n)),
            key=lambda n: int(re.search(r"(\d+)", n.split("/")[-1]).group(1)),
        )
        for n in slides:
            num = int(re.search(r"(\d+)", n.split("/")[-1]).group(1))
            xml = z.read(n).decode("utf-8", errors="replace")
            # Merge runs inside one paragraph so words are not split by formatting.
            lines = []
            for p in re.findall(r"<a:p>(.*?)</a:p>", xml, flags=re.S):
                t = "".join(html.unescape(x) for x in re.findall(r"<a:t>([^<]*)</a:t>", p)).strip()
                if t:
                    lines.append(t)
            all_text[num] = " / ".join(lines)
            print(f"  slide {num:>2}: {all_text[num]}")
    print(f"  total slides: {len(all_text)}")
    print("\n  Coverage (slides mentioning each topic):")
    for topic, rx in COVERAGE.items():
        hits = [str(k) for k, v in all_text.items() if re.search(rx, v, re.I)]
        print(f"    {topic:<20} {', '.join(hits) if hits else 'NOT MENTIONED'}")
    flagged = [f"slide {k}: '{m.group(0)}'" for k, v in all_text.items() if (m := STATUS_WORDS.search(v))]
    if flagged:
        print("  Status words suggesting unfinished or stale content: " + "; ".join(flagged))


def bullets_under(lines: list[str], heading_rx: str, checkbox: bool = False) -> int:
    start = next((i for i, l in enumerate(lines) if re.match(r"^#{2,4}\s+" + heading_rx, l, re.I)), None)
    if start is None:
        return -1
    item = r"^- \[[ x]\]" if checkbox else r"^- "
    n = 0
    for l in lines[start + 1 :]:
        if l.startswith("#") or l.strip() == "---":
            break
        if re.match(item, l):
            n += 1
    return n


def facts(root: Path) -> None:
    """Print counts and a heading outline with line numbers so the report cites facts, not guesses."""
    print("\n== Facts (use these for counts and line citations; do not estimate)")
    sa = root / "docs" / "sprintA" / "sprintA.md"
    bl = root / "docs" / "backlog.md"
    rq = root / "docs" / "requisitos.md"
    sb = root / "docs" / "sprintB" / "backlog.md"
    if bl.exists():
        ids = sorted({m.group(1) for _, l in outside_code(read_lines(bl)) if (m := re.match(r"^\s*\|\s*(US-\d+)\s*\|", l))})
        print(f"  user stories in docs/backlog.md: {len(ids)} ({ids[0] if ids else '-'}..{ids[-1] if ids else '-'})")
        has_epic = re.search("epic", bl.read_text(encoding="utf-8-sig"), re.I) is not None
        print(f"  word 'epic' appears in docs/backlog.md: {'yes' if has_epic else 'no'}")
    if rq.exists():
        txt = read_lines(rq)
        rf = {m.group(1) for l in txt if (m := re.match(r"^\|\s*(RF-\d+)\s*\|", l))}
        rnf = {m.group(1) for l in txt if (m := re.match(r"^\|\s*(RNF-\d+)\s*\|", l))}
        print(f"  functional requirements: {len(rf)}; non-functional: {len(rnf)}")
    if sb.exists():
        print(f"  stories in docs/sprintB/backlog.md: {len(parse_us_table(sb))}")
    if sa.exists():
        lines = read_lines(sa)
        adrs = [l for _, l in outside_code(lines) if re.match(r"^###\s+ADR-\d+", l)]
        print(f"  ADRs: {len(adrs)}")
        print(f"  DoR bullet criteria: {bullets_under(lines, 'Definition of Ready')}; DoD bullet criteria: {bullets_under(lines, 'Definition of Done')}")
    pr = root / ".github" / "PULL_REQUEST_TEMPLATE" / "feature.md"
    if pr.exists():
        print(f"  PR template (feature.md) DoD checklist items: {bullets_under(read_lines(pr), 'Definition of Done', checkbox=True)}")
    if sa.exists():
        print(f"\n  Outline of {sa.relative_to(root)} (line: heading):")
        for i, l in outside_code(read_lines(sa)):
            m = HEADING.match(l)
            if m and len(m.group(1)) in (2, 3):
                print(f"    {i}: {m.group(1)} {m.group(2)}")


DELIVERABLES = [
    ("Problem and Opportunity Report", r"problema e oportunidade|problem and opportunity"),
    ("Market and Competitor Analysis", r"an[aá]lise de mercado|competitor"),
    ("User Research", r"investiga[cç][aã]o de utilizadores|user research"),
    ("Product Vision", r"product vision|vis[aã]o do produto"),
    ("Product Backlog", r"product backlog"),
    ("Responsible AI Opportunity Assessment", r"responsible ai"),
    ("Technical Design", r"technical design"),
    ("  system context", r"contexto do sistema|system context"),
    ("  container view", r"containers?"),
    ("  data model", r"modelo de dados|data model"),
    ("  API outline", r"\bapi\b"),
    ("  asynchronous workflow", r"ass[ií]ncrono|asynchronous"),
    ("  external integration", r"integra[cç][aã]o externa|external integration"),
    ("  deployment view", r"deployment"),
    ("Architecture Decision Records", r"architecture decision records|^ADR-\d+"),
    ("Security and Privacy Assessment", r"security and privacy"),
    ("  threat model", r"modelo de amea[cç]as|threat model"),
    ("Walking Skeleton", r"walking skeleton"),
    ("Ethical engagement mechanism", r"participa[cç][aã]o [eé]tica|ethical engagement"),
    ("Investor engagement", r"investidores|investor"),
    ("Degraded mode / fallback", r"fallback|degrad|modo offline|offline"),
]


def deliverables(root: Path) -> None:
    """Presence-only check of the assignment's Sprint 1 deliverables (headings in sprintA.md)."""
    sa = root / "docs" / "sprintA" / "sprintA.md"
    print("\n== Assignment deliverables (heading present in sprintA.md; read the section before marking Done)")
    if not sa.exists():
        print("  docs/sprintA/sprintA.md not found")
        return
    heads = [(i, m.group(2)) for i, l in outside_code(read_lines(sa)) if (m := HEADING.match(l))]
    for name, rx in DELIVERABLES:
        hit = next(((i, h) for i, h in heads if re.search(rx, h, re.I)), None)
        print(f"  {name:<40} {'line %d: %s' % hit if hit else 'NO HEADING FOUND'}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=None)
    ap.add_argument("--pptx", type=Path, default=None)
    ap.add_argument("--no-pptx", action="store_true")
    args = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    root = (args.root or find_root(Path.cwd())).resolve()
    mds = sprint_a_docs(root)
    print("Scope: Sprint A only. Excluded: docs/sprintB/sprintB.md, docs/sprintC/ (Sprint B/C deliverables).")
    for extra in (root / "README.md", root / "DomusCast" / "README.md"):
        if extra.exists():
            mds.append(extra)
    cache: dict[Path, set[str]] = {}
    for md in mds:
        check_markdown(md, root, cache)
    check_backlogs(root)

    order = {"ERROR": 0, "WARN": 1}
    findings.sort(key=lambda f: (order[f[0]], f[1], f[2], f[3]))
    for level, cat, path, line, msg in findings:
        rel = Path(path).resolve().relative_to(root) if Path(path).is_absolute() else path
        print(f"{level:5} [{cat}] {str(rel).replace(chr(92), '/')}:{line}: {msg}")

    errors = sum(1 for f in findings if f[0] == "ERROR")
    warns = len(findings) - errors
    cats: dict[str, int] = {}
    for f in findings:
        cats[f[1]] = cats.get(f[1], 0) + 1
    print(f"\nSummary: {errors} error(s), {warns} warning(s) in {len(mds)} markdown file(s)")
    if cats:
        print("By category: " + ", ".join(f"{k}={v}" for k, v in sorted(cats.items())))

    facts(root)
    deliverables(root)

    if not args.no_pptx:
        pptx_files = [args.pptx] if args.pptx else sorted((root / "docs" / "sprintA" / "presentation").glob("*.pptx"))
        if not pptx_files:
            print("\nNo presentation (.pptx) found in docs/sprintA/presentation/")
        for p in pptx_files:
            try:
                pptx_dump(p.resolve())
            except (zipfile.BadZipFile, OSError) as exc:
                print(f"\nCould not read {p}: {exc}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
