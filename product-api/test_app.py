import importlib
import os


def make_client(tmp_path):
    os.environ["DB_PATH"] = str(tmp_path / "test.db")
    import app as module
    importlib.reload(module)
    return module.app.test_client()


def test_health(tmp_path):
    res = make_client(tmp_path).get("/api/products/health")
    assert res.status_code == 200
    assert res.get_json()["status"] == "ok"


def test_list_products(tmp_path):
    res = make_client(tmp_path).get("/api/products")
    assert res.status_code == 200
    assert len(res.get_json()["items"]) == 3


def test_get_missing_product(tmp_path):
    res = make_client(tmp_path).get("/api/products/999")
    assert res.status_code == 404
