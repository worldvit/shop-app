"""product-api: 상품 목록 서비스 (Flask + SQLite)"""
import os
import sqlite3

from flask import Flask, g, jsonify

APP_VERSION = os.environ.get("APP_VERSION", "v1")
DB_PATH = os.environ.get("DB_PATH", "/tmp/products.db")

SEED = [
    (1, "키보드", 39000),
    (2, "마우스", 19000),
    (3, "모니터", 189000),
]


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db


def init_db():
    db = sqlite3.connect(DB_PATH)
    db.execute("CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
    if db.execute("SELECT COUNT(*) FROM products").fetchone()[0] == 0:
        db.executemany("INSERT INTO products VALUES (?, ?, ?)", SEED)
    db.commit()
    db.close()


def create_app():
    app = Flask(__name__)
    init_db()

    @app.teardown_appcontext
    def close_db(_exc):
        db = g.pop("db", None)
        if db is not None:
            db.close()

    @app.after_request
    def add_version(resp):
        resp.headers["X-App-Version"] = APP_VERSION
        return resp

    @app.get("/api/products/health")
    def health():
        return jsonify(status="ok", service="product-api", version=APP_VERSION)

    @app.get("/api/products")
    def list_products():
        # 장애 훈련용 스위치: 환경 변수 BREAK_PRODUCTS=1이면 헬스 체크는 정상인데 상품 API만 500 응답
        if os.environ.get("BREAK_PRODUCTS") == "1":
            return jsonify(error="장애 훈련용 오류"), 500
        rows = get_db().execute("SELECT id, name, price FROM products ORDER BY id").fetchall()
        return jsonify(version=APP_VERSION, items=[dict(r) for r in rows])

    @app.get("/api/products/<int:pid>")
    def get_product(pid):
        row = get_db().execute("SELECT id, name, price FROM products WHERE id = ?", (pid,)).fetchone()
        if row is None:
            return jsonify(error="not found"), 404
        return jsonify(dict(row))

    return app


app = create_app()
