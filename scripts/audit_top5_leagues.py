"""Audit whether the five priority leagues have identifiable local samples."""
from pathlib import Path
import csv
import json

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
STD = ROOT / "data" / "standardized"
ARCHIVE = STD / "archive_market_matches.csv"
OUT = ROOT / "data" / "quality"
DOC = ROOT / "docs" / "TOP5_LEAGUE_DATA_AUDIT_20260717.md"

LEAGUES = {
    "EPL": ["EPL", "ENG", "England", "英超"],
    "LaLiga": ["LaLiga", "ESP", "Spain", "西甲"],
    "SerieA": ["SerieA", "ITA", "Italy", "意甲"],
    "Bundesliga": ["Bundesliga", "GER", "Germany", "德甲"],
    "Ligue1": ["Ligue1", "FRA", "France", "法甲"],
}
ARCHIVE_NAMES = {"Premier League": "EPL", "La Liga": "LaLiga", "Serie A": "SerieA", "Bundesliga": "Bundesliga", "Ligue 1": "Ligue1"}

def files_for(tokens, folder):
    hits = []
    for p in folder.glob("*"):
        if p.is_file() and any(t.lower() in p.name.lower() for t in tokens):
            hits.append(p.name)
    return sorted(hits)

def csv_headers(paths):
    headers = set()
    for name in paths:
        p = RAW / name
        try:
            with p.open("r", encoding="utf-8-sig", newline="") as f:
                headers.update(next(csv.reader(f), []))
        except (OSError, UnicodeError, StopIteration):
            pass
    return sorted(headers)

rows = []
archive_counts = {}
archive_seasons = {}
if ARCHIVE.exists():
    with ARCHIVE.open("r", encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            league = row.get("League", "")
            key = ARCHIVE_NAMES.get(league)
            if key:
                archive_counts[key] = archive_counts.get(key, 0) + 1
                archive_seasons.setdefault(key, set()).add(row.get("Season", ""))
for league, tokens in LEAGUES.items():
    raw = files_for(tokens, RAW)
    std = files_for(tokens, STD)
    headers = csv_headers(raw)
    required = {"Date", "Home", "Away", "HG", "AG", "Res"}
    result_ok = required.issubset(headers)
    rows.append({
        "league": league,
        "raw_files": raw,
        "standardized_files": std,
        "archive_match_count": archive_counts.get(league, 0),
        "archive_seasons": sorted(archive_seasons.get(league, set())),
        "result_fields_present": result_ok,
        "headers": headers,
        "status": "ARCHIVE_SAMPLE_PRESENT" if archive_counts.get(league, 0) else ("READY_FOR_QUALITY_AUDIT" if raw and result_ok else "MISSING_OR_UNIDENTIFIED"),
    })

OUT.mkdir(parents=True, exist_ok=True)
(OUT / "top5_league_data_audit.json").write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")

lines = ["# 五大联赛数据核验结果", "", "生成时间：2026-07-17", "", "| 联赛 | 原始文件 | 标准化文件 | 归档比赛数 | 归档赛季 | 结果字段 | 状态 |", "|---|---|---|---:|---|---|---|"]
for r in rows:
    lines.append(f"| {r['league']} | {', '.join(r['raw_files']) or '无'} | {', '.join(r['standardized_files']) or '无'} | {r['archive_match_count']} | {', '.join(r['archive_seasons']) or '无'} | {'是' if r['result_fields_present'] else '否'} | {r['status']} |")
lines += ["", "说明：READY_FOR_QUALITY_AUDIT 只表示已识别到候选文件，不代表已通过样本质量、赔率来源或回测门禁。"]
DOC.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(DOC)
