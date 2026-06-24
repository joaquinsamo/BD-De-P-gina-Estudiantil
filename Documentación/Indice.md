# Estrategias de Indexación y Justificación Técnica

En esta fase del proyecto, se han implementado diversos tipos de índices para optimizar el rendimiento de la base de datos, considerando un volumen de datos superior a **1.000.000 de registros**.

---

## Índices Implementados

| Tipo de Índice | Tabla | Columna | Propósito |
| :--- | :--- | :--- | :--- |
| **B-Tree** | `publicacion` | `id_usuario` | Optimización de JOINs y filtros de autoría. |
| **Hash** | `usuario` | `correo` | Búsqueda de igualdad exacta para autenticación. |
| **GIN** | `publicacion` | `etiquetas` (JSONB) | Búsqueda dentro de estructuras de datos anidadas. |
| **GiST** | `reporte_publicacion` | `ventana_revision` (tsrange) | Gestión de solapamientos e intersección de tiempo. |

---

## Justificación

### 1. B-Tree (Balanced Tree)
*   **Implementación:** Aplicado sobre `id_usuario` en la tabla `publicacion`.
*   **Justificación:** Es el índice por defecto y más versátil. Dado que las consultas más frecuentes implican obtener todas las publicaciones de un usuario específico, el B-Tree reduce la complejidad de búsqueda de un escaneo secuencial $O(N)$ a uno logarítmico $O(\log N)$. Esto es vital para mantener la fluidez en un set de **500.000 filas**.

### 2. Hash Index
*   **Implementación:** Aplicado sobre `usuario.correo`.
*   **Justificación:** Las búsquedas por correo electrónico en nuestra plataforma son exclusivamente de **igualdad exacta** (durante el login). Los índices Hash en PostgreSQL están optimizados para este escenario, ofreciendo una velocidad de recuperación $O(1)$, siendo más compactos y rápidos que un B-Tree para cadenas de texto largas donde no se requieren búsquedas por rango.

### 3. GIN (Generalized Inverted Index)
*   **Implementación:** Aplicado sobre la columna `etiquetas` de tipo **JSONB**.
*   **Justificación:** Para permitir que la aplicación filtre publicaciones por etiquetas dinámicas (ej: `{"urgente": true}`), es necesario un índice que pueda "entrar" en el objeto JSON. GIN permite indexar cada clave y valor interno, evitando que la base de datos tenga que procesar cada documento individualmente.

### 4. GiST (Generalized Search Tree)
*   **Implementación:** Aplicado sobre `ventana_revision` de tipo **tsrange**.
*   **Justificación:** Los índices convencionales no pueden procesar eficientemente tipos de datos de rango. GiST permite utilizar operadores de **intersección** (`&&`) y **contención** (`@>`). Esto permite gestionar de manera óptima los solapamientos de fechas en el sistema de reportes, asegurando que no haya conflictos temporales en las revisiones.

---

## Impacto en el Rendimiento
El uso de estas estrategias permite que consultas que originalmente tardarían cientos de milisegundos (debido al alto volumen de carga masiva) se resuelvan en tiempos cercanos a **< 1ms**.
