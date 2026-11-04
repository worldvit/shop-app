import importlib
import os


def make_client(tmp_path):
    os.environ["DB_PATH"] = str(tmp_path / "test.db")
    import app as module
    importlib.reload(module)
    return module.app.test_client()


def test_health(tmp_path):
    res = make_client(tmp_path).get("/api/orders/health")
    assert res.status_code == 200
    assert res.get_json()["status"] == "ok"


def test_create_and_list_order(tmp_path):
    client = make_client(tmp_path)
    res = client.post("/api/orders", json={"product_id": 1, "qty": 2})
    assert res.status_code == 201
    assert len(client.get("/api/orders").get_json()["items"]) == 1


def test_reject_bad_order(tmp_path):
    res = make_client(tmp_path).post("/api/orders", json={"qty": 0})
    assert res.status_code == 400
