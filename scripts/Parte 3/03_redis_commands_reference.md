# Referencia de Comandos Redis para Cache-Aside

## Nomenclatura (Keyspace Namespacing)

Redis es una estructura plana. Usamos convención con dos puntos `:` como separador.

### ❌ MAL (Evitar)
```redis
set("1", data)
set("producto1", data)
set("users_list", data)
```

### ✅ BIEN (Estándar)
```redis
set("user:123", userData)
set("products:list:active", productList)
set("publication:456", postData)
set("feed:latest", feedData)
set("config:app:theme", themeConfig)
```

## Operaciones Básicas

### SET - Guardar un dato
```redis
# SET simple (sin expiración - PELIGROSO)
SET key value

# SET con TTL en segundos (RECOMENDADO)
SETEX key 300 value                    # 5 minutos
SETEX user:123 300 '{"name":"Juan"}'

# SET con TTL en milisegundos
PSETEX key 300000 value

# SET con opciones (Redis 6.2+)
SET key value EX 300 NX              # NX = solo si no existe
SET key value EX 300 XX              # XX = solo si existe
SET key value KEEPTTL                # Mantener TTL existente
```

### GET - Obtener un dato
```redis
GET key
GET user:123
# Output: '{"name":"Juan"}'

# Si la clave no existe
GET user:999
# Output: (nil)
```

### DEL - Eliminar claves
```redis
DEL key1 key2 key3

# Invalidar caché de usuario
DEL user:123

# Invalidar feed
DEL feed:latest

# Eliminar múltiples claves con patrón
DEL user:* publication:*
```

### EXISTS - Verificar existencia
```redis
EXISTS key
# Output: 1 (existe) o 0 (no existe)

EXISTS user:123
# Output: 1
```

### TTL / PTTL - Ver tiempo de expiración
```redis
TTL key                    # Retorna segundos restantes
PTTL key                   # Retorna milisegundos restantes

TTL user:123
# Output: 287 (segundos restantes)

# -1 = sin expiración
# -2 = no existe
```

### EXPIRE - Establecer/modificar TTL
```redis
EXPIRE key 300             # Establecer 5 minutos
EXPIRE user:123 600        # Modificar a 10 minutos

PEXPIRE key 300000         # En milisegundos

# Ver y modificar TTL
TTL user:123               # 287 segundos
EXPIRE user:123 600
TTL user:123               # 600 segundos
```

### PERSIST - Remover expiración
```redis
PERSIST key                # Hacer que viva por siempre

PERSIST user:123
# Output: 1
```

## Operaciones con Hashes (Objetos JSON)

Para datos complejos, usar HASHES es más eficiente que strings JSON.

```redis
# HSET - Guardar campos
HSET user:123 name "Juan" email "juan@example.com" age 30

# HGET - Obtener un campo
HGET user:123 name
# Output: "Juan"

# HGETALL - Obtener todos los campos
HGETALL user:123
# Output:
# 1) "name"
# 2) "Juan"
# 3) "email"
# 4) "juan@example.com"
# 5) "age"
# 6) "30"

# HDEL - Eliminar campos
HDEL user:123 age

# HEXISTS - Verificar existencia de campo
HEXISTS user:123 name
# Output: 1

# Combinar con SETEX equivalente
HSET user:123 name "Juan"
EXPIRE user:123 300
```

## Operaciones con Lists (Colas/Pilas)

Para cachear colecciones ordenadas (feed, comentarios, etc.)

```redis
# LPUSH / RPUSH - Agregar elementos
LPUSH feed:latest post:1 post:2 post:3

# LRANGE - Obtener rango
LRANGE feed:latest 0 49           # Primeros 50 elementos
# Output: [post:1, post:2, ..., post:50]

# LLEN - Contar elementos
LLEN feed:latest
# Output: 100

# LPOP / RPOP - Eliminar y retornar
LPOP feed:latest
RPOP feed:latest

# Limpiar lista
DEL feed:latest
```

## Operaciones con Sets (Colecciones únicas)

Para cachear conjuntos sin duplicados.

```redis
# SADD - Agregar miembros
SADD user:123:followers 456 789 1011

# SMEMBERS - Obtener todos
SMEMBERS user:123:followers
# Output: [456, 789, 1011]

# SISMEMBER - Verificar pertenencia
SISMEMBER user:123:followers 456
# Output: 1

# SCARD - Contar miembros
SCARD user:123:followers
# Output: 3

# SREM - Eliminar miembro
SREM user:123:followers 456
```

## Operaciones con Sorted Sets (Sets ordenados)

Para ranking, leaderboards, feeds con score.

```redis
# ZADD - Agregar con score
ZADD publication:trending 100 post:1 95 post:2 80 post:3

# ZRANGE - Rango por índice
ZRANGE publication:trending 0 9              # Top 10 por posición
ZREVRANGE publication:trending 0 9           # Reverse (mayor primero)

# ZRANGE con scores
ZRANGE publication:trending 0 9 WITHSCORES
# Output:
# 1) "post:1"
# 2) "100"
# 3) "post:2"
# 4) "95"

# ZSCORE - Ver score de un elemento
ZSCORE publication:trending post:1
# Output: "100"

# ZREM - Eliminar elemento
ZREM publication:trending post:1
```

## Administración y Monitoreo

### KEYS - Buscar claves
```redis
KEYS *                     # Todas las claves (EVITAR en producción)
KEYS user:*                # Todas las de usuarios
KEYS publication:*
KEYS *trending*

# Mejor: usar SCAN
SCAN 0
SCAN 0 MATCH user:* COUNT 100
```

### DBSIZE - Cantidad de claves
```redis
DBSIZE
# Output: 1547
```

### FLUSHDB - Limpiar base de datos
```redis
FLUSHDB                    # Eliminar todas las claves (¡CUIDADO!)
FLUSHALL                   # Eliminar TODAS las BDs (¡MÁS CUIDADO!)
```

### INFO - Estadísticas
```redis
INFO                       # Todo
INFO stats                 # Estadísticas de ejecución
INFO memory                # Uso de memoria
INFO replication           # Estado de replicación
```

### MONITOR - Ver comandos en tiempo real
```redis
MONITOR                    # Ver todos los comandos ejecutados
# Presionar Ctrl+C para salir
```

## Transacciones (Multi/Exec)

Para operaciones atómicas.

```redis
MULTI
SET user:123 data1
SET user:124 data2
HSET config:app theme dark
EXEC

# Con errores
MULTI
SET key1 value1
INCR key1                  # Esto causará error
EXEC
# QUEUED para cada comando
# Error en ejecución
```

## Pipeline - Enviar múltiples comandos

Para optimizar rendimiento con muchas operaciones.

```
INCR counter:requests
INCR counter:requests
INCR counter:requests
GET counter:requests

# Redis procesa todos juntos = más rápido
```

## Pseudocódigo de Aplicación (Node.js con redis)

```javascript
const redis = require('redis');
const client = redis.createClient({
    host: 'localhost',
    port: 6379,
    password: process.env.REDIS_PASSWORD
});

// Función Cache-Aside
async function getUser(userId) {
    const cacheKey = `user:${userId}`;
    
    try {
        // 1. Intentar obtener de Redis
        const cached = await client.get(cacheKey);
        if (cached) {
            return JSON.parse(cached);  // HIT
        }
        
        // 2. MISS - Consultar DB
        const user = await db.query(
            'SELECT * FROM usuarios WHERE user_id = $1',
            [userId]
        );
        
        // 3. Guardar en caché por 5 minutos
        await client.setex(
            cacheKey,
            300,  // TTL en segundos
            JSON.stringify(user)
        );
        
        return user;
    } catch (error) {
        logger.error(`Error en getUser: ${error}`);
        throw error;
    }
}

// Invalidar caché al actualizar
async function updateUser(userId, newData) {
    // 1. Actualizar BD
    await db.query('UPDATE usuarios SET ... WHERE user_id = $1', [userId]);
    
    // 2. Invalidar caché
    await client.del(`user:${userId}`);
    
    return newData;
}
```
