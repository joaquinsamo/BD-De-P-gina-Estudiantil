# Proyecto Integrador - Base de Datos III
## Eje I: Optimización y SQL Avanzado

### Descripción del Proyecto
Este proyecto consiste en el diseño, implementación y optimización de una base de datos relacional desarrollada en **PostgreSQL**. El sistema gestiona una plataforma de comunidad y foro con un volumen de datos superior a **1.100.000 de registros**, permitiendo validar técnicas de indexación avanzada, análisis de performance y lógica de negocio mediante SQL complejo.

### Integrantes
Grosso Joaquín, Santiago Orlando Luna, Ivo Giuliano Cappetto, Lautaro Gutierrez Lardit, Sánchez Martin, Nicolás Fernández García.

## Estructura del Repositorio
 
#### `/documentacion`
- **Indice.md**: Justificación de las estrategias de indexación (B-Tree, Hash, GIN y GiST).
- **LogicaSQL.md**: Explicación técnica de Window Functions y CTEs Recursivos.
- **Reporte_Performance.md**: Análisis de costos y tiempos (`EXPLAIN ANALYZE`) con capturas.
- **TAMAÑO_INDICES.png**: Captura del peso de los índices en el motor.
#### `/MER`
- **Diagrama Entidad-Relación**: Modelo de datos normalizado en **3NF**.
#### `/scripts/parte1`
- `tablas.sql`: Estructura DDL (Tablas, Claves Primarias y Foráneas).
- `data-seeding.sql`: Carga masiva de +1.1M de registros.
- `Indices.sql`: Creación de índices optimizados.
- `windows function.sql`: Métricas de ranking y análisis de actividad.
- `CTE y Recursividad.sql`: Gestión de hilos de comentarios anidados.
#### `/scripts/parte2`
- `seccionA_funcion_score.sql`: Función `calcular_score_publicacion` — volatilidad `STABLE`, `%TYPE`.
- `seccionBC_auditoria.sql`: Tabla `audit_logs` y función `registrar_actividad_comentario`.
- `seccionD_procedimiento.sql`: Procedimiento `crear_comentario_seguro` — transacciones, auditoría, seguridad.
- `seccionE_trigger.sql`: Trigger `AFTER UPDATE` con `OLD`/`NEW` y prueba DML.
---

*   ## Checklist de Avance - Proyecto Integrador (Parte 2)


Marquen con una `X` dentro de los corchetes `[ ]` (ej: `[x]`) las tareas completadas a medida que realicen los commits en el repositorio:


### A. Abstracción y Lógica Procedural

- [x] **1.** Categorizar correctamente la volatilidad de la función (`IMMUTABLE`, `STABLE` o `VOLATILE`) analizando el consumo de CPU.

- [x] **2.** Diseñar el procedimiento almacenado principal para la tarea compleja de negocio.

- [x] **3.** Implementar la robustez de tipos en variables usando `%TYPE`, `%ROWTYPE` o `RECORD` (evitar tipos estáticos).

###  B. Gestión Avanzada de Transacciones

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

---

### Tecnologías y Herramientas
*   **Motor:** PostgreSQL 
*   **Visualización de Planes:** Dalibo
*   **Métricas Globales:** Extensión `pg_stat_statements`.
*   **Entorno de Desarrollo:** Windows.

## Instalación y Uso
1. **Esquema:** Ejecutar primero `scripts/parte1/tablas.sql`.
2. **Poblado:** Ejecutar `scripts/parte1/data-seeding.sql`.
3. **Optimización:** Aplicar `scripts/parte1/Indices.sql` para notar la mejora en los tiempos de respuesta.
4. **Análisis:** Los scripts de `/scripts/parte1` pueden ejecutarse de manera independiente para verificar la lógica de negocio.
5. **Parte 2:** Ejecutar los scripts de `/scripts/parte2` en orden alfabético sobre la base ya poblada.
