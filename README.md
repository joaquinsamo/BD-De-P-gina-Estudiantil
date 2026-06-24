# Proyecto Integrador — Base de Datos III

Sistema de foro y plataforma de preguntas y respuestas desarrollado sobre PostgreSQL, con lógica de negocio en el servidor, caché en Redis y API REST en Node.js.

## Integrantes

- Grosso Joaquín
- Santiago Orlando Luna
- Ivo Giuliano Cappetto
- Lautaro Gutierrez Lardit
- Martín Sánchez
- Nicolás Fernández García

---

## Descripción del Proyecto

El sistema permite a los usuarios publicar preguntas, responder con comentarios anidados, votar publicaciones y comentarios, y reportar contenido. El desafío técnico principal fue manejar más de **1.1 millón de registros** con consultas eficientes, lógica de negocio robusta en la base de datos y una capa de caché que reduce la carga sobre PostgreSQL.

---

## Tecnologías y Herramientas

| Tecnología | Uso |
|---|---|
| PostgreSQL 15 | Motor de base de datos principal |
| Redis 7 | Caché en memoria (patrón Cache-Aside) |
| Node.js + Express | API REST |
| Docker | Contenedores para PostgreSQL y Redis |
| pgAdmin | Administración de PostgreSQL |
| Redis Insight | Visualización del estado del caché |
| Postman | Testing de endpoints |
| Dalibo PEV2 | Visualización de planes de ejecución |

---

## Estructura del Repositorio

```
/
├── index.js                        # API REST (Parte 4)
├── docker-compose.yml              # Contenedores PostgreSQL + Redis
├── .env                            # Variables de entorno (no subir a Git)
│
├── scripts/
│   ├── Parte 1/
│   │   ├── tablas.sql              # DDL: tablas, PKs y FKs
│   │   ├── data-seeding.sql        # Carga masiva +1.1M de registros
│   │   ├── Indices.sql             # Índices B-Tree, Hash, GIN y GiST
│   │   ├── windows function.sql    # Window Function: ranking de usuarios
│   │   └── CTE y Recursividad.sql  # CTE recursiva: árbol de comentarios
│   │
│   ├── Parte 2/
│   │   ├── seccionA_funcion_score.sql      # Función calcular_score_publicacion
│   │   ├── seccionBC_auditoria.sql         # Tabla audit_logs y función de auditoría
│   │   ├── seccionD_procedimiento.sql      # Procedimiento crear_comentario_seguro
│   │   └── seccionE_trigger.sql            # Trigger AFTER UPDATE sobre usuario
│   │
│   ├── Parte 3/
│   │   ├── 00_QUICKSTART.md                # Guía de inicio rápido
│   │   ├── 01_redis_setup.md               # Instalación y configuración de Redis
│   │   ├── 02_cache_aside_pattern.sql      # Queries cacheables documentadas
│   │   ├── 03_redis_commands_reference.md  # Referencia de comandos Redis
│   │   ├── 04_performance_metrics.md       # Benchmarks y métricas
│   │   └── 05_implementation_examples.js   # Ejemplos de implementación Node.js
│   │
│   └── Parte 4/
│       └── AgregarColumna.sql      # Agrega columna activo a publicacion
│
├── Documentación/
│   ├── Indice.md                   # Justificación de estrategias de indexación
│   ├── LogicaSQL.md                # Explicación de Window Functions y CTEs
│   └── Reporte_Performance.md      # Análisis EXPLAIN ANALYZE con capturas
│
└── MER/
    └── PROTOTIPO4.drawio.png       # Diagrama Entidad-Relación (3NF)
```

---

## Instalación y Uso

### 1. Levantar la infraestructura

```bash
docker compose up -d postgres redis
```

### 2. Ejecutar los scripts SQL en pgAdmin en este orden

| Orden | Archivo |
|---|---|
| 1 | `scripts/Parte 1/tablas.sql` |
| 2 | `scripts/Parte 4/AgregarColumna.sql` |
| 3 | `scripts/Parte 2/seccionBC_auditoria.sql` |
| 4 | `scripts/Parte 2/seccionA_funcion_score.sql` |
| 5 | `scripts/Parte 2/seccionD_procedimiento.sql` |
| 6 | `scripts/Parte 2/seccionE_trigger.sql` |
| 7 | `scripts/Parte 1/data-seeding.sql` *(tarda ~10 minutos)* |
| 8 | `scripts/Parte 1/Indices.sql` |

### 3. Levantar la API

```bash
npm install express pg redis cors dotenv
node index.js
```

### 4. Endpoints disponibles

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/publicaciones` | Listar publicaciones (con caché) |
| `POST` | `/api/publicaciones` | Crear publicación |
| `PUT` | `/api/publicaciones/:id` | Actualizar publicación |
| `DELETE` | `/api/publicaciones/:id` | Baja lógica (`activo = false`) |
| `GET` | `/api/cache/info` | Ver estado del caché Redis |

---

## Checklist de Avance — Parte 2

### A. Abstracción y Lógica Procedural

- [x] **1.** Categorizar correctamente la volatilidad de la función (`IMMUTABLE`, `STABLE` o `VOLATILE`) analizando el consumo de CPU.
- [x] **2.** Diseñar el procedimiento almacenado principal para la tarea compleja de negocio.
- [x] **3.** Implementar la robustez de tipos en variables usando `%TYPE`, `%ROWTYPE` o `RECORD` (evitar tipos estáticos).

### B. Gestión Avanzada de Transacciones

- [x] **1.** Asegurar la atomicidad global del procedimiento mediante sentencias explícitas de `COMMIT` y `ROLLBACK`.
- [x] **2.** Identificar el subproceso secundario propenso a fallas y aislarlo mediante la declaración de un `SAVEPOINT`.
- [x] **3.** Implementar la lógica de reversión parcial (`ROLLBACK TO SAVEPOINT`) ante un error controlado.

### C. Capa de Auditoría y Forense de Datos

- [x] **1.** Crear la tabla física `audit_logs` con los campos necesarios para metadatos del sistema.
- [x] **2.** Implementar bloques estructurados `EXCEPTION` en los puntos críticos de los scripts.
- [x] **3.** Utilizar `GET STACKED DIAGNOSTICS` para extraer de forma limpia el `RETURNED_SQLSTATE` y el `MESSAGE_TEXT`.

### D. Seguridad y Blindaje (Hardening)

- [x] **1.** Configurar la cabecera del proceso administrativo crítico bajo el contexto de `SECURITY DEFINER`.
- [x] **2.** Blindar las funciones restringiendo el vector de ataque mediante la fijación explícita del parámetro `search_path`.

### E. Automatización con Triggers

- [x] **1.** Definir la tabla objetivo y la sincronización temporal del disparador (`BEFORE` / `AFTER`).
- [x] **2.** Crear la función asociada al disparador aplicando lógica condicional mediante las pseudovariables `OLD` y `NEW`.
- [x] **3.** Ejecutar la sentencia `CREATE TRIGGER` y verificar la reactividad ante eventos DML (INSERT, UPDATE o DELETE).

> 💡 Cada casilla completada está respaldada por su respectivo script dentro de `scripts/Parte 2/`.

---

## Checklist: Integración de Caché con Redis — Parte 3

Esta sección detalla el progreso de la implementación de la capa de persistencia políglota utilizando Redis como almacén clave-valor en memoria.

### 1. Fase de Diseño y Selección

- [x] Identificamos 1 o 2 endpoints estratégicos para cachear (alta frecuencia de lectura, baja de escritura).
- [x] Listado de endpoints cacheados:
  - *Endpoint 1:* `GET /api/publicaciones` — listado completo con JOIN a usuario y categoría
  - *Endpoint 2:* `GET /api/cache/info` — estado del caché en tiempo real
- [x] Asegurar que el caso de uso soporta **consistencia eventual** (tolera desactualización de 1 o 2 minutos sin romper el sistema).

### 2. Configuración (Setup)

- [x] Instalamos el cliente de Redis en nuestro proyecto (`npm install redis`).
- [x] Establecemos conexión exitosa con el servidor de Redis (Docker local en puerto 6379).
- [x] Implementamos **Manejo de Errores (Fallback)**: Si Redis se cae, la aplicación registra el error pero sigue funcionando, consultando directamente la base de datos principal.

### 3. Implementación del Patrón Cache-Aside

- [x] **Consulta a la Caché:** El endpoint verifica primero si la clave existe en Redis.
- [x] **Cache HIT:** Si el dato existe, se retorna inmediatamente al cliente (se evita ir a la DB).
- [x] **Cache MISS (Consulta a la DB):** Si el dato NO existe, el sistema realiza la consulta a la base de datos principal (PostgreSQL).
- [x] **Población de la Caché:** Guardamos el resultado obtenido de la base de datos en Redis.
- [x] Devolver la respuesta final al cliente en todos los flujos.

### 4. Buenas Prácticas Técnicas

- [x] **Nomenclatura (Namespacing):** Utilizamos el estándar de separación con dos puntos (`:`) para las claves. *(Clave usada: `publicaciones:all`, patrón de invalidación: `publicaciones:*`)*.
- [x] **Asignación de TTL:** Toda clave guardada en Redis tiene un tiempo de vida de **300 segundos (5 minutos)** configurado.

---

## Checklist: API REST e Invalidación de Caché — Parte 4

### Endpoints implementados

- [x] **POST** `/api/publicaciones` — Alta de nueva publicación con validación de usuario y categoría. Devuelve status `201 Created`.
- [x] **PUT** `/api/publicaciones/:id` — Modificación de campos de una publicación existente. ID viaja en la URL, datos en el Body JSON.
- [x] **DELETE** `/api/publicaciones/:id` — Baja lógica: actualiza `activo = false`. No se usa `DELETE FROM`.

### Invalidación selectiva de caché

- [x] Al crear, modificar o dar de baja una publicación, el sistema invalida selectivamente las claves `publicaciones:*` usando `keys()` + `del()`.
- [x] **Prohibido cumplido:** No se utiliza `redisClient.flushDb()` en ningún punto del código.

### Testing con Postman

- [x] `POST` con JSON en el Body — respuesta `201 Created`
- [x] `PUT` con ID en la URL y JSON en el Body — respuesta `200 OK`
- [x] `DELETE` con baja lógica verificada en pgAdmin (`activo = false`) — respuesta `200 OK`
- [x] Validación de errores: respuestas `400` y `404` ante datos incorrectos o inexistentes