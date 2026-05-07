Aquí tienes el reporte actualizado y profesionalizado. He sustituido los datos genéricos del sistema por los resultados reales de tu test de estrés, eliminando la captura innecesaria y ajustando las conclusiones para que reflejen tu trabajo de ingeniería.

---

# Analisis de Performance 

## Objetivo del Analisis
El presente documento detalla las pruebas de rendimiento realizadas sobre una base de datos con un volumen superior a **1.100.000 de registros**. Se busca validar la eficacia de los indices implementados comparando los planes de ejecucion y analizando las metricas de consumo de recursos del servidor mediante pruebas de carga controladas.

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

<img width="422" height="268" alt="1" src="https://github.com/user-attachments/assets/9f1d4938-733c-4ff4-b90c-ff7ff846aa8f" />


### Escenario Post-Optimizacion (Con Indice GIN)
Tras la creacion del indice **idx_publicacion_etiquetas_gin**, el motor de base de datos cambio su estrategia de acceso.

*   **Metodo de acceso:** Bitmap Index Scan / Bitmap Heap Scan.
*   **Costo Total Estimado:** 12.380,26.
*   **Resultados del Analisis:** El motor utilizo el indice para localizar unicamente las paginas de datos relevantes. Se observa el uso explicito del nodo **using idx_publicacion_etiquetas_gin**, lo que reduce el escaneo de filas irrelevantes y optimiza el uso de la memoria RAM.

<img width="358" height="571" alt="2" src="https://github.com/user-attachments/assets/afbbb79d-d7b3-436f-97bf-a4c9534b8c05" />


---

## Estadisticas Globales del Servidor

Para el monitoreo de la actividad general, se utilizo la extension **pg_stat_statements**, registrando el historial de operaciones de negocio tras un test de 10 ejecuciones consecutivas por cada funcionalidad crítica.

### Top de Operaciones por Tiempo de Ejecución

| Operación de Negocio | Llamadas | Tiempo Total (ms) | Tiempo Promedio (ms) |
| :--- | :---: | :---: | :---: |
| **Ranking de Reputación (Window Function)** | 10 | 468.42 | 46.842 |
| **Hilos de Comentarios (Recursividad)** | 10 | 0.29 | 0.029 |
| **Moderación de Reportes (GiST Index)** | 10 | 0.24 | 0.024 |
| **Búsqueda por Etiquetas (GIN Index)** | 10 | 0.11 | 0.011 |
| **Autenticación (Hash Index)** | 10 | 0.06 | 0.006 |
<img width="577" height="165" alt="sg" src="https://github.com/user-attachments/assets/42852419-003f-4c90-be6b-652b22fa4958" />

### Conclusiones del Monitoreo
Las métricas reflejan que, tras la estabilización de los planes de ejecución en el Buffer Cache, las consultas optimizadas con índices especializados (**Hash, GIN y GiST**) presentan tiempos de respuesta sub-milisegundos (inferiores a **0.03 ms**). La operación de mayor carga corresponde al Ranking de Reputación, lo cual es coherente debido al procesamiento analítico de agregación y ordenamiento sobre el gran volumen de datos.

## Conclusion General
La implementacion de indices especializados permitió transformar operaciones de lectura costosas en accesos optimizados de alta velocidad. Asimismo, la integración de **Window Functions** y **Consultas Recursivas** permite resolver estructuras jerárquicas y métricas complejas de forma eficiente. El sistema garantiza una respuesta óptima y escalable, manteniendo la integridad del rendimiento a pesar de superar el millón de registros en las tablas principales.
