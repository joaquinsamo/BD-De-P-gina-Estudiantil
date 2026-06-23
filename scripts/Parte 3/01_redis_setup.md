# Redis Setup - Integración de Caché con la Base de Datos

## Objetivo
Implementar un almacén de datos clave-valor en memoria (Redis) como capa de caché para reducir latencia de consultas recurrentes y aliviar la carga de PostgreSQL.

## Instalación y Configuración de Redis

### Opción 1: Instalación Local (Linux/Ubuntu)
```bash
sudo apt-get update
sudo apt-get install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verificar que Redis está corriendo
redis-cli ping
# Output esperado: PONG
```

### Opción 2: Docker (Recomendado para desarrollo)
```bash
docker run -d --name redis-cache -p 6379:6379 redis:latest
docker exec redis-cache redis-cli ping
```

### Opción 3: Redis Cloud (Producción)
- Crear cuenta en [redis.com](https://redis.com)
- Obtener conexión string: `redis://:password@host:port`
- Guardar credenciales en variables de entorno

## Validación de Conexión
```bash
# Conectarse a Redis
redis-cli

# Comandos de validación
ping              # Debe retornar PONG
dbsize            # Ver cantidad de claves
flushdb           # Limpiar BD (solo para desarrollo)
exit
```

## Configuración de Persistencia (Opcional)
En `/etc/redis/redis.conf`:
```conf
# Habilitar guardar snapshots cada 900 segundos si hay 1+ cambio
save 900 1
save 300 10
save 60 10000

# Habilitar AOF (Append-Only File) para máxima durabilidad
appendonly yes
appendfsync everysec
```

Reiniciar Redis:
```bash
sudo systemctl restart redis-server
```

## Métricas Importantes
```bash
# Ver estadísticas en tiempo real
redis-cli info stats

# Monitor de comandos en tiempo real
redis-cli monitor

# Analizar memoria utilizada
redis-cli info memory
```
