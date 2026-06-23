// index.js - Proyecto Integrador Parte 4
// Arquitecturas Híbridas e Integración

const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// =============================================
// CONFIGURACIÓN DE MIDDLEWARES
// =============================================
app.use(cors());
app.use(express.json());

// =============================================
// CONEXIÓN A POSTGRESQL
// =============================================
const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'foro_db',
    password: process.env.DB_PASSWORD || 'postgres',
    port: process.env.DB_PORT || 5432,
});

pool.connect()
    .then(() => console.log('✅ Conectado a PostgreSQL'))
    .catch(err => console.error('❌ Error conectando a PostgreSQL:', err));

// =============================================
// CONEXIÓN A REDIS
// =============================================
const redisClient = redis.createClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379'
});

redisClient.on('error', (err) => console.error('❌ Redis Client Error:', err));
redisClient.on('connect', () => console.log('✅ Conectado a Redis'));

(async () => {
    await redisClient.connect();
})();

// =============================================
// 1. OPERACIÓN CREATE (POST)
// =============================================
app.post('/api/publicaciones', async (req, res) => {
    const { titulo, cuerpo, id_usuario, id_categoria, etiquetas } = req.body;

    // Validación de campos requeridos
    if (!titulo || !cuerpo || !id_usuario || !id_categoria) {
        return res.status(400).json({
            error: 'Faltan campos requeridos: titulo, cuerpo, id_usuario, id_categoria'
        });
    }

    try {
        // Verificar que el usuario existe
        const usuarioCheck = await pool.query(
            'SELECT id_usuario FROM usuario WHERE id_usuario = $1',
            [id_usuario]
        );
        if (usuarioCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Verificar que la categoría existe
        const categoriaCheck = await pool.query(
            'SELECT id_categoria FROM categoria WHERE id_categoria = $1',
            [id_categoria]
        );
        if (categoriaCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Categoría no encontrada' });
        }

        // Insertar nueva publicación
        const result = await pool.query(
            `INSERT INTO publicacion (titulo, cuerpo, id_usuario, id_categoria, etiquetas)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING *`,
            [titulo, cuerpo, id_usuario, id_categoria, etiquetas || null]
        );

        // =============================================
        // INVALIDACIÓN SELECTIVA DE CACHÉ
        // PROHIBIDO: redisClient.flushDb()
        // =============================================
        const keys = await redisClient.keys('publicaciones:*');
        if (keys.length > 0) {
            await redisClient.del(keys);
            console.log(`🗑️  Caché invalidado: ${keys.length} llaves eliminadas`);
        }

        res.status(201).json({
            mensaje: '✅ Publicación creada exitosamente',
            publicacion: result.rows[0]
        });

    } catch (error) {
        console.error('Error al crear publicación:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// =============================================
// 2. OPERACIÓN UPDATE (PUT)
// =============================================
app.put('/api/publicaciones/:id', async (req, res) => {
    const { id } = req.params;
    const { titulo, cuerpo, id_categoria, esta_resuelto, etiquetas } = req.body;

    // Validar que al menos un campo venga en el body
    if (!titulo && !cuerpo && !id_categoria && esta_resuelto === undefined && !etiquetas) {
        return res.status(400).json({
            error: 'Debe proporcionar al menos un campo para actualizar'
        });
    }

    try {
        // Verificar que la publicación existe
        const publicacionCheck = await pool.query(
            'SELECT id_publicacion FROM publicacion WHERE id_publicacion = $1',
            [id]
        );
        if (publicacionCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Publicación no encontrada' });
        }

        // Construir consulta dinámica
        const updates = [];
        const values = [];
        let paramCounter = 1;

        if (titulo) {
            updates.push(`titulo = $${paramCounter}`);
            values.push(titulo);
            paramCounter++;
        }
        if (cuerpo) {
            updates.push(`cuerpo = $${paramCounter}`);
            values.push(cuerpo);
            paramCounter++;
        }
        if (id_categoria) {
            // Verificar que la categoría existe
            const categoriaCheck = await pool.query(
                'SELECT id_categoria FROM categoria WHERE id_categoria = $1',
                [id_categoria]
            );
            if (categoriaCheck.rows.length === 0) {
                return res.status(404).json({ error: 'Categoría no encontrada' });
            }
            updates.push(`id_categoria = $${paramCounter}`);
            values.push(id_categoria);
            paramCounter++;
        }
        if (esta_resuelto !== undefined) {
            updates.push(`esta_resuelto = $${paramCounter}`);
            values.push(esta_resuelto);
            paramCounter++;
        }
        if (etiquetas) {
            updates.push(`etiquetas = $${paramCounter}`);
            values.push(etiquetas);
            paramCounter++;
        }

        values.push(id);

        const query = `
            UPDATE publicacion 
            SET ${updates.join(', ')}
            WHERE id_publicacion = $${paramCounter}
            RETURNING *
        `;

        const result = await pool.query(query, values);

        // =============================================
        // INVALIDACIÓN SELECTIVA DE CACHÉ
        // PROHIBIDO: redisClient.flushDb()
        // =============================================
        const keys = await redisClient.keys('publicaciones:*');
        if (keys.length > 0) {
            await redisClient.del(keys);
            console.log(`🗑️  Caché invalidado: ${keys.length} llaves eliminadas`);
        }

        res.status(200).json({
            mensaje: '✅ Publicación actualizada exitosamente',
            publicacion: result.rows[0]
        });

    } catch (error) {
        console.error('Error al actualizar publicación:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// =============================================
// 3. OPERACIÓN DELETE (Baja Lógica)
// =============================================
app.delete('/api/publicaciones/:id', async (req, res) => {
    const { id } = req.params;

    try {
        // Verificar que la publicación existe y su estado actual
        const publicacionCheck = await pool.query(
            'SELECT id_publicacion, activo FROM publicacion WHERE id_publicacion = $1',
            [id]
        );

        if (publicacionCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Publicación no encontrada' });
        }

        if (publicacionCheck.rows[0].activo === false) {
            return res.status(400).json({ 
                error: 'La publicación ya se encuentra desactivada' 
            });
        }

        // Baja Lógica: NO usar DELETE FROM
        const result = await pool.query(
            `UPDATE publicacion 
             SET activo = false 
             WHERE id_publicacion = $1
             RETURNING *`,
            [id]
        );

        // =============================================
        // INVALIDACIÓN SELECTIVA DE CACHÉ
        // PROHIBIDO: redisClient.flushDb()
        // =============================================
        const keys = await redisClient.keys('publicaciones:*');
        if (keys.length > 0) {
            await redisClient.del(keys);
            console.log(`🗑️  Caché invalidado: ${keys.length} llaves eliminadas`);
        }

        res.status(200).json({
            mensaje: '✅ Publicación desactivada exitosamente (Baja Lógica)',
            publicacion: result.rows[0]
        });

    } catch (error) {
        console.error('Error al desactivar publicación:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// =============================================
// 4. ENDPOINT DE CONSULTA (para demostrar caché)
// =============================================
app.get('/api/publicaciones', async (req, res) => {
    const cacheKey = 'publicaciones:all';

    try {
        // Intentar obtener del caché
        const cachedData = await redisClient.get(cacheKey);
        
        if (cachedData) {
            console.log('📦 Datos obtenidos desde Redis CACHE');
            return res.status(200).json({
                origen: 'cache',
                data: JSON.parse(cachedData)
            });
        }

        // Si no está en caché, consultar PostgreSQL
        const result = await pool.query(
            `SELECT p.id_publicacion, p.titulo, p.cuerpo, p.esta_resuelto, 
                    p.etiquetas, p.activo, u.nombre_usuario, c.nombre as categoria
             FROM publicacion p
             JOIN usuario u ON p.id_usuario = u.id_usuario
             JOIN categoria c ON p.id_categoria = c.id_categoria
             WHERE p.activo = true
             ORDER BY p.id_publicacion DESC
             LIMIT 100`
        );

        // Guardar en caché (TTL 5 minutos)
        await redisClient.set(cacheKey, JSON.stringify(result.rows), {
            EX: 300
        });

        console.log('💾 Datos obtenidos desde PostgreSQL');
        res.status(200).json({
            origen: 'base_de_datos',
            data: result.rows
        });

    } catch (error) {
        console.error('Error al obtener publicaciones:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// =============================================
// 5. ENDPOINT PARA DEMOSTRAR INVALIDACIÓN
// =============================================
app.get('/api/cache/info', async (req, res) => {
    try {
        const keys = await redisClient.keys('publicaciones:*');
        res.status(200).json({
            llaves_en_cache: keys,
            cantidad: keys.length
        });
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener info del cache' });
    }
});

// =============================================
// MIDDLEWARE DE MANEJO DE ERRORES GLOBAL
// =============================================
app.use((err, req, res, next) => {
    console.error('Error no manejado:', err);
    res.status(500).json({ 
        error: 'Error interno del servidor',
        detalles: err.message 
    });
});

// =============================================
// INICIO DEL SERVIDOR
// =============================================
app.listen(PORT, () => {
    console.log('\n=================================');
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
    console.log('=================================');
    console.log('📊 Base de Datos: PostgreSQL');
    console.log('⚡ Caché: Redis');
    console.log('\n📌 Endpoints disponibles:');
    console.log('  POST   /api/publicaciones       - Crear publicación');
    console.log('  PUT    /api/publicaciones/:id   - Actualizar publicación');
    console.log('  DELETE /api/publicaciones/:id   - Baja lógica');
    console.log('  GET    /api/publicaciones       - Listar publicaciones');
    console.log('  GET    /api/cache/info          - Ver estado del caché');
    console.log('=================================\n');
});

// =============================================
// MANEJO DE CIERRE GRACIAL
// =============================================
process.on('SIGINT', async () => {
    console.log('\n🛑 Cerrando conexiones...');
    await redisClient.quit();
    await pool.end();
    process.exit(0);
});

module.exports = app;