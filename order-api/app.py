"""order-api: 주문 서비스 (Flask + SQLite)"""
import os
import sqlite3

from flask import Flask, g, jsonify, request

APP_VERSION = os.environ.get("APP_VERSION", "v1")
DB_PATH = os.environ.get("DB_PATH", "/tmp/orders.db")


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db


def init_db():
    db = sqlite3.connect(DB_PATH)
    db.execute("CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER, qty INTEGER)")
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

    @app.get("/api/orders/health")
    def health():
        return jsonify(status="ok", service="order-api", version=APP_VERSION)

    @app.get("/api/orders")
    def list_orders():
        rows = get_db().execute("SELECT id, product_id, qty FROM orders ORDER BY id").fetchall()
        return jsonify(version=APP_VERSION, items=[dict(r) for r in rows])

    @app.post("/api/orders")
    def create_order():
        data = request.get_json(silent=True) or {}
        product_id, qty = data.get("product_id"), data.get("qty", 1)
        if not isinstance(product_id, int) or not isinstance(qty, int) or qty < 1:
            return jsonify(error="product_id(정수)와 qty(1 이상)가 필요합니다"), 400
        db = get_db()
        cur = db.execute("INSERT INTO orders (product_id, qty) VALUES (?, ?)", (product_id, qty))
        db.commit()
        return jsonify(id=cur.lastrowid, product_id=product_id, qty=qty), 201

    return app


app = create_app()
