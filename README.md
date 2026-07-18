# Football AI Pro

## Latest postmortem sync — 2026-07-19

`scripts/build_8match_postmortem.py` reproducibly generates the 2026-07-18 eight-match postmortem and writes prediction context, verified outcomes, settlement details and user-preference updates to the unified tracking database. Post-match outcomes are audit-only and are never fed back into pre-match features.

Football AI Pro 是面向中国竞彩、兼容欧洲赔率体系的数据驱动足球分析系统。

当前版本：**Football AI 1.0.0-alpha.1（数据基线）**

## 数据红线

- 不使用未验证或编造的数据。
- 每场历史比赛必须拥有确定性 `MatchID`。
- 原始数据只读保存，所有字段修正在标准化层完成。
- 模型只有在可复现回测通过准入门禁后才能标记为 `production`。
- 缺失让球盘、大小球或实时 xG 时，对应结论必须标记为不可用，不以估算值伪装实盘数据。

## 目录

- `data/raw/`：来源文件原样副本
- `data/standardized/`：统一比赛表、赔率表和导入清单
- `data/source_archive/2026-07-15/`：用户提供的大型历史工程归档（待逐项审计）
- `docs/`：字段、规则、模型与报告规范
- `scripts/import.ps1`：无第三方依赖的数据导入与校验程序

## 导入

在 PowerShell 中执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\import.ps1 -SourceDirectory "C:\Users\apple\Downloads"
```

导入程序会拒绝非法赛果、非法比分、关键字段缺失和 `MatchID` 冲突。

## 单场研究报告

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\analyze.ps1 `
  -LeagueCode SWE -HomeTeam Hacken -AwayTeam Hammarby `
  -HomeOdds 2.40 -DrawOdds 3.50 -AwayOdds 2.80 -Handicap -1
```

报告写入 `reports/`。当前没有 production 模型，因此程序始终返回 `FormalRecommendation=false`；所有方向仅供模型研究，不能作为正式投注推荐。

`data/standardized/matches_all.csv` 是当前统一比赛视图，共83,659场；`markets_extended.csv` 保存欧洲开/收盘1X2、大小球和亚洲盘口。归档清洗证据见 `docs/ARCHIVE_MARKET_AUDIT.md`。

中国竞彩接口见 `docs/JCZQ_DATA_STANDARD.md`。正式库 `data/standardized/jczq_odds.csv` 当前只有表头、0条数据；不得把测试夹具作为历史赔率。项目完成度与剩余缺口见 `docs/COMPLETION_AUDIT.md`。
