# Football AI Pro 单场分析报告

生成时间：{{GENERATED_AT}}  
数据截止：{{CUTOFF}}  
系统版本：{{VERSION}}  
模型：{{MODEL_STATUS}}

## 首页摘要

| 项目 | 结果 |
|---|---|
| 比赛 | {{MATCH}} |
| 推荐 | {{RECOMMENDATION}} |
| 推荐赔率 | {{RECOMMENDED_ODDS}} |
| AI 综合评分 | {{AI_SCORE}} |
| 信心指数 | {{CONFIDENCE}} |
| 冷门指数 | {{UPSET_INDEX}} |

> {{RESEARCH_NOTICE}}

## 核心数据

- 历史样本：主队 {{HOME_SAMPLE}} 场，客队 {{AWAY_SAMPLE}} 场
- 最近状态窗口：{{WINDOW}} 场
- 预期进球：{{LAMBDA_HOME}} / {{LAMBDA_AWAY}}
- 主客场与交锋上下文：{{CONTEXT_ANALYSIS}}
- 数据质量：{{DATA_QUALITY}}

## 赔率分析

{{ODDS_ANALYSIS}}

## 返还率分析

{{RETURN_ANALYSIS}}

## 凯利分析

{{KELLY_ANALYSIS}}

## 模型分析

- 胜平负概率：主胜 {{PH}} / 平局 {{PD}} / 客胜 {{PA}}
- 最可能比分：{{SCORE}}
- 比分候选：{{TOP_SCORES}}
- 2.5球：小球 {{UNDER25}} / 大球 {{OVER25}}
- 最可能总进球：{{TOTAL_MODE}}
- {{HANDICAP_ANALYSIS}}

## 推荐结果

| 默认输出 | 结果 |
|---|---|
| 胜平负 | {{WDL}} |
| 让球胜平负 | {{HANDICAP_WDL}} |
| 比分预测 | {{SCORE}} |
| 总进球预测 | {{TOTAL_MODE}} 球；{{TOTAL_SIDE}} |
| 冷门指数 | {{UPSET_INDEX}} |
| AI综合评分 | {{AI_SCORE}} |
| 信心指数 | {{CONFIDENCE}} |
| 推荐赔率 | {{RECOMMENDED_ODDS}} |
| 风险提示 | {{RISK_SUMMARY}} |

## 风险提示

{{RISKS}}

## 可追溯信息

- 数据文件 SHA-256：`{{DATA_HASH}}`
- 参数：窗口={{WINDOW}}，主场系数={{HOME_ADVANTAGE}}，rho={{RHO}}
- 适用规则：Rule001、Rule003、Rule004、Rule005、Rule007、Rule008、Rule009、Rule010
