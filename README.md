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
