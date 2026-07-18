"""Audit extended market coverage for the five priority leagues."""
from pathlib import Path
import csv, collections, json

ROOT = Path(__file__).resolve().parents[1]
P = ROOT / "data" / "standardized" / "markets_extended.csv"
OUT = ROOT / "data" / "quality" / "top5_market_coverage.json"
DOC = ROOT / "docs" / "TOP5_MARKET_COVERAGE_20260717.md"
TOKENS = {"EPL":"epl_", "LaLiga":"laliga_", "SerieA":"seriea_", "Bundesliga":"bundesliga_", "Ligue1":"ligue1_"}
rows=[]
data=list(csv.DictReader(P.open(encoding="utf-8-sig", newline="")))
for league, token in TOKENS.items():
    x=[r for r in data if r.get("SourceFile", "").lower().startswith(token)]
    files=sorted(set(r.get("SourceFile", "") for r in x))
    byfile=collections.defaultdict(lambda: collections.Counter())
    providers=collections.Counter()
    for r in x:
        byfile[r["SourceFile"]][r["Market"]]+=1
        providers[r.get("Provider", "")]+=1
    rows.append({"league":league,"files":files,"rows":len(x),"providers":dict(providers),"markets":{f:dict(c) for f,c in byfile.items()},"status":"RESEARCH_READY_MARKET_DATA" if x else "MISSING"})
OUT.write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding="utf-8")
lines=["# 五大联赛扩展市场覆盖审计","","生成时间：2026-07-17","","| 联赛 | 赛季文件数 | 扩展市场记录 | Provider | 状态 |","|---|---:|---:|---|---|"]
for r in rows:
    lines.append(f"| {r['league']} | {len(r['files'])} | {r['rows']} | {', '.join(r['providers']) or '无'} | {r['status']} |")
lines += ["","说明：本表只确认归档扩展市场存在；Provider 为 MarketAverage 时，不等于已具备可审计的逐公司历史走势。正式模型仍需逐赛季缺失率、时间顺序和结果回测。"]
DOC.write_text("\n".join(lines)+"\n",encoding="utf-8")
print(DOC)
