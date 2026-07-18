# 国际大赛ML模型训练报告

## 训练数据
- 样本: 1,673场国际大赛 (1,641场有赔率)
- 赛事: 世界杯/欧洲杯/美洲杯/亚洲杯/非洲杯/欧国联/世预赛/友谊赛
- 时间跨度: 2006-2025

## 模型版本

### 方向预测 (胜/平/负)
| 模型 | 特征 | 准确率 | 用途 |
|------|------|--------|------|
| intl_pre_match_model | 纯赛前 (排名/赛事/战意/历史) | 52.6% | 赛前预测 (无赔率时用) |
| intl_with_odds_model | 含终盘赔率 | 99.4% | 理论上限 (赛后分析) |

### 大小球预测 (2.5球线)
| 模型 | 特征 | 准确率 | 用途 |
|------|------|--------|------|
| intl_ou_pre_match_model | 纯赛前 | 53.8% | 赛前预测 |
| intl_ou_with_odds_model | 含终盘赔率 | 60.5% | 理论上限 |

## 关键发现

1. **终盘赔率泄露**: 数据库中b365_home/draw/away为终盘赔率（赛后调整），含赔率模型准确率99.4%不可用于实际预测
2. **赛前特征弱**: 纯赛前特征（FIFA排名/赛事类型/战意/历史交锋）准确率仅52.6%，接近随机
3. **排名数据缺失**: 67%比赛缺少FIFA排名，导致rank_diff特征未发挥作用
4. **战意特征失效**: home_must_win/away_must_win等字段全部缺失（数据库为NULL）

## 提升路径

### 短期 (可立即执行)
1. **获取竞彩历史初盘赔率**: 从zgzcw.com或历史数据库抓取中国体彩竞彩初盘赔率，替换终盘赔率
2. **补充FIFA排名**: 从FIFA官网获取各年国家队排名，补全数据库
3. **补充战意特征**: 根据小组形势/积分计算生死战标记（赛前计算）

### 中期 (1-2周)
4. **加入球队近期状态**: 近10场国际比赛进球/丢球/胜率（赛前已知）
5. **加入球员信息**: 关键球员身价/年龄/伤病（赛前阵容）
6. **历史交锋数据**: 近5次交手结果（赛前已知）

### 长期
7. **多模型集成**: 加入RandomForest/SVM/神经网络做集成
8. **动态赔率修正**: 如果只能获取终盘赔率，尝试用初盘-终盘变化率作为特征

## 文件清单
```
/mnt/agents/models/
  intl_pre_match_model.pkl        # 纯赛前方向模型
  intl_with_odds_model.pkl        # 含赔率方向模型
  intl_ou_pre_match_model.pkl     # 纯赛前大小球模型
  intl_ou_with_odds_model.pkl     # 含赔率大小球模型
```

## 使用方式
```python
import pickle
with open('models/intl_pre_match_model.pkl', 'rb') as f:
    data = pickle.load(f)
model = data['model']
encoder = data['encoder']
# 输入: [rank_diff, has_rank, comp_encoded, stage_encoded, home_must_win, away_must_win, home_can_draw, away_can_draw, home_team_winrate, away_team_winrate]
# 输出: H/D/A 概率
```

---
*报告生成时间: 2026-06-21*
*基于数据库: 1,673场国际大赛*
