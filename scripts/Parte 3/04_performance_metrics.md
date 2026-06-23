# Métricas de Performance - Redis Cache

## Benchmark: Con Cache vs Sin Cache

### Escenario: 1000 peticiones de perfil de usuario

#### SIN CACHÉ (Consultas directas a PostgreSQL)
```
Tiempo total: 45.2 segundos
Promedio por query: 45.2 ms
Conexiones a BD: 1000
I/O Disk: Alto
CPU PostgreSQL: 85%
Conexiones activas: 150+
```

#### CON CACHÉ (Cache-Aside)
```
Supuesto: Hit Rate = 80% (800 hits, 200 misses)

Hits en Redis (800):
- 800 * 2ms = 1.6 segundos

Misses a DB (200):
- 200 * 45ms = 9 segundos

Guardado en Redis (200):
- 200 * 1ms = 0.2 segundos

Tiempo total: ~10.8 segundos (4.2X más rápido)
Hit Rate: 80%
```

## Cálculo de Hit Rate

```
Hit Rate (%) = (Cache Hits / Total Requests) * 100

Ejemplo:
- 8000 hits
- 2000 misses
- Total: 10000 requests

Hit Rate = (8000 / 10000) * 100 = 80%
```

### Interpretación
- **0-30%**: Muy bajo - Evaluar qué datos cachear
- **30-60%**: Aceptable - Considerar TTL más largo
- **60-80%**: Bueno - Caché funcionando bien
- **80%+**: Excelente - Configuración óptima

## Monitoreo en Redis

### Comando INFO - Estadísticas
```bash
redis-cli INFO stats
```

Campos importantes:
```
# Stats
total_connections_received:1234    # Total conexiones recibidas
total_commands_processed:45678     # Total comandos procesados
instantaneous_ops_per_sec:120      # Ops/segundo actualmente
total_net_input_bytes:234567       # Bytes recibidos
total_net_output_bytes:345678      # Bytes enviados
expired_keys:5634                  # Claves expiradas por TTL
evicted_keys:0                     # Claves eliminadas por política
keyspace_hits:234560               # Cache HIT
keyspace_misses:56789              # Cache MISS
```

### Calcular Hit Rate en Redis
```bash
redis-cli INFO stats | grep keyspace

# Output:
# keyspace_hits:234560
# keyspace_misses:56789

# Cálculo manual:
# Hit Rate = 234560 / (234560 + 56789) * 100 = 80.5%
```

## Comando MONITOR - Análisis en Tiempo Real

```bash
redis-cli MONITOR
```

Muestra todos los comandos en vivo:
```
1686123456.789456 [0 127.0.0.1:54321] "GET" "user:123"
1686123456.789987 [0 127.0.0.1:54321] "SETEX" "user:123" "300" "{...}"
1686123456.790123 [0 127.0.0.1:54321] "GET" "feed:latest"
1686123456.790456 [0 127.0.0.1:54321] "MISS"
```

## Memory Usage - Analiysis

### Ver consumo de memoria
```bash
redis-cli INFO memory
```

```
# Memory
used_memory:1048576                # Bytes usados (1MB)
used_memory_human:1M
used_memory_rss:2097152            # RSS (2MB)
used_memory_rss_human:2M
mem_fragmentation_ratio:2.0        # Fragmentación
```

### Calcular memoria promedio por clave
```
Memoria promedio = used_memory / dbsize

Ejemplo:
- used_memory: 100 MB
- dbsize: 1,000,000 claves
- Promedio por clave: 100 bytes
```

### Política de Eviction (Desalojo)
Cuando Redis alcanza maxmemory:

```bash
# En redis.conf
maxmemory 256mb
maxmemory-policy allkeys-lru        # Eliminar LRU si maxmemory
```

Opciones:
- `noeviction`: Rechazar nuevas escrituras
- `allkeys-lru`: Eliminar claves menos usadas recientemente
- `allkeys-lfu`: Eliminar claves menos frecuentes
- `volatile-lru`: Eliminar solo claves con TTL (LRU)
- `volatile-lfu`: Eliminar solo claves con TTL (LFU)

## Latency Monitoring

### Detectar operaciones lentas
```bash
redis-cli --latency              # Monitor de latencia
redis-cli --latency-history      # Histórico
redis-cli --latency-doctor       # Diagnóstico automático
```

## Slow Log - Operaciones lentas

```bash
# Ver comandos lentos
redis-cli SLOWLOG GET 10          # Últimos 10

# Output:
# 1) (integer) 1234               # ID
#    (integer) 1686123456         # Timestamp
#    (integer) 50000              # Tiempo en microsegundos
#    1) "KEYS"                    # Comando
#    2) "*"

# Limpiar slowlog
redis-cli SLOWLOG RESET

# Configurar threshold (10000 microsegundos = 10ms)
CONFIG SET slowlog-max-len 100
CONFIG SET slowlog-log-slower-than 10000
```

## Persistencia - Performance Trade-off

### RDB (Snapshots)
```conf
save 900 1      # Cada 900s si 1+ cambio
save 300 10     # Cada 300s si 10+ cambios
```
- ✅ Recuperación rápida
- ❌ Pérdida de datos si falla entre snapshots

### AOF (Append-Only File)
```conf
appendonly yes
appendfsync everysec        # Sincronizar cada segundo
```
- ✅ Máxima durabilidad
- ❌ Más lento que RDB
- ❌ Archivo más grande

### Híbrido (Recomendado)
```conf
save 900 1
appendonly yes
appendfsync everysec
```

## Comparativa: Redis vs Base de Datos

| Métrica | PostgreSQL | Redis |
|---------|-----------|-------|
| Latencia p95 | 45ms | 2-5ms |
| Throughput | 5k ops/sec | 100k+ ops/sec |
| Persistencia | Sí (disco) | Opcional (memoria) |
| Tipos de datos | Tablas | Key-Value, Sets, Lists, etc. |
| Complejidad query | Alta | Baja |
| Costo CPU | Medio-Alto | Bajo |

## Red Flags - Cuándo optimizar

🔴 **Hit Rate < 50%**: Revisar qué se cachea
🔴 **Fragmentation > 2.0**: Reiniciar o cambiar política
🔴 **Slowlog muestra > 100ms**: Investigar comandos bloqueantes
🔴 **Memory creceiendo continuamente**: Revisar TTLs
🔴 **Latency > 10ms promedio**: Problema de red o servidor lleno

## Checklist de Validación

- [ ] Hit Rate >= 60%
- [ ] Memory Usage < maxmemory
- [ ] Fragmentación ratio < 1.5
- [ ] Latencia p95 < 10ms
- [ ] Slowlog vacío o con tiempos < 50ms
- [ ] TTL configurado en todas las claves
- [ ] Fallback a BD si Redis cae
- [ ] Monitoreo activo con alertas
