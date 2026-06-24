-- ================================================================
-- CACHE-ASIDE PATTERN (LAZY LOADING)
-- Implementación del patrón de caché en la capa de aplicación
-- ================================================================

-- Este archivo documenta las consultas de PostgreSQL que serán
-- cacheadas en Redis siguiendo el patrón Cache-Aside.

-- El flujo es:
-- 1. Cliente solicita dato (ej: usuario_123)
-- 2. App consulta Redis por clave "user:123"
-- 3. Si HIT: retorna datos cacheados al cliente (FIN)
-- 4. Si MISS: ejecuta query en PostgreSQL
-- 5. App guarda resultado en Redis con TTL (ej: 300 segundos)
-- 6. Retorna dato al cliente

-- ================================================================
-- CANDIDATOS A CACHEAR
-- ================================================================
-- Criterios de selección:
-- ✓ Alta frecuencia de lectura
-- ✓ Baja frecuencia de escritura
-- ✓ Tolerancia a consistencia eventual (1-2 minutos)

-- ================================================================
-- ENDPOINT 1: Obtener usuario por ID
-- Caso de uso: Perfil de usuario, detalles de cuenta
-- ================================================================

-- QUERY EN POSTGRESQL (Se ejecuta en MISS):
-- Clave Redis: user:{user_id}
-- TTL: 300 segundos (5 minutos)

SELECT 
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
GROUP BY u.user_id, u.username, u.email, u.created_at, u.profile_picture_url;

-- Pseudocódigo de aplicación:
/*
function getUserProfile(userId) {
    // 1. Consultar caché
    let cachedUser = redis.get(`user:${userId}`);
    
    if (cachedUser) {
        return JSON.parse(cachedUser);  // CACHE HIT
    }
    
    // 2. Cache MISS - Consultar BD
    let user = db.query(
        `SELECT ... FROM usuarios WHERE user_id = $1`, 
        [userId]
    );
    
    // 3. Guardar en caché con TTL de 5 minutos
    redis.setex(`user:${userId}`, 300, JSON.stringify(user));
    
    // 4. Retornar dato
    return user;
}
*/

-- ================================================================
-- ENDPOINT 2: Obtener últimas publicaciones (Feed)
-- Caso de uso: Timeline/Feed de la aplicación
-- ================================================================

-- QUERY EN POSTGRESQL (Se ejecuta en MISS):
-- Clave Redis: feed:latest
-- TTL: 60 segundos (1 minuto) - Feed es muy dinámico

SELECT 
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
LIMIT 50;

-- Pseudocódigo de aplicación:
/*
function getLatestFeed(limit = 50) {
    // 1. Consultar caché
    let cachedFeed = redis.get(`feed:latest`);
    
    if (cachedFeed) {
        return JSON.parse(cachedFeed);  // CACHE HIT
    }
    
    // 2. Cache MISS - Consultar BD
    let feed = db.query(
        `SELECT ... FROM publicaciones ... LIMIT $1`,
        [limit]
    );
    
    // 3. Guardar con TTL más corto (1 minuto) por naturaleza dinámica
    redis.setex(`feed:latest`, 60, JSON.stringify(feed));
    
    // 4. Retornar dato
    return feed;
}
*/

-- ================================================================
-- INVALIDACIÓN DE CACHÉ
-- ================================================================

-- Cuando un usuario ACTUALIZA su perfil, la caché debe invalidarse:
-- DELETE FROM cache: redis.del(`user:{user_id}`)

-- Cuando se CREA una nueva publicación, se invalida el feed:
-- redis.del(`feed:latest`)

-- Cuando se ACTUALIZA una publicación, se invalida ambas:
-- redis.del(`publication:{pub_id}`)
-- redis.del(`feed:latest`)

-- ================================================================
-- MANEJO DE ERRORES (FALLBACK)
-- ================================================================

/*
function getUserProfileWithFallback(userId) {
    try {
        // 1. Intentar obtener de caché
        let cachedUser = redis.get(`user:${userId}`);
        if (cachedUser) {
            return JSON.parse(cachedUser);
        }
    } catch (redisError) {
        // Si Redis falla, registramos el error pero continuamos
        logger.error(`Redis connection failed: ${redisError.message}`);
        // No lanzamos error, continuamos a la BD
    }
    
    try {
        // 2. Si caché falló o MISS, consultar BD
        let user = db.query(
            `SELECT ... FROM usuarios WHERE user_id = $1`,
            [userId]
        );
        
        // 3. Intentar guardar en caché (si Redis se recuperó)
        try {
            redis.setex(`user:${userId}`, 300, JSON.stringify(user));
        } catch (cacheError) {
            // Si la caché no funcionaba, continuamos sin ella
            logger.warn(`Failed to cache user ${userId}: ${cacheError.message}`);
        }
        
        return user;
    } catch (dbError) {
        // Si BD falla, retornar error
        logger.error(`Database error: ${dbError.message}`);
        throw dbError;
    }
}
*/

-- ================================================================
-- ESTRATEGIA DE TTL (Time-To-Live)
-- ================================================================

/*
TTL Recomendados por tipo de dato:

Datos Estáticos:
- Configuración de usuario: 3600 segundos (1 hora)
- Categorías de productos: 1800 segundos (30 minutos)
- Información de permisos: 600 segundos (10 minutos)

Datos Semi-Dinámicos:
- Perfil de usuario: 300 segundos (5 minutos)
- Últimas publicaciones: 60 segundos (1 minuto)
- Conteos de comentarios: 120 segundos (2 minutos)

Datos Muy Dinámicos:
- Feed en tiempo real: 30 segundos
- Notificaciones: 15 segundos

REGLA DE ORO: TTL más corto = menos inconsistencia, más carga en BD
*/
