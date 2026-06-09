/**
 * EJEMPLOS DE IMPLEMENTACIÓN - Cache-Aside Pattern
 * Usando Node.js + Redis + PostgreSQL
 * 
 * Instalar dependencias:
 * npm install redis pg dotenv
 */

const redis = require('redis');
const { Pool } = require('pg');
require('dotenv').config();

// ================================================================
// CONFIGURACIÓN
// ================================================================

// Cliente Redis
const redisClient = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
    }
});

redisClient.on('error', (err) => {
    console.error('Redis Error:', err);
});

redisClient.on('connect', () => {
    console.log('✓ Conectado a Redis');
});

// Pool de conexiones PostgreSQL
const dbPool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'comunidad_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'password'
});

dbPool.on('error', (err) => {
    console.error('Database Error:', err);
});

// Logger helper
const logger = {
    info: (msg) => console.log(`[INFO] ${new Date().toISOString()} - ${msg}`),
    error: (msg) => console.error(`[ERROR] ${new Date().toISOString()} - ${msg}`),
    warn: (msg) => console.warn(`[WARN] ${new Date().toISOString()} - ${msg}`),
    debug: (msg) => console.debug(`[DEBUG] ${new Date().toISOString()} - ${msg}`)
};

// ================================================================
// EJEMPLO 1: Obtener Perfil de Usuario (Cache-Aside)
// ================================================================

/**
 * Obtiene perfil de usuario con caché
 * Clave: user:{userId}
 * TTL: 300 segundos (5 minutos)
 */
async function getUserProfile(userId) {
    const cacheKey = `user:${userId}`;
    
    try {
        // 1. CONSULTAR CACHÉ
        logger.debug(`Consultando caché: ${cacheKey}`);
        const cachedUser = await new Promise((resolve, reject) => {
            redisClient.get(cacheKey, (err, data) => {
                if (err) reject(err);
                resolve(data);
            });
        });
        
        if (cachedUser) {
            logger.info(`✓ CACHE HIT: ${cacheKey}`);
            return JSON.parse(cachedUser);
        }
        
        logger.warn(`✗ CACHE MISS: ${cacheKey} - Consultando BD...`);
        
        // 2. CACHE MISS - CONSULTAR BASE DE DATOS
        const result = await dbPool.query(
            `SELECT 
                u.user_id,
                u.username,
                u.email,
                u.created_at,
                u.profile_picture_url,
                COUNT(DISTINCT p.publication_id) as total_publications,
                COUNT(DISTINCT c.comment_id) as total_comments
            FROM usuarios u
            LEFT JOIN publicaciones p ON u.user_id = p.user_id
            LEFT JOIN comentarios c ON u.user_id = c.user_id
            WHERE u.user_id = $1
            GROUP BY u.user_id, u.username, u.email, u.created_at, u.profile_picture_url`,
            [userId]
        );
        
        if (result.rows.length === 0) {
            logger.warn(`Usuario no encontrado: ${userId}`);
            return null;
        }
        
        const user = result.rows[0];
        
        // 3. GUARDAR EN CACHÉ
        logger.debug(`Guardando en caché: ${cacheKey}`);
        await new Promise((resolve, reject) => {
            redisClient.setex(
                cacheKey,
                300,  // TTL: 5 minutos
                JSON.stringify(user),
                (err) => {
                    if (err) reject(err);
                    resolve();
                }
            );
        });
        
        logger.info(`Dato guardado en caché: ${cacheKey}`);
        return user;
        
    } catch (error) {
        logger.error(`Error en getUserProfile(${userId}): ${error.message}`);
        
        // FALLBACK: Si Redis falla, intentar solo BD
        if (error.message.includes('Redis')) {
            logger.warn('Redis no disponible, consultando BD directamente...');
            const result = await dbPool.query(
                'SELECT * FROM usuarios WHERE user_id = $1',
                [userId]
            );
            return result.rows[0] || null;
        }
        
        throw error;
    }
}

// ================================================================
// EJEMPLO 2: Obtener Feed Reciente (Patrón Cache-Aside)
// ================================================================

/**
 * Obtiene últimas publicaciones del feed
 * Clave: feed:latest
 * TTL: 60 segundos (1 minuto) - Feed es muy dinámico
 */
async function getLatestFeed(limit = 50) {
    const cacheKey = 'feed:latest';
    
    try {
        // 1. CONSULTAR CACHÉ
        const cachedFeed = await new Promise((resolve, reject) => {
            redisClient.get(cacheKey, (err, data) => {
                if (err) reject(err);
                resolve(data);
            });
        });
        
        if (cachedFeed) {
            logger.info(`✓ CACHE HIT: ${cacheKey}`);
            return JSON.parse(cachedFeed);
        }
        
        logger.warn(`✗ CACHE MISS: ${cacheKey}`);
        
        // 2. CACHE MISS - CONSULTAR BASE DE DATOS
        const result = await dbPool.query(
            `SELECT 
                p.publication_id,
                p.title,
                p.content,
                p.created_at,
                u.username,
                u.user_id,
                COUNT(DISTINCT c.comment_id) as comment_count,
                COUNT(DISTINCT r.reaction_id) as reaction_count,
                ROUND(score_publication(p.publication_id)::numeric, 2) as score
            FROM publicaciones p
            JOIN usuarios u ON p.user_id = u.user_id
            LEFT JOIN comentarios c ON p.publication_id = c.publication_id
            LEFT JOIN reactions r ON p.publication_id = r.publication_id
            WHERE p.created_at >= NOW() - INTERVAL '7 days'
            ORDER BY p.created_at DESC
            LIMIT $1`,
            [limit]
        );
        
        const feed = result.rows;
        
        // 3. GUARDAR EN CACHÉ (TTL corto por naturaleza dinámica)
        await new Promise((resolve, reject) => {
            redisClient.setex(
                cacheKey,
                60,  // TTL: 1 minuto
                JSON.stringify(feed),
                (err) => {
                    if (err) reject(err);
                    resolve();
                }
            );
        });
        
        logger.info(`Feed guardado en caché (${feed.length} posts)`);
        return feed;
        
    } catch (error) {
        logger.error(`Error en getLatestFeed: ${error.message}`);
        throw error;
    }
}

// ================================================================
// EJEMPLO 3: Actualizar Usuario (Invalidación de Caché)
// ================================================================

/**
 * Actualiza perfil de usuario e invalida caché
 * 1. Actualiza BD
 * 2. Elimina caché
 */
async function updateUserProfile(userId, updatedData) {
    const cacheKey = `user:${userId}`;
    
    try {
        // 1. ACTUALIZAR BASE DE DATOS
        const result = await dbPool.query(
            `UPDATE usuarios 
            SET username = $2, email = $3, profile_picture_url = $4
            WHERE user_id = $1
            RETURNING *`,
            [userId, updatedData.username, updatedData.email, updatedData.profile_picture_url]
        );
        
        if (result.rows.length === 0) {
            throw new Error(`Usuario ${userId} no encontrado`);
        }
        
        logger.info(`Usuario actualizado en BD: ${userId}`);
        
        // 2. INVALIDAR CACHÉ
        await new Promise((resolve, reject) => {
            redisClient.del(cacheKey, (err) => {
                if (err) reject(err);
                resolve();
            });
        });
        
        logger.info(`Caché invalidada: ${cacheKey}`);
        
        return result.rows[0];
        
    } catch (error) {
        logger.error(`Error en updateUserProfile(${userId}): ${error.message}`);
        throw error;
    }
}

// ================================================================
// EJEMPLO 4: Crear Nueva Publicación (Invalidar Feed)
// ================================================================

/**
 * Crea nueva publicación e invalida caché del feed
 */
async function createPublication(userId, title, content) {
    const feedCacheKey = 'feed:latest';
    
    try {
        // 1. INSERTAR EN BASE DE DATOS
        const result = await dbPool.query(
            `INSERT INTO publicaciones (user_id, title, content, created_at)
            VALUES ($1, $2, $3, NOW())
            RETURNING *`,
            [userId, title, content]
        );
        
        const publication = result.rows[0];
        logger.info(`Publicación creada: ${publication.publication_id}`);
        
        // 2. INVALIDAR FEED (Es dinámico, necesita refrescarse)
        await new Promise((resolve, reject) => {
            redisClient.del(feedCacheKey, (err) => {
                if (err) reject(err);
                resolve();
            });
        });
        
        logger.info(`Feed cacheado invalidado`);
        
        return publication;
        
    } catch (error) {
        logger.error(`Error en createPublication: ${error.message}`);
        throw error;
    }
}

// ================================================================
// EJEMPLO 5: Verificar Estados de Caché
// ================================================================

/**
 * Obtiene estadísticas de Redis
 */
async function getCacheStats() {
    return new Promise((resolve, reject) => {
        redisClient.info('stats', (err, data) => {
            if (err) reject(err);
            
            const stats = {};
            data.split('\r\n').forEach(line => {
                const [key, value] = line.split(':');
                if (key && value) {
                    stats[key] = isNaN(value) ? value : parseInt(value);
                }
            });
            
            // Calcular Hit Rate
            const hits = stats.keyspace_hits || 0;
            const misses = stats.keyspace_misses || 0;
            const total = hits + misses;
            const hitRate = total > 0 ? ((hits / total) * 100).toFixed(2) : 0;
            
            resolve({
                hits,
                misses,
                total,
                hitRate: `${hitRate}%`,
                memory_used: stats.used_memory_human,
                connected_clients: stats.connected_clients
            });
        });
    });
}

/**
 * Obtiene tamaño de la caché
 */
async function getCacheSize() {
    return new Promise((resolve, reject) => {
        redisClient.dbsize((err, size) => {
            if (err) reject(err);
            resolve(size);
        });
    });
}

// ================================================================
// EJEMPLO 6: Limpiar Caché (Mantenimiento)
// ================================================================

/**
 * Invalida todas las claves de un patrón
 */
async function invalidateCachePattern(pattern) {
    return new Promise((resolve, reject) => {
        redisClient.keys(pattern, (err, keys) => {
            if (err) reject(err);
            
            if (keys.length === 0) {
                logger.warn(`No se encontraron claves con patrón: ${pattern}`);
                resolve(0);
                return;
            }
            
            redisClient.del(...keys, (err, deletedCount) => {
                if (err) reject(err);
                logger.info(`${deletedCount} claves eliminadas con patrón: ${pattern}`);
                resolve(deletedCount);
            });
        });
    });
}

// ================================================================
// API REST ENDPOINTS (Express.js)
// ================================================================

const express = require('express');
const app = express();
app.use(express.json());

// GET /api/users/:userId
app.get('/api/users/:userId', async (req, res) => {
    try {
        const user = await getUserProfile(parseInt(req.params.userId));
        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }
        res.json(user);
    } catch (error) {
        logger.error(`GET /api/users/${req.params.userId}: ${error.message}`);
        res.status(500).json({ error: error.message });
    }
});

// GET /api/feed
app.get('/api/feed', async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 50;
        const feed = await getLatestFeed(limit);
        res.json(feed);
    } catch (error) {
        logger.error(`GET /api/feed: ${error.message}`);
        res.status(500).json({ error: error.message });
    }
});

// PUT /api/users/:userId
app.put('/api/users/:userId', async (req, res) => {
    try {
        const user = await updateUserProfile(parseInt(req.params.userId), req.body);
        res.json({ message: 'Usuario actualizado', user });
    } catch (error) {
        logger.error(`PUT /api/users/${req.params.userId}: ${error.message}`);
        res.status(500).json({ error: error.message });
    }
});

// POST /api/publications
app.post('/api/publications', async (req, res) => {
    try {
        const pub = await createPublication(
            req.body.userId,
            req.body.title,
            req.body.content
        );
        res.status(201).json(pub);
    } catch (error) {
        logger.error(`POST /api/publications: ${error.message}`);
        res.status(500).json({ error: error.message });
    }
});

// GET /api/cache/stats
app.get('/api/cache/stats', async (req, res) => {
    try {
        const stats = await getCacheStats();
        const size = await getCacheSize();
        res.json({ ...stats, total_keys: size });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// DELETE /api/cache/:pattern
app.delete('/api/cache/:pattern', async (req, res) => {
    try {
        const deleted = await invalidateCachePattern(req.params.pattern);
        res.json({ message: `${deleted} claves eliminadas`, pattern: req.params.pattern });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ================================================================
// MAIN
// ================================================================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    logger.info(`Servidor escuchando en puerto ${PORT}`);
    logger.info('Endpoints disponibles:');
    logger.info('  GET  /api/users/:userId      - Obtener perfil de usuario');
    logger.info('  GET  /api/feed               - Obtener feed reciente');
    logger.info('  PUT  /api/users/:userId      - Actualizar usuario');
    logger.info('  POST /api/publications       - Crear publicación');
    logger.info('  GET  /api/cache/stats        - Estadísticas de caché');
    logger.info('  DELETE /api/cache/:pattern   - Invalidar caché');
});

// Graceful shutdown
process.on('SIGINT', async () => {
    logger.info('Cerrando conexiones...');
    redisClient.quit();
    await dbPool.end();
    process.exit(0);
});

module.exports = {
    getUserProfile,
    getLatestFeed,
    updateUserProfile,
    createPublication,
    getCacheStats,
    getCacheSize,
    invalidateCachePattern
};
