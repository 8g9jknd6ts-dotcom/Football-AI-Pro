from pathlib import Path
import json
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / 'data' / 'raw'
OUT = ROOT / 'data' / 'quality' / 'league_sample_quality.csv'
OUT_MD = ROOT / 'docs' / 'LEAGUE_SAMPLE_QUALITY_20260719.md'
OUT_JSON = ROOT / 'data' / 'quality' / 'league_model_gate.json'

rows = []
for path in sorted(RAW.glob('*.csv')):
    try:
        df = pd.read_csv(path)
    except Exception:
        continue
    required = ['Date','Home','Away','HG','AG','Res','AvgCH','AvgCD','AvgCA','MaxCH','MaxCD','MaxCA']
    if not set(required).issubset(df.columns):
        continue
    n = len(df)
    duplicate_rows = int(df.duplicated(subset=['Date','Home','Away'], keep='first').sum())
    result_ok = int(df[['HG','AG','Res']].notna().all(axis=1).sum())
    avg_ok = int(df[['AvgCH','AvgCD','AvgCA']].notna().all(axis=1).sum())
    max_ok = int(df[['MaxCH','MaxCD','MaxCA']].notna().all(axis=1).sum())
    b365_cols = [c for c in ['B365CH','B365CD','B365CA'] if c in df.columns]
    b365_ok = int(df[b365_cols].notna().all(axis=1).sum()) if len(b365_cols)==3 else 0
    seasons = int(df['Season'].nunique()) if 'Season' in df.columns else 0
    result_rate = result_ok/n if n else 0
    avg_rate = avg_ok/n if n else 0
    max_rate = max_ok/n if n else 0
    duplicate_rate = duplicate_rows/n if n else 0
    if n >= 500 and seasons >= 3 and result_rate >= .99 and avg_rate >= .99 and duplicate_rate <= .005:
        status = 'RESEARCH_AND_1X2_BACKTEST'
    elif n >= 200 and result_rate >= .98:
        status = 'RESEARCH_ONLY'
    else:
        status = 'LOW_TRUST_REVIEW'
    parsed_dates = pd.to_datetime(df['Date'], dayfirst=True, errors='coerce')
    valid_dates = parsed_dates.dropna()
    date_min = valid_dates.min().date().isoformat() if len(valid_dates) else ''
    date_max = valid_dates.max().date().isoformat() if len(valid_dates) else ''
    rows.append({'league_file':path.name,'matches':n,'effective_matches':n-duplicate_rows,'duplicate_rows':duplicate_rows,'duplicate_rate':round(duplicate_rate,4),'seasons':seasons,'date_min':date_min,'date_max':date_max,'result_complete':round(result_rate,4),'avg_1x2_complete':round(avg_rate,4),'max_1x2_complete':round(max_rate,4),'b365_complete':round(b365_ok/n,4) if n else 0,'status':status})

out = pd.DataFrame(rows)
out.to_csv(OUT, index=False, encoding='utf-8-sig')
OUT_JSON.write_text(json.dumps({'generated_at':'2026-07-19','policy':{'1X2':'RESEARCH_AND_1X2_BACKTEST','asian_totals':'SEPARATE_MARKET_HISTORY_REQUIRED','production':'BACKTEST_GATE_REQUIRED'},'leagues':rows}, ensure_ascii=False, indent=2), encoding='utf-8')
lines = ['# 联赛样本质量审计（2026-07-17）','', '分级门禁：`RESEARCH_AND_1X2_BACKTEST` 仅表示可进入1X2独立回测，不代表可直接生产；亚盘/大小球仍需独立盘口历史。重复键按日期+主客队识别。','', '| 文件 | 有效场次 | 重复率 | 赛季数 | 赛果完整 | 平均1X2 | 最高1X2 | 状态 |','|---|---:|---:|---:|---:|---:|---:|---|']
for r in rows:
    lines.append(f"| {r['league_file']} | {r['effective_matches']} | {r['duplicate_rate']:.1%} | {r['seasons']} | {r['result_complete']:.1%} | {r['avg_1x2_complete']:.1%} | {r['max_1x2_complete']:.1%} | {r['status']} |")
lines += ['', '## 当前优化结论', '', '- 平均/最高赔率完整且重复率不超过0.5%的联赛进入1X2独立回测；不把单一B365缺失误判为整库不可用。', '- 亚盘、大小球、凯利和冷门信号必须另有开盘/即时、多公司、时间戳数据，否则保持候选或影子模式。', '- 进行中赛季不进入训练集，只作为时间切分后的外样本。']
OUT_MD.write_text('\n'.join(lines), encoding='utf-8')
print(OUT)
print(OUT_MD)
print(OUT_JSON)
