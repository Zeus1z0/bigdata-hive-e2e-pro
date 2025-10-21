-- 初始化：数据库与常用参数
CREATE DATABASE IF NOT EXISTS demo;
USE demo;

-- 打印更干净
SET hive.cli.print.header=true;

-- 允许动态分区
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

-- 本地导出格式更可控
SET hive.resultset.use.unique.column.names=false;
