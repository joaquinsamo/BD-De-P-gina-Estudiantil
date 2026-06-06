CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE INDEX idx_publicacion_id_usuario ON publicacion(id_usuario);

CREATE INDEX idx_usuario_correo_hash ON usuario USING HASH (correo);

CREATE INDEX idx_publicacion_etiquetas_gin ON publicacion USING GIN (etiquetas);

CREATE INDEX idx_publicacion_titulo_fts ON publicacion USING GIN (to_tsvector('spanish', titulo));

CREATE INDEX idx_reporte_ventana_gist ON reporte_publicacion USING GIST (ventana_revision);
