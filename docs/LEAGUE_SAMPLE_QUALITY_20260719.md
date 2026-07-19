# 联赛样本质量审计（2026-07-17）

分级门禁：`RESEARCH_AND_1X2_BACKTEST` 仅表示可进入1X2独立回测，不代表可直接生产；亚盘/大小球仍需独立盘口历史。重复键按日期+主客队识别。

| 文件 | 有效场次 | 重复率 | 赛季数 | 赛果完整 | 平均1X2 | 最高1X2 | 状态 |
|---|---:|---:|---:|---:|---:|---:|---|
| ARG.csv | 6235 | 0.0% | 16 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| AUT.csv | 2638 | 0.0% | 14 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| BRA.csv | 5497 | 0.0% | 15 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| CHN.csv | 2928 | 0.0% | 13 | 100.0% | 99.8% | 99.8% | RESEARCH_AND_1X2_BACKTEST |
| FIN.csv | 2608 | 0.0% | 15 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| IRL.csv | 2664 | 0.0% | 15 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| JPN.csv | 4523 | 0.0% | 14 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| MEX.csv | 4655 | 0.0% | 14 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| NOR.csv | 3471 | 0.0% | 15 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| POL.csv | 4082 | 0.0% | 14 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| ROU.csv | 4182 | 0.0% | 14 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| RUS.csv | 3400 | 0.0% | 14 | 100.0% | 97.6% | 97.6% | RESEARCH_ONLY |
| SWE.csv | 3465 | 0.0% | 15 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| SWZ.csv | 2675 | 0.0% | 14 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |
| USA.csv | 6034 | 0.0% | 15 | 100.0% | 100.0% | 100.0% | RESEARCH_AND_1X2_BACKTEST |

## 当前优化结论

- 平均/最高赔率完整且重复率不超过0.5%的联赛进入1X2独立回测；不把单一B365缺失误判为整库不可用。
- 亚盘、大小球、凯利和冷门信号必须另有开盘/即时、多公司、时间戳数据，否则保持候选或影子模式。
- 进行中赛季不进入训练集，只作为时间切分后的外样本。