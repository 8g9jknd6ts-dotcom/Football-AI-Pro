# 2026 FIFA WORLD CUP PREDICTION SYSTEM - COMPLETE BACKUP REPORT
## 完整备份数据与框架 v3.2

**生成时间**: 2026-06-13  
**引擎版本**: v3.2  
**数据基础**: 179场大赛 + 2024欧洲杯 + 四大洲际杯赛80队

---

# 第一部分：数据基础

## 1.1 核心数据集

| 赛事 | 场次 | 场均进球 | 平局率 | 关键统计 | 数据来源 |
|------|------|----------|--------|----------|----------|
| 2018/2022世界杯 | 128场 | 2.63 | 21.9% | xG/射门/控球率 | FIFA官方 |
| Euro 2024 | 51场 | 2.27 | 33.3% | 详细xG/射门/控球率 | UEFA官方 |
| **Copa America 2024** | **16队** | **2.35** | **25%** | 参赛状态标记 | CONMEBOL |
| **AFC Asian Cup 2023** | **24队** | **2.45** | **23%** | 参赛状态标记 | AFC |
| **AFCON 2023** | **24队** | **2.15** | **28%** | 参赛状态标记 | CAF |
| **Gold Cup 2023** | **16队** | **3.39** | **18%** | 参赛状态标记 | CONCACAF |

## 1.2 四大洲际杯赛详细数据

### Copa America 2024（美国，2024年6-7月）
- **参赛队伍**: 16队（10 CONMEBOL + 6 CONCACAF特邀）
- **冠军**: Argentina（第16冠）
- **最佳射手**: Lautaro Martínez（5球）
- **场均进球**: 2.35
- **2026引擎中的队伍**: Argentina, Brazil, Colombia, Ecuador, Mexico, Paraguay, Uruguay, USA, Canada, Costa Rica, Jamaica, Panama, Bolivia, Chile, Peru, Venezuela

### AFC Asian Cup 2023（卡塔尔，2024年1-2月）
- **参赛队伍**: 24队
- **冠军**: Qatar（卫冕）
- **最佳射手**: Akram Afif（8球）
- **场均进球**: 2.45
- **2026引擎中的队伍**: Australia, Iran, Japan, Qatar, Saudi Arabia, South Korea, Iraq, Uzbekistan, Jordan, UAE, Syria, Bahrain, Oman, Thailand, China, Palestine, India, Tajikistan, Lebanon, Kyrgyzstan, Malaysia, Vietnam, Indonesia, Hong Kong

### AFCON 2023（科特迪瓦，2024年1-2月）
- **参赛队伍**: 24队
- **冠军**: Ivory Coast（主办国夺冠）
- **场均进球**: 2.15（防守最强）
- **2026引擎中的队伍**: Morocco, Senegal, Egypt, Tunisia, Algeria, Cameroon, Ghana, Ivory Coast, Mali, Burkina Faso, DR Congo, Guinea, Nigeria, Angola, South Africa, Cape Verde, Zambia, Mozambique, Tanzania, Guinea-Bissau, Namibia, Sudan, Equatorial Guinea, Libya

### Gold Cup 2023（美国/加拿大，2023年6-7月）
- **参赛队伍**: 16队（含特邀Qatar）
- **冠军**: Mexico（第9冠）
- **最佳射手**: Jesús Ferreira（7球）
- **场均进球**: 3.39（进球最多）
- **2026引擎中的队伍**: Mexico, USA, Canada, Costa Rica, Panama, Jamaica, Honduras, Guatemala, Haiti, El Salvador, Nicaragua, Trinidad and Tobago, Qatar, Martinique, Guadeloupe, Saint Lucia

---

# 第二部分：引擎架构

## 2.1 核心类设计

```python
class TeamV3:
    # 基础属性
    name: str                    # 球队名称
    fifa_rank: int              # FIFA排名
    confederation: str          # 所属大洲
    attack_index: float         # 攻击指数 (0-1)
    defense_index: float      # 防守指数 (0-1)
    form_index: float         # 状态指数 (0-1)
    xg_for: float             # 预期进球
    xg_against: float         # 预期失球
    
    # Euro 2024 详细数据
    euro_2024_xg: float
    euro_2024_xga: float
    euro_2024_goals: int
    euro_2024_games: int
    possession_avg: float      # 控球率
    shots_per_game: float      # 场均射门
    shot_accuracy: float       # 射正率
    set_piece_efficiency: float # 定位球效率
    wing_attack_share: float   # 边路进攻占比
    traditional_striker: bool  # 传统中锋
    striker_efficiency: float  # 中锋效率
    
    # 洲际杯赛参赛记录（v3.2新增）
    continental_cups: List[str] = []  # ['copa_2024', 'asian_cup_2023', 'afcon_2023', 'gold_cup_2023']
    continental_cup_performance: Dict[str, str] = {}  # tournament -> stage_reached
    
    # 洲际杯赛加成计算
    @property
    def continental_cup_boost(self) -> float:
        """参赛1项 +2%, 2项 +3%, 3项+ +4-5%"""
        n = len(self.continental_cups)
        if n == 1:
            return 0.02
        elif n == 2:
            return 0.03
        elif n >= 3:
            return 0.04 + (n - 3) * 0.01
        return 0.0
```

## 2.2 校准参数

```python
CALIBRATION_V3 = {
    'wc': {
        'avg_goals': 2.63, 'draw_rate': 0.219, 'group_draw_rate': 0.208,
        'btts': 0.484, 'over_25': 0.469, 'defense_factor': 0.95,
        'clean_sheet_rate': 0.516, 'possession_win_rate': 0.55,
        'shots_per_game': 22.5, 'shot_accuracy': 0.28,
        'set_piece_share': 0.35, 'wing_attack_share': 0.50,
        'traditional_striker_efficiency': 0.75,
        'xg_conversion_rate': 0.94,
    },
    'euro_2024': {
        'avg_goals': 2.27, 'draw_rate': 0.333, 'group_draw_rate': 0.389,
        'btts': 0.42, 'over_25': 0.38, 'defense_factor': 0.90,
        'clean_sheet_rate': 0.58, 'possession_win_rate': 0.48,
        'shots_per_game': 18.0, 'shot_accuracy': 0.26,
        'set_piece_share': 0.40, 'wing_attack_share': 0.45,
        'traditional_striker_efficiency': 0.68,
        'xg_conversion_rate': 0.88,
    },
    '2026': {
        'avg_goals': 2.60, 'avg_xg': 2.70, 'draw_rate': 0.24,
        'group_draw_rate': 0.22, 'btts': 0.48, 'over_25': 0.47,
        'defense_factor': 0.95, 'clean_sheet_rate': 0.52,
        'possession_win_rate': 0.55, 'shots_per_game': 22.5,
        'shot_accuracy': 0.28, 'set_piece_share': 0.35,
        'wing_attack_share': 0.50,
        'traditional_striker_efficiency': 0.75,
        'xg_conversion_rate': 0.94,
    },
    'copa_2024': {'avg_goals': 2.35, 'draw_rate': 0.25},
    'asian_cup_2023': {'avg_goals': 2.45, 'draw_rate': 0.23},
    'afcon_2023': {'avg_goals': 2.15, 'draw_rate': 0.28},
    'gold_cup_2023': {'avg_goals': 3.39, 'draw_rate': 0.18},
}
```

## 2.3 修正系数叠加方式

**v3.2更新：加法约束 + 叠加上限**

```python
def apply_modifiers(base, modifiers):
    """从连续乘法改为加法约束，防止多修正因子过度压制"""
    total_adjustment = sum(m - 1.0 for m in modifiers)
    combined = 1.0 + total_adjustment
    return max(0.75, combined) * base
```

## 2.4 阶段乘数（回测校准后）

| 阶段 | 乘数 | 说明 |
|------|------|------|
| 小组赛 | 1.00 | 基准 |
| 1/32决赛 | 1.12 | ⚠️ 新增阶段，极低置信度 |
| 1/16决赛 | 1.25 | 从1.12上调 |
| 1/4决赛 | 1.15 | 从0.98上调 |
| 半决赛 | 1.10 | 从0.93上调 |
| 决赛 | 1.15 | 从1.05上调 |
| 三四名 | 1.20 | 从1.05上调 |

## 2.5 关键算法流程

```
base_xg = attack_index * defense_index * stage_mult * fatigue_mult * 3.5 * defense_factor

modifiers收集：
├── 欧洲德比修正 (×0.88)
├── 控球率修正 (削弱至30%影响)
├── 边路进攻修正 (仅Spain全溢价1.12，其他1.06)
├── 中锋效率惩罚 (<0.6时 ×0.92)
├── 定位球修正 (>0.4时 ×1.08)
├── 小组赛实力差修正 (>30名差距)
├── 状态修正 (0.8 + 0.4*form_index + continental_cup_boost)
├── 第三轮修正 (1.0，无修正)
├── 主场优势 (+10% for Mexico/USA/Canada)
└── 洲际杯赛加成 (+2-5% for participants)

最终：加法约束，下限0.75
```

---

# 第三部分：48队完整数据

## 3.1 分组情况

| 小组 | 球队1 | 球队2 | 球队3 | 球队4 |
|------|-------|-------|-------|-------|
| **A** | Mexico | South Africa | South Korea | Czech Republic |
| **B** | Canada | Bosnia | Qatar | Switzerland |
| **C** | Brazil | Morocco | Haiti | Scotland |
| **D** | USA | Paraguay | Australia | Turkey |
| **E** | Germany | Curacao | Ivory Coast | Ecuador |
| **F** | Netherlands | Japan | Sweden | Tunisia |
| **G** | Belgium | Egypt | Iran | New Zealand |
| **H** | Spain | Cape Verde | Saudi Arabia | Uruguay |
| **I** | France | Senegal | Iraq | Norway |
| **J** | Argentina | Algeria | Austria | Jordan |
| **K** | Portugal | DR Congo | Uzbekistan | Colombia |
| **L** | England | Croatia | Ghana | Panama |

## 3.2 洲际杯赛覆盖统计

| 洲际杯赛 | 参赛队伍数 | 在2026引擎中 | 覆盖率 |
|----------|------------|--------------|--------|
| Copa America 2024 | 16 | 8 | 50% |
| AFC Asian Cup 2023 | 24 | 8 | 33% |
| AFCON 2023 | 24 | 12 | 50% |
| Gold Cup 2023 | 16 | 5 | 31% |

## 3.3 多赛事参赛队伍（高经验值）

| 队伍 | 参赛杯赛 | 加成 |
|------|----------|------|
| Mexico | Copa 2024 + Gold Cup 2023 | +3% |
| Canada | Copa 2024 + Gold Cup 2023 | +3% |
| USA | Copa 2024 + Gold Cup 2023 | +3% |
| Qatar | Asian Cup 2023 + Gold Cup 2023 | +3% |
| Panama | Copa 2024 + Gold Cup 2023 | +3% |

---

# 第四部分：回测验证

## 4.1 2022世界杯回测（46场有效）

| 指标 | 实际值 | 预测值 | 偏差 | 状态 |
|------|--------|--------|------|------|
| 场均进球 | 2.69 | 2.60 | **3.4%** | ✅ |
| 平局率 | 23.4% | 24.1% | **3.0%** | ✅ |
| Over 2.5 | 46.9% | 47.9% | **2.2%** | ✅ |
| BTTS | 48.4% | 47.6% | **1.6%** | ✅ |
| 1球分差 | 37.5% | 38.2% | **2.0%** | ✅ |
| 零封率 | 51.6% | 52.4% | **1.5%** | ✅ |
| 小组赛场均 | 2.50 | 2.55 | **2.1%** | ✅ |
| 淘汰赛场均 | 3.25 | 2.70 | **17.0%** | ⚠️ |
| 第三轮平局 | 6.2% | 22.7% | **265.6%** | ❌ |

## 4.2 边缘偏差（结构性限制）

| 指标 | 偏差 | 说明 |
|------|------|------|
| 0-0率 | 26.3% | 模型无法捕捉极端防守策略 |
| KO平局率 | 22.5% | 加时赛/点球机制未建模 |
| 第三轮平局 | 265.6% | 模型无法识别已出线/未出线动机 |

---

# 第五部分：完整模拟结果

## 5.1 小组赛结果

### Group A
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| Mexico | 5.4 | 3 | 0 | 0 | 6 | 3 | +3 |
| South Korea | 4.4 | 2 | 0 | 1 | 4 | 4 | 0 |
| Czech Republic | 4.0 | 1 | 0 | 2 | 3 | 4 | -1 |
| South Africa | 2.7 | 0 | 0 | 3 | 3 | 5 | -2 |

### Group B
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| Switzerland | 5.6 | 3 | 0 | 0 | 6 | 3 | +3 |
| Canada | 4.9 | 2 | 0 | 1 | 5 | 4 | +1 |
| Qatar | 3.3 | 1 | 0 | 2 | 3 | 5 | -2 |
| Bosnia | 2.7 | 0 | 0 | 3 | 3 | 5 | -2 |

### Group C
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| Brazil | 6.4 | 3 | 0 | 0 | 6 | 3 | +3 |
| Morocco | 5.2 | 2 | 0 | 1 | 5 | 3 | +2 |
| Scotland | 3.5 | 1 | 0 | 2 | 4 | 5 | -1 |
| Haiti | 1.6 | 0 | 0 | 3 | 3 | 7 | -4 |

### Group D
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| USA | 5.2 | 3 | 0 | 0 | 6 | 3 | +3 |
| Turkey | 4.2 | 1 | 1 | 1 | 4 | 4 | 0 |
| Australia | 4.0 | 1 | 1 | 1 | 3 | 4 | -1 |
| Paraguay | 3.1 | 0 | 0 | 3 | 3 | 5 | -2 |

### Group E
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| Germany | 6.4 | 3 | 0 | 0 | 6 | 3 | +3 |
| Ecuador | 4.8 | 2 | 0 | 1 | 5 | 4 | +1 |
| Ivory Coast | 3.7 | 1 | 0 | 2 | 4 | 5 | -1 |
| Curacao | 1.8 | 0 | 0 | 3 | 3 | 6 | -3 |

### Group F
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| Netherlands | 5.8 | 3 | 0 | 0 | 4 | 3 | +1 |
| Japan | 4.2 | 2 | 0 | 1 | 4 | 3 | +1 |
| Sweden | 3.8 | 1 | 0 | 2 | 3 | 3 | 0 |
| Tunisia | 2.7 | 0 | 0 | 3 | 3 | 5 | -2 |

### Group G
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| Belgium | 6.0 | 3 | 0 | 0 | 5 | 3 | +2 |
| Iran | 4.7 | 2 | 0 | 1 | 4 | 3 | +1 |
| Egypt | 4.3 | 1 | 0 | 2 | 4 | 4 | 0 |
| New Zealand | 1.7 | 0 | 0 | 3 | 3 | 6 | -3 |

### Group H
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| Spain | 7.1 | 3 | 0 | 0 | 8 | 2 | +6 |
| Uruguay | 5.3 | 2 | 0 | 1 | 5 | 4 | +1 |
| Saudi Arabia | 2.6 | 1 | 0 | 2 | 3 | 6 | -3 |
| Cape Verde | 1.8 | 0 | 0 | 3 | 2 | 6 | -4 |

### Group I
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| France | 6.4 | 3 | 0 | 0 | 6 | 3 | +3 |
| Senegal | 4.4 | 2 | 0 | 1 | 4 | 4 | 0 |
| Norway | 3.9 | 1 | 0 | 2 | 4 | 4 | 0 |
| Iraq | 1.9 | 0 | 0 | 3 | 3 | 6 | -3 |

### Group J
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| Argentina | 6.8 | 3 | 0 | 0 | 7 | 3 | +4 |
| Austria | 4.6 | 2 | 0 | 1 | 4 | 4 | 0 |
| Algeria | 3.4 | 1 | 0 | 2 | 4 | 4 | 0 |
| Jordan | 1.9 | 0 | 0 | 3 | 3 | 7 | -4 |

### Group K
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| Portugal | 6.4 | 3 | 0 | 0 | 5 | 3 | +2 |
| Colombia | 5.5 | 2 | 0 | 1 | 5 | 3 | +2 |
| DR Congo | 2.6 | 1 | 0 | 2 | 3 | 5 | -2 |
| Uzbekistan | 2.3 | 0 | 0 | 3 | 3 | 5 | -2 |

### Group L
| 球队 | 积分 | 胜 | 平 | 负 | 进球 | 失球 | 净胜球 |
|------|------|----|----|----|------|------|--------|
| England | 6.6 | 3 | 0 | 0 | 5 | 3 | +2 |
| Croatia | 5.4 | 2 | 0 | 1 | 5 | 3 | +2 |
| Ghana | 2.7 | 1 | 0 | 2 | 3 | 5 | -2 |
| Panama | 2.1 | 0 | 0 | 3 | 3 | 5 | -2 |

## 5.2 最佳第三晋级队伍

| 排名 | 球队 | 积分 | 净胜球 | 进球 | 小组 |
|------|------|------|--------|------|------|
| 1 | Egypt | 4.3 | 0 | 4 | G |
| 2 | Australia | 4.0 | -1 | 3 | D |
| 3 | Czech Republic | 4.0 | -1 | 3 | A |
| 4 | Norway | 3.9 | 0 | 4 | I |
| 5 | Sweden | 3.8 | 0 | 3 | F |
| 6 | Ivory Coast | 3.7 | -1 | 4 | E |
| 7 | Scotland | 3.5 | -1 | 4 | C |
| 8 | Algeria | 3.4 | 0 | 4 | J |

## 5.3 淘汰赛完整路径

### 1/32决赛（32强→16强）
| 场次 | 对阵 | 赛果 | 晋级 |
|------|------|------|------|
| 1 | Czech Republic vs Morocco | 1-1 | Morocco |
| 2 | Netherlands vs Uruguay | 1-1 | Netherlands |
| 3 | Australia vs Japan | 1-1 | Japan |
| 4 | England vs USA | 1-1 | England |
| 5 | Austria vs Belgium | 0-1 | Belgium |
| 6 | France vs Ecuador | 1-0 | France |
| 7 | Sweden vs Spain | 0-1 | Spain |
| 8 | Egypt vs Portugal | 0-1 | Portugal |
| 9 | Scotland vs South Korea | 1-1 | South Korea |
| 10 | Iran vs Argentina | 0-1 | Argentina |
| 11 | Switzerland vs Senegal | 1-1 | Switzerland |
| 12 | Colombia vs Canada | 1-1 | Colombia |
| 13 | Ivory Coast vs Brazil | 0-2 | Brazil |
| 14 | Norway vs Algeria | 1-1 | Norway |
| 15 | Germany vs Croatia | 1-0 | Germany |
| 16 | Mexico vs Turkey | 1-1 | Mexico |

### 1/16决赛（16强→8强）
| 场次 | 对阵 | 赛果 | 晋级 |
|------|------|------|------|
| 1 | Morocco vs Netherlands | 1-1 | Netherlands |
| 2 | Japan vs England | 1-1 | England |
| 3 | Belgium vs France | 0-1 | France |
| 4 | Spain vs Portugal | 1-0 | Spain |
| 5 | South Korea vs Argentina | 0-2 | Argentina |
| 6 | Switzerland vs Colombia | 1-1 | Colombia |
| 7 | Brazil vs Norway | 1-0 | Brazil |
| 8 | Germany vs Mexico | 1-1 | Germany |

### 1/4决赛（8强→4强）
| 场次 | 对阵 | 赛果 | 晋级 |
|------|------|------|------|
| 1 | Netherlands vs England | 1-1 | England |
| 2 | France vs Spain | 0-1 | Spain |
| 3 | Argentina vs Colombia | 1-0 | Argentina |
| 4 | Brazil vs Germany | 1-1 | Brazil |

### 半决赛（4强→2强）
| 场次 | 对阵 | 赛果 | 晋级 |
|------|------|------|------|
| 1 | England vs Spain | 0-1 | Spain |
| 2 | Argentina vs Brazil | 1-1 | Argentina |

### 三四名决赛
| 对阵 | 赛果 | 胜者 |
|------|------|------|
| England vs Brazil | 1-1 | Brazil |

### 决赛
| 对阵 | 赛果 | 冠军 |
|------|------|------|
| Spain vs Argentina | 1-1 | **Spain** |

## 5.4 最终排名

| 排名 | 球队 | 阶段 | 关键路径 |
|------|------|------|----------|
| 🏆 1 | **Spain** | 冠军 | 小组赛7.1pts → 2-0 Algeria → 1-0 Portugal → 1-0 France → 1-0 England → 1-1 Argentina |
| 🥈 2 | **Argentina** | 亚军 | 小组赛6.8pts → 2-0 South Korea → 1-0 Colombia → 1-1 Brazil → 1-1 Spain |
| 🥉 3 | **Brazil** | 季军 | 小组赛6.4pts → 2-0 Ivory Coast → 1-0 Norway → 1-1 Germany → 1-1 Argentina → 1-1 England |
| 4 | England | 殿军 | 小组赛6.6pts → 1-1 USA → 1-1 Japan → 1-1 Netherlands → 0-1 Spain |
| 5-8 | France | 八强 | 1-0 Ecuador → 1-0 Belgium → 0-1 Spain |
| 5-8 | Germany | 八强 | 1-0 Croatia → 1-1 Mexico → 1-1 Brazil |
| 5-8 | Netherlands | 八强 | 1-1 Uruguay → 1-1 Morocco → 1-1 England |
| 5-8 | Colombia | 八强 | 1-1 Canada → 1-1 Switzerland → 0-1 Argentina |

---

# 第六部分：文件清单与使用说明

## 6.1 文件清单

| 文件 | 说明 |
|------|------|
| `worldcup_2026_engine_v3.2.py` | 主引擎（含四大洲际杯赛数据） |
| `worldcup_2022_data.json` | 2022世界杯比赛数据 |
| `backtest_2022_engine.py` | 回测脚本 |
| `四大洲际杯赛参赛队伍数据.md` | 四大洲际杯赛原始数据 |
| `2026世界杯预测架构完整报告v3.2.md` | 架构报告 |
| `2026世界杯完整模拟报告v3.2.md` | 小组赛模拟报告 |
| `2026世界杯淘汰赛完整模拟报告.md` | 淘汰赛模拟报告 |
| `2026世界杯预测框架评估报告.md` | 问题诊断与修改方案 |
| `2026世界杯完整备份报告.md` | 本备份报告 |

## 6.2 使用说明

### 运行单场预测
```bash
python3 worldcup_2026_engine_v3.2.py match Spain Germany round_of_16
```

### 运行演示
```bash
python3 worldcup_2026_engine_v3.2.py
```

### 运行全部小组赛模拟
```bash
python3 -c "import sys; sys.path.insert(0, '.'); from worldcup_2026_engine_v3_2 import *; engine = WorldCup2026EngineV3(); ..."
```

## 6.3 引擎版本历史

| 版本 | 日期 | 主要更新 |
|------|------|----------|
| v3.0 | 2026-06-10 | 基础框架：179场大赛 + Euro 2024 |
| v3.1 | 2026-06-11 | 回测校准：基础乘数2.5→3.5，防守因子0.90→0.95，加法约束 |
| v3.2 | 2026-06-13 | 四大洲际杯赛：80队参赛标记 + 状态加成 + 淘汰赛模拟 |

---

# 第七部分：免责声明

⚠️ 本预测架构基于历史数据统计和概率模型，仅供娱乐和学术研究参考。足球比赛存在大量不可预测因素（红牌、点球、伤病、天气、裁判等），模型无法完全捕捉。请理性看待预测结果。

---

**报告生成时间**: 2026-06-13 00:41  
**引擎版本**: v3.2  
**数据基础**: 179场大赛 + 四大洲际杯赛80队  
**完整备份**: 是
