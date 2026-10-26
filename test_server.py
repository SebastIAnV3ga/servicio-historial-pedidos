import json
import os
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer

import server


class ApiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        fd, cls.path = tempfile.mkstemp(suffix=".db")
        os.close(fd)
        os.remove(cls.path)
        server.DB_PATH = cls.path
        server.init_db()
        cls.httpd = ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
        cls.base = f"http://127.0.0.1:{cls.httpd.server_address[1]}"
        threading.Thread(target=cls.httpd.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()
        cls.httpd.server_close()
        if os.path.exists(cls.path):
            os.remove(cls.path)

    def call(self, method, path, body=None):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base + path, data=data, method=method,
                                     headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req) as r:
                return r.status, json.loads(r.read())
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read())

    def test_health(self):
        self.assertEqual(self.call("GET", "/health")[0], 200)

    def test_listar_por_usuario_y_orden(self):
        s, d = self.call("GET", "/api/historial?usuario_id=1")
        self.assertEqual(s, 200)
        self.assertEqual(d["total"], 3)
        fechas = [p["fecha"] for p in d["pedidos"]]
        self.assertEqual(fechas, sorted(fechas, reverse=True))

    def test_filtros(self):
        _, d = self.call("GET", "/api/historial?estado=cancelado")
        self.assertTrue(all(p["estado"] == "cancelado" for p in d["pedidos"]))
        _, d = self.call("GET", "/api/historial?q=Florero")
        self.assertEqual([p["id"] for p in d["pedidos"]], ["PED-1003"])
        _, d = self.call("GET", "/api/historial?usuario_id=1&desde=2026-10-01&hasta=2026-10-10")
        self.assertEqual([p["id"] for p in d["pedidos"]], ["PED-1003"])

    def test_detalle(self):
        s, d = self.call("GET", "/api/historial/PED-1001")
        self.assertEqual(s, 200)
        self.assertEqual(len(d["items"]), 2)
        self.assertEqual(d["total"], 580.0)
        self.assertEqual(self.call("GET", "/api/historial/NOEXISTE")[0], 404)

    def test_crear_y_cambiar_estado(self):
        body = {"id": "PED-T1", "usuario_id": "9",
                "items": [{"sku": "A", "nombre": "Algo", "cantidad": 2, "precio_unitario": 10}]}
        s, d = self.call("POST", "/api/historial", body)
        self.assertEqual(s, 201)
        self.assertEqual(d["total"], 20.0)
        self.assertEqual(d["estado"], "pendiente")
        self.assertEqual(self.call("POST", "/api/historial", body)[0], 409)
        s, d = self.call("PUT", "/api/historial/PED-T1/estado", {"estado": "enviado", "tracking": "TRK1"})
        self.assertEqual(s, 200)
        self.assertEqual(d["tracking"], "TRK1")
        self.assertEqual([e["estado"] for e in d["eventos"]], ["pendiente", "enviado"])

    def test_validaciones(self):
        self.assertEqual(self.call("POST", "/api/historial", {"id": "X"})[0], 400)
        mal = {"id": "X2", "usuario_id": "1", "items": [{"sku": "A", "cantidad": 0, "precio_unitario": 1}]}
        self.assertEqual(self.call("POST", "/api/historial", mal)[0], 400)
        self.assertEqual(self.call("PUT", "/api/historial/PED-1001/estado", {"estado": "volando"})[0], 400)
        self.assertEqual(self.call("PUT", "/api/historial/NOEXISTE/estado", {"estado": "pagado"})[0], 404)

    def test_resumen(self):
        s, d = self.call("GET", "/api/historial/resumen?usuario_id=2")
        self.assertEqual(s, 200)
        self.assertEqual(d["pedidos"], 2)
        self.assertEqual(d["total_gastado"], 510.0)  # el cancelado no cuenta
        self.assertEqual(self.call("GET", "/api/historial/resumen")[0], 400)


if __name__ == "__main__":
    unittest.main()
