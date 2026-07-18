from pathlib import Path
import sqlite3

ROOT = Path(__file__).resolve().parents[1]
db_path = ROOT / "data" / "football_ai_tracking.sqlite"
schema = (ROOT / "data" / "schema.sql").read_text(encoding="utf-8")
with sqlite3.connect(db_path) as conn:
    conn.executescript(schema)
    conn.execute("INSERT OR IGNORE INTO user_preferences(preference_id, recorded_at, category, preference_text, source, applied_to_version) VALUES (?, datetime('now'), ?, ?, ?, ?)", ("Pref001", "workflow", "每次完成分析后必须写入偏好、预测、赔率、赛果和盈亏数据库；不得仅依赖对话记忆。", "user", "Football AI Pro 3.0"))
    conn.commit()
print(db_path)
