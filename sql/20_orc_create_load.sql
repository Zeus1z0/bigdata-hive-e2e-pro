-- 生产层（ORC + 分区 + 衍生字段）
USE demo;

DROP TABLE IF EXISTS tips_orc;
CREATE TABLE tips_orc(
  total_bill DOUBLE,
  tip DOUBLE,
  sex STRING,
  smoker STRING,
  time STRING,
  size INT,
  tip_pct DOUBLE,        -- 以百分数存储（0-100）
  is_weekend BOOLEAN
)
PARTITIONED BY (day STRING)
STORED AS ORC
TBLPROPERTIES ("orc.compress"="SNAPPY");

-- 动态分区装载
INSERT OVERWRITE TABLE tips_orc PARTITION (day)
SELECT
  total_bill,
  tip,
  sex,
  smoker,
  time,
  size,
  CASE WHEN total_bill>0 AND tip >= 0 THEN (tip/total_bill)*100 ELSE NULL END AS tip_pct,
  CASE WHEN day IN ('Sat','Sun') THEN true ELSE false END AS is_weekend,
  day
FROM demo.tips_csv;
