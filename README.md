# Servicio 12 – Historial de Pedidos

Guarda y consulta los pedidos ya realizados por cada usuario: lista con filtros, detalle con productos y línea de tiempo de estados.
Solo usa Python 3 (`http.server` + `sqlite3`), igual que el servicio de Gestión de Pedidos. No hay nada que instalar.

## Requisitos
Python 3.8 o superior. No hay dependencias externas.

## Cómo abrirlo
- **Windows:** doble clic en `iniciar.bat` (abre `http://127.0.0.1:8012`).
- **Con git:** `git clone <URL-de-este-repo>` y luego lo de arriba.
- **macOS / Linux:** `python3 server.py`

El puerto es **8012** (cambia con la variable `PORT`) para no chocar con otros servicios que usan el 8000.
Usa el archivo `historial.db` incluido en el repo (si no existe, lo crea con 5 pedidos de ejemplo). Para volver a los datos originales: `python crear_base_datos.py`.

## Base de datos de ejemplo
El repo incluye `historial.db` con **31 pedidos** de 4 usuarios (1 a 4) en todos los estados, con productos, direcciones y línea de tiempo.
- `base_de_datos.sql`: el **script SQL** de la base de datos: tablas, 31 pedidos con sus productos y eventos, y consultas de ejemplo. Funciona en MySQL/MariaDB (`SOURCE base_de_datos.sql;`) y en SQLite (`sqlite3 historial.db < base_de_datos.sql`).
- `crear_base_datos.py`: vuelve a generar `historial.db` y `base_de_datos.sql` desde cero (`python crear_base_datos.py`). Ojo: borra los datos actuales.

## API
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/health` | Estado del servicio |
| GET | `/api/historial` | Lista paginada, más reciente primero. Filtros: `usuario_id`, `estado`, `desde`, `hasta` (YYYY-MM-DD), `q` (id, nombre o sku), `page`, `limit` (máx. 100) |
| GET | `/api/historial/<id>` | Detalle: productos y eventos de estado |
| GET | `/api/historial/resumen?usuario_id=1` | Número de pedidos, total gastado y conteo por estado |
| POST | `/api/historial` | Registrar un pedido (lo llama Gestión de Pedidos al confirmar). 201 / 400 / 409 si el id ya existe |
| PUT | `/api/historial/<id>/estado` | `{estado, tracking?}`; agrega un evento a la línea de tiempo |

Estados válidos: `pendiente, pagado, en_preparacion, enviado, entregado, cancelado, devuelto`.

### Contrato para registrar un pedido
```json
{
  "id": "PED-2001",
  "usuario_id": "1",
  "fecha": "2026-10-25T12:00:00",
  "estado": "pagado",
  "direccion_envio": "Calle Hidalgo 45, Los Mochis",
  "metodo_pago": "tarjeta",
  "items": [{"sku": "SKU-001", "nombre": "Taza de barro", "cantidad": 2, "precio_unitario": 120.0}]
}
```
`fecha`, `estado` (por defecto `pendiente`) y `total` (se calcula) son opcionales.

Ejemplo:
```
curl -X POST http://127.0.0.1:8012/api/historial -H "Content-Type: application/json" -d @pedido.json
curl "http://127.0.0.1:8012/api/historial?usuario_id=1&estado=enviado"
```

## Cómo encaja con los demás servicios
- **Gestión de Pedidos (11):** al confirmar un pedido hace `POST /api/historial`.
- **Seguimiento (13), Picking (17), Packing (18), Envíos (19):** al cambiar el estado llaman `PUT /api/historial/<id>/estado`.
- **Autenticación (2):** `usuario_id` es el id del usuario autenticado.

## Pruebas
```
python -m unittest test_server.py
```

## Archivos
| Archivo | Qué hace |
|---|---|
| `server.py` | Servidor HTTP, API JSON y SQLite |
| `static/index.html` | Interfaz de consulta |
| `test_server.py` | Pruebas de la API |
| `crear_base_datos.py` | Regenera la base de datos de ejemplo |
| `historial.db` / `base_de_datos.sql` | Base de datos con 31 pedidos |
| `iniciar.bat` | Lanzador para Windows |
