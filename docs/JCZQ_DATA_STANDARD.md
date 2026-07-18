# 中国竞彩官方赔率数据标准 v1.0

## 原则

中国竞彩数据与欧洲公司赔率分表保存，不允许用欧洲赔率冒充竞彩官方赔率。每条记录必须包含官方场次号、快照时间、销售状态和来源引用。

## 长表字段

| 字段 | 约束 |
|---|---|
| MatchID | 必填，必须引用统一比赛库或未来赛程注册表 |
| LotteryMatchID | 必填，官方场次稳定标识 |
| MatchNumber | 必填，例如周三001 |
| SnapshotTime | 必填，含时区的ISO-8601时间 |
| Market | `SPF/RQSPF/BF/JQS/BQC` |
| Handicap | `RQSPF`必填整数，其他玩法为空 |
| Selection | 玩法对应选择代码 |
| Odds | 大于1的十进制赔率 |
| SaleStatus | `OPEN/CLOSED/SUSPENDED` |
| SourceAgency | 正式数据必须为 `CHINA_SPORTS_LOTTERY` |
| SourceReference | 官方页面、文件批次或可审计来源编号 |

## 选择代码

- `SPF/RQSPF`：`H/D/A`
- `JQS`：`0/1/2/3/4/5/6/7+`
- `BQC`：`HH/HD/HA/DH/DD/DA/AH/AD/AA`
- `BF`：标准比分代码或 `H_OTHER/D_OTHER/A_OTHER`

同一 `MatchID + SnapshotTime + Market + Handicap` 快照必须玩法完整。SPF/RQSPF必须恰有H/D/A，JQS必须包含8个选择，BQC必须包含9个选择。

## 返还率

SPF/RQSPF快照返还率为：

`ReturnRate = 1 / Σ(1 / Odds_i)`

返还率只描述该快照的理论水位，不代表投注收益率。

## 当前状态

项目已收到 1 个赛前官方快照：2026 世界杯半决赛英格兰 vs 阿根廷，含 SPF 与 RQSPF 共 6 条，并保存原图证据。该单场快照不足以构成历史回测样本，竞彩返还率修正模型仍不得升级为 production。`data/templates/jczq_odds_template.csv` 仅是接口模板；`tests/fixtures/` 中的赔率只用于校验程序测试，禁止进入正式数据库或回测。

## 官方来源登记

| SourceReference | 用途 | 访问状态（2026-07-15） |
|---|---|---|
| `https://m.sporttery.cn/mjc/jsq/zqspf/` | 移动端竞彩足球 SPF/RQSPF 页面 | 官网 EdgeOne 安全策略拦截自动化访问；不得将拦截页或搜索缓存当作赔率快照 |
| `https://www.sporttery.cn/jc/jsq/zqspf/index.html` | 桌面端竞彩足球 SPF/RQSPF 页面 | 官方公开入口；可用于来源核验，但当前环境未取得可审计的动态赔率载荷 |
| `https://www.sporttery.cn/jc/zqsgkj/` | 足球赛果开奖 | 官方赛果核验入口 |

可接受的正式接入方式：官网允许的公开数据接口、带时间戳的官方导出文件，或用户提供且可核对场次号和采集时间的官方页面/APP截图。每次采集必须保留原始快照、采集时间、页面地址和内容哈希。搜索引擎摘要、第三方转载和仅声称“官方”的历史报告不得直接进入正式竞彩赔率库。

## 截图采集要求

用户提供截图时，单张或连续截图应尽量完整显示：

1. 官方应用或网页身份，以及奖金更新时间；
2. 比赛日期、竞彩编号、联赛、主队和客队；
3. 玩法名称（SPF/RQSPF/BF/JQS/BQC）；
4. 让球数、全部可售选项 SP 值和销售状态；
5. 截图设备显示时间，或由用户同时说明采集时间与时区。

导入前必须先输出识别预览供人工核对。裁切导致玩法、让球数、场次号或更新时间无法确定时，该截图只能进入待复核区；不得猜测缺失字段。相邻截图需要用场次号和可见重叠行拼接，不能仅按图片顺序推断。

## 证据快照登记

先执行 `scripts/register_jczq_evidence.ps1`，为截图、官方导出或官方接口响应生成 `JCZQ-EV-...` 证据编号。原文件会复制到 `data/raw/jczq/`；登记记录会保存采集时间、来源地址、原文件名、保存相对路径和 SHA-256。

将该编号写入赔率 CSV 的 `SourceReference`，再使用 `scripts/import_jczq.ps1` 导入。正式来源会自动拒绝未登记的来源引用。测试夹具只能用 `-AllowTestSource`，永远不能进入正式库。
