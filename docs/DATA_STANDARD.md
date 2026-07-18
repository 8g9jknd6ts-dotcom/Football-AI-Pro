# 数据标准 v1

## 核心比赛表

| 字段 | 类型 | 约束 |
|---|---|---|
| MatchID | 文本 | 主键，格式 `FAI-` + SHA-256 前24位 |
| Country | 文本 | 可空；缺失时由联赛代码补足 |
| LeagueCode | 文本 | 必填，稳定代码 |
| League | 文本 | 可空 |
| Season | 文本 | 必填 |
| MatchDate | `YYYY-MM-DD` | 源数据无日期时可空 |
| MatchTime | `HH:mm` | 可空 |
| Stage | 文本 | 日期缺失时用于场次身份 |
| HomeTeam | 文本 | 必填 |
| AwayTeam | 文本 | 必填且不能等于主队 |
| HomeGoals | 非负整数 | 必填 |
| AwayGoals | 非负整数 | 必填 |
| Result | H/D/A | 必须与比分一致 |
| SourceFile | 文本 | 必填，保留来源追踪 |
| SourceRow | 正整数 | 必填（不含表头） |

## MatchID v1

身份原文由以下字段以 `|` 拼接并转为大写：

`LeagueCode, Season, MatchDate, Stage, HomeTeam, AwayTeam`

随后计算 SHA-256，取十六进制前 24 位，并加前缀 `FAI-`。对于没有日期的 ISL、K1，源文件行号追加到 Stage，避免同赛季同队重复交锋发生碰撞。这个降级身份有稳定性，但无法替代真实比赛日期；质量清单会明确标记。

## 赔率表

每场比赛每家/每类市场一行，字段为：`MatchID,Provider,Market,HomeOdds,DrawOdds,AwayOdds`。只有三个方向均为大于 1 的有效十进制赔率时才写入。

