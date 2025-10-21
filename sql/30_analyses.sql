-- 分析与导出
USE demo;

-- 概览
INSERT OVERWRITE LOCAL DIRECTORY 'out/summary'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT 'rows' as metric, CAST(COUNT(*) AS STRING) FROM tips_orc
UNION ALL
SELECT 'avg_tip_pct', CAST(ROUND(AVG(tip_pct),2) AS STRING) FROM tips_orc WHERE tip_pct IS NOT NULL;

-- 按工作日
INSERT OVERWRITE LOCAL DIRECTORY 'out/by_day'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT day,
       ROUND(AVG(tip_pct),2) AS avg_tip_pct,
       ROUND(STDDEV_POP(tip_pct),2) AS stddev_tip_pct,
       COUNT(*) AS n
FROM tips_orc
GROUP BY day
ORDER BY avg_tip_pct DESC;

-- 按就餐人数
INSERT OVERWRITE LOCAL DIRECTORY 'out/by_size'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT size,
       ROUND(AVG(tip_pct),2) AS avg_tip_pct,
       COUNT(*) AS n
FROM tips_orc
GROUP BY size
ORDER BY size ASC;

-- day × time 热力图
INSERT OVERWRITE LOCAL DIRECTORY 'out/heatmap'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT day, time, ROUND(AVG(tip_pct),2) AS avg_tip_pct, COUNT(*) AS n
FROM tips_orc
GROUP BY day, time;
