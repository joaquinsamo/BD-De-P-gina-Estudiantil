WITH RECURSIVE hilo_comentarios AS (
    -- Caso base
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

    -- Caso recursivo
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
