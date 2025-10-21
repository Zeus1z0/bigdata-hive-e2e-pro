-- 外部表（CSV 原始层）
USE demo;

DROP TABLE IF EXISTS tips_csv;
CREATE EXTERNAL TABLE tips_csv(
  total_bill DOUBLE,
  tip DOUBLE,
  sex STRING,
  smoker STRING,
  day STRING,
  time STRING,
  size INT
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  "separatorChar" = ",",
  "quoteChar" = "\"",
  "escapeChar" = "\\"
)
STORED AS TEXTFILE
LOCATION '/projects/tips/raw'
TBLPROPERTIES("skip.header.line.count"="1");
