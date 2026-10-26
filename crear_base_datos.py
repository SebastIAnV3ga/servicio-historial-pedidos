"""Crea historial.db desde cero con pedidos de ejemplo (y base_de_datos.sql).

Uso:  python crear_base_datos.py
Borra el historial.db existente. Los datos son siempre los mismos.
"""
import os
import random
import sqlite3
from datetime import datetime, timedelta

import server

FLOW = ["pendiente", "pagado", "en_preparacion", "enviado", "entregado"]

PRODUCTOS = [
    ("SKU-001", "Taza de barro", 120.0), ("SKU-002", "Jarra artesanal", 350.0),
    ("SKU-003", "Florero", 210.0), ("SKU-004", "Plato hondo", 85.0),
    ("SKU-005", "Cazuela", 480.0), ("SKU-006", "Olla de barro", 560.0),
    ("SKU-007", "Maceta pintada", 150.0), ("SKU-008", "Juego de 4 vasos", 260.0),
    ("SKU-009", "Fuente para horno", 390.0), ("SKU-010", "Alcancia de gallo", 95.0),
]
USUARIOS = {
    "1": ["Av. Reforma 120, Los Mochis, Sinaloa", "Calle Hidalgo 45, Los Mochis, Sinaloa"],
    "2": ["Blvd. Rosales 300, Culiacan, Sinaloa"],
    "3": ["Calle Obregon 78, Guasave, Sinaloa", "Av. del Mar 910, Mazatlan, Sinaloa"],
    "4": ["Calle Juarez 15, Navojoa, Sonora"],
}
PAGOS = ["tarjeta", "tarjeta", "paypal", "transferencia", "oxxo"]
# estado final y cuantos pedidos de cada uno
FINALES = ["entregado"] * 14 + ["enviado"] * 4 + ["en_preparacion"] * 3 + ["pagado"] * 3 \
          + ["pendiente"] * 2 + ["cancelado"] * 3 + ["devuelto"] * 2


def generar(db):
    rnd = random.Random(2026)
    hoy = datetime(2026, 10, 24, 18, 0)
    n = 1000
    pedidos = []
    for final in FINALES:
        n += 1
        uid = rnd.choice(list(USUARIOS))
        inicio = hoy - timedelta(days=rnd.randint(1, 140), hours=rnd.randint(0, 12))
        pedidos.append((inicio, f"PED-{n}", uid, final))
    pedidos.sort()  # los ids crecen con la fecha
    for k, (inicio, _, uid, final) in enumerate(pedidos):
        pid = f"PED-{1001 + k}"
        items = rnd.sample(PRODUCTOS, rnd.randint(1, 4))
        lineas = [(s, nom, rnd.randint(1, 3), p) for s, nom, p in items]
        total = sum(c * p for _, _, c, p in lineas)
        # recorrido de estados
        if final in FLOW:
            ruta = FLOW[:FLOW.index(final) + 1]
        elif final == "cancelado":
            ruta = ["pendiente", "pagado", "cancelado"] if rnd.random() < .4 else ["pendiente", "cancelado"]
        else:  # devuelto
            ruta = FLOW + ["devuelto"]
        eventos, t = [], inicio
        for e in ruta:
            eventos.append((e, t.strftime("%Y-%m-%dT%H:%M:%S")))
            t += timedelta(hours=rnd.randint(3, 40))
        tracking = f"GUIA{rnd.randint(10**7, 10**8 - 1)}" if "enviado" in ruta else None
        db.execute("INSERT INTO pedidos VALUES (?,?,?,?,?,?,?,?)",
                   (pid, uid, eventos[0][1], final, total, rnd.choice(USUARIOS[uid]),
                    rnd.choice(PAGOS), tracking))
        db.executemany(
            "INSERT INTO pedido_items (pedido_id,sku,nombre,cantidad,precio_unitario) VALUES (?,?,?,?,?)",
            [(pid, *l) for l in lineas])
        db.executemany("INSERT INTO pedido_eventos (pedido_id,estado,fecha) VALUES (?,?,?)",
                       [(pid, e, f) for e, f in eventos])


ESQUEMA_SQL = """-- Servicio 12: Historial de Pedidos
-- Script de base de datos (esquema + datos de ejemplo).
-- Compatible con MySQL / MariaDB y con SQLite.
-- Uso en MySQL:  SOURCE base_de_datos.sql;
-- Uso en SQLite: sqlite3 historial.db < base_de_datos.sql

DROP TABLE IF EXISTS pedido_eventos;
DROP TABLE IF EXISTS pedido_items;
DROP TABLE IF EXISTS pedidos;

CREATE TABLE pedidos (
    id              VARCHAR(20)   NOT NULL PRIMARY KEY,
    usuario_id      VARCHAR(20)   NOT NULL,
    fecha           DATETIME      NOT NULL,
    estado          VARCHAR(20)   NOT NULL,  -- pendiente, pagado, en_preparacion, enviado, entregado, cancelado, devuelto
    total           DECIMAL(10,2) NOT NULL,
    direccion_envio VARCHAR(200),
    metodo_pago     VARCHAR(30),
    tracking        VARCHAR(30)
);

CREATE TABLE pedido_items (
    id              INT           NOT NULL PRIMARY KEY,
    pedido_id       VARCHAR(20)   NOT NULL,
    sku             VARCHAR(20)   NOT NULL,
    nombre          VARCHAR(100),
    cantidad        INT           NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
);

CREATE TABLE pedido_eventos (
    id         INT         NOT NULL PRIMARY KEY,
    pedido_id  VARCHAR(20) NOT NULL,
    estado     VARCHAR(20) NOT NULL,
    fecha      DATETIME    NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
);

CREATE INDEX idx_pedidos_usuario ON pedidos (usuario_id, fecha);

-- ---------------------------------------------------------------
-- Datos de ejemplo
-- ---------------------------------------------------------------
"""

CONSULTAS_SQL = """
-- ---------------------------------------------------------------
-- Consultas de ejemplo
-- ---------------------------------------------------------------

-- Historial de un usuario, del mas reciente al mas antiguo
SELECT id, fecha, estado, total FROM pedidos WHERE usuario_id = '1' ORDER BY fecha DESC;

-- Detalle de un pedido
SELECT p.id, p.estado, i.sku, i.nombre, i.cantidad, i.precio_unitario
FROM pedidos p JOIN pedido_items i ON i.pedido_id = p.id
WHERE p.id = 'PED-1010';

-- Linea de tiempo de un pedido
SELECT estado, fecha FROM pedido_eventos WHERE pedido_id = 'PED-1010' ORDER BY id;

-- Resumen por usuario (sin contar cancelados ni devueltos)
SELECT usuario_id, COUNT(*) AS pedidos, SUM(total) AS total_gastado
FROM pedidos WHERE estado NOT IN ('cancelado', 'devuelto')
GROUP BY usuario_id;
"""


def _q(v):
    if v is None:
        return "NULL"
    if isinstance(v, (int, float)):
        return repr(v) if isinstance(v, float) else str(v)
    return "'" + str(v).replace("'", "''") + "'"


def exportar_sql(db, ruta):
    out = [ESQUEMA_SQL]
    for p in db.execute("SELECT * FROM pedidos ORDER BY id").fetchall():
        out.append(f"-- {p[0]} | usuario {p[1]} | {p[3]}")
        out.append("INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES\n    ("
                   + ", ".join(_q(x) for x in p) + ");")
        items = db.execute("SELECT id,pedido_id,sku,nombre,cantidad,precio_unitario FROM pedido_items "
                           "WHERE pedido_id=? ORDER BY id", (p[0],)).fetchall()
        out.append("INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES\n    "
                   + ",\n    ".join("(" + ", ".join(_q(x) for x in i) + ")" for i in items) + ";")
        evs = db.execute("SELECT id,pedido_id,estado,fecha FROM pedido_eventos WHERE pedido_id=? ORDER BY id",
                         (p[0],)).fetchall()
        out.append("INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES\n    "
                   + ",\n    ".join("(" + ", ".join(_q(x) for x in e) + ")" for e in evs) + ";\n")
    out.append(CONSULTAS_SQL)
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


def main():
    ruta = server.DB_PATH
    if os.path.exists(ruta):
        os.remove(ruta)
    server.init_db(sembrar=False)
    with server.get_db() as db:
        generar(db)
    with sqlite3.connect(ruta) as db:
        exportar_sql(db, os.path.join(server.BASE, "base_de_datos.sql"))
        total = db.execute("SELECT COUNT(*) FROM pedidos").fetchone()[0]
        por = db.execute("SELECT usuario_id, COUNT(*) FROM pedidos GROUP BY usuario_id").fetchall()
    print(f"Listo: {total} pedidos en {ruta}")
    for u, c in por:
        print(f"  usuario {u}: {c} pedidos")


if __name__ == "__main__":
    main()
