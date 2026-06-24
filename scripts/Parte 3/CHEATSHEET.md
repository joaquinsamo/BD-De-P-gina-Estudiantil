# 🚀 Redis Cheatsheet - Comandos Rápidos

## Conexión a Redis

```bash
# Conectarse a Redis CLI
redis-cli

# Con contraseña
redis-cli -a tu_password

# Remoto
redis-cli -h servidor.com -p 6379

# Verificar conexión
ping
# Output: PONG
```

---

## Comandos Esenciales

### GET / SET
```redis
# Guardar un valor
SET user:123 '{"name":"Juan"}'
SET user:123 '{"name":"Juan"}' EX 300          # Con TTL de 5 min

# Obtener valor
GET user:123

# Eliminar
DEL user:123 user:124
```

### TTL (Time To Live)
```redis
# Ver tiempo restante (en segundos)
TTL user:123                    # Output: 287

# Ver en milisegundos
PTTL user:123                   # Output: 287000

# Establecer expiración
EXPIRE user:123 600             # 10 minutos

# Hacer que viva para siempre
PERSIST user:123
```

### Hashes (Objetos)
```redis
# Guardar objeto
HSET user:123 name "Juan" email "juan@example.com"

# Obtener un campo
HGET user:123 name              # Output: "Juan"

# Obtener todos
HGETALL user:123                # Output: name, Juan, email, juan@example.com

# Actualizar campo
HSET user:123 age 30

# Eliminar campo
HDEL user:123 age
```

### Lists (Colecciones ordenadas)
```redis
# Agregar elementos
LPUSH feed:latest post:1 post:2     # Agregar al inicio
RPUSH feed:latest post:3            # Agregar al final

# Ver rango
LRANGE feed:latest 0 -1             # Todos
LRANGE feed:latest 0 49             # Primeros 50

# Contar
LLEN feed:latest                    # Cantidad de elementos

# Eliminar elementos
LPOP feed:latest                    # Sacar del inicio
RPOP feed:latest                    # Sacar del final
```

### Sets (Conjuntos sin duplicados)
```redis
# Agregar miembros
SADD user:123:followers 456 789

# Ver miembros
SMEMBERS user:123:followers

# Contar miembros
SCARD user:123:followers

# Verificar pertenencia
SISMEMBER user:123:followers 456    # Output: 1 (sí) o 0 (no)

# Eliminar miembro
SREM user:123:followers 456
```

### Sorted Sets (Sets ordenados por score)
```redis
# Agregar con score
ZADD publication:trending 100 post:1 95 post:2

# Obtener rango por posición
ZRANGE publication:trending 0 9             # Top 10
ZREVRANGE publication:trending 0 9          # Reverse

# Con scores
ZRANGE publication:trending 0 9 WITHSCORES

# Obtener score
ZSCORE publication:trending post:1          # Output: "100"

# Eliminar
ZREM publication:trending post:1
```

---

## Administración

### Base de Datos
```redis
# Ver cantidad de claves
DBSIZE                          # Output: 1234

# Ver todas las claves
KEYS *                          # ⚠️ EVITAR en producción

# Ver claves con patrón
KEYS user:*
KEYS feed:*

# Buscar de forma segura (SCAN)
SCAN 0                          # Cursor 0 (empezar)
SCAN 0 MATCH user:* COUNT 100   # Con patrón y límite
```

### Limpieza
```redis
# Eliminar una clave
DEL user:123

# Eliminar múltiples
DEL user:123 user:124 feed:*

# Limpiar TODA la BD
FLUSHDB                         # ⚠️ Cuidado!

# Limpiar TODAS las BDs
FLUSHALL                        # ⚠️ ¡MUY CUIDADO!
```

---

## Monitoreo

### Estadísticas
```bash
# Ver todo
redis-cli INFO

# Solo estadísticas
redis-cli INFO stats

# Hit Rate
redis-cli INFO stats | grep keyspace
# Output:
# keyspace_hits:12345
# keyspace_misses:3456
```

### Cálcular Hit Rate
```
Hit Rate = keyspace_hits / (keyspace_hits + keyspace_misses) * 100
         = 12345 / (12345 + 3456) * 100
         = 78%
```

### Monitoreo en vivo
```bash
# Ver todos los comandos en tiempo real
redis-cli MONITOR

# Ver diagnóstico de latencia
redis-cli LATENCY DOCTOR

# Ver comandos lentos
redis-cli SLOWLOG GET 10
```

---

## Troubleshooting Rápido

| Problema | Comando | Solución |
|----------|---------|----------|
| Redis no responde | `redis-cli ping` | Reiniciar servicio |
| Memoria llena | `redis-cli INFO memory` | Reducir TTL o limpiar claves |
| Hit Rate bajo | `redis-cli INFO stats` | Aumentar TTL o cambiar qué cachear |
| Claves obsoletas | `redis-cli KEYS *` | Establecer EXPIRE |
| Conexión rechazada | `redis-cli -h host -p puerto` | Verificar host/puerto |

---

## Pattern: Cache-Aside en 3 líneas

```javascript
// 1. Obtener
const cached = await redis.get(`user:${id}`);
if (cached) return JSON.parse(cached);

// 2. Consultar BD
const user = await db.query('SELECT * FROM usuarios WHERE id=$1', [id]);

// 3. Cachear
await redis.setex(`user:${id}`, 300, JSON.stringify(user));
return user;
```

---

## Configuraciones Recomendadas

### TTL por tipo de dato
```
Perfil usuario:       300 seg (5 min)
Feed/Timeline:         60 seg (1 min)
Catálogo productos:  1800 seg (30 min)
Configuración app:   3600 seg (1 hora)
Datos muy dinámicos:    15 seg
```

### Maxmemory policy
```conf
# En redis.conf o línea de comando
CONFIG SET maxmemory 256mb
CONFIG SET maxmemory-policy allkeys-lru    # Eliminar menos usadas
```

---

## Salida de Redis CLI

| Output | Significado |
|--------|------------|
| `(nil)` | Clave no existe |
| `(integer) 1` | Sí, existe o operación exitosa |
| `(integer) 0` | No existe o falló |
| `PONG` | Conexión OK |
| `OK` | Comando ejecutado |

---

## Salir de Redis CLI

```redis
exit
# o
QUIT
```

---

**Última actualización:** 2024-06  
**Eje:** III - NoSQL  
**Proyecto:** Integrador - Parte 3
