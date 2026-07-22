# Football AI Pro 规则库

| 编号 | 状态 | 规则 |
|---|---|---|
| Rule001 | 生效 | 所有推荐必须可追溯到输入数据与模型版本，禁止凭感觉推荐。 |
| Rule002 | 生效 | 每场历史比赛必须生成唯一、确定性的 MatchID；冲突时导入失败。 |
| Rule003 | 生效 | 未通过可复现历史回测门禁的模型不得进入 production。 |
| Rule073 | 生效 | 当前赛前方向以可核验的临场市场赔率为唯一方向依据；时间较久或不匹配的历史样本只用于赛后审计，不得反转或重新加权当前推荐。 |
| Rule074 | 生效 | 让球必须按净胜球严格结算；主让一球时，主胜一球为让平、主胜两球以上为让胜、平局或客胜为让负。标准胜平负与让球结果集冲突时，不得同时输出为可执行推荐。 |
| Rule075 | 生效 | 让球盘面研究标签必须区分“一球小胜”和“客队两球以上胜出”：盘口支持主队小胜时写盘面倾向让平，明确支持客队净胜两球以上时才写盘面倾向让负，无法区分时写不设盘面方向；研究标签不得替代正式推荐，独立净胜球分布不可审计时仍必须 HANDICAP_DECISION=SKIP。 |
| Rule004 | 生效 | 缺失盘口数据时对应玩法输出 unavailable，并给出缺失原因。 |
| Rule005 | 生效 | 分析报告必须包含九项默认输出和规定的逐场分析章节。 |
| Rule006 | 生效 | 任何字段修正必须发生在标准化层，原始来源文件不得静默修改。 |
| Rule007 | 生效 | 回测协议、评价指标和准入阈值必须在查看本轮结果前确定，禁止结果导向调参。 |
| Rule008 | 生效 | 当市场基准显著优于模型时必须披露，模型不得仅凭通过基础门禁升级为 production。 |
| Rule009 | 生效 | 冷门指数、AI评分和信心指数在独立回测前必须标记为实验性展示指标，不得解释为历史命中率。 |
| Rule010 | 生效 | 自动报告必须披露模型状态、数据截止时间、缺失市场、参数、数据哈希和是否构成正式推荐。 |
| Rule011 | 生效 | 来源文件名与内部联赛字段冲突时不得按文件名入库；必须以内部字段、内容哈希和比赛身份审计后决定。 |
| Rule012 | 生效 | 亚洲四分之一盘口必须拆分结算并记录半赢、半输、走盘；不得用普通胜负替代真实收益。 |
| Rule013 | 生效 | 大小球策略必须使用实际市场赔率结算并按联赛报告收益置信区间；概率命中率不得代替ROI门禁。 |
| Rule014 | 生效 | 开盘—收盘变化只能称为市场概率迁移；没有独立证据时不得解释为庄家意图、诱盘或内幕信号。 |
| Rule015 | 生效 | AI评分、信心指数和冷门指数必须分别通过校准或排序门禁；一个指标通过不得替其他指标背书。 |
| Rule016 | 生效 | 凯利比例只能使用经校准概率并必须经过资金曲线回测；正模型EV不得直接视为真实市场优势。 |
| Rule017 | 生效 | 中国竞彩赔率必须保存官方场次、快照时间、销售状态和来源；欧洲赔率、测试赔率或估算值不得冒充官方数据。 |
| Rule018 | 生效 | 官方站点访问受限时不得绕过安全防护或以搜索缓存代替原始赔率；仅允许可审计的官方接口、导出文件或含场次号与采集时间的官方截图进入正式竞彩库。 |
| Rule019 | 生效 | 缺少有效比赛日期、逐行来源或存在异常比赛统计的历史样本必须留在隔离层；分片副本不得重复计数，未经身份核验不得生成正式 MatchID 或参与训练回测。 |
| Rule020 | 生效 | 中国竞彩正式赔率导入必须关联已登记的证据快照；证据快照须保留采集时间、来源地址和内容哈希，导入时启用证据校验。 |
| Rule021 | 生效 | 单场赛前上下文样本必须使用唯一 MatchID、比赛日期和逐行来源，并标注 `CONTEXT_ONLY_NOT_TRAINING`；未经独立历史回测，不得进入训练集、回测集、AI评分、信心指数或正式推荐。 |
| Rule022 | 生效 | 默认交付采用“双层输出”：聊天屏只保留每场比赛的重点汇总、最终方向、核心盘口与主要风险；完整数据、模型交叉验证、盘口明细、比分与进球数推演必须生成独立报告文档交付。用户明确要求在聊天屏展开时除外。 |
| Rule023 | 生效 | 正式回测、模型输入和正式推荐只接收可追溯的一手数据：赛事信息与赛果须来自赛事主办方或其正式数据接口；盘口须来自目标公司原始页面/API或经授权的可审计数据供应商，并保留采集时间、原始内容、URL与哈希。用户明确确认可靠的截图可作为 `USER_CERTIFIED_CONTEXT` 用于单场临场分析，并保留原图、接收时间和用户确认记录；但未具备原始URL/API与完整历史序列时，不得进入长期训练、历史回测或被表述为独立可复核的100%官方数据。 |
| Rule024 | 生效 | 读取球探网亚洲盘表时必须先转换为统一主队视角：中间盘值为正表示主队让球，标准化为主队负让球；中间盘值为负表示客队让球，标准化为主队正受让。例：`0.5/1`→主队-0.75，`-0.5/1`→主队+0.75。转换后必须与1X2强弱方向交叉校验，出现矛盾时停止输出并复核。 |
| Rule025 | 生效 | 所有原始归档文件必须生成路径、文件类型、字节数与 SHA-256 哈希清单；归档清单只证明保留和可追溯，不构成训练、回测或正式推荐的准入许可。 |
| Rule026 | 生效 | 版本号与开发日志只能作为发布元数据；优先使用存在 Git 可执行程序、HEAD 和对象数据库的可审计提交链。Git 暂不可用时，可使用经 SHA-256 校验、含父版本哈希与文件树哈希的发布账本作为降级版本控制证据；两者均不存在时必须标记为 unavailable。 |
| Rule027 | 生效 | 每个发布账本条目必须记录版本、UTC时间、父条目哈希、受控文件树哈希和条目哈希；审计时必须验证整条哈希链、当前版本与当前文件树。任何不一致均禁止声明版本控制有效。 |
| Rule028 | 生效 | 中国足彩网等第三方页面抓取的历史竞彩赔率必须记录页面地址、选择日期、采集时间、字段完整率和来源性质；在与官方原始证据交叉核验前，只能作为 `THIRD_PARTY_CANDIDATE_CONTEXT`，不得进入正式竞彩回测或 production。 |
| Rule029 | ACTIVE | League-specific parameters must be isolated and generic fallbacks must remain candidate-only. |
| Rule030 | ACTIVE | Opening and live markets must be stored separately; live movement requires multi-source and fundamental confirmation. |
| Rule031 | ACTIVE | Abstention gates take precedence over recommendations when sample, completeness, separation, or model-market agreement is insufficient. |
| Rule032 | ACTIVE | ColdHunter decomposes favorite non-win into draw risk and opponent-win risk; cold signals require multi-company consensus and remain candidate-only until rolling backtest approval. |
| Rule033 | CANDIDATE | When an exact target-bookmaker Asian quote cannot be independently audited, the Asian conclusion must be expressed as direction, available multi-book market snapshot, and an abstention threshold; it must not claim an exact target-bookmaker price, initial line, live movement, or Kelly signal. |
| Rule034 | ACTIVE | China Sports Lottery and Asian Handicap are separate output markets. A China Sports Lottery ticket may combine only 1X2 and handicap 1X2 selections. Global multi-book European odds and Asian Handicap data must be used as independent cross-validation inputs for both outputs, but must never be presented as a China Sports Lottery selection or substituted for its official odds. |
| Rule035 | ACTIVE | Small-sample leagues use hierarchical shrinkage toward a documented global/competition baseline; league-specific evidence may adjust the baseline only in proportion to effective sample size. |
| Rule036 | ACTIVE | A league or market with insufficient independent samples remains `CANDIDATE` or `SHADOW`; it may generate paper predictions but cannot enter production recommendations. |
| Rule037 | ACTIVE | Small-sample performance must be evaluated with walk-forward expanding windows and uncertainty intervals; a short positive run cannot pass the profitability or hit-rate gate. |
| Rule038 | ACTIVE | Until a market passes its gate, all predictions must be paper-tracked with timestamp, odds, outcome, calibration error, hit rate, ROI and maximum drawdown. |
| Rule039 | ACTIVE | For hit-rate optimization, an abstention threshold is mandatory: when calibrated top-choice probability advantage is below the configured margin or inputs conflict, output no recommended selection. |
| Rule040 | ACTIVE | No new feature, rule or league parameter may be promoted because of a single match or short sample; promotion requires a predeclared out-of-sample comparison against the market baseline. |
| Rule041 | CANDIDATE | An AI-score threshold of 70 is a pre-registered hit-rate screening experiment only; it must be tested on the next time-out window with coverage and abstention rate before use in recommendations. |
| Rule042 | ACTIVE | AI score and market favorite information must be evaluated in separate strata to detect duplicate market counting; a high score that adds no out-of-sample value cannot upgrade a recommendation. |
| Rule043 | ACTIVE | Every hit-rate experiment must report coverage and abstention rate alongside accuracy; a model cannot claim improvement by selecting only a tiny favorable subset. |
| Rule044 | ACTIVE | Candidate thresholds must be frozen before the next evaluation window; changing the threshold after seeing outcomes is prohibited. |
| Rule045 | ACTIVE | Any claimed hit-rate improvement must beat the predeclared market-favorite baseline in the same league, date window and odds band. |
| Rule046 | ACTIVE | Hit-rate optimization must use calibrated probabilities first; raw AI score or confidence ranking cannot directly select a production outcome. |
| Rule047 | ACTIVE | A high hit rate with low coverage is a selective-screening result and must be reported separately from overall model accuracy. |
| Rule048 | ACTIVE | Thresholds, league weights and abstention rules are frozen before each out-of-sample window and may only be changed in a new version after audit. |
| Rule049 | ACTIVE | Any AI screening threshold with high overlap with the market favorite must be treated as a market-following screen until a market-ablated comparison proves independent gain. |
| Rule050 | ACTIVE | Multi-company odds screenshots must be parsed company-by-company; aggregate averages alone cannot establish a market consensus signal. |
| Rule051 | ACTIVE | A market-movement signal requires a recorded initial quote, current quote, timestamp and source company for each row; missing values must be marked unavailable rather than inferred. |
| Rule052 | ACTIVE | Synchronization is measured by company count and weighted company count. A single-company movement never increases recommendation weight. |
| Rule053 | ACTIVE | Crown, Bet365, Macau, William Hill and other companies must retain separate source identities and weights; no company may be silently merged into an average. |
| Rule054 | ACTIVE | Outlier prices and reverse movements must be reported separately; consensus direction and dispersion are both required in the final risk assessment. |
| Rule055 | ACTIVE | For Chinese Crazy Red List screenshots, Chinese handicap labels such as 主让、客让、受让、平手、初、即 are parsed directly as certified context; no symbol-sign conversion may override the displayed Chinese meaning. |
| Rule056 | ACTIVE | Direct Chinese labels reduce sign ambiguity but do not replace validation of home/away identity, market tab, initial/current columns, company row and snapshot time. |
| Rule057 | ACTIVE | Chinese Crazy Red List labels have semantic precedence over symbolized or third-party-transcribed handicap signs; conflicts are retained as review flags rather than silently converted. |
| Rule058 | ACTIVE | Initial and current quotes must be paired within the same company row and same market; cross-company pairing is prohibited. |
| Rule059 | ACTIVE | A water-price change without a confirmed handicap-level change is recorded only as water movement, never as an inferred line raise or drop. |
| Rule060 | ACTIVE | Missing or unreadable Chinese labels, market tabs, company identity, or home/away identity force `unavailable`/`REVIEW` and block a formal handicap recommendation. |
| Rule061 | ACTIVE | League samples must pass an automated quality gate before model use: result completeness, season count, date range, average/max 1X2 coverage and single-book coverage are reported separately; passing 1X2 research does not authorize Asian-handicap, totals or production use. |
| Rule062 | ACTIVE | Effective league sample size must exclude duplicate date/home/away keys; duplicate rate above 0.5% blocks 1X2 backtest eligibility until deduplication is audited. |
| Rule063 | ACTIVE | The English Premier League, La Liga, Serie A, Bundesliga and Ligue 1 are the first-priority league expansion set. A priority league may enter formal modeling only after its own MatchID sample, result data, opening/closing 1X2 odds and source-company coverage pass the quality gate; data from another league cannot substitute for a missing priority sample. |
| Rule064 | ACTIVE | An extended-market row whose Provider is `MarketAverage` is research context only; it cannot be reported as multi-company consensus or company-level movement until individual provider identity and timestamps are available. |
| Rule065 | ACTIVE | Structural validity, source authenticity and model eligibility are separate gates. A dataset with zero foreign keys and duplicate errors may still remain `SOURCE_AUTHENTICITY_PENDING` until provenance, independent cross-checks and market-provider identity are verified. |
| Rule066 | ACTIVE | Recommendation evaluation must separate hit rate from value: the market favorite is the primary hit-rate baseline, but a formal selection also requires odds-implied probability, calibrated model probability, coverage, risk and expected-value backtesting; China Sports Lottery handicap results must be modeled separately from standard 1X2. |
| Rule067 | ACTIVE | Postponed, abandoned or rescheduled matches are coded `VOID_POSTPONED` and excluded from hit-rate, Brier, LogLoss and profit denominators until an official final result exists. |
| Rule068 | ACTIVE | “防平/防负” coverage results must be reported separately from a single primary selection; a covered outcome cannot be presented as a single-outcome hit. |
| Rule069 | ACTIVE | European qualifying matches require competition, opponent canonical name and two-leg format validation before league samples or strength priors are applied. |
| Rule070 | ACTIVE | One-goal-margin matches are a separate Asian-handicap boundary class; -1/＋1 settlement must be calculated from the actual goal margin and not inferred from the 1X2 result. |
| Rule071 | ACTIVE | Derbies, cross-league qualifiers and large score/odds reversals receive an elevated cold-risk penalty unless synchronized multi-company movement and verified team news support the direction. |
| Rule072 | ACTIVE | Pre-match direction is market-led: de-vigged, time-stamped odds are the sole current directional input. Historical samples are retained for post-match audit and future validation, not for reversing or re-weighting a live direction; totals odds are a cross-check only. The independent JCZQ handicap layer must still calculate and strictly map the auditable goal-margin distribution to the actual line. Missing distribution, market conflict, insufficient edge, or a failed formal gate must produce an explicit observation or `HANDICAP_DECISION=SKIP`, never a forced selection. |
