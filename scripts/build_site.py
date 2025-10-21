#!/usr/bin/env python3
import argparse, os, json, csv, time, shutil
from collections import defaultdict, OrderedDict

def read_dir_csv(dir_path, headers=None):
    rows = []
    if not os.path.isdir(dir_path): return rows
    for fn in os.listdir(dir_path):
        if fn.startswith("_"): continue
        fp = os.path.join(dir_path, fn)
        if os.path.isdir(fp): continue
        with open(fp, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            for r in reader:
                if not r: continue
                rows.append(r)
    return rows

def load_by_day(path):
    # day, avg_tip_pct, stddev_tip_pct, n
    rows = read_dir_csv(path)
    # 维持 Hive 排序（已按 avg_tip_pct DESC）
    data = [{"day": r[0], "avg_tip_pct": float(r[1]), "stddev_tip_pct": float(r[2]), "n": int(r[3])} for r in rows]
    return data

def load_by_size(path):
    rows = read_dir_csv(path)
    data = [{"size": int(r[0]), "avg_tip_pct": float(r[1]), "n": int(r[2])} for r in rows]
    return data

def load_heatmap(path):
    rows = read_dir_csv(path)
    # 期望维度顺序
    day_order = ["Thur","Fri","Sat","Sun"]
    time_order = ["Lunch","Dinner"]
    # collect
    grid = {(d,t): {"avg":0.0,"n":0} for d in day_order for t in time_order}
    for r in rows:
        d, t, avg, n = r[0], r[1], float(r[2]), int(r[3])
        if d in day_order and t in time_order:
            grid[(d,t)] = {"avg": avg, "n": n}
    # 转为 ECharts 需要的 [xIndex, yIndex, value]
    data = []
    for yi, t in enumerate(time_order):
        for xi, d in enumerate(day_order):
            data.append([xi, yi, grid[(d,t)]["avg"]])
    return {"x": day_order, "y": time_order, "values": data}

def load_summary(path):
    rows = read_dir_csv(path)
    d = {}
    for k,v in rows:
        try:
            d[k] = float(v) if k=="avg_tip_pct" else int(v)
        except:
            d[k] = v
    return d

def ensure_assets(assets_dir):
    os.makedirs(assets_dir, exist_ok=True)
    # 写一个简单 CSS
    css = """
    :root { --bg:#0b1020; --fg:#e9eefb; --muted:#9fb3c8; --card:#151b33; }
    html,body{margin:0;padding:0;background:var(--bg);color:var(--fg);font-family:Inter,system-ui,Segoe UI,Helvetica,Arial;}
    a{color:#6ea8fe}
    .wrap{max-width:1080px;margin:24px auto;padding:0 16px;}
    .grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;}
    .card{background:var(--card);padding:16px;border-radius:10px;box-shadow:0 2px 14px rgba(0,0,0,.25)}
    h1{font-size:24px;margin:8px 0 16px}
    h2{font-size:18px;margin:0 0 12px;color:var(--muted)}
    .kpis{display:flex;gap:16px;flex-wrap:wrap}
    .kpi{background:#0f1630;border-radius:8px;padding:12px 16px;min-width:160px}
    .muted{color:var(--muted)}
    footer{margin:24px 0;color:var(--muted);font-size:12px}
    """
    with open(os.path.join(assets_dir, "style.css"), "w", encoding="utf-8") as f:
        f.write(css)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--by-day", required=True)
    ap.add_argument("--by-size", required=True)
    ap.add_argument("--heatmap", required=True)
    ap.add_argument("--summary", required=True)
    ap.add_argument("--template", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--assets-dir", required=True)
    args = ap.parse_args()

    by_day = load_by_day(args.by_day)
    by_size = load_by_size(args.by_size)
    heatmap = load_heatmap(args.heatmap)
    summary = load_summary(args.summary)
    data = {
        "byDay": by_day,
        "bySize": by_size,
        "heatmap": heatmap,
        "summary": summary,
        "generatedAt": time.strftime("%Y-%m-%d %H:%M:%S")
    }

    with open(args.template, "r", encoding="utf-8") as f:
        html = f.read()
    html = html.replace("__DATA_JSON__", json.dumps(data, ensure_ascii=False))

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(html)

    ensure_assets(args.assets_dir)

    # 额外：把 CSV 结果复制到 docs/assets 方便下载
    for name, srcdir in [("by_day.csv", args.by_day), ("by_size.csv", args.by_size), ("heatmap.csv", args.heatmap), ("summary.csv", args.summary)]:
        target = os.path.join(args.assets_dir, name)
        with open(target, "w", encoding="utf-8") as out:
            for fn in os.listdir(srcdir):
                if fn.startswith("_"): continue
                fp = os.path.join(srcdir, fn)
                if os.path.isdir(fp): continue
                with open(fp, "r", encoding="utf-8") as f:
                    out.write(f.read())
    print(f"Wrote {args.out}")

if __name__ == "__main__":
    main()
