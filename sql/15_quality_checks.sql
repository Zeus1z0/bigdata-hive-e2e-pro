-- 数据质量检查：生成本地 CSV（check,violations）
USE demo;

-- 输出目录：out/quality
INSERT OVERWRITE LOCAL DIRECTORY 'out/quality'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT x.check_name, x.violations FROM (
  SELECT 'negative_total_bill' AS check_name, COUNT(*) AS violations
    FROM tips_orc WHERE total_bill < 0
  UNION ALL
  SELECT 'negative_tip', COUNT(*) FROM tips_orc WHERE tip < 0
  UNION ALL
  SELECT 'tip_pct_out_of_range', COUNT(*) FROM tips_orc WHERE tip_pct < 0 OR tip_pct > 100
  UNION ALL
  SELECT 'null_essential', COUNT(*) FROM tips_orc
    WHERE total_bill IS NULL OR tip IS NULL OR day IS NULL OR time IS NULL OR size IS NULL
) x;
