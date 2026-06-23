ALTER TABLE publicacion ADD COLUMN activo BOOLEAN DEFAULT TRUE;

UPDATE publicacion SET activo = true WHERE activo IS NULL;

CREATE INDEX idx_publicacion_activo ON publicacion(activo);
