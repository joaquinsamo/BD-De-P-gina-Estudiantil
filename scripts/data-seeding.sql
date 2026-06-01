INSERT INTO rol(nombre)
SELECT 'Rol' || i
FROM generate_series(1,10) AS i;

INSERT INTO categoria(nombre)
SELECT 'Categoria' || i
FROM generate_series(1,10) AS i;

INSERT INTO usuario(nombre_usuario, correo, contrasena_hash, id_rol, periodo_actividad)
SELECT
    'Usuario' || i,
    'Correo' || i || '@test.com',
    'Contraseña' || i,
    r.id_rol,
    tsrange('2020-01-01', '2025-12-31')
FROM generate_series(1, 100000) AS i
CROSS JOIN LATERAL (
    SELECT id_rol FROM rol
    OFFSET (floor(random() * (SELECT COUNT(*) FROM rol)))::int
    LIMIT 1
) AS r;

INSERT INTO publicacion (titulo, cuerpo, id_usuario, id_categoria, etiquetas)
SELECT
    'Titulo' || i,
    'Cuerpo' || i,
    u.id_usuario,
    cat.id_categoria,
    CASE WHEN random() < 0.3 THEN '{"urgente": true}'::jsonb
         WHEN random() < 0.6 THEN '{"importante": true}'::jsonb
         ELSE '{"normal": true}'::jsonb END
FROM generate_series(1, 500000) AS i
CROSS JOIN LATERAL (
    SELECT id_usuario FROM usuario
    OFFSET (floor(random() * (SELECT COUNT(*) FROM usuario)))::int
    LIMIT 1
) AS u
CROSS JOIN LATERAL (
    SELECT id_categoria FROM categoria
    OFFSET (floor(random() * (SELECT COUNT(*) FROM categoria)))::int
    LIMIT 1
) AS cat;

INSERT INTO comentario (cuerpo, id_publicacion, id_usuario, id_comentario_padre)
SELECT
    'Comentario' || i,
    p.id_publicacion,
    u.id_usuario,
    NULL
FROM generate_series(1, 200000) AS i
CROSS JOIN LATERAL (
    SELECT id_publicacion FROM publicacion
    OFFSET (floor(random() * (SELECT COUNT(*) FROM publicacion)))::int
    LIMIT 1
) AS p
CROSS JOIN LATERAL (
    SELECT id_usuario FROM usuario
    OFFSET (floor(random() * (SELECT COUNT(*) FROM usuario)))::int
    LIMIT 1
) AS u;

UPDATE comentario
SET id_comentario_padre = padre.id_comentario
FROM (
    SELECT c.id_comentario AS hijo, p.id_comentario
    FROM comentario c
    CROSS JOIN LATERAL (
        SELECT id_comentario FROM comentario
        OFFSET (floor(random() * (SELECT COUNT(*) FROM comentario)))::int
        LIMIT 1
    ) AS p
    WHERE random() < 0.3
      AND c.id_comentario <> p.id_comentario
) AS padre
WHERE comentario.id_comentario = padre.hijo;

WITH u AS (
    SELECT id_usuario, ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM usuario
),
p AS (
    SELECT id_publicacion, ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM publicacion
)
INSERT INTO voto_publicacion (valor, id_usuario, id_publicacion)
SELECT
    CASE WHEN random() < 0.5 THEN 1 ELSE -1 END,
    u.id_usuario,
    p.id_publicacion
FROM u JOIN p ON u.rn = p.rn
WHERE u.rn <= 50000;

WITH u AS (
    SELECT id_usuario, ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM usuario
),
c AS (
    SELECT id_comentario, ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM comentario
)
INSERT INTO voto_comentario (valor, id_usuario, id_comentario)
SELECT
    CASE WHEN random() < 0.5 THEN 1 ELSE -1 END,
    u.id_usuario,
    c.id_comentario
FROM u JOIN c ON u.rn = c.rn
WHERE u.rn <= 50000;

WITH u AS (
    SELECT id_usuario, ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM usuario
),
p AS (
    SELECT id_publicacion, ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM publicacion
)
INSERT INTO reporte_publicacion (motivo, id_usuario, id_publicacion, ventana_revision)
SELECT
    'Motivo' || u.rn,
    u.id_usuario,
    p.id_publicacion,
    tsrange(inicio, inicio + interval '7 days')
FROM u
JOIN p ON u.rn = p.rn
CROSS JOIN LATERAL (
    SELECT ('2024-01-01'::timestamp + (random() * 358)::int * interval '1 day') AS inicio
) AS rango
WHERE u.rn <= 50000;

WITH u AS (
    SELECT id_usuario, ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM usuario
),
c AS (
    SELECT id_comentario, ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM comentario
)
INSERT INTO reporte_comentario (motivo, id_usuario, id_comentario)
SELECT
    'Motivo' || u.rn,
    u.id_usuario,
    c.id_comentario
FROM u JOIN c ON u.rn = c.rn
WHERE u.rn <= 50000;

SELECT
    (SELECT COUNT(*) FROM rol)                 AS total_roles,
    (SELECT COUNT(*) FROM usuario)             AS total_usuarios,
    (SELECT COUNT(*) FROM categoria)           AS total_carreras,
    (SELECT COUNT(*) FROM publicacion)         AS total_publicacion,
    (SELECT COUNT(*) FROM comentario)          AS total_comentarios,
    (SELECT COUNT(*) FROM voto_publicacion)    AS total_voto_publicacion,
    (SELECT COUNT(*) FROM voto_comentario)     AS total_voto_comentario,
    (SELECT COUNT(*) FROM reporte_publicacion) AS total_rep_publicacion,
    (SELECT COUNT(*) FROM reporte_comentario)  AS total_rep_comentario;
