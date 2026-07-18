# 回测协议 v1.0

本协议在首次运行 Football AI 泊松基线前确定，防止看到结果后修改门槛。

## 时间与信息边界

- 按 `MatchDate, MatchTime, SourceRow` 升序逐场滚动。
- 预测一场比赛时，只能使用该场之前已完成的比赛。
- 主客队均至少有 5 场历史记录才产生预测。
- 最近状态窗口固定为 10 场。
- 收盘赔率只用于独立市场基准，不作为当前泊松模型输入。
- 无日期的 ISL/K1 不进入 v1.0 正式回测，避免无法证明时间顺序。

## 指标

- 1X2 Accuracy
- 三分类 Brier Score（越低越好）
- Multiclass Log Loss（越低越好）
- 与联赛多数类基准的 Accuracy 差值
- 市场去水概率的相同指标（有有效赔率时）

## candidate → validated 门禁

同一联赛必须同时满足：

1. 可评估样本不少于 500 场；
2. Accuracy 至少比历史多数类基准高 2 个百分点；
3. Brier Score 不高于 0.65；
4. Log Loss 不高于 1.10；
5. 无未来数据泄漏和 MatchID 冲突；
6. 产出逐场预测文件、汇总 JSON、数据文件 SHA-256 和参数版本。

`validated` 仍不等于 `production`。正式推荐还需赔率价值、ROI、校准、联赛外推风险及中国竞彩数据适配审查。

