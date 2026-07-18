足球分析框架完整备份 V3（最终版）
生成时间: 2026-06-23 01:16
用途: 断档恢复（直接发此包即可恢复全部数据+框架）

=== 文件清单 ===

【分析框架】（6个文件，terry提供）
framework.py                     - 分析框架主脚本 v2.3（去水+DC泊松+联赛修正+H2H+双选策略）
framework_v3.2.py                - 修正版 v3.2（碾压盘单选+双选优化）
knowledge_base.md                - 框架知识库 v2.3（标准模式+冷门猎手定义+复盘因子）
框架知识库_v2.3.md              - 知识库备用版本（内容一致）
mapping.json                     - 概率→预期进球映射表（18个离散点）
probability_to_goals_mapping.json - 映射表备用版本（内容一致）

【比赛数据】（5个文件）
matches_compact_part01~05.json  - 25,000场联赛比赛（含B365赔率、比分）

【球队信息】
teams_compact.json               - 1,459支球队（缩写ID如ARS/MUN）

【H2H历史交锋】（11个文件）
h2h_compact_part01~03.json      - 原始H2H（6,000条，26联赛，数字ID格式）
h2h_complete_v2_part01~07.json - 补充H2H统一版V2（13,247条，39联赛，球队全称格式）
h2h_complete_v2_summary.json     - H2H汇总报告（含联赛分布）
team_id_mapping_full.json        - 数字ID→球队全称映射表

【数据报告】
data_coverage.json               - 多联赛数据完整度统计（26个联赛）

=== 版本说明 ===
- V1: 仅数据文件，无框架
- V2: 补充框架文件（聊天记录中翻找）+ 数据 + H2H
- V3: 补充terry最新提供的 framework_v3.2.py + 知识库v2.3 + 映射表，框架完整

=== 使用说明 ===
1. 解压后将所有JSON和PY文件放在同一目录
2. framework.py 或 framework_v3.2.py 可直接运行分析
3. H2H数据供联赛分析使用，世界杯分析不适用
4. 断档后直接发此压缩包即可恢复全部
