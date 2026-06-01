# Proyecto Integrador - Base de Datos III
## Eje I: Optimización y SQL Avanzado

### Descripción del Proyecto
Este proyecto consiste en el diseño, implementación y optimización de una base de datos relacional desarrollada en **PostgreSQL**. El sistema gestiona una plataforma de comunidad y foro con un volumen de datos superior a **1.100.000 de registros**, permitiendo validar técnicas de indexación avanzada, análisis de performance y lógica de negocio mediante SQL complejo.

### Integrantes
Grosso Joaquín, Santiago Orlando Luna, Ivo Giuliano Cappetto, Lautaro Gutierrez Lardit, Sánchez Martin, Nicolás Fernández García.

### Estructura del Repositorio:

####  /documentación
Contiene los fundamentos teóricos y los reportes de métricas:
*   **Indice.md**: Justificación de las estrategias de indexación (B-Tree, Hash, GIN y GiST).
*   **LogicaSQL.md**: Explicación técnica de la implementación de Window Functions y CTEs Recursivos.
*   **Reporte_Performance.md**: Análisis de costos y tiempos (EXPLAIN ANALYZE) con capturas.
*   **TAMAÑO INDICES.png**: Captura de pantalla del peso de los índices en el motor.

####  /MER
*   **Diagrama Entidad-Relación**: Imagen del modelo de datos normalizado en **3NF**.

#### /scripts
Scripts SQL para la reproducción total del entorno:
*   **tablas.sql**: Estructura DDL (Tablas, Claves Primarias y Foráneas).
*   **data-seeding.sql**: Carga masiva de +1.1M de registros.
*   **Indices.sql**: Creación de índices optimizados.
*   **windows function.sql**: Métricas de ranking y análisis de actividad.
*   **CTE y Recursividad.sql**: Gestión de hilos de comentarios anidados.

*   ## Checklist de Avance - Proyecto Integrador (Parte 2)


Marquen con una `X` dentro de los corchetes `[ ]` (ej: `[x]`) las tareas completadas a medida que realicen los commits en el repositorio:


### A. Abstracción y Lógica Procedural

- [x] **1.** Categorizar correctamente la volatilidad de la función (`IMMUTABLE`, `STABLE` o `VOLATILE`) analizando el consumo de CPU.

- [x] **2.** Diseñar el procedimiento almacenado principal para la tarea compleja de negocio.

- [x] **3.** Implementar la robustez de tipos en variables usando `%TYPE`, `%ROWTYPE` o `RECORD` (evitar tipos estáticos).


###  B. Gestión Avanzada de Transacciones

- [ ] **1.** Asegurar la atomicidad global del procedimiento mediante sentencias explícitas de `COMMIT` y `ROLLBACK`.

- [ ] **2.** Identificar el subproceso secundario propenso a fallas y aislarlo mediante la declaración de un `SAVEPOINT`.

- [ ] **3.** Implementar la lógica de reversión parcial (`ROLLBACK TO SAVEPOINT`) ante un error controlado.


### C. Capa de Auditoría y Forense de Datos

- [ ] **1.** Crear la tabla física `audit_logs` con los campos necesarios para metadatos del sistema.

- [ ] **2.** Implementar bloques estructurados `EXCEPTION` en los puntos críticos de los scripts.

- [ ] **3.** Utilizar `GET STACKED DIAGNOSTICS` para extraer de forma limpia el `RETURNED_SQLSTATE` y el `MESSAGE_TEXT`.


### D. Seguridad y Blindaje (Hardening)

- [ ] **1.** Configurar la cabecera del proceso administrativo crítico bajo el contexto de `SECURITY DEFINER`.

- [ ] **2.** Blindar las funciones restringiendo el vector de ataque mediante la fijación explícita del parámetro `search_path`.


### E. Automatización con Triggers

- [ ] **1.** Definir la tabla objetivo y la sincronización temporal del disparador (`BEFORE` / `AFTER`).

- [ ] **2.** Crear la función asociada al disparador aplicando lógica condicional mediante las pseudovariables `OLD` y `NEW`.

- [ ] **3.** Ejecutar la sentencia `CREATE TRIGGER` y verificar la reactividad ante eventos DML (INSERT, UPDATE o DELETE).

---

### Tecnologías y Herramientas
*   **Motor:** PostgreSQL 
*   **Visualización de Planes:** Dalibo
*   **Métricas Globales:** Extensión `pg_stat_statements`.
*   **Entorno de Desarrollo:** Windows.

### Instalación y Uso
1.  **Esquema:** Ejecutar primero `tablas.sql`.
2.  **Poblado:** Ejecutar `data-seeding.sql`. 
3.  **Optimización:** Aplicar `Indices.sql` para notar la mejora en los tiempos de respuesta.
4.  **Análisis:** Los scripts de la carpeta `/scripts` pueden ejecutarse de manera independiente para verificar la lógica de negocio.
