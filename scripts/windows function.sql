SELECT 
    u.nombre_usuario,
    u.correo,
    COUNT(p.id_publicacion) as cantidad_publicaciones,
    DENSE_RANK() OVER (ORDER BY COUNT(p.id_publicacion) DESC) as ranking_usuario
FROM usuario u
LEFT JOIN publicacion p ON u.id_usuario = p.id_usuario
GROUP BY u.id_usuario, u.nombre_usuario, u.correo
ORDER BY ranking_usuario ASC;
