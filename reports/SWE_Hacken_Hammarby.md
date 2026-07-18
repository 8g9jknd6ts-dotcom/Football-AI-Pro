# Football AI Pro 单场分析报告

生成时间：2026-07-16 23:24:10 +08:00  
数据截止：2026-07-16  
系统版本：Football AI 1.0.0-alpha.36  
模型：FootballAI-Poisson-Baseline 1.0.0 (validated)

## 首页摘要

| 项目 | 结果 |
|---|---|
| 比赛 | Hacken vs Hammarby (SWE) |
| 推荐 | Research lean H; no formal bet |
| 推荐赔率 | fair reference 2.44; not a production recommendation |
| AI 综合评分 | 41.1/100 (validated display metric) |
| 信心指数 | 12/100 (validated ranking metric) |
| 冷门指数 | 58.9/100 (candidate; failed calibration gate) |

> This report is research output, not a production betting recommendation.

## 核心数据

- 历史样本：主队 10 场，客队 10 场
- 最近状态窗口：10 场
- 预期进球：1.897 / 1.75
- 主客场与交锋上下文：Home team home-only: 10 matches, W-D-L 4-4-2, GF 1.7, GA 1.5. Away team away-only: 10 matches, W-D-L 3-3-4, GF 1.3, GA 1.5. Head-to-head from home-team perspective: 5 matches, W-D-L 2-1-2, GF 1.2, GA 2. Context is descriptive only and does not alter the backtested Poisson baseline.
- 数据质量：historical results available; model status=validated

## 赔率分析

European 1X2 input: 2.4 / 3.5 / 2.8; de-vig probabilities: H=39.33% D=26.97% A=33.71%; market favorite=H.

## 返还率分析

European 1X2 estimated return rate: 94.38%.

## 凯利分析

Model-implied Kelly fractions (candidate model failed ROI gate; not stake advice): H=-0.0104, D=-0.0667, A=-0.009

## 模型分析

- 胜平负概率：主胜 41.06% / 平局 23.8% / 客胜 35.13%
- 最可能比分：1-1
- 比分候选：1-1 9.7%; 2-1 8.2%; 1-2 7.6%
- 2.5球：小球 29.45% / 大球 70.55%
- 最可能总进球：3
- Home handicap -1: H=22.9%, D=18.2%, A=58.9%.

## 推荐结果

| 默认输出 | 结果 |
|---|---|
| 胜平负 | H |
| 让球胜平负 | A |
| 比分预测 | 1-1 |
| 总进球预测 | 3 球；Over 2.5 |
| 冷门指数 | 58.9/100 (candidate; failed calibration gate) |
| AI综合评分 | 41.1/100 (validated display metric) |
| 信心指数 | 12/100 (validated ranking metric) |
| 推荐赔率 | fair reference 2.44; not a production recommendation |
| 风险提示 | No production model is available; output is research-only. Upset index failed its cross-league calibration gate and remains candidate. Handicap result is model-derived only; no Asian/China Sports Lottery handicap price was supplied or backtested. AI score and confidence passed calibration/ranking gates on validated leagues, but neither proves betting profitability. |

## 风险提示

- No production model is available; output is research-only.
- Upset index failed its cross-league calibration gate and remains candidate.
- Handicap result is model-derived only; no Asian/China Sports Lottery handicap price was supplied or backtested.
- AI score and confidence passed calibration/ranking gates on validated leagues, but neither proves betting profitability.

## 可追溯信息

- 数据文件 SHA-256：`a0c3c634b01f9778c3afd3c5e58c98f0b330c3357d10b0747677ea202457fbe5`
- 参数：窗口=10，主场系数=1.15，rho=-0.12
- 适用规则：Rule001、Rule003、Rule004、Rule005、Rule007、Rule008、Rule009、Rule010

