# 《云计算与大数据》课堂展示（加强版）
端到端：HDFS → Hive（CSV → ORC 分层）→ 数据质量检查 → 结果导出 → ECharts 静态网站 → GitHub Pages

环境
- Hadoop 2.10.2（已就绪）
- Hive 2.3.9（已就绪）
- WSL2 Ubuntu 22.04
- Python 3（仅用于生成静态页面）

一键运行
```bash
bash scripts/run_all.sh
```

完成后
- 本地预览：docs/index.html
- 发布：GitHub → Settings → Pages → 选择 main 分支的 /docs
- 提交 URL：例如 https://<你的用户名>.github.io/bigdata-hive-e2e-pro/

数据与分析
- 数据集：tips.csv（7 列、无版权风险）
- 表设计
  - demo.tips_csv：外部表，TEXT/CSV，跳过表头
  - demo.tips_orc：内部表，ORC（SNAPPY），分区字段 day，衍生列 tip_pct、is_weekend
- 指标
  - 不同工作日平均小费率（%）
  - 不同就餐人数（size）平均小费率（%）
  - day × time（Lunch/Dinner）热力图
  - 概览：样本量、整体平均小费率
- 数据质量（DQ）
  - 负数金额、负小费
  - tip_pct 越界（<0 或 >100）
  - 关键列空值
  - 违规即在控制台警示；可设置 ALLOW_QUALITY_FAIL=1 跳过

课堂展示 1–2 分钟话术（可直接照读）
1. 环境与目标（10s）
   - “我在 Hadoop 2.10.2 + Hive 2.3.9 伪分布式上做了端到端分析，并自动生成可公开访问的可视化网页。”
2. 数据与建模（20s）
   - “CSV 外部表只做落地；生产表转为 ORC+SNAPPY，并按 day 分区，同时计算衍生字段 tip_pct、is_weekend，便于后续聚合与压缩加速。”
3. 指标与质量（20s）
   - “这里是 DQ 检查结果；若有越界/空值将直接告警。聚合指标包括按工作日、就餐人数，以及 day×time 的热力图。”
4. 结果页（10–20s）
   - “这是静态 ECharts 页面，可交互浏览；仓库通过 GitHub Pages 发布，任何人可在线复现。”
5. 链接（5s）
   - “演示代码与网页地址已提交在作业链接中。”

常见问题
- OpenCSVSerde：Hive 2.3.9 自带 `org.apache.hadoop.hive.serde2.OpenCSVSerde`
- 权限问题：若 LOCAL DIRECTORY 导出失败，请确保本地目录可写：`mkdir -p out && chmod -R 777 out`
- Hive 卡住：先确认 HDFS/YARN 已启动；`hdfs dfs -ls /` 正常返回
