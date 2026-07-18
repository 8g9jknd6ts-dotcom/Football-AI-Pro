# 冷门预测系统 ML 增强方案 V6.0

## 项目背景

在现有「足球冷门预测系统 V5.0」纯规则驱动（CRI 指数）基础上，引入 **LightGBM + XGBoost 双模型 + 高质量特征工程**，构建规则与机器学习融合的混合预测系统。ML 负责捕捉非线性模式和高维特征交互，CRI 保留可解释性核心信号，两者加权融合输出最终冷门概率。

---

## 一、模型定位与融合策略

### 1.1 不替代，只增强

| 模块 | 职责 | 输出 |
|------|------|------|
| CRI V5.0 | 可解释规则信号 | CRI_score（0-20+）、分级（极高/高/中高/中/低/极低） |
| LightGBM | 非线性模式识别、特征交互 | 冷门概率 P_lgb（0-1） |
| XGBoost | 互补建模、降低过拟合 | 冷门概率 P_xgb（0-1） |
| 融合层 | 加权集成 | 最终冷门概率 P_final、置信度标签、特征重要性 |

### 1.2 融合公式

```python
# Step 1: CRI 归一化为概率
CRI_prob = sigmoid((CRI_score - 10) / 3)  # S型映射，CRI=10时约0.5

# Step 2: ML 双模型平均
ML_prob = (P_lgb + P_xgb) / 2

# Step 3: 加权融合（CRI 权重更高，保持可解释性）
P_final = α * CRI_prob + (1 - α) * ML_prob
# α = 0.6（可动态调整，CRI信号强时α提高，ML信号强时α降低）

# Step 4: 分级输出（复用V5.0阈值，增加ML置信度）
if P_final >= 0.70: 等级 = "极高风险"
elif P_final >= 0.55: 等级 = "高风险"
elif P_final >= 0.45: 等级 = "中高风险"
elif P_final >= 0.35: 等级 = "中等"
elif P_final >= 0.20: 等级 = "低风险"
else: 等级 = "极低风险"

# 附加输出
置信度 = "高" if abs(P_lgb - P_xgb) < 0.1 and P_final > 0.5 else "中" if P_final > 0.3 else "低"
Top5_特征 = SHAP_values.top5()
```

---

## 二、特征工程（5 层 40+ 特征）

### Layer 1: 原始赔率特征（直接可用，10个）

| 特征名 | 说明 | 来源 |
|--------|------|------|
| `fav_pre` | 当前低赔方平均赔率 | 球探网/体彩网 |
| `draw_pre` | 当前平局平均赔率 | 球探网/体彩网 |
| `upset_pre` | 当前高赔方平均赔率 | 球探网/体彩网 |
| `fav_init` | 初始低赔方赔率 | 球探网/体彩网 |
| `draw_init` | 初始平局赔率 | 球探网/体彩网 |
| `upset_init` | 初始高赔方赔率 | 球探网/体彩网 |
| `fav_wl` | 威廉希尔低赔方赔率 | 球探网 |
| `fav_lb` | 立博低赔方赔率 | 球探网 |
| `fav_b365` | Bet365 低赔方赔率 | 球探网 |
| `payout_rate` | 返还率（平均） | 计算：1/(1/a+1/b+1/c) |

### Layer 2: 赔率变化特征（V5.0 核心复用 + 扩展，12个）

| 特征名 | 说明 | 计算方式 |
|--------|------|----------|
| `ratio` | 抬/降比 | `up_against / down_for` |
| `ratio_score` | 对数化 ratio 得分 | V5.0 公式 |
| `delta_rate` | 赔率变动率 | `(fav_pre - fav_init) / fav_init * 100` |
| `up_against` | 抬高低赔方家数 | 原始计数 |
| `down_for` | 降低低赔方家数 | 原始计数 |
| `draw_down` | 降低平局赔率家数 | 原始计数 |
| `upset_down` | 降低高赔方赔率家数 | 原始计数 |
| `total_books` | 总统计机构数 | 原始计数 |
| `delta_draw` | 平局赔率变化 | `draw_init - draw_pre` |
| `delta_upset` | 高赔方赔率变化 | `upset_init - upset_pre` |
| `fav_change_speed` | 低赔方赔率变化速度 | 需要时序数据 |
| `consistency` | 同向变化一致性 | `max(up_against, down_for) / total_books` |

### Layer 3: 市场结构特征（新增，10个）

| 特征名 | 说明 | 计算方式 |
|--------|------|----------|
| `odds_std` | 赔率分布标准差 | `std([各家fav赔率])` |
| `odds_cv` | 变异系数 | `std / mean` |
| `top3_avg` | 三大公司平均 | `(fav_wl + fav_lb + fav_b365) / 3` |
| `top3_diff` | 三大公司 vs 市场平均 | `top3_avg - fav_pre` |
| `kelly_home` | 凯利指数（主） | `fav_pre / (1/payout_rate)` |
| `kelly_draw` | 凯利指数（平） | `draw_pre / (1/payout_rate)` |
| `kelly_away` | 凯利指数（客） | `upset_pre / (1/payout_rate)` |
| `profit_index` | 盈亏指数方向 | `fav_pre / upset_pre` 的偏离度 |
| `market_entropy` | 市场不确定性熵 | `entropy(各家fav赔率分布)` |
| `asian_spread` | 亚盘让球盘口 | 球探网/体彩网 |

### Layer 4: 赛事背景特征（新增，部分需外部数据，10个）

| 特征名 | 说明 | 来源 |
|--------|------|------|
| `league_coeff` | 联赛系数 | 复用 V5.0 映射表 |
| `match_type` | 赛事类型编码 | 联赛=0, 杯赛=1, 洲际=2 |
| `fifa_rank_diff` | FIFA排名差 | 公开数据 |
| `home_form_5` | 主队近5场胜率 | 公开数据 |
| `away_form_5` | 客队近5场胜率 | 公开数据 |
| `home_goal_diff_5` | 主队近5场净胜球 | 公开数据 |
| `h2h_home_wins` | 近5次交手主队胜场 | 公开数据 |
| `fixture_density` | 赛程密度（距上赛天数） | 公开数据 |
| `stakes_index` | 战意指数（积分需求） | 公开数据计算 |
| `key_injury` | 核心伤停评分（0-10） | 公开数据 |

### Layer 5: 时序与统计特征（新增，8个）

| 特征名 | 说明 | 计算方式 |
|--------|------|----------|
| `cri_ma_5` | 过去5场平均 CRI | 滑动窗口 |
| `cri_std_5` | 过去5场 CRI 标准差 | 滑动窗口 |
| `upset_rate_30` | 该联赛近30天冷门率 | 滑动窗口 |
| `team_upset_freq` | 该队近10场被爆冷频率 | 滑动窗口 |
| `fav_odds_trend` | 低赔方赔率变化趋势 | 线性回归斜率 |
| `draw_odds_trend` | 平局赔率变化趋势 | 线性回归斜率 |
| `upset_odds_trend` | 高赔方赔率变化趋势 | 线性回归斜率 |
| `time_to_kickoff` | 距开赛时间（小时） | 计算 |

---

## 三、模型架构

### 3.1 双模型并行

```
[Layer 1-5 特征工程] 
         ↓
[特征选择：相关性过滤 + 递归特征消除]
         ↓
    ┌────────────┐
    │ LightGBM   │ → P_lgb (0-1)
    │ 调参：optuna │
    └────────────┘
         ↘
          ┌──────────┐
          │ 平均融合   │ → ML_prob
          └──────────┘
         ↗
    ┌────────────┐
    │ XGBoost    │ → P_xgb (0-1)
    │ 调参：optuna │
    └────────────┘
         ↓
[Stacking 层：与 CRI 加权融合]
         ↓
    P_final = 0.6 * CRI_prob + 0.4 * ML_prob
         ↓
[输出：冷门概率 + 分级 + 置信度 + SHAP Top5]
```

### 3.2 LightGBM 核心参数（optuna 搜索空间）

```python
param_lgb = {
    'objective': 'binary',
    'metric': 'auc',
    'boosting_type': 'gbdt',
    'num_leaves': trial.suggest_int('num_leaves', 20, 150),
    'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
    'feature_fraction': trial.suggest_float('feature_fraction', 0.5, 1.0),
    'bagging_fraction': trial.suggest_float('bagging_fraction', 0.5, 1.0),
    'bagging_freq': trial.suggest_int('bagging_freq', 1, 10),
    'min_child_samples': trial.suggest_int('min_child_samples', 5, 100),
    'reg_alpha': trial.suggest_float('reg_alpha', 1e-8, 10.0, log=True),
    'reg_lambda': trial.suggest_float('reg_lambda', 1e-8, 10.0, log=True),
    'n_estimators': 1000,
    'early_stopping_rounds': 50,
    'class_weight': 'balanced'  # 处理不平衡
}
```

### 3.3 XGBoost 核心参数（optuna 搜索空间）

```python
param_xgb = {
    'objective': 'binary:logistic',
    'eval_metric': 'auc',
    'max_depth': trial.suggest_int('max_depth', 3, 12),
    'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
    'subsample': trial.suggest_float('subsample', 0.5, 1.0),
    'colsample_bytree': trial.suggest_float('colsample_bytree', 0.5, 1.0),
    'min_child_weight': trial.suggest_int('min_child_weight', 1, 20),
    'gamma': trial.suggest_float('gamma', 1e-8, 1.0, log=True),
    'reg_alpha': trial.suggest_float('reg_alpha', 1e-8, 10.0, log=True),
    'reg_lambda': trial.suggest_float('reg_lambda', 1e-8, 10.0, log=True),
    'n_estimators': 1000,
    'early_stopping_rounds': 50,
    'scale_pos_weight': len(neg) / len(pos)  # 处理不平衡
}
```

---

## 四、训练方案

### 4.1 目标变量定义

```python
# 冷门 = 赛前被一致看好的低赔方，最终未能赢球（平局或输球）
y = 1 if (低赔方最终未赢球) else 0
# 即：如果 fav_pre < draw_pre and fav_pre < upset_pre:
#        y = 1 if 赛果 != 主胜 else 0
```

### 4.2 数据划分（时间序列 Walk-Forward）

```
训练集：2022-01 ~ 2024-06（约30个月）
验证集：2024-07 ~ 2025-06（约12个月，用于 optuna 调参）
测试集：2025-07 ~ 2026-01（约6个月，最终评估）
```

**关键**：必须按时间顺序划分，不能随机打乱，防止未来信息泄露。

### 4.3 不平衡处理

- 冷门率通常 15-25%，属于中度不平衡
- LightGBM: `class_weight='balanced'`
- XGBoost: `scale_pos_weight = len(neg) / len(pos)`
- 备选：SMOTE 过采样（仅在训练集使用，验证/测试集不处理）

### 4.4 评估指标

| 指标 | 说明 | 目标 |
|------|------|------|
| AUC-ROC | 核心指标 | > 0.70（显著优于随机） |
| AUC-PR | 精确率-召回率曲线下面积 | > 0.50（不平衡场景更准确） |
| Precision@Top20 | 预测概率前20%中的冷门率 | 越高越好 |
| Recall@Top20 | 实际冷门中被预测为前20%的比例 | 越高越好 |
| F1-score | Precision 和 Recall 调和平均 | > 0.45 |
| Brier Score | 概率校准度 | < 0.20 |
| LogLoss | 整体概率质量 | < 0.50 |
| CRI vs ML uplift | ML 相对 CRI 的提升 | AUC 提升 > 5% |

---

## 五、可解释性（SHAP 分析）

每次预测输出附带：

```python
# SHAP 值分析
explainer = shap.TreeExplainer(model_lgb)
shap_values = explainer.shap_values(X)

# 全局特征重要性（每轮重训后更新）
global_importance = pd.DataFrame({
    'feature': feature_names,
    'importance': np.abs(shap_values).mean(axis=0)
}).sort_values('importance', ascending=False)

# 单样本解释（每次预测输出）
sample_shap = shap_values[0]
top5_features = np.argsort(np.abs(sample_shap))[-5:][::-1]
# 输出："本场冷门概率主要由 [ratio=12.3]、[dds=4.5]、[kelly_home=0.85] 驱动"
```

---

## 六、与 V5.0 集成路径

### 6.1 现有代码改动点

```python
# 当前 V5.0 输出：
# cri_score, level, direction_probs

# V6.0 新增输出：
result = {
    'cri_score': cri_score,           # 保留
    'cri_level': level,               # 保留
    'ml_prob': ml_prob,               # 新增
    'lgb_prob': p_lgb,                # 新增（调试可见）
    'xgb_prob': p_xgb,                # 新增（调试可见）
    'final_prob': p_final,            # 新增（融合概率）
    'final_level': final_level,        # 新增（基于融合概率）
    'confidence': confidence,          # 新增（高/中/低）
    'shap_top5': shap_features,        # 新增（可解释性）
    'model_agreement': agreement       # 新增（LGB/XGB一致性）
}
```

### 6.2 版本兼容

- V5.0 的 CRI 计算逻辑完全保留，不做改动
- V6.0 在 CRI 输出后追加 ML 模块
- 用户可选择只看 CRI（传统模式）或融合模式（V6.0）
- 默认输出融合模式，但保留 CRI 独立值供参考

---

## 七、实现阶段（Phase 1-3）

### Phase 1: 特征工程实现（第1-2周）

- [ ] Layer 1-3 特征全部实现（基于现有数据）
- [ ] Layer 4 部分实现（从公开数据获取，可先简化）
- [ ] 特征存储结构设计（CSV/JSON 格式）
- [ ] 特征数据管道：每日自动抓取 → 计算特征 → 存储
- [ ] 特征质量检查：缺失率、异常值、分布

### Phase 2: 模型训练与验证（第2-3周）

- [ ] 收集历史数据（至少2个完整赛季，500+ 样本）
- [ ] 特征标准化/编码
- [ ] LightGBM 训练（optuna 调参）
- [ ] XGBoost 训练（optuna 调参）
- [ ] 与 CRI 融合逻辑实现
- [ ] 验证集 Walk-Forward 评估
- [ ] SHAP 可解释性分析
- [ ] 与 CRI 单独对比（AUC uplift 测试）

### Phase 3: 部署与持续优化（第3-4周起）

- [ ] 自动化推理管道：赛前2小时执行预测
- [ ] 结果回灌：赛果出来后自动更新训练集
- [ ] 模型重训练：每周/每两周触发一次
- [ ] 监控看板：AUC 漂移、特征分布漂移
- [ ] 模型退化告警：AUC 下降 > 5% 时触发重训练

---

## 八、技术栈

| 组件 | 工具 | 说明 |
|------|------|------|
| 特征工程 | pandas, numpy | 数据处理与计算 |
| 模型训练 | lightgbm, xgboost | 双模型 |
| 调参 | optuna | 贝叶斯优化 |
| 可解释性 | shap | 特征重要性分析 |
| 评估 | sklearn.metrics | AUC, F1, Brier等 |
| 数据存储 | CSV/JSON + SQLite | 本地存储 |
| 部署 | Python script + cron | 定时任务 |
| 可视化 | matplotlib, shap.plots | 特征重要性图 |

---

## 九、风险提示

1. **数据质量**：ML 效果高度依赖历史数据质量，如果数据有噪声或偏差，模型会学到错误的模式
2. **过拟合**：足球比赛噪声大，容易过拟合历史规律，必须用 Walk-Forward CV 验证
3. **特征泄露**：绝对禁止将赛后信息作为特征（如半场数据、控球率等），只能用赛前可得信息
4. **市场变化**：赔率市场效率在提升，历史模式可能在未来失效，需持续监控模型性能
5. **冷启动**：新联赛/新球队数据不足时，ML 模型可能失效，此时应退化为纯 CRI 模式

---

## 十、预期收益

基于类似项目的经验数据：

| 模块 | 单独 AUC | 融合后 AUC | 提升 |
|------|----------|------------|------|
| CRI V5.0（规则） | ~0.62-0.65 | — | — |
| LightGBM（特征工程） | ~0.65-0.68 | — | — |
| XGBoost（特征工程） | ~0.64-0.67 | — | — |
| CRI + LGB + XGB 融合 | — | ~0.70-0.74 | +5-10% |

> 核心提升点：ML 能捕捉 CRI 规则无法覆盖的复杂交互（如 "联赛系数 × 赔率变化速度 × 排名差" 的三维交互），从而识别更多 CRI 遗漏的冷门信号。

---

**文档版本**: V6.0-设计稿  
**基于**: 冷门预测系统 V5.0  
**日期**: 2026-06-19  
**状态**: 设计阶段，待 Phase 1 执行
