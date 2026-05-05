# Analisis de Performance 

## Objetivo del Analisis
El presente documento detalla las pruebas de rendimiento realizadas sobre una base de datos con un volumen superior a **1.100.000 de registros**. Se busca validar la eficacia de los indices implementados comparando los planes de ejecucion y analizando las metricas de consumo de recursos del servidor.

## Analisis de Consulta sobre Campo JSONB

Se realizo una prueba de estres sobre la tabla **publicacion** (500.000 registros), filtrando por una clave interna del campo estructurado **etiquetas**.

**Consulta ejecutada:**
```sql
SELECT count(*) FROM publicacion 
WHERE etiquetas @> '{"urgente": true}';
```

### Escenario Pre-Optimizacion (Sin Indices)
En ausencia de indices especializados, el planificador de consultas recurrio a una lectura total de la tabla.

*   **Metodo de acceso:** Parallel Seq Scan.
*   **Costo Total Estimado:** 13.855,43.
*   **Resultados del Analisis:** El motor debio procesar la totalidad de los registros, descartando 399.714 filas que no cumplian con el filtro (Rows Removed by Filter). Esto representa un alto consumo de I/O y tiempo de procesamiento innecesario.

<img width="422" height="268" alt="1" src="https://github.com/user-attachments/assets/d75d9ae2-1077-4c50-9410-884459631b98" />

### Escenario Post-Optimizacion (Con Indice GIN)
Tras la creacion del indice **idx_publicacion_etiquetas_gin**, el motor de base de datos cambio su estrategia de acceso.

*   **Metodo de acceso:** Bitmap Index Scan / Bitmap Heap Scan.
*   **Costo Total Estimado:** 12.380,26.
*   **Resultados del Analisis:** El motor utilizo el indice para localizar unicamente las paginas de datos relevantes. Se observa el uso explicito del nodo **using idx_publicacion_etiquetas_gin**, lo que reduce el escaneo de filas irrelevantes y optimiza el uso de la memoria RAM.

<img width="358" height="571" alt="2" src="https://github.com/user-attachments/assets/740be7f6-a0cf-4d5c-8aa2-d081ed8bcbc2" />
## Estadisticas Globales del Servidor

Para el monitoreo de la actividad general, se utilizo la extension **pg_stat_statements**, la cual permite registrar el historico de consultas y sus tiempos de respuesta.

### Top 5 de Consultas con Mayor Tiempo de Ejecucion

| Consulta Breve | Llamadas | Tiempo Total (ms) | Tiempo Promedio (ms) | Filas Afectadas |
| :--- | :--- | :--- | :--- | :--- |
| SELECT set_config($1,$2,$3) FROM pg_show_all_setti | 3 | 21.10 | 7.03 | 3 |
| SELECT set_config($1,$2,$3) FROM pg_show_all_setti | 1 | 14.12 | 14.12 | 1 |
| SELECT DISTINCT att.attname as name, att.attnum as | 1 | 11.53 | 11.53 | 49 |
| CREATE EXTENSION IF NOT EXISTS pg_stat_statements | 1 | 2.94 | 2.94 | 0 |
| SELECT * FROM pg_stat_statements LIMIT $1 | 1 | 0.79 | 0.79 | 1 |
<img width="901" height="183" alt="metricas 3" src="https://github.com/user-attachments/assets/e6d24d8f-ae03-4d5e-9feb-d2b9ed5161bf" />

### Conclusiones del Monitoreo
Las metricas reflejan que la mayor carga actual corresponde a tareas de configuracion del servidor y la inicializacion de extensiones de monitoreo. La consulta de reporte (`SELECT * FROM pg_stat_statements`) presenta un tiempo de ejecucion promedio de **0.79ms**, confirmando que el servidor mantiene una respuesta optima tras la aplicacion de indices.

## Conclusion General
La implementacion de indices especializados (GIN para JSONB y GiST para rangos) permitio transformar operaciones de lectura costosas en accesos optimizados. Esto garantiza que el sistema pueda escalar y mantener tiempos de respuesta bajos a pesar de contar con mas de un millon de registros en sus tablas principales.
