# 低可信历史样本审计

审计日期：2026-07-15  
审计程序：`scripts/audit_low_trust_history.ps1`

## 结论

| 数据集 | 原始行数 | 结构可复核 | 隔离 | 正式入库 |
|---|---:|---:|---:|---:|
| match_history_core | 148,375 | 24,370 | 124,005 | 0 |
| international_matches | 1,673 | 0 | 1,673 | 0 |

“结构可复核”不等于可信，也不等于已经进入统一比赛库。只有补齐逐行来源、核对日期/球队/联赛，并通过与现有 MatchID 的重复和冲突检查后，才可转入正式层。

## 主要问题

### match_history_core

- 123,961 行无法从 `match_id` 恢复有效比赛日期。
- 45 行主客队相同。
- 2 行主胜赔率无效。
- `match_history_core_part01.csv` 至 `part15.csv` 合计也是 148,375 行，是主文件的分发分片，不是额外比赛；禁止重复计数。

### international_matches

- 1,673 行全部缺少可接受的逐行权威来源，`search_results` 或 `manual_import` 不能证明具体字段。
- 387 行存在异常 xG。
- 387 行控球率字段异常。
- 226 行存在单队超过 60 次射门等异常。
- 例如英格兰—伊朗记录出现 123/78 次射门和 7.31/2.59 xG，与可信比赛统计不符，因此不能用于模型训练或回测。

## 产物

- `data/quality/match_history_core_audit.csv`：148,375 条逐行判定。
- `data/quality/international_matches_audit.csv`：1,673 条逐行判定。
- `data/quality/low_trust_history_summary.csv`：汇总统计。

原始文件保持不变。审计结果只决定隔离和复核状态，不静默修复来源数据。
