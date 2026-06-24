# Documentacion de Logica de Negocio

## 1. Metricas Analiticas con Window Functions

Se implemento una consulta analitica para generar un ranking dinamico de los usuarios mas activos de la plataforma, basandose en su volumen de publicaciones.

**Problematica a resolver:**
El sistema necesita identificar a los usuarios con mayor participacion ("Top Contributors") para posibles recompensas o moderacion. Realizar este calculo mediante agrupamientos tradicionales y subconsultas genera un alto costo de procesamiento y pierde el detalle de la informacion del usuario.

**Solucion implementada:**
Se utilizo la funcion de ventana `DENSE_RANK() OVER`. A diferencia de `RANK()`, esta funcion garantiza que en caso de empates (usuarios con la misma cantidad de publicaciones), no existan saltos en la numeracion de las posiciones. El calculo se realiza de manera eficiente sobre la proyeccion final de los datos.

**Codigo SQL:**
```sql
SELECT 
    u.nombre_usuario,
    u.correo,
    COUNT(p.id_publicacion) as cantidad_publicaciones,
    DENSE_RANK() OVER (ORDER BY COUNT(p.id_publicacion) DESC) as ranking_usuario
FROM usuario u
LEFT JOIN publicacion p ON u.id_usuario = p.id_usuario
GROUP BY u.id_usuario, u.nombre_usuario, u.correo
ORDER BY ranking_usuario ASC;
```

**Ejemplo de Salida (Muestra parcial del conjunto de 100.000 registros):**

| nombre_usuario | correo | cantidad_publicaciones | ranking_usuario |
| :--- | :--- | :--- | :--- |
| Usuario63787 | user63787@test.com | 20 | 1 |
| Usuario79509 | user79509@test.com | 17 | 2 |
| Usuario48401 | user48401@test.com | 16 | 3 |
| Usuario67968 | user67968@test.com | 16 | 3 |
| Usuario79970 | user79970@test.com | 16 | 3 |
| Usuario63654 | user63654@test.com | 15 | 4 |
| Usuario5551 | user5551@test.com | 13 | 5 |

## 2. Consultas Recursivas ( CTE ) para Estructuras Jerarquicas

Para soportar el sistema de respuestas de la plataforma, se desarrollo una consulta recursiva capaz de reconstruir los hilos de comentarios anidados.

**Problematica a resolver:**
La tabla `comentario` posee una estructura autorreferencial (la columna `id_comentario_padre` apunta a la misma tabla). Obtener un hilo completo de conversacion linealmente es imposible con consultas `JOIN` tradicionales, ya que la profundidad de las respuestas es dinamica e indefinida.

**Solucion implementada:**
Se aplico un Common Table Expression (CTE) del tipo `WITH RECURSIVE`. El motor ejecuta un caso base para identificar los comentarios raiz (donde el padre es nulo) y luego itera recursivamente uniendo cada respuesta con su comentario originario. Adicionalmente, se genera un campo `ruta_jerarquia` que mapea el camino exacto del hilo.

**Codigo SQL:**
```sql
WITH RECURSIVE hilo_comentarios AS (
    -- Caso base: Comentarios principales
    SELECT 
        id_comentario, 
        cuerpo, 
        id_comentario_padre, 
        id_publicacion, 
        1 as nivel,
        CAST(id_comentario AS TEXT) as ruta_jerarquia
    FROM comentario
    WHERE id_comentario_padre IS NULL

    UNION ALL

    -- Caso recursivo: Unir respuestas
    SELECT 
        c.id_comentario, 
        c.cuerpo, 
        c.id_comentario_padre, 
        c.id_publicacion, 
        hc.nivel + 1,
        hc.ruta_jerarquia || ' -> ' || c.id_comentario
    FROM comentario c
    JOIN hilo_comentarios hc ON c.id_comentario_padre = hc.id_comentario
)
SELECT * FROM hilo_comentarios 
ORDER BY id_publicacion, ruta_jerarquia;
```

**Ejemplo de Salida (Muestra parcial del conjunto de 400.000 registros evaluados):**

| id_comentario | cuerpo | id_comentario_padre | id_publicacion | nivel | ruta_jerarquia |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 15716 | Comentario de respuesta 15716 | 4 | 1 | 1 | 15716 |
| 121645 | Comentario de respuesta 121645 | 7 | 1 | 1 | 121645 |
| 273218 | Comentario de respuesta 273218 | 7 | 1 | 1 | 273218 |
| 301794 | Comentario de respuesta 301794 | 9 | 1 | 1 | 301794 |
| 53657 | Comentario de respuesta 53657 | 9 | 1 | 1 | 53657 |
