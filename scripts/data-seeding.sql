INSERT INTO rol(nombre) 
SELECT 'Rol' || i
FROM generate_series(1,10) AS i;

INSERT INTO categoria(nombre) 
SELECT 'Categoria' || i
FROM generate_series(1,10) AS i;

INSERT INTO usuario(nombre_usuario,correo,contrasena_hash,id_rol)
SELECT 'Usuario' ||i,
		'Correo' || i,
		'Contrasenia' || i,
		(SELECT id_rol FROM rol ORDER BY random() LIMIT 1)
FROM generate_series(1, 100000) AS i;

INSERT INTO publicacion (titulo,cuerpo,id_usuario,id_categoria)
SELECT 'Titulo' || i,
		'Cuerpo' || i,
		(SELECT id_usuario FROM usuario ORDER BY random() LIMIT 1),
		(SELECT id_categoria FROM categoria ORDER BY random() LIMIT 1)
FROM generate_series(1,500000) AS i;
		
		
INSERT INTO comentario (cuerpo,id_publicacion,id_usuario,id_comentario_padre)
SELECT 'Comentario' || i,
	   (SELECT id_publicacion FROM publicacion ORDER BY random() LIMIT 1),
	   (SELECT id_usuario FROM usuario ORDER BY random() LIMIT 1),
	   (SELECT id_comentario FROM comentario ORDER BY random() LIMIT 1)
FROM generate_series(1,200000) AS i;

INSERT INTO voto_publicacion (valor, id_usuario, id_publicacion)
SELECT DISTINCT ON (id_usuario, id_publicacion)  
    CASE 
        WHEN random() < 0.5 THEN 1 
        ELSE -1 
    END as valor,
    (floor(random() * 1000) + 1)::int as id_usuario,
    (floor(random() * 5000) + 1)::int as id_publicacion
FROM generate_series(1, 100000) 
LIMIT 50000;

INSERT INTO voto_comentario (valor, id_usuario, id_comentario)
SELECT DISTINCT ON (id_usuario, id_comentario)  
    CASE 
        WHEN random() < 0.5 THEN 1 
        ELSE -1 
    END as valor,
    (floor(random() * 1000) + 1)::int as id_usuario,
    (floor(random() * 5000) + 1)::int as id_comentario
FROM generate_series(1, 100000) 
LIMIT 50000;



INSERT INTO reporte_publicacion (motivo, id_usuario, id_publicacion)
SELECT DISTINCT ON (id_usuario, id_publicacion)  
     'Motivo' || i,
    (floor(random() * 1000) + 1)::int as id_usuario,
    (floor(random() * 5000) + 1)::int as id_publicacion
FROM generate_series(1, 100000) as i
LIMIT 50000;


INSERT INTO reporte_comentario (motivo, id_usuario, id_comentario)
SELECT DISTINCT ON (id_usuario, id_comentario)  
    'Motivo' || i,
    (floor(random() * 1000) + 1)::int as id_usuario,
    (floor(random() * 5000) + 1)::int as id_comentario
FROM generate_series(1, 100000) as i 
LIMIT 50000;

SELECT
(SELECT COUNT(*) FROM rol) AS total_roles,
(SELECT COUNT(*) FROM usuario) AS total_usuarios,
(SELECT COUNT(*) FROM categoria) AS total_carreras,
(SELECT COUNT(*) FROM publicacion) AS total_publicacion,
(SELECT COUNT(*) FROM comentario) AS total_comentarios,
(SELECT COUNT(*) FROM voto_publicacion) AS total_voto_publicacion,
(SELECT COUNT(*) FROM voto_comentario) AS total_voto_comentario,
(SELECT COUNT(*) FROM reporte_publicacion) AS total_rep_publicacion,
(SELECT COUNT(*) FROM reporte_comentario) AS total_rep_comentario;

