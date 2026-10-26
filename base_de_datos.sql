-- Servicio 12: Historial de Pedidos
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

-- PED-1001 | usuario 4 | pagado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1001', '4', '2026-06-06T14:00:00', 'pagado', 1415.0, 'Calle Juarez 15, Navojoa, Sonora', 'transferencia', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (1, 'PED-1001', 'SKU-007', 'Maceta pintada', 2, 150.0),
    (2, 'PED-1001', 'SKU-009', 'Fuente para horno', 2, 390.0),
    (3, 'PED-1001', 'SKU-001', 'Taza de barro', 2, 120.0),
    (4, 'PED-1001', 'SKU-010', 'Alcancia de gallo', 1, 95.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (1, 'PED-1001', 'pendiente', '2026-06-06T14:00:00'),
    (2, 'PED-1001', 'pagado', '2026-06-07T21:00:00');

-- PED-1002 | usuario 4 | cancelado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1002', '4', '2026-06-12T11:00:00', 'cancelado', 930.0, 'Calle Juarez 15, Navojoa, Sonora', 'transferencia', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (5, 'PED-1002', 'SKU-007', 'Maceta pintada', 1, 150.0),
    (6, 'PED-1002', 'SKU-008', 'Juego de 4 vasos', 3, 260.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (3, 'PED-1002', 'pendiente', '2026-06-12T11:00:00'),
    (4, 'PED-1002', 'pagado', '2026-06-13T21:00:00'),
    (5, 'PED-1002', 'cancelado', '2026-06-14T23:00:00');

-- PED-1003 | usuario 4 | enviado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1003', '4', '2026-06-14T10:00:00', 'enviado', 380.0, 'Calle Juarez 15, Navojoa, Sonora', 'tarjeta', 'GUIA91890761');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (7, 'PED-1003', 'SKU-008', 'Juego de 4 vasos', 1, 260.0),
    (8, 'PED-1003', 'SKU-001', 'Taza de barro', 1, 120.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (6, 'PED-1003', 'pendiente', '2026-06-14T10:00:00'),
    (7, 'PED-1003', 'pagado', '2026-06-15T17:00:00'),
    (8, 'PED-1003', 'en_preparacion', '2026-06-17T09:00:00'),
    (9, 'PED-1003', 'enviado', '2026-06-18T22:00:00');

-- PED-1004 | usuario 4 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1004', '4', '2026-06-20T06:00:00', 'entregado', 95.0, 'Calle Juarez 15, Navojoa, Sonora', 'tarjeta', 'GUIA52069571');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (9, 'PED-1004', 'SKU-010', 'Alcancia de gallo', 1, 95.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (10, 'PED-1004', 'pendiente', '2026-06-20T06:00:00'),
    (11, 'PED-1004', 'pagado', '2026-06-21T19:00:00'),
    (12, 'PED-1004', 'en_preparacion', '2026-06-22T15:00:00'),
    (13, 'PED-1004', 'enviado', '2026-06-23T16:00:00'),
    (14, 'PED-1004', 'entregado', '2026-06-24T04:00:00');

-- PED-1005 | usuario 2 | pagado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1005', '2', '2026-06-22T15:00:00', 'pagado', 1410.0, 'Blvd. Rosales 300, Culiacan, Sinaloa', 'transferencia', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (10, 'PED-1005', 'SKU-008', 'Juego de 4 vasos', 3, 260.0),
    (11, 'PED-1005', 'SKU-003', 'Florero', 3, 210.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (15, 'PED-1005', 'pendiente', '2026-06-22T15:00:00'),
    (16, 'PED-1005', 'pagado', '2026-06-24T02:00:00');

-- PED-1006 | usuario 4 | devuelto
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1006', '4', '2026-06-26T10:00:00', 'devuelto', 1590.0, 'Calle Juarez 15, Navojoa, Sonora', 'tarjeta', 'GUIA24245056');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (12, 'PED-1006', 'SKU-003', 'Florero', 3, 210.0),
    (13, 'PED-1006', 'SKU-005', 'Cazuela', 2, 480.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (17, 'PED-1006', 'pendiente', '2026-06-26T10:00:00'),
    (18, 'PED-1006', 'pagado', '2026-06-27T13:00:00'),
    (19, 'PED-1006', 'en_preparacion', '2026-06-28T01:00:00'),
    (20, 'PED-1006', 'enviado', '2026-06-29T13:00:00'),
    (21, 'PED-1006', 'entregado', '2026-06-30T04:00:00'),
    (22, 'PED-1006', 'devuelto', '2026-07-01T07:00:00');

-- PED-1007 | usuario 1 | pagado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1007', '1', '2026-06-29T08:00:00', 'pagado', 1680.0, 'Av. Reforma 120, Los Mochis, Sinaloa', 'oxxo', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (14, 'PED-1007', 'SKU-006', 'Olla de barro', 3, 560.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (23, 'PED-1007', 'pendiente', '2026-06-29T08:00:00'),
    (24, 'PED-1007', 'pagado', '2026-06-30T09:00:00');

-- PED-1008 | usuario 1 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1008', '1', '2026-06-30T18:00:00', 'entregado', 2670.0, 'Calle Hidalgo 45, Los Mochis, Sinaloa', 'transferencia', 'GUIA68197822');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (15, 'PED-1008', 'SKU-006', 'Olla de barro', 1, 560.0),
    (16, 'PED-1008', 'SKU-005', 'Cazuela', 2, 480.0),
    (17, 'PED-1008', 'SKU-008', 'Juego de 4 vasos', 2, 260.0),
    (18, 'PED-1008', 'SKU-003', 'Florero', 3, 210.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (25, 'PED-1008', 'pendiente', '2026-06-30T18:00:00'),
    (26, 'PED-1008', 'pagado', '2026-07-01T07:00:00'),
    (27, 'PED-1008', 'en_preparacion', '2026-07-01T19:00:00'),
    (28, 'PED-1008', 'enviado', '2026-07-03T11:00:00'),
    (29, 'PED-1008', 'entregado', '2026-07-04T23:00:00');

-- PED-1009 | usuario 1 | en_preparacion
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1009', '1', '2026-07-06T11:00:00', 'en_preparacion', 1090.0, 'Av. Reforma 120, Los Mochis, Sinaloa', 'transferencia', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (19, 'PED-1009', 'SKU-002', 'Jarra artesanal', 2, 350.0),
    (20, 'PED-1009', 'SKU-009', 'Fuente para horno', 1, 390.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (30, 'PED-1009', 'pendiente', '2026-07-06T11:00:00'),
    (31, 'PED-1009', 'pagado', '2026-07-07T02:00:00'),
    (32, 'PED-1009', 'en_preparacion', '2026-07-07T16:00:00');

-- PED-1010 | usuario 3 | enviado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1010', '3', '2026-07-08T09:00:00', 'enviado', 620.0, 'Calle Obregon 78, Guasave, Sinaloa', 'transferencia', 'GUIA31527272');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (21, 'PED-1010', 'SKU-008', 'Juego de 4 vasos', 1, 260.0),
    (22, 'PED-1010', 'SKU-001', 'Taza de barro', 3, 120.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (33, 'PED-1010', 'pendiente', '2026-07-08T09:00:00'),
    (34, 'PED-1010', 'pagado', '2026-07-09T21:00:00'),
    (35, 'PED-1010', 'en_preparacion', '2026-07-10T13:00:00'),
    (36, 'PED-1010', 'enviado', '2026-07-12T01:00:00');

-- PED-1011 | usuario 4 | pendiente
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1011', '4', '2026-07-13T12:00:00', 'pendiente', 1120.0, 'Calle Juarez 15, Navojoa, Sonora', 'tarjeta', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (23, 'PED-1011', 'SKU-007', 'Maceta pintada', 1, 150.0),
    (24, 'PED-1011', 'SKU-009', 'Fuente para horno', 2, 390.0),
    (25, 'PED-1011', 'SKU-010', 'Alcancia de gallo', 2, 95.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (37, 'PED-1011', 'pendiente', '2026-07-13T12:00:00');

-- PED-1012 | usuario 4 | enviado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1012', '4', '2026-07-14T10:00:00', 'enviado', 860.0, 'Calle Juarez 15, Navojoa, Sonora', 'tarjeta', 'GUIA26120303');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (26, 'PED-1012', 'SKU-008', 'Juego de 4 vasos', 2, 260.0),
    (27, 'PED-1012', 'SKU-010', 'Alcancia de gallo', 2, 95.0),
    (28, 'PED-1012', 'SKU-007', 'Maceta pintada', 1, 150.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (38, 'PED-1012', 'pendiente', '2026-07-14T10:00:00'),
    (39, 'PED-1012', 'pagado', '2026-07-15T09:00:00'),
    (40, 'PED-1012', 'en_preparacion', '2026-07-16T21:00:00'),
    (41, 'PED-1012', 'enviado', '2026-07-18T06:00:00');

-- PED-1013 | usuario 3 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1013', '3', '2026-07-19T07:00:00', 'entregado', 325.0, 'Calle Obregon 78, Guasave, Sinaloa', 'paypal', 'GUIA57237950');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (29, 'PED-1013', 'SKU-004', 'Plato hondo', 1, 85.0),
    (30, 'PED-1013', 'SKU-001', 'Taza de barro', 2, 120.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (42, 'PED-1013', 'pendiente', '2026-07-19T07:00:00'),
    (43, 'PED-1013', 'pagado', '2026-07-20T07:00:00'),
    (44, 'PED-1013', 'en_preparacion', '2026-07-21T12:00:00'),
    (45, 'PED-1013', 'enviado', '2026-07-23T01:00:00'),
    (46, 'PED-1013', 'entregado', '2026-07-23T15:00:00');

-- PED-1014 | usuario 3 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1014', '3', '2026-07-22T11:00:00', 'entregado', 2490.0, 'Calle Obregon 78, Guasave, Sinaloa', 'tarjeta', 'GUIA99967131');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (31, 'PED-1014', 'SKU-002', 'Jarra artesanal', 3, 350.0),
    (32, 'PED-1014', 'SKU-005', 'Cazuela', 3, 480.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (47, 'PED-1014', 'pendiente', '2026-07-22T11:00:00'),
    (48, 'PED-1014', 'pagado', '2026-07-23T03:00:00'),
    (49, 'PED-1014', 'en_preparacion', '2026-07-24T18:00:00'),
    (50, 'PED-1014', 'enviado', '2026-07-25T15:00:00'),
    (51, 'PED-1014', 'entregado', '2026-07-27T06:00:00');

-- PED-1015 | usuario 1 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1015', '1', '2026-07-28T17:00:00', 'entregado', 1010.0, 'Av. Reforma 120, Los Mochis, Sinaloa', 'paypal', 'GUIA47149597');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (33, 'PED-1015', 'SKU-002', 'Jarra artesanal', 1, 350.0),
    (34, 'PED-1015', 'SKU-007', 'Maceta pintada', 3, 150.0),
    (35, 'PED-1015', 'SKU-003', 'Florero', 1, 210.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (52, 'PED-1015', 'pendiente', '2026-07-28T17:00:00'),
    (53, 'PED-1015', 'pagado', '2026-07-29T18:00:00'),
    (54, 'PED-1015', 'en_preparacion', '2026-07-30T08:00:00'),
    (55, 'PED-1015', 'enviado', '2026-07-30T17:00:00'),
    (56, 'PED-1015', 'entregado', '2026-08-01T04:00:00');

-- PED-1016 | usuario 1 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1016', '1', '2026-08-03T10:00:00', 'entregado', 1470.0, 'Av. Reforma 120, Los Mochis, Sinaloa', 'paypal', 'GUIA41571416');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (36, 'PED-1016', 'SKU-003', 'Florero', 1, 210.0),
    (37, 'PED-1016', 'SKU-005', 'Cazuela', 1, 480.0),
    (38, 'PED-1016', 'SKU-009', 'Fuente para horno', 2, 390.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (57, 'PED-1016', 'pendiente', '2026-08-03T10:00:00'),
    (58, 'PED-1016', 'pagado', '2026-08-04T05:00:00'),
    (59, 'PED-1016', 'en_preparacion', '2026-08-05T10:00:00'),
    (60, 'PED-1016', 'enviado', '2026-08-05T13:00:00'),
    (61, 'PED-1016', 'entregado', '2026-08-05T19:00:00');

-- PED-1017 | usuario 4 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1017', '4', '2026-08-04T15:00:00', 'entregado', 1050.0, 'Calle Juarez 15, Navojoa, Sonora', 'transferencia', 'GUIA91504394');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (39, 'PED-1017', 'SKU-002', 'Jarra artesanal', 3, 350.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (62, 'PED-1017', 'pendiente', '2026-08-04T15:00:00'),
    (63, 'PED-1017', 'pagado', '2026-08-06T05:00:00'),
    (64, 'PED-1017', 'en_preparacion', '2026-08-07T20:00:00'),
    (65, 'PED-1017', 'enviado', '2026-08-08T21:00:00'),
    (66, 'PED-1017', 'entregado', '2026-08-09T20:00:00');

-- PED-1018 | usuario 2 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1018', '2', '2026-08-05T18:00:00', 'entregado', 705.0, 'Blvd. Rosales 300, Culiacan, Sinaloa', 'transferencia', 'GUIA57824180');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (40, 'PED-1018', 'SKU-010', 'Alcancia de gallo', 2, 95.0),
    (41, 'PED-1018', 'SKU-004', 'Plato hondo', 3, 85.0),
    (42, 'PED-1018', 'SKU-008', 'Juego de 4 vasos', 1, 260.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (67, 'PED-1018', 'pendiente', '2026-08-05T18:00:00'),
    (68, 'PED-1018', 'pagado', '2026-08-06T20:00:00'),
    (69, 'PED-1018', 'en_preparacion', '2026-08-08T07:00:00'),
    (70, 'PED-1018', 'enviado', '2026-08-09T02:00:00'),
    (71, 'PED-1018', 'entregado', '2026-08-10T05:00:00');

-- PED-1019 | usuario 4 | pendiente
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1019', '4', '2026-08-06T10:00:00', 'pendiente', 1440.0, 'Calle Juarez 15, Navojoa, Sonora', 'tarjeta', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (43, 'PED-1019', 'SKU-005', 'Cazuela', 3, 480.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (72, 'PED-1019', 'pendiente', '2026-08-06T10:00:00');

-- PED-1020 | usuario 2 | cancelado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1020', '2', '2026-08-09T14:00:00', 'cancelado', 1690.0, 'Blvd. Rosales 300, Culiacan, Sinaloa', 'tarjeta', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (44, 'PED-1020', 'SKU-007', 'Maceta pintada', 3, 150.0),
    (45, 'PED-1020', 'SKU-006', 'Olla de barro', 2, 560.0),
    (46, 'PED-1020', 'SKU-001', 'Taza de barro', 1, 120.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (73, 'PED-1020', 'pendiente', '2026-08-09T14:00:00'),
    (74, 'PED-1020', 'cancelado', '2026-08-10T00:00:00');

-- PED-1021 | usuario 3 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1021', '3', '2026-08-11T11:00:00', 'entregado', 630.0, 'Av. del Mar 910, Mazatlan, Sinaloa', 'transferencia', 'GUIA26951405');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (47, 'PED-1021', 'SKU-003', 'Florero', 3, 210.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (75, 'PED-1021', 'pendiente', '2026-08-11T11:00:00'),
    (76, 'PED-1021', 'pagado', '2026-08-12T12:00:00'),
    (77, 'PED-1021', 'en_preparacion', '2026-08-13T10:00:00'),
    (78, 'PED-1021', 'enviado', '2026-08-13T14:00:00'),
    (79, 'PED-1021', 'entregado', '2026-08-14T20:00:00');

-- PED-1022 | usuario 4 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1022', '4', '2026-08-20T13:00:00', 'entregado', 2010.0, 'Calle Juarez 15, Navojoa, Sonora', 'tarjeta', 'GUIA29821727');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (48, 'PED-1022', 'SKU-007', 'Maceta pintada', 1, 150.0),
    (49, 'PED-1022', 'SKU-004', 'Plato hondo', 1, 85.0),
    (50, 'PED-1022', 'SKU-010', 'Alcancia de gallo', 1, 95.0),
    (51, 'PED-1022', 'SKU-006', 'Olla de barro', 3, 560.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (80, 'PED-1022', 'pendiente', '2026-08-20T13:00:00'),
    (81, 'PED-1022', 'pagado', '2026-08-20T17:00:00'),
    (82, 'PED-1022', 'en_preparacion', '2026-08-22T06:00:00'),
    (83, 'PED-1022', 'enviado', '2026-08-23T20:00:00'),
    (84, 'PED-1022', 'entregado', '2026-08-25T00:00:00');

-- PED-1023 | usuario 4 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1023', '4', '2026-08-23T18:00:00', 'entregado', 1440.0, 'Calle Juarez 15, Navojoa, Sonora', 'tarjeta', 'GUIA94124685');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (52, 'PED-1023', 'SKU-005', 'Cazuela', 3, 480.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (85, 'PED-1023', 'pendiente', '2026-08-23T18:00:00'),
    (86, 'PED-1023', 'pagado', '2026-08-25T03:00:00'),
    (87, 'PED-1023', 'en_preparacion', '2026-08-26T08:00:00'),
    (88, 'PED-1023', 'enviado', '2026-08-27T03:00:00'),
    (89, 'PED-1023', 'entregado', '2026-08-28T02:00:00');

-- PED-1024 | usuario 1 | en_preparacion
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1024', '1', '2026-08-27T06:00:00', 'en_preparacion', 780.0, 'Av. Reforma 120, Los Mochis, Sinaloa', 'tarjeta', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (53, 'PED-1024', 'SKU-009', 'Fuente para horno', 2, 390.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (90, 'PED-1024', 'pendiente', '2026-08-27T06:00:00'),
    (91, 'PED-1024', 'pagado', '2026-08-28T06:00:00'),
    (92, 'PED-1024', 'en_preparacion', '2026-08-29T18:00:00');

-- PED-1025 | usuario 1 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1025', '1', '2026-08-27T09:00:00', 'entregado', 620.0, 'Calle Hidalgo 45, Los Mochis, Sinaloa', 'paypal', 'GUIA85375365');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (54, 'PED-1025', 'SKU-008', 'Juego de 4 vasos', 1, 260.0),
    (55, 'PED-1025', 'SKU-001', 'Taza de barro', 3, 120.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (93, 'PED-1025', 'pendiente', '2026-08-27T09:00:00'),
    (94, 'PED-1025', 'pagado', '2026-08-28T20:00:00'),
    (95, 'PED-1025', 'en_preparacion', '2026-08-29T08:00:00'),
    (96, 'PED-1025', 'enviado', '2026-08-30T12:00:00'),
    (97, 'PED-1025', 'entregado', '2026-08-31T14:00:00');

-- PED-1026 | usuario 3 | devuelto
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1026', '3', '2026-09-02T14:00:00', 'devuelto', 1405.0, 'Av. del Mar 910, Mazatlan, Sinaloa', 'tarjeta', 'GUIA31245891');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (56, 'PED-1026', 'SKU-006', 'Olla de barro', 2, 560.0),
    (57, 'PED-1026', 'SKU-010', 'Alcancia de gallo', 3, 95.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (98, 'PED-1026', 'pendiente', '2026-09-02T14:00:00'),
    (99, 'PED-1026', 'pagado', '2026-09-03T22:00:00'),
    (100, 'PED-1026', 'en_preparacion', '2026-09-05T12:00:00'),
    (101, 'PED-1026', 'enviado', '2026-09-06T21:00:00'),
    (102, 'PED-1026', 'entregado', '2026-09-08T13:00:00'),
    (103, 'PED-1026', 'devuelto', '2026-09-09T11:00:00');

-- PED-1027 | usuario 4 | enviado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1027', '4', '2026-09-24T12:00:00', 'enviado', 2210.0, 'Calle Juarez 15, Navojoa, Sonora', 'tarjeta', 'GUIA28516756');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (58, 'PED-1027', 'SKU-001', 'Taza de barro', 1, 120.0),
    (59, 'PED-1027', 'SKU-006', 'Olla de barro', 3, 560.0),
    (60, 'PED-1027', 'SKU-007', 'Maceta pintada', 1, 150.0),
    (61, 'PED-1027', 'SKU-008', 'Juego de 4 vasos', 1, 260.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (104, 'PED-1027', 'pendiente', '2026-09-24T12:00:00'),
    (105, 'PED-1027', 'pagado', '2026-09-25T10:00:00'),
    (106, 'PED-1027', 'en_preparacion', '2026-09-26T12:00:00'),
    (107, 'PED-1027', 'enviado', '2026-09-28T01:00:00');

-- PED-1028 | usuario 1 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1028', '1', '2026-09-25T14:00:00', 'entregado', 765.0, 'Av. Reforma 120, Los Mochis, Sinaloa', 'tarjeta', 'GUIA78284809');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (62, 'PED-1028', 'SKU-010', 'Alcancia de gallo', 3, 95.0),
    (63, 'PED-1028', 'SKU-005', 'Cazuela', 1, 480.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (108, 'PED-1028', 'pendiente', '2026-09-25T14:00:00'),
    (109, 'PED-1028', 'pagado', '2026-09-26T18:00:00'),
    (110, 'PED-1028', 'en_preparacion', '2026-09-27T21:00:00'),
    (111, 'PED-1028', 'enviado', '2026-09-29T10:00:00'),
    (112, 'PED-1028', 'entregado', '2026-09-30T22:00:00');

-- PED-1029 | usuario 4 | entregado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1029', '4', '2026-09-30T12:00:00', 'entregado', 1570.0, 'Calle Juarez 15, Navojoa, Sonora', 'oxxo', 'GUIA49314126');
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (64, 'PED-1029', 'SKU-007', 'Maceta pintada', 3, 150.0),
    (65, 'PED-1029', 'SKU-006', 'Olla de barro', 2, 560.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (113, 'PED-1029', 'pendiente', '2026-09-30T12:00:00'),
    (114, 'PED-1029', 'pagado', '2026-10-01T10:00:00'),
    (115, 'PED-1029', 'en_preparacion', '2026-10-01T15:00:00'),
    (116, 'PED-1029', 'enviado', '2026-10-03T07:00:00'),
    (117, 'PED-1029', 'entregado', '2026-10-03T22:00:00');

-- PED-1030 | usuario 2 | en_preparacion
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1030', '2', '2026-10-11T07:00:00', 'en_preparacion', 1640.0, 'Blvd. Rosales 300, Culiacan, Sinaloa', 'oxxo', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (66, 'PED-1030', 'SKU-006', 'Olla de barro', 1, 560.0),
    (67, 'PED-1030', 'SKU-003', 'Florero', 3, 210.0),
    (68, 'PED-1030', 'SKU-007', 'Maceta pintada', 3, 150.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (118, 'PED-1030', 'pendiente', '2026-10-11T07:00:00'),
    (119, 'PED-1030', 'pagado', '2026-10-11T10:00:00'),
    (120, 'PED-1030', 'en_preparacion', '2026-10-12T19:00:00');

-- PED-1031 | usuario 1 | cancelado
INSERT INTO pedidos (id, usuario_id, fecha, estado, total, direccion_envio, metodo_pago, tracking) VALUES
    ('PED-1031', '1', '2026-10-15T16:00:00', 'cancelado', 630.0, 'Av. Reforma 120, Los Mochis, Sinaloa', 'oxxo', NULL);
INSERT INTO pedido_items (id, pedido_id, sku, nombre, cantidad, precio_unitario) VALUES
    (69, 'PED-1031', 'SKU-009', 'Fuente para horno', 1, 390.0),
    (70, 'PED-1031', 'SKU-001', 'Taza de barro', 2, 120.0);
INSERT INTO pedido_eventos (id, pedido_id, estado, fecha) VALUES
    (121, 'PED-1031', 'pendiente', '2026-10-15T16:00:00'),
    (122, 'PED-1031', 'cancelado', '2026-10-16T05:00:00');


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
