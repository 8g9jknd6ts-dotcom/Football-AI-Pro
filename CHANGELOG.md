# 开发日志

## Unreleased

- Added Rule072 and made the operating framework explicit: de-vigged odds are the market baseline, dated same-league history calibrates scoring and goal-margin distributions, and totals odds constrain expected goals. The three layers are complementary and cannot replace one another.
- Distinguished a dated-history research result from a formally validated handicap recommendation. Historical calibration may be reported with probabilities and edge; official handicap recommendations remain gated on league, line and time-ordered historical odds backtesting.
- Required reports to distinguish insufficient-data observation from a computed research result that fails the formal handicap gate or has material cross-layer conflict.
- Repaired the independent JCZQ goal-margin calculation so probability mass is preserved and no longer produces empty values.
- Made handicap analysis require dated, pre-match history; undated league records are excluded rather than risking future-data leakage.
- Added explicit `GoalMarginDistributionStatus` and coverage/rejection fields so reports distinguish an unavailable distribution from a computed distribution that fails a decision gate.

## Football AI 1.0.0-alpha.48 - 2026-07-20

- Added an independent JCZQ handicap model, exact settlement mapping, mandatory skip gate, post-match audit entry point, official-history template and protocol.
- Kept the standard 1X2 probability logic unchanged; recent results were recorded as audit context only and did not change parameters.

## Football AI 1.0.0-alpha.47 - 2026-07-19

- Corrected FIN/SWE date-range auditing to parse day-first dates instead of lexicographic strings.
- Regenerated league quality and model-gate outputs; Asian/totals history remains blocked until verifiable multi-bookmaker archives are imported.

## Football AI 1.0.0-alpha.46 - 2026-07-19

- Fixed league-quality audit root resolution and refreshed FIN/SWE quality outputs.
- Kept Asian/totals markets gated until source archives are available.

## Football AI 1.0.0-alpha.45 - 2026-07-19

- Added `docs/MODEL_RULES_SUMMARY.md` as the concise operating contract for data tiers, market evidence, model status, rules, reporting and production gates.
- Linked the model rules summary from the README.
- Regenerated the verified eight-match postmortem and synchronized its tracking-database snapshot during validation.
- Unified version references across README and completion-audit documents.

## Football AI 1.0.0-alpha.40 - 2026-07-17

- Set the English Premier League, La Liga, Serie A, Bundesliga and Ligue 1 as the first-priority league expansion set.
- Added Rule063 and a separate priority/missing-data gate document.

## Football AI 1.0.0-alpha.41 - 2026-07-17

- Added five-league extended-market coverage audit.
- Added Rule064 to separate MarketAverage research context from company-level odds evidence.

## Football AI 1.0.0-alpha.42 - 2026-07-17

- Completed a strict structural audit of the five-league archive market data.
- Added Rule065 separating structural validity from source-authenticity approval.

## Football AI 1.0.0-alpha.43 - 2026-07-17

- Added Rule066 separating hit rate from odds value and requiring a separate handicap evaluation.

## Football AI 1.0.0-alpha.39 - 2026-07-17

- Added duplicate-key exclusion and effective sample size to the league quality gate.
- Added Rule062 to block leagues with duplicate date/home/away keys above 0.5%.

## Football AI 1.0.0-alpha.38 - 2026-07-17

- Added automated league-sample quality audit and `league_model_gate.json`.
- Added Rule061: 1X2 research eligibility is separated from Asian-handicap, totals and production eligibility.
- Added explicit reporting of result, season, average/max 1X2 and single-book coverage.

## Football AI 1.0.0-alpha.32 - 2026-07-15

- Audited the user-designated China Soccer Lottery history page for 2026-07-08: 174 match cards and 80 complete SPF odds cards were observed.
- Added Rule028 to quarantine third-party historical odds as candidate context until official-source cross-validation is available.

## Football AI 1.0.0-alpha.31 - 2026-07-15

- Corrected single-entry ledger cardinality handling so parent linkage and entry counts remain deterministic as the release chain grows.

## Football AI 1.0.0-alpha.30 - 2026-07-15

- Added Rule027 and a SHA-256 hash-chain release ledger as an auditable fallback version-control mechanism when Git is unavailable.
- Version-control audit now recognizes either a valid Git commit chain or a valid hash-chain release ledger; Git remains the preferred mechanism.

## Football AI 1.0.0-alpha.29 - 2026-07-15

- Added Rule026 and an explicit version-control audit that distinguishes release metadata from a verifiable Git commit chain.
- Recorded the current environment as unavailable for Git provenance because the executable, HEAD, and object database are absent.

## Football AI 1.0.0-alpha.28 - 2026-07-15

- Added Rule025 and a full raw-source archive manifest with file metadata and SHA-256 hashes.
- Added archive-manifest verification to the regression suite; retained raw data remains explicitly excluded from training by default.

## Football AI 1.0.0-alpha.27 - 2026-07-15

- Corrected the requirement-audit summary so it reports the required report-section count accurately.

## Football AI 1.0.0-alpha.26 - 2026-07-15

- Added a machine-checkable project requirement audit for report fields, contiguous RuleNNN numbering, completion-audit version alignment, and the production-model gate.

## Football AI 1.0.0-alpha.25 - 2026-07-15

- Updated the requirement-completion audit to the current Rule024 and full-verification evidence.
- Clarified model-registry names so a backtested candidate component is not confused with a production decision layer.

## Football AI 1.0.0-alpha.24 - 2026-07-15

- Repaired the official JCZQ snapshot report parser after an encoding-damaged RQSPF text literal prevented the full verification suite from reaching completion.
- Confirmed deterministic snapshot reporting for the registered two-snapshot evidence chain; formal recommendation remains disabled.

## Football AI 1.0.0-alpha.23 - 2026-07-15

- Added a Titan007 Asian-handicap normalizer that converts the source sign to a single home-team line before analysis.
- Added a 1X2 direction cross-check that flags contradictory home/away handicap interpretations for review.
- Added regression coverage for the captured Atert, Sutjeska, and Egnatia line conventions.

## Football AI 1.0.0-alpha.22 - 2026-07-15

- 新增 Rule024：固化球探网亚洲盘符号到统一主队视角的转换规则，并要求与1X2强弱方向进行自动交叉校验，防止主客让球方向反转。

## Football AI 1.0.0-alpha.21 - 2026-07-15

- 新增 Rule023：正式回测与推荐仅允许可审计的一手赛果和盘口数据；第三方聚合页、社交媒体与用户截图一律隔离为赛前上下文，不能被称为100%可靠。
- 根据用户确认，补充 `USER_CERTIFIED_CONTEXT`：用户保证可靠的原始截图可作为单场临场分析输入，但仍与可复核的长期回测数据分层保存。
- 登记球探网移动站为用户指定的临场数据源；后续逐场记录页面地址、采集时间、公司、盘口和比赛身份，以便沉淀为可审计历史序列。

## Football AI 1.0.0-alpha.20 - 2026-07-15

- 新增 Rule022：分析交付默认分为聊天屏重点汇总与独立完整报告文档两层；只有用户明确要求时才在聊天屏展开全部细节。

## Football AI 1.0.0-alpha.19 - 2026-07-15

- 新增 `analyze_jczq_snapshots.ps1`：从已登记的官方竞彩 SPF/RQSPF 快照自动生成去水概率、返还率、赔率迁移与证据链报告。
- 该报告器强制保持 `FormalRecommendation=false`，不将国家队世界杯未经回测的泊松、凯利、AI、信心或冷门模型伪装为有效输出。
- 新增回归断言，覆盖双快照对比、证据编号渲染、报告模板完整性和正式推荐关闭状态。

## Football AI 1.0.0-alpha.18 - 2026-07-15

- 导入世界杯半决赛英格兰 vs 阿根廷 14:55 官方竞彩 SPF/RQSPF 快照6条；每条均关联新登记的官方截图证据。
- 新增14:55完整更新报告：对比官方竞彩、欧洲平均、亚洲平手盘、大小球与本届世界杯样本，并显式披露已交叉模块和未获国家队回测许可的模块。
- 竞彩回归断言扩展为校验两次官方快照共12条及各自证据关联，防止更新快照覆盖或脱离审计链。

## Football AI 1.0.0-alpha.17 - 2026-07-15

- 世界杯赛前上下文样本补齐比赛日期和符合统一规范的 `FAI-` MatchID；12 条数据均保留逐行可访问来源。
- 新增 `validate_context_samples.ps1` 与回归断言，验证样本数、MatchID唯一性、日期、赛果、来源与隔离状态。
- 新增 Rule021：上下文样本在没有独立历史回测之前，强制隔离于训练、回测、AI评分、信心指数和正式推荐。

## Football AI 1.0.0-alpha.16 - 2026-07-15

- 为世界杯半决赛英格兰 vs 阿根廷补录两队本届赛事前六场完赛样本，共 12 条；逐行保留来源链接和 `authoritative-context-only` 数据状态。
- 报告新增本届赛事样本层，明确区分小样本的赛前情境修正与已通过回测的正式模型，避免将 12 场比赛错误升级为生产级概率模型。
- 根据两队本届进失球、淘汰赛失球和加时负荷，调整比分场景为 1-1 / 1-2 / 2-1，并保留小球市场与高进球历史样本之间的冲突提示。

## Football AI 1.0.0-alpha.15 - 2026-07-15

- 首次导入带原图证据的中国竞彩正式赔率：世界杯半决赛英格兰 vs 阿根廷，SPF 与让[-1]共 6 条。
- 为该场创建确定性 MatchID、未来赛程记录和完整赛前研究报告。
- 报告区分官方竞彩、第三方欧赔/亚盘/大小球截图与公开赛事资讯；国家队模型未通过独立回测的输出保持 unavailable。
- 更新自动验证基线，确认 6 条官方赔率均链接到已登记的证据快照。

## Football AI 1.0.0-alpha.14 - 2026-07-15

- 单场报告新增可追溯的主队主场、客队客场和直接交锋上下文，并披露样本量、胜平负与场均进失球。
- 明确上述上下文当前只作描述性分析，不改变已回测的泊松基线或正式推荐状态。
- 自动验证新增主客场与交锋上下文渲染断言。

## Football AI 1.0.0-alpha.13 - 2026-07-15

- 新增竞彩证据快照登记：对官方截图、导出文件和接口响应生成稳定证据编号及 SHA-256 审计记录。
- 竞彩导入器对正式来源默认强制证据登记，拒绝未登记证据编号的赔率。
- 证据登记器将原始截图/导出文件保存到 `data/raw/jczq/`；导入时复核文件存在性与 SHA-256，防止证据被替换或丢失。
- 完整回归验证 PASS：原始证据保存与完整性校验未影响统一数据、历史回测、自动报告和正式推荐门禁。
- 新增 Rule020，要求正式竞彩赔率与已登记的证据快照关联。
- 完整验证 PASS：证据登记和未登记官方来源拒绝门禁已覆盖；统一数据、回测、自动报告和现有竞彩接口检查均通过。

## Football AI 1.0.0-alpha.12 - 2026-07-15

- 新增可重复执行的低可信历史样本逐行审计程序。
- 审计 `match_history_core` 148,375 行：24,370 行仅达到结构可复核，124,005 行隔离；15 个分片确认为同量分发副本。
- 审计 `international_matches` 1,673 行：全部因逐行来源不可验证而隔离，并识别异常射门、xG 和控球率字段。
- 新增 Rule019，禁止低可信、异常或重复分片样本生成正式 MatchID 或参与训练回测。
- 完整验证 PASS：统一比赛 83,659 条、欧洲赔率 185,694 条、扩展市场 138,695 条；质量审计门禁通过；官方竞彩库保持 0 条，正式推荐保持关闭。

## Football AI 1.0.0-alpha.11 - 2026-07-15

- 登记中国体育彩票移动端、桌面端 SPF/RQSPF 页面及官方赛果入口。
- 验证移动端在普通浏览器与 Chrome 环境均被 EdgeOne 安全策略拦截，未取得可审计的动态赔率载荷。
- 明确搜索缓存只能用于确认页面性质，不能作为赔率快照或历史回测数据。
- 新增 Rule018，规定官方站点受限时的合规采集边界和可接受来源。

## Football AI 1.0.0-alpha.10 - 2026-07-15

- 建立中国竞彩SPF、RQSPF、比分、进球数和半全场长表标准。
- 实现未来赛程注册与确定性MatchID生成。
- 实现官方来源、快照时间、赔率范围、玩法选择完整性和重复快照校验。
- 增加中国竞彩与欧洲赔率来源区分，报告可单独计算竞彩SPF返还率。
- 正式竞彩库保持0条；测试赔率只允许ValidateOnly，不进入数据库。
- 新增 Rule017，禁止欧洲或测试数据冒充中国竞彩官方赔率。

## Football AI 1.0.0-alpha.9 - 2026-07-15

- 在运行前固定75%市场/25%泊松融合、3%EV和四分之一凯利规则。
- 完成13联赛10,362注回测，固定单位ROI -19.440%。
- 凯利账户合计由1,300降至467.434，收益率 -64.044%。
- 修复PowerShell数值重载导致凯利下注比例被错误归零的问题，并新增非零下注与2%上限断言。
- 13联赛全部未通过，融合与凯利模型保持candidate。
- 新增 Rule016，禁止以正模型EV替代真实收益验证。

## Football AI 1.0.0-alpha.8 - 2026-07-15

- 在运行前固定AI评分、信心指数和冷门指数的独立门禁。
- 使用26,373场validated联赛滚动预测完成校准。
- AI评分通过：ECE 1.79%，最高四分位准确率64.65%。
- 信心指数通过：AUC 0.6159，最高四分位提升15.14个百分点。
- 冷门指数未通过跨联赛与ECE门禁，继续保持candidate。
- 自动报告改用已测试的冷门定义，并分别披露三个指标状态。
- 新增 Rule015，禁止指标间相互替代验证。

## Football AI 1.0.0-alpha.7 - 2026-07-15

- 实现1X2开盘与收盘去水概率迁移模型。
- 在运行前固定2个百分点迁移阈值及准确率/ROI双门禁。
- 完成9,480个信号回测，总ROI -5.181%，13联赛全部未通过。
- 禁止将聚合赔率变化解释成庄家主观意图或诱盘。
- 新增 Rule014，规范庄家行为模型的证据边界。

## Football AI 1.0.0-alpha.6 - 2026-07-15

- 在首次收益回测前固定大小2.5球策略协议和门禁。
- 完成13联赛15,253注固定单位回测，总ROI -7.256%。
- 13联赛全部未通过，大小球策略保持 candidate。
- 对账逐注净收益与汇总盈亏，差异为0。
- 新增 Rule013，禁止以概率命中率代替真实赔率ROI验证。

## Football AI 1.0.0-alpha.5 - 2026-07-15

- 实现亚洲盘口整数、半球和四分之一盘结算。
- 支持 WIN、HALF_WIN、PUSH、HALF_LOSS、LOSS 和真实净收益。
- 在查看结果前固定3%模型EV阈值与95%置信下界门禁。
- 完成13联赛16,904注滚动回测，总ROI -4.824%，无联赛通过。
- 荷甲轻微正ROI未达显著性门槛，保持 candidate。
- 新增 Rule012，禁止用普通胜负替代亚洲盘口真实结算。

## Football AI 1.0.0-alpha.4 - 2026-07-15

- 审计156个归档CSV并发现系统性错名、重复和40行伪扩展样本。
- 按内部 Div 与 SHA-256 去重，接入13个真实欧洲联赛、23,147场比赛。
- 标准化138,695条开/收盘1X2、大小球和亚洲盘口记录。
- 统一数据库扩展至83,659场，MatchID全部唯一，市场外键孤儿为0。
- 完成22,068场欧洲滚动回测；11联赛通过1X2基础门禁，E1/SC1未通过。
- 大小球仅登记诊断结果，未因事后观察结果升级模型状态。
- 新增 Rule011，禁止在文件名与内部数据冲突时按文件名盲目入库。

## Football AI 1.0.0-alpha.3 - 2026-07-15

- 实现单场研究分析入口和自动 Markdown 专业报告。
- 输出胜平负、让球胜平负、比分、总进球、冷门指数、AI评分、信心指数、参考公平赔率和风险提示九项结果。
- 增加赔率去水、返还率和实验性凯利比例章节。
- 增加 Rule009、Rule010，强制披露实验指标和报告可追溯信息。
- 修复 PowerShell 可空让球参数未生效的问题，并加入回归断言。
- 在没有 production 模型时，代码级强制 `FormalRecommendation=false`。

## Football AI 1.0.0-alpha.2 - 2026-07-15

- 固化回测协议和模型准入门槛，先定规则、后看结果。
- 实现纯 PowerShell 的 Dixon-Coles 泊松基线、欧赔去水与三分类评估指标。
- 完成 BRA/JPN/SWE 共 13,105 场历史预测的严格滚动回测。
- JPN、SWE 通过 candidate → validated 门禁；BRA 未通过并保持 candidate。
- 保留 MatchID 级逐场预测、参数、数据哈希和汇总结果。
- 验证三联赛市场基准均优于当前泊松基线，因此不升级至 production。

## Football AI 1.0.0-alpha.1 - 2026-07-15

- 建立首版标准化比赛、赔率和数据来源结构。
- 建立确定性 MatchID 规则与冲突校验。
- 接入 17 个联赛 CSV 的标准字段映射。
- 修正 JPN 源文件 `B36CA` 到标准字段 `B365CA` 的映射。
- 识别并排除与 `ROU.csv` 内容完全相同的 `ROU (1).csv`。
- 建立 Rule001-Rule006 初始规则库。
- 将外部文档中的四项回测声明登记为“待复现”，尚未批准为生产模型。
## Football AI 1.0.0-alpha.33

- 新增候选联赛分层参数接口 `Get-LeagueProfile`。
- 新增不下注门禁 `Get-AbstentionDecision`，覆盖样本不足、数据不完整、概率分离不足和模型/市场冲突。
- 新增第一阶段优化协议，明确初盘与即时盘分离及严格滚动回测要求。
- 新增 Rule029–Rule031；所有新增能力继续保持非生产状态。
## Football AI 1.0.0-alpha.34

- ColdHunter 1.1 candidate interface: decomposes favorite non-win into draw and opponent-win risk.
- Adds multi-company agreement, movement-against-favorite and lineup-uncertainty adjustments.
- Keeps FormalRecommendation=false pending rolling backtest and calibration gates.
## Football AI 1.0.0-alpha.35

- Added USA MLS and Norway Eliteserien sample-quality audit.
- Confirmed complete standardized results and 1X2 close-odds coverage, while keeping both leagues outside production validation until league-specific backtests and extended markets are available.
## Football AI 1.0.0-alpha.36

- Added the Crazy Red List Chinese-handicap parsing protocol.
- Added Rule057–Rule060 for Chinese-label precedence, same-company initial/current pairing, water-only movement handling, and missing-field abstention.
- Kept the protocol at parsing/quality-control level; no unbacktested market model was promoted.

## Football AI 1.0.0-alpha.37

- Added executable Chinese Crazy Red List quality validation and a CSV transcription template.
- Validation checks Chinese-label semantics, same-company initial/current pairing, identity fields, water values, source hash and duplicate rows.
- Validation remains a data gate; it does not promote screenshots into training or production.
## Football AI 1.0.0-alpha.44 - 2026-07-19

- Added a reproducible eight-match postmortem generator with verified outcomes, settlement records and source references.
- Added the 2026-07-18 postmortem report and synchronized its outcome records into the tracking database.
- Added the latest user preference: persist corrections, prediction context, market data, final result and P/L rather than rely on chat memory.
- Kept the postmortem leakage-safe: verified outcomes are audit-only and never enter pre-match feature generation.
