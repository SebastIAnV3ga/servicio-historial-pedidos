"""Servicio 12 - Historial de Pedidos.

Solo Python 3 estandar: http.server + sqlite3. Sin instalar nada.
Guarda y consulta los pedidos ya realizados por cada usuario.
Puerto por defecto: 8012 (variable de entorno PORT).
"""
import json
import os
import sqlite3
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

BASE = os.path.dirname(os.path.abspath(__file__))
STATIC = os.path.join(BASE, "static")
DB_PATH = os.environ.get("HISTORIAL_DB", os.path.join(BASE, "historial.db"))
PORT = int(os.environ.get("PORT", 8012))

ESTADOS = ["pendiente", "pagado", "en_preparacion", "enviado",
           "entregado", "cancelado", "devuelto"]


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def ahora():
    return datetime.now().strftime("%Y-%m-%dT%H:%M:%S")


def init_db(sembrar=True):
    with get_db() as db:
        db.executescript("""
        CREATE TABLE IF NOT EXISTS pedidos (
            id TEXT PRIMARY KEY,
            usuario_id TEXT NOT NULL,
            fecha TEXT NOT NULL,
            estado TEXT NOT NULL,
            total REAL NOT NULL,
            direccion_envio TEXT,
            metodo_pago TEXT,
            tracking TEXT
        );
        CREATE TABLE IF NOT EXISTS pedido_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pedido_id TEXT NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
            sku TEXT NOT NULL,
            nombre TEXT,
            cantidad INTEGER NOT NULL,
            precio_unitario REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS pedido_eventos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pedido_id TEXT NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
            estado TEXT NOT NULL,
            fecha TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_pedidos_usuario ON pedidos(usuario_id, fecha);
        """)
        if sembrar and db.execute("SELECT COUNT(*) FROM pedidos").fetchone()[0] == 0:
            seed(db)


def seed(db):
    demo = [
        ("PED-1001", "1", "2026-09-02T10:15:00", "entregado", "Av. Reforma 120, Los Mochis", "tarjeta",
         [("SKU-001", "Taza de barro", 2, 120.0), ("SKU-004", "Plato hondo", 4, 85.0)]),
        ("PED-1002", "1", "2026-09-20T18:40:00", "enviado", "Av. Reforma 120, Los Mochis", "tarjeta",
         [("SKU-002", "Jarra artesanal", 1, 350.0)]),
        ("PED-1003", "1", "2026-10-10T09:05:00", "pagado", "Calle Hidalgo 45, Los Mochis", "paypal",
         [("SKU-003", "Florero", 1, 210.0), ("SKU-001", "Taza de barro", 1, 120.0)]),
        ("PED-1004", "2", "2026-10-15T13:20:00", "cancelado", "Blvd. Rosales 300, Culiacan", "tarjeta",
         [("SKU-005", "Cazuela", 1, 480.0)]),
        ("PED-1005", "2", "2026-10-22T16:00:00", "pendiente", "Blvd. Rosales 300, Culiacan", "transferencia",
         [("SKU-004", "Plato hondo", 6, 85.0)]),
    ]
    for pid, uid, fecha, estado, dire, pago, items in demo:
        total = sum(c * p for _, _, c, p in items)
        db.execute("INSERT INTO pedidos VALUES (?,?,?,?,?,?,?,?)",
                   (pid, uid, fecha, estado, total, dire, pago, None))
        db.executemany(
            "INSERT INTO pedido_items (pedido_id,sku,nombre,cantidad,precio_unitario) VALUES (?,?,?,?,?)",
            [(pid, s, n, c, p) for s, n, c, p in items])
        db.execute("INSERT INTO pedido_eventos (pedido_id,estado,fecha) VALUES (?,?,?)",
                   (pid, "pendiente", fecha))
        if estado != "pendiente":
            db.execute("INSERT INTO pedido_eventos (pedido_id,estado,fecha) VALUES (?,?,?)",
                       (pid, estado, fecha))


# ---------- logica ----------

class ApiError(Exception):
    def __init__(self, status, mensaje):
        super().__init__(mensaje)
        self.status = status
        self.mensaje = mensaje


def detalle(db, pedido_id):
    p = db.execute("SELECT * FROM pedidos WHERE id=?", (pedido_id,)).fetchone()
    if not p:
        raise ApiError(404, "Pedido no encontrado")
    d = dict(p)
    d["items"] = [dict(r) for r in db.execute(
        "SELECT sku,nombre,cantidad,precio_unitario FROM pedido_items WHERE pedido_id=? ORDER BY id",
        (pedido_id,))]
    d["eventos"] = [dict(r) for r in db.execute(
        "SELECT estado,fecha FROM pedido_eventos WHERE pedido_id=? ORDER BY id", (pedido_id,))]
    return d


def listar(params):
    where, args = [], []
    uid = params.get("usuario_id")
    if uid:
        where.append("p.usuario_id=?"); args.append(uid)
    estado = params.get("estado")
    if estado:
        where.append("p.estado=?"); args.append(estado)
    desde, hasta = params.get("desde"), params.get("hasta")
    if desde:
        where.append("p.fecha>=?"); args.append(desde)
    if hasta:
        where.append("p.fecha<=?"); args.append(hasta + "T23:59:59" if len(hasta) == 10 else hasta)
    q = params.get("q")
    if q:
        where.append("(p.id LIKE ? OR EXISTS (SELECT 1 FROM pedido_items i "
                     "WHERE i.pedido_id=p.id AND (i.nombre LIKE ? OR i.sku LIKE ?)))")
        like = f"%{q}%"
        args += [like, like, like]
    try:
        limit = max(1, min(int(params.get("limit", 20)), 100))
        page = max(1, int(params.get("page", 1)))
    except ValueError:
        raise ApiError(400, "page y limit deben ser numeros")
    cond = ("WHERE " + " AND ".join(where)) if where else ""
    with get_db() as db:
        total = db.execute(f"SELECT COUNT(*) FROM pedidos p {cond}", args).fetchone()[0]
        rows = db.execute(
            f"""SELECT p.*, COALESCE((SELECT SUM(cantidad) FROM pedido_items WHERE pedido_id=p.id),0) AS n_items
                FROM pedidos p {cond} ORDER BY p.fecha DESC, p.id DESC LIMIT ? OFFSET ?""",
            args + [limit, (page - 1) * limit]).fetchall()
    return {"total": total, "page": page, "limit": limit, "pedidos": [dict(r) for r in rows]}


def resumen(params):
    uid = params.get("usuario_id")
    if not uid:
        raise ApiError(400, "usuario_id es obligatorio")
    with get_db() as db:
        por_estado = {r["estado"]: r["n"] for r in db.execute(
            "SELECT estado, COUNT(*) n FROM pedidos WHERE usuario_id=? GROUP BY estado", (uid,))}
        gastado = db.execute(
            "SELECT COALESCE(SUM(total),0) FROM pedidos WHERE usuario_id=? AND estado NOT IN ('cancelado','devuelto')",
            (uid,)).fetchone()[0]
    return {"usuario_id": uid, "pedidos": sum(por_estado.values()),
            "total_gastado": gastado, "por_estado": por_estado}


def crear(data):
    if not isinstance(data, dict):
        raise ApiError(400, "Cuerpo JSON invalido")
    pid = str(data.get("id") or "").strip()
    uid = str(data.get("usuario_id") or "").strip()
    if not pid or not uid:
        raise ApiError(400, "id y usuario_id son obligatorios")
    estado = data.get("estado", "pendiente")
    if estado not in ESTADOS:
        raise ApiError(400, f"estado invalido. Validos: {', '.join(ESTADOS)}")
    items = data.get("items")
    if not isinstance(items, list) or not items:
        raise ApiError(400, "items debe ser una lista con al menos un producto")
    limpios = []
    for it in items:
        try:
            sku = str(it["sku"]).strip()
            cant = int(it["cantidad"])
            precio = float(it["precio_unitario"])
        except (KeyError, TypeError, ValueError):
            raise ApiError(400, "Cada item necesita sku, cantidad y precio_unitario")
        if not sku or cant <= 0 or precio < 0:
            raise ApiError(400, "Item con sku vacio, cantidad <= 0 o precio negativo")
        limpios.append((sku, it.get("nombre"), cant, precio))
    total = data.get("total")
    total = sum(c * p for _, _, c, p in limpios) if total is None else float(total)
    fecha = data.get("fecha") or ahora()
    with get_db() as db:
        if db.execute("SELECT 1 FROM pedidos WHERE id=?", (pid,)).fetchone():
            raise ApiError(409, "Ya existe un pedido con ese id")
        db.execute("INSERT INTO pedidos VALUES (?,?,?,?,?,?,?,?)",
                   (pid, uid, fecha, estado, total, data.get("direccion_envio"),
                    data.get("metodo_pago"), data.get("tracking")))
        db.executemany(
            "INSERT INTO pedido_items (pedido_id,sku,nombre,cantidad,precio_unitario) VALUES (?,?,?,?,?)",
            [(pid, *i) for i in limpios])
        db.execute("INSERT INTO pedido_eventos (pedido_id,estado,fecha) VALUES (?,?,?)", (pid, estado, fecha))
        return detalle(db, pid)


def cambiar_estado(pid, data):
    estado = (data or {}).get("estado")
    if estado not in ESTADOS:
        raise ApiError(400, f"estado invalido. Validos: {', '.join(ESTADOS)}")
    with get_db() as db:
        detalle(db, pid)  # 404 si no existe
        db.execute("UPDATE pedidos SET estado=? WHERE id=?", (estado, pid))
        if (data or {}).get("tracking"):
            db.execute("UPDATE pedidos SET tracking=? WHERE id=?", (data["tracking"], pid))
        db.execute("INSERT INTO pedido_eventos (pedido_id,estado,fecha) VALUES (?,?,?)", (pid, estado, ahora()))
        return detalle(db, pid)


# ---------- HTTP ----------

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, status, body, ctype="application/json; charset=utf-8"):
        raw = body if isinstance(body, bytes) else json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,PUT,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(raw)

    def _json_body(self):
        n = int(self.headers.get("Content-Length") or 0)
        try:
            return json.loads(self.rfile.read(n) or b"{}")
        except ValueError:
            raise ApiError(400, "JSON invalido")

    def _route(self, method):
        url = urlparse(self.path)
        parts = [p for p in url.path.split("/") if p]
        params = {k: v[0] for k, v in parse_qs(url.query).items()}
        if method == "GET" and not parts:
            return self._static("index.html")
        if method == "GET" and parts == ["health"]:
            return self._send(200, {"servicio": "historial-pedidos", "estado": "ok"})
        if parts[:2] == ["api", "historial"]:
            rest = parts[2:]
            if method == "GET" and not rest:
                return self._send(200, listar(params))
            if method == "GET" and rest == ["resumen"]:
                return self._send(200, resumen(params))
            if method == "GET" and len(rest) == 1:
                with get_db() as db:
                    return self._send(200, detalle(db, rest[0]))
            if method == "POST" and not rest:
                return self._send(201, crear(self._json_body()))
            if method == "PUT" and len(rest) == 2 and rest[1] == "estado":
                return self._send(200, cambiar_estado(rest[0], self._json_body()))
        if method == "GET" and parts and parts[0] == "static":
            return self._static("/".join(parts[1:]))
        raise ApiError(404, "Ruta no encontrada")

    def _static(self, rel):
        full = os.path.realpath(os.path.join(STATIC, rel))
        if not full.startswith(os.path.realpath(STATIC) + os.sep) or not os.path.isfile(full):
            raise ApiError(404, "Archivo no encontrado")
        ctype = "text/html; charset=utf-8" if full.endswith(".html") else "application/octet-stream"
        with open(full, "rb") as f:
            self._send(200, f.read(), ctype)

    def _handle(self, method):
        try:
            self._route(method)
        except ApiError as e:
            self._send(e.status, {"error": e.mensaje})
        except Exception as e:  # noqa
            self._send(500, {"error": f"Error interno: {e}"})

    def do_GET(self): self._handle("GET")
    def do_POST(self): self._handle("POST")
    def do_PUT(self): self._handle("PUT")

    def do_OPTIONS(self):
        self._send(204, b"", "text/plain")


def main():
    init_db()
    httpd = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Historial de Pedidos en http://127.0.0.1:{PORT}  (Ctrl+C para salir)")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
