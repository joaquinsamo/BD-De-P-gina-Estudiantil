CREATE TABLE rol (
    id_rol SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(50) UNIQUE NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    contrasena_hash TEXT NOT NULL,
    id_rol INT NOT NULL,
    periodo_actividad TSRANGE,
    FOREIGN KEY (id_rol) REFERENCES rol(id_rol)
);

CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE publicacion (
    id_publicacion SERIAL PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    cuerpo TEXT NOT NULL,
    id_usuario INT NOT NULL,
    id_categoria INT NOT NULL,
    esta_resuelto BOOLEAN DEFAULT FALSE,
    etiquetas JSONB,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);

CREATE TABLE comentario (
    id_comentario SERIAL PRIMARY KEY,
    cuerpo TEXT NOT NULL,
    id_usuario INT NOT NULL,
    id_publicacion INT NOT NULL,
    id_comentario_padre INT,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_publicacion) REFERENCES publicacion(id_publicacion) ON DELETE CASCADE,
    FOREIGN KEY (id_comentario_padre) REFERENCES comentario(id_comentario) ON DELETE CASCADE
);

CREATE TABLE voto_publicacion (
    id_voto SERIAL PRIMARY KEY,
    valor INT CHECK (valor IN (1, -1)) NOT NULL,
    id_usuario INT NOT NULL,
    id_publicacion INT NOT NULL,
    UNIQUE (id_usuario, id_publicacion),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_publicacion) REFERENCES publicacion(id_publicacion) ON DELETE CASCADE
);

CREATE TABLE voto_comentario (
    id_voto SERIAL PRIMARY KEY,
    valor INT CHECK (valor IN (1, -1)) NOT NULL,
    id_usuario INT NOT NULL,
    id_comentario INT NOT NULL,
    UNIQUE (id_usuario, id_comentario),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_comentario) REFERENCES comentario(id_comentario) ON DELETE CASCADE
);

CREATE TABLE reporte_publicacion (
    id_reporte SERIAL PRIMARY KEY,
    motivo TEXT NOT NULL,
    id_usuario INT NOT NULL,
    id_publicacion INT NOT NULL,
    ventana_revision TSRANGE,
    UNIQUE (id_usuario, id_publicacion),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_publicacion) REFERENCES publicacion(id_publicacion) ON DELETE CASCADE
);

CREATE TABLE reporte_comentario (
    id_reporte SERIAL PRIMARY KEY,
    motivo TEXT NOT NULL,
    id_usuario INT NOT NULL,
    id_comentario INT NOT NULL,
    UNIQUE (id_usuario, id_comentario),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_comentario) REFERENCES comentario(id_comentario) ON DELETE CASCADE
);
