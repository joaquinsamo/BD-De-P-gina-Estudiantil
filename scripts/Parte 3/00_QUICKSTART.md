# Quick Start - Redis + Cache-Aside Pattern

## 1️⃣ Levanta Redis (Elige una opción)

### Opción A: Docker (Recomendado para desarrollo)
```bash
# Crear y ejecutar contenedor Redis
docker run -d --name redis-cache -p 6379:6379 redis:latest

# Verificar que funciona
docker exec redis-cache redis-cli ping
# Output: PONG ✓
```

### Opción B: Instalación Local (Ubuntu/Linux)
```bash
sudo apt-get install redis-server
sudo systemctl start redis-server
redis-cli ping
# Output: PONG ✓
```

### Opción C: Verificar conexión manual
```bash
# Conectarse a Redis CLI
redis-cli

# Dentro de redis-cli:
ping
# Output: PONG
exit
```

---

## 2️⃣ Instala dependencias del proyecto

```bash
# Si usas Node.js
npm install redis pg dotenv

# Si usas Python
pip install redis psycopg2-binary

# Si usas PHP
composer require predis/predis
```

---

## 3️⃣ Crea archivo .env

```bash
# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=          # Dejar vacío si no tiene contraseña

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=comunidad_db
DB_USER=postgres
DB_PASSWORD=tu_password

# App
PORT=3000
```

---

## 4️⃣ Implementa Cache-Aside en tu aplicación

### Ejemplo simplificado (Node.js)

```javascript
const redis = require('redis');
const client = redis.createClient();

// Función helper: Cache-Aside
async function getWithCache(key, ttl, fetchFn) {
    // 1. Intentar obtener de caché
    const cached = await client.get(key);
    if (cached) {
        console.log(`✓ Cache HIT: ${key}`);
        return JSON.parse(cached);
    }
    
    console.log(`✗ Cache MISS: ${key}`);
    
    // 2. Cache miss - obtener del origen
    const data = await fetchFn();
    
    // 3. Guardar en caché
    await client.setex(key, ttl, JSON.stringify(data));
    
    return data;
}

// Uso:
app.get('/api/users/:id', async (req, res) => {
    const user = await getWithCache(
        `user:${req.params.id}`,
        300,  // TTL: 5 minutos
        () => db.query('SELECT * FROM usuarios WHERE user_id = $1', [req.params.id])
    );
    res.json(user);
});
```

---

## 5️⃣ Valida que funciona

### Verificar Hit Rate
```bash
redis-cli INFO stats | grep keyspace
# Debe mostrar:
# keyspace_hits:XX
# keyspace_misses:YY
```

### Cálcular Hit Rate
```
Hit Rate (%) = keyspace_hits / (keyspace_hits + keyspace_misses) * 100
```

**Objetivo:** Hit Rate >= 60%

### Monitor en tiempo real
```bash
# Terminal 1: Ver comandos
redis-cli MONITOR

# Terminal 2: Hacer requests
curl http://localhost:3000/api/users/123
curl http://localhost:3000/api/users/123  # Este debería ser HIT
```

### Inspeccionar caché
```bash
redis-cli

# Ver todas las claves
KEYS *

# Ver una clave específica
GET user:123

# Ver tiempo de vida restante
TTL user:123

# Limpiar caché
FLUSHDB
```

---

## 6️⃣ Patrones de Invalidación

### Cuando actualiza un usuario
```javascript
// 1. Actualizar BD
await db.query('UPDATE usuarios SET ... WHERE user_id = $1', [userId]);

// 2. Invalidar caché
await client.del(`user:${userId}`);
```

### Cuando crea una publicación nueva
```javascript
// 1. Crear publicación
await db.query('INSERT INTO publicaciones ...');

// 2. Invalidar feed (porque cambió)
await client.del('feed:latest');
```

### Invalidar múltiples claves
```bash
redis-cli

# Eliminar todas las claves de un usuario
DEL user:123 user:123:* 

# Eliminar todas de un patrón
DEL feed:*

# Limpiar todo (CUIDADO!)
FLUSHDB
```

---

## 7️⃣ Checklist de Validación

- [ ] Redis está running (`redis-cli ping` retorna PONG)
- [ ] Aplicación se conecta a Redis sin errores
- [ ] Hit Rate >= 60% en producción
- [ ] Latencia promedio < 10ms
- [ ] Si Redis cae, la app sigue funcionando (fallback a BD)
- [ ] TTL configurado en todas las claves
- [ ] Caché se invalida al actualizar datos
- [ ] Monitores configurados para alertas

---

## 🐛 Troubleshooting

### "Connection refused" a Redis
```bash
# Verificar que Redis está corriendo
redis-cli ping

# Si falla, iniciar:
# Docker:
docker start redis-cache

# Local:
redis-server

# Ubuntu/systemd:
sudo systemctl start redis-server
```

### Hit Rate muy bajo (<30%)
- Revisar TTL: ¿Demasiado corto?
- Revisar qué se cachea: ¿Datos muy variables?
- Verificar claves: ¿La nomenclatura es consistente?

### Redis consume mucha memoria
```bash
redis-cli INFO memory

# Reducir TTL o implementar eviction policy:
redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

### Datos cacheados quedan obsoletos
- Implementar invalidación al actualizar
- Reducir TTL
- Usar patrón de escucha (PUBSUB - avanzado)

---

## 📊 Comandos útiles

```bash
# Estadísticas generales
redis-cli INFO

# Hit Rate específico
redis-cli INFO stats | grep -E "keyspace|^connected"

# Memoria usada
redis-cli INFO memory

# Claves más grandes
redis-cli --bigkeys

# Ver todas las claves con patrón
redis-cli KEYS "user:*"

# Limpiar expiradas (automático pero puedes forzar)
redis-cli RANDOMKEY

# Monitoreo en tiempo real
redis-cli LATENCY DOCTOR
```

---

## 🚀 Próximos pasos

1. Lee `02_cache_aside_pattern.sql` para queries específicas
2. Implementa en 2-3 endpoints críticos
3. Monitora con `04_performance_metrics.md`
4. Ajusta TTLs según tu Hit Rate
5. Agrega fallback a BD si falla Redis

¡Listo para escalar! 🎉
