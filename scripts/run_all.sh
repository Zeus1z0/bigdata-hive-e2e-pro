#!/usr/bin/env bash
set -euo pipefail

# -------- Config --------
DATA_URL="https://raw.githubusercontent.com/mwaskom/seaborn-data/master/tips.csv"
LOCAL_DATA_DIR="data"
LOCAL_DATA_FILE="${LOCAL_DATA_DIR}/tips.csv"
HDFS_DATA_DIR="/projects/tips/raw"
OUT_DIR="out"
DOCS_DIR="docs"
TEMPLATE="templates/index.template.html"

# -------- Helpers --------
log() { echo "[`date +'%F %T'`] $*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 1; }; }

# -------- Prechecks --------
need_cmd hive
need_cmd hdfs
need_cmd sed
need_cmd awk
need_cmd python3

mkdir -p "${LOCAL_DATA_DIR}" "${OUT_DIR}"

log "Step 0: Ensure Hadoop/Hive are up (you should have started dfs & yarn). Quick ping:"
set +e
hdfs dfs -ls / >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: HDFS not reachable. Run: start-dfs.sh && start-yarn.sh"
  exit 1
fi
set -e

# -------- Step 1: Fetch dataset --------
if [ ! -s "${LOCAL_DATA_FILE}" ]; then
  log "Downloading dataset -> ${LOCAL_DATA_FILE}"
  wget -q -O "${LOCAL_DATA_FILE}" "${DATA_URL}"
else
  log "Dataset exists -> ${LOCAL_DATA_FILE}"
fi

# -------- Step 2: Put to HDFS --------
log "Uploading to HDFS -> ${HDFS_DATA_DIR}"
hdfs dfs -mkdir -p "${HDFS_DATA_DIR}"
hdfs dfs -put -f "${LOCAL_DATA_FILE}" "${HDFS_DATA_DIR}/tips.csv"

# -------- Step 3: Hive DDL + ETL --------
log "Running Hive initialization and table creation"
hive -S -f sql/00_init.sql
hive -S -f sql/10_ext_create.sql
hive -S -f sql/20_orc_create_load.sql

# -------- Step 4: Data Quality Checks --------
log "Running data quality checks"
hive -S -f sql/15_quality_checks.sql

# Parse DQ results (CSV: check,violations)
dq_total=$(cat out/quality/* 2>/dev/null | awk -F',' '{sum+=$2} END{print sum+0}')
if [ "${dq_total}" -gt 0 ]; then
  echo "============================================================"
  echo "DATA QUALITY ALERT: Found ${dq_total} violation(s). Details:"
  cat out/quality/* || true
  echo "============================================================"
  if [ "${ALLOW_QUALITY_FAIL:-0}" -ne 1 ]; then
    echo "Failing the pipeline (set ALLOW_QUALITY_FAIL=1 to ignore)."
    exit 2
  fi
fi

# -------- Step 5: Analyses & Export --------
log "Running analyses and exporting results to ${OUT_DIR}/"
hive -S -f sql/30_analyses.sql

# -------- Step 6: Build static site --------
log "Generating static site"
mkdir -p "${DOCS_DIR}"
python3 scripts/build_site.py \
  --by-day "${OUT_DIR}/by_day" \
  --by-size "${OUT_DIR}/by_size" \
  --heatmap "${OUT_DIR}/heatmap" \
  --summary "${OUT_DIR}/summary" \
  --template "${TEMPLATE}" \
  --out "${DOCS_DIR}/index.html" \
  --assets-dir "${DOCS_DIR}/assets"

log "Done."
echo "Open file://${PWD}/${DOCS_DIR}/index.html"
echo "Then publish GitHub Pages (main branch /docs)."
