# 📚 Parte 3 - Ecosistema NoSQL: Redis Cache Implementation

## 📖 Estructura de la Documentación

Este directorio contiene toda la documentación e implementación del patrón Cache-Aside usando Redis para reducir la latencia y aliviar la carga de PostgreSQL.

---

## 📄 Archivos en este directorio

### 🚀 Inicio Rápido
| Archivo | Descripción | Para |
|---------|-------------|------|
| **00_QUICKSTART.md** | Guía de 7 pasos para levantar Redis y empezar | Quien quiera empezar AHORA |

### 🔧 Configuración
| Archivo | Descripción | Para |
|---------|-------------|------|
| **01_redis_setup.md** | Instalación, configuración y validación de Redis | DevOps / SysAdmin |
| **docker-compose.yml** | Contenedores Docker para PostgreSQL + Redis + UIs | Desarrollo local |
| **.env.example** | Variables de entorno necesarias | Configuración de app |

### 💾 Base de Datos & Caché
| Archivo | Descripción | Para |
|---------|-------------|------|
| **02_cache_aside_pattern.sql** | Queries PostgreSQL cacheables e invalidación | Data Engineer / Backend |

### 🎮 Referencia Técnica
| Archivo | Descripción | Para |
|---------|-------------|------|
| **03_redis_commands_reference.md** | Todos los comandos Redis con ejemplos | Referencia técnica |
| **04_performance_metrics.md** | Benchmarks, monitoreo y análisis | Performance Engineer |

### 💻 Código de Implementación
| Archivo | Descripción | Para |
|---------|-------------|------|
| **05_implementation_examples.js** | Código Node.js completo con patrones | Desarrolladores |

---

## 🎯 Flujo Recomendado de Lectura

### Para iniciar rápido
```
00_QUICKSTART.md 
    ↓
docker-compose.yml (levanta todo)
    ↓
05_implementation_examples.js (integra en tu app)
    ↓
04_performance_metrics.md (monitorea)
```

### Para aprendizaje profundo
```
01_redis_setup.md (entender Redis)
    ↓
02_cache_aside_pattern.sql (entender patrón)
    ↓
03_redis_commands_reference.md (dominar comandos)
    ↓
04_performance_metrics.md (optimizar)
    ↓
05_implementation_examples.js (implementar)
```

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────┐
│          Aplicación (Backend)               │
│  ┌───────────────────────────────────────┐  │
│  │   Cache-Aside Pattern                │  │
│  │  1. Consulta Redis                   │  │
│  │  2. Si MISS → Consulta PostgreSQL    │  │
│  │  3. Guarda en Redis con TTL          │  │
│  └───────────────────────────────────────┘  │
└──────┬──────────────────────┬────────────────┘
       │                      │
   ┌───▼────┐           ┌─────▼──────┐
   │  REDIS │           │ PostgreSQL │
   │  CACHE │           │ (Primaria) │
   │ (RAM)  │           │            │
   └────────┘           └────────────┘
   - Hit Rate: 60-80%    - Fuente de verdad
   - TTL: 60-300s        - Consultas complejas
   - Fallback: Activo    - Escrituras seguras
```

---

## ✅ Checklist de Implementación

- [ ] **Fase 1: Setup**
  - [ ] Redis instalado y corriendo
  - [ ] PostgreSQL disponible
  - [ ] Variables de entorno configuradas

- [ ] **Fase 2: Integración**
  - [ ] Cache-Aside implementado en 2 endpoints
  - [ ] Manejo de errores (Fallback a BD)
  - [ ] Invalidación de caché al actualizar

- [ ] **Fase 3: Validación**
  - [ ] Hit Rate >= 60%
  - [ ] Latencia promedio < 10ms
  - [ ] Memoria utilizada < maxmemory
  - [ ] Monitoreo configurado

---

## 📊 Métricas Clave

```
ENDPOINT: GET /api/users/:id

Sin Cache:
  - Latencia p95: 45ms
  - Throughput: 5k ops/sec
  - Carga BD: 100%

Con Cache (80% hit rate):
  - Latencia p95: 5ms
  - Throughput: 100k ops/sec
  - Carga BD: 20%

Mejora: 9x más rápido, 80% menos carga
```

---

## 🛠️ Herramientas Incluidas

### Con docker-compose
- ✅ PostgreSQL 15 (BD Principal)
- ✅ Redis 7 (Cache en Memoria)
- ✅ Redis Commander (UI web para inspeccionar Redis)
- ✅ pgAdmin (UI web para PostgreSQL)

### Acceso
```
Redis Commander: http://localhost:8081
pgAdmin:         http://localhost:5050
PostgreSQL:      localhost:5432
Redis:           localhost:6379
```

---

## 🚨 Common Issues & Soluciones

| Problema | Causa | Solución |
|----------|-------|----------|
| "Connection refused" | Redis no está corriendo | Ver `01_redis_setup.md` |
| Hit Rate < 30% | TTL muy corto o datos muy variables | Revisar TTL en `02_cache_aside_pattern.sql` |
| Memory leak | Claves sin expiración | Agregar EXPIRE a todas las claves |
| App lenta | Cache fallando silenciosamente | Revisar logs y fallback logic en `05_implementation_examples.js` |

---

## 📚 Referencias Adicionales

- **Redis Official Docs:** https://redis.io/docs/
- **PostgreSQL Cache Patterns:** https://wiki.postgresql.org/
- **Performance Tuning:** Ver `04_performance_metrics.md`
- **Node.js Redis Client:** https://github.com/redis/node-redis

---

## 🤝 Contribuciones

Para agregar ejemplos en otros lenguajes (Python, PHP, Go):
1. Crear archivo `05_implementation_examples_[LENGUAJE].ext`
2. Seguir mismo patrón Cache-Aside
3. Incluir manejo de errores

---

## 📝 Notas Importantes

1. **Consistencia Eventual:** Los datos cacheados pueden estar desactualizados por el TTL. Usar solo para datos que toleren esto.

2. **Invalidación:** Siempre invalidar caché después de actualizar datos en BD.

3. **Fallback:** Si Redis falla, la aplicación debe continuar funcionando consultando PostgreSQL directamente.

4. **Monitoreo:** Revisar Hit Rate y latencias regularmente.

5. **TTL:** Balancear entre reducir carga (TTL largo) e inconsistencia (TTL corto).

---

**Última actualización:** 2024-06  
**Versión:** 1.0  
**Eje:** III - El Ecosistema NoSQL
