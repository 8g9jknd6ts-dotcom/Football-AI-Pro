# 冷门预测系统 Dixon-Coles 增强方案 — V6.1

## 一、Dixon-Coles 模型定位

Dixon-Coles (1997) 是足球预测领域最经典的统计模型，基于泊松分布建模两队进球数，并加入低比分修正项。在现有 V5.0 + V6.0 ML 体系中，DC 作为第三层加入：

```
V5.0 CRI (规则驱动) ──┐
                      ├──→ 融合层 → 最终冷门概率 + 比分预测
V6.0 ML (LGB+XGB) ────┘
                      ↑
Dixon-Coles (统计模型) ─→ 提供：预期进球、比分概率、胜平负概率、实力参数
                      ↓
              同时作为 ML 的 Layer 4+ 特征输入
```

| 模块 | 核心能力 | 补充点 |
|------|----------|--------|
| CRI V5.0 | 赔率变化 → 冷门信号 | 不预测比分，只判断低赔方是否翻车 |
| ML V6.0 | 非线性模式识别 | 需要大量特征，冷启动困难 |
| Dixon-Coles | 历史战绩 → 进球期望 | 提供基本面基准，与赔率形成对比 |

---

## 二、Dixon-Coles 核心模型

### 2.1 基础泊松模型

对于主队 H vs 客队 A：

```
λ_H = α_H * β_A * γ   # 主队预期进球 = 主队攻击 × 客队防守 × 主场优势
λ_A = α_A * β_H       # 客队预期进球 = 客队攻击 × 主队防守

P(H goals = i, A goals = j) = Poisson(i, λ_H) * Poisson(j, λ_A)
```

参数说明：
- α_H, α_A：主队/客队的攻击强度参数
- β_H, β_A：主队/客队的防守弱点参数（越大防守越弱）
- γ：主场优势系数（通常 ~1.3-1.4）

### 2.2 低比分修正（Dixon-Coles 关键创新）

实际足球中 0-0 和 1-0 比纯泊松预测更频繁。DC 引入依赖参数 ρ（rho）修正：

```python
tau(i, j, λ_H, λ_A, ρ) = 1                          if i ≠ 0,1 and j ≠ 0,1
                         = 1 - ρ * λ_H * λ_A      if i = 0, j = 0
                         = 1 + ρ * λ_H            if i = 0, j = 1
                         = 1 + ρ * λ_A            if i = 1, j = 0
                         = 1 - ρ                  if i = 1, j = 1

P(i, j) = tau(i, j) * Poisson(i, λ_H) * Poisson(j, λ_A)
```

ρ 通常为负值（-0.05 到 -0.15），表示低比分之间的负相关。

### 2.3 参数估计（MLE）

```python
# 约束条件：
# Σ log(α_t) = 0  （所有球队攻击参数几何平均为1）
# Σ log(β_t) = 0  （所有球队防守参数几何平均为1）
# ρ ∈ [-0.5, 0.5]

# 使用 scipy.optimize.minimize(L-BFGS-B) 最大化对数似然
```

---

## 三、与现有系统融合架构

### 3.1 三层融合架构

```
Layer 1: 基本面层 (Dixon-Coles)
├── 历史战绩 → 攻击/防守参数 → 预期进球 → 比分概率矩阵
└── 输出: P_win, P_draw, P_loss, E_goals_home, E_goals_away

Layer 2: 市场层 (CRI V5.0)
├── 赔率变化 → 冷门信号 → CRI_score
└── 输出: CRI_score, level, direction_probs

Layer 3: 模式层 (ML V6.0)
├── 40+ 特征 → LightGBM + XGBoost → 冷门概率
└── 输出: P_lgb, P_xgb, feature_importance

融合层: 加权集成
├── DC基本面概率 vs CRI赔率信号 vs ML模式概率
└── 输出: 最终冷门概率, 比分预测, 置信度, 分层解释
```

### 3.2 Dixon-Coles 作为 ML 特征（12个）

| 特征名 | 说明 |
|--------|------|
| `dc_home_xg` | 主队预期进球 |
| `dc_away_xg` | 客队预期进球 |
| `dc_home_win_prob` | 主队胜概率 |
| `dc_draw_prob` | 平局概率 |
| `dc_away_win_prob` | 客队胜概率 |
| `dc_total_goals_exp` | 预期总进球 |
| `dc_home_attack` | 主队攻击参数 |
| `dc_away_attack` | 客队攻击参数 |
| `dc_home_defense` | 主队防守参数 |
| `dc_away_defense` | 客队防守参数 |
| `dc_prob_spread` | DC预测概率 - 赔率隐含概率 |
| `dc_upset_signal` | 当 DC 认为低赔方胜率 < 赔率隐含概率时标记为1 |

**关键洞察**：当 DC 基本面预测与赔率隐含概率存在显著分歧时，这本身就是强烈的冷门信号。ML 可以学习这种分歧模式。

### 3.3 比分预测模块

Dixon-Coles 天然提供完整的比分概率矩阵：

```python
# 比分概率矩阵 (0:0 到 5:5)
score_matrix = dc_model.predict_score_prob(home, away, max_goals=5)

# 最可能比分
top_scores = np.argsort(score_matrix.flatten())[-5:][::-1]
# 输出: [(2,1)=12.3%, (1,0)=10.1%, (1,1)=9.8%, (2,0)=8.5%, (0,1)=7.2%]
```

---

## 四、实现方案

### 4.1 模块结构

```
v6.1/
├── dixon_coles/
│   ├── model.py          # 核心 DC 模型实现
│   ├── fitter.py         # MLE 参数估计
│   ├── predict.py        # 比分/胜平负预测
│   └── features.py       # 为 ML 生成 DC 特征
├── v6_feature_engineering.py   # 已有：32维特征
├── v6_baseline_train.py        # 已有：LGB+XGB训练
├── v6_1_fusion.py            # 新增：三层融合引擎
└── v6_1_score_predictor.py    # 新增：比分预测模块
```

### 4.2 融合策略

```python
# 三层信号融合

def fusion_prediction(home_team, away_team, match_odds, match_features):
    # Layer 1: Dixon-Coles 基本面
    dc_result = dc_model.predict_match(home_team, away_team)
    dc_home_prob = dc_result['home_win']
    
    # Layer 2: CRI 赔率信号
    cri_result = cri_v5.calculate(match_odds)
    cri_score = cri_result['cri_score']
    
    # Layer 3: ML 模式识别
    ml_features = feature_engineer.extract(match_odds, match_features, dc_result)
    ml_prob = ml_model.predict_proba(ml_features)[0][1]
    
    # 融合权重
    weights = {'dc': 0.25, 'cri': 0.35, 'ml': 0.40}
    
    # 如果 DC 与赔率分歧大，降低 DC 权重，提高 ML 权重
    dc_odds_spread = abs(dc_home_prob - odds_implied_prob)
    if dc_odds_spread > 0.15:
        weights['dc'] = 0.15
        weights['ml'] = 0.50
    
    # 标准化
    cri_prob = sigmoid((cri_score - 10) / 3)
    dc_upset_prob = 1 - max(dc_home_prob, dc_away_prob)
    
    final_upset_prob = (
        weights['dc'] * dc_upset_prob +
        weights['cri'] * cri_prob +
        weights['ml'] * ml_prob
    )
    
    return {
        'final_upset_prob': final_upset_prob,
        'top_scores': dc_result['top_scores'],
        'dc_odds_spread': dc_odds_spread,
        'weights_used': weights
    }
```

---

## 五、数据需求

| 字段 | 说明 | 最小样本量 |
|------|------|-----------|
| 比赛日期 | 时间衰减 | 500+ 场 |
| 主队/客队 | 标准化队名 | 20+ 球队 |
| 主队/客队进球 | 实际比分 | 500+ 场 |
| 赛事类型 | 联赛优先 | 联赛数据 |

**时间衰减**：`decay=0.0065`（约3个月半衰期），近期比赛权重更高。

---

## 六、预期收益

| 模块 | 能力 | 增益 |
|------|------|------|
| Dixon-Coles | 比分预测 | 新增最可能比分输出 |
| DC 基本面概率 | 与赔率对比 | 发现赔率偏离基本面的机会 |
| DC 特征输入 ML | 12个高质量特征 | 预期 ML AUC 从 0.70 提升到 0.74-0.76 |
| 三层融合 | 集成学习 | 比单层更稳健，降低黑天鹅风险 |

---

## 七、实现阶段

### Phase 1: Dixon-Coles 核心模块（本周）
- [ ] 实现 `dixon_coles/model.py` 核心模型
- [ ] 实现 `dixon_coles/fitter.py` MLE 参数估计
- [ ] 使用现有历史数据训练第一个 DC 模型
- [ ] 验证：预期进球、比分概率是否合理

### Phase 2: DC 特征集成到 ML（下周）
- [ ] 在特征工程中增加 12 个 DC 特征
- [ ] 重新训练 LightGBM + XGBoost
- [ ] 验证：DC 特征是否进入 Top 10

### Phase 3: 三层融合引擎（第3周）
- [ ] 实现融合层 + 动态权重调整
- [ ] 实现比分预测输出模块
- [ ] 端到端测试

### Phase 4: 验证与优化（第4周起）
- [ ] 回测：三层融合 vs 单层对比
- [ ] 校准：DC 概率校准、ML 概率校准
- [ ] 监控各层预测准确率

---

**版本**: V6.1 设计稿  
**基于**: V5.0 + V6.0 ML 增强 + Dixon-Coles  
**日期**: 2026-06-19
