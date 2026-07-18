
# 框架Bug扫描与更新建议报告

## 一、框架组件完整性检查

| 组件 | 文件 | 状态 | 大小 |
|------|------|------|------|
| CRI自动化引擎 | cri_automated_engine_v1.py | ✅ 可用 | 14.7KB |
| 回测引擎 | cri_backtest_engine_v1.py | ✅ 可用 | 19.0KB |
| 输入校验器 | match_input_validator_v1.py | ✅ 可用 | 20.8KB |
| 融合引擎 | fusion_engine_v1.py | ⚠️ 部分可用 | 18.3KB |
| 赔率解析器 | odds_parser_v1.py | ✅ 可用 | 20.0KB |
| DC模型 | dixon_coles_model_v1.py | ✅ 可用 | 17.5KB |
| ML模型 | ml_ensemble_model_v1.py | ✅ 可用 | 22.6KB |
| 数据库层 | db_storage_v1.py | ✅ 可用 | 8.7KB |
| 球队数据管理 | team_data_manager_v1.py | ✅ 可用 | 25.9KB |
| 抓取脚本v1 | 双源赔率抓取脚本_v1.py | ✅ 可用 | 11.8KB |
| 抓取脚本v2 | 双源赔率全维度抓取脚本_v2.py | ✅ 可用 | 18.1KB |

## 二、发现的问题清单

### 🔴 HIGH - 关键Bug（2项）

1. **fusion_engine_v1.py - EndToEndPredictor 未集成DC/ML模型**
   - 位置：EndToEndPredictor.predict() 方法，第45/49/52行
   - 问题：DC模型、ML模型、融合引擎的调用全部被注释掉，仅返回CRI结果
   - 影响：端到端预测器实际上只工作了一层（CRI），DC和ML模块没有参与
   - 修复：取消注释并正确调用 self.dc_model.predict() 和 self.ml_model.predict()

2. **fusion_engine_v1.py - 缺乏实时预测接口**
   - 位置：FusionEngine.fuse() 方法需要 DCResult/MLResult/CRIResult 对象
   - 问题：只有从对象融合的方法，没有从原始赔率数据直接预测的接口
   - 影响：每次使用需要手动创建数据类对象，无法一键预测
   - 修复：添加直接接受原始数据的 predict_from_odds() 接口

### 🟡 MEDIUM - 中等问题（5项）

3. **odds_parser_v1.py - 缺少足彩网(zgzcw)解析器集成**
   - 问题：OddsDataParser 类中没有 zgzcw 的解析方法
   - 影响：足彩网数据需要单独处理，无法统一解析
   - 修复：添加 parse_zgzcw_html() / parse_zgzcw_ajax() 方法

4. **odds_parser_v1.py - 缺少自动抓取方法**
   - 问题：只有 parse_xxx_html() 方法，没有 fetch_xxx() 自动下载
   - 影响：需要外部下载HTML后再解析，无法一键自动采集
   - 修复：添加 fetch_titan_euro_js() / fetch_titan_asian() 等自动抓取方法

5. **ml_ensemble_model_v1.py - 仅支持合成数据训练**
   - 问题：fit() 方法默认 use_synthetic=True，没有真实历史数据加载管道
   - 影响：模型无法使用真实比赛结果进行训练
   - 修复：添加从数据库/CSV加载历史比赛数据的功能

6. **db_storage_v1.py - 外键约束未启用**
   - 问题：FOREIGN KEY 定义在表结构中，但缺少 PRAGMA foreign_keys = ON
   - 影响：SQLite 默认不强制外键约束，数据完整性风险
   - 修复：连接数据库后执行 PRAGMA foreign_keys = ON

7. **dixon_coles_model_v1.py - 缺少与球队数据管理器集成**
   - 问题：没有从 team_data_manager 加载历史比赛数据的方法
   - 影响：需要手动提供历史比赛数据，无法自动获取
   - 修复：添加 load_history_from_db() 方法，从 team_data.db 加载

### 🟢 LOW - 轻微问题（3项）

8. **db_storage_v1.py - 缺少数据库索引**
   - 问题：没有为 match_id、company_id、date 等列创建索引
   - 影响：大数据量时查询性能下降
   - 修复：CREATE INDEX idx_match_id ON euro_odds(match_id)

9. **ml_ensemble_model_v1.py - LightGBM缺失时无优雅降级**
   - 问题：导入 lightgbm 失败时只有 print 提示，没有完整回退逻辑
   - 影响：仅使用XGBoost或规则预测时，特征重要性可能不完整
   - 修复：完善 LGB_AVAILABLE 为 False 时的降级逻辑

10. **team_data_manager_v1.py - 数据更新机制缺失**
    - 问题：球队数据（FIFA排名、ELO等）是静态预置的，没有自动更新
    - 影响：数据会随时间过时（FIFA排名每月更新）
    - 修复：添加 update_fifa_rankings() 和 update_elo_ratings() 方法

## 三、建议更新优先级

### 第一批（立即修复）- 影响端到端运行
- 修复#1：fusion_engine 注释掉的DC/ML调用
- 修复#2：fusion_engine 添加实时预测接口
- 修复#6：db_storage 启用外键约束

### 第二批（本周内）- 提升自动化能力
- 修复#4：odds_parser 添加自动抓取方法
- 修复#3：odds_parser 集成zgzcw解析
- 修复#7：dixon_coles 集成球队数据管理器

### 第三批（后续优化）- 提升模型质量
- 修复#5：ML模型真实历史数据训练管道
- 修复#10：球队数据自动更新机制
- 修复#8/#9：数据库索引和降级逻辑

## 四、架构完整性评估

```
数据层:    ✅ 球队数据(70队)  ✅ 数据库(SQLite)  ✅ 解析器(球探网)
           ⚠️ 足彩网集成(缺失)  ⚠️ 自动抓取(缺失)  ⚠️ 数据更新(缺失)

模型层:    ✅ CRI引擎(可用)  ✅ DC模型(可用)  ✅ ML模型(可用)
           ⚠️ 端到端集成(注释掉)  ⚠️ 真实训练数据(合成数据)  

融合层:    ✅ 权重算法(可用)  ✅ 置信度计算(可用)  ✅ 解释生成(可用)
           ⚠️ 实时预测接口(缺失)  ⚠️ 仓位管理(报告中)

输出层:    ✅ 格式化报告(可用)  ✅ 方案A/B/C(可用)  ✅ 仓位管理(可用)
           ✅ 信号扫描(A0/C8/X1/V5d/S3/C13)  ✅ 怀疑指数评分(可用)
```
