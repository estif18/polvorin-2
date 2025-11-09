# 🗃️ Scripts de Base de Datos - Sistema Polvorín

Este directorio contiene todos los scripts SQL necesarios para crear y mantener la base de datos del sistema de polvorín desde cero.

## 📁 Estructura de Scripts

### 🏗️ Scripts de Instalación (Orden de Ejecución)

1. **`01_crear_estructura_completa.sql`** 
   - 🎯 **Propósito:** Crear base de datos y todas las tablas
   - 📊 **Incluye:** Tablas, constraints, foreign keys, índices básicos
   - ⏱️ **Tiempo estimado:** 2-3 minutos

2. **`02_crear_vistas_optimizadas.sql`**
   - 🎯 **Propósito:** Crear vistas optimizadas para consultas y PowerBI  
   - 📊 **Incluye:** Vistas de stock, reportes, alertas, auditoría
   - ⏱️ **Tiempo estimado:** 1-2 minutos

3. **`03_insertar_datos_maestros.sql`**
   - 🎯 **Propósito:** Insertar explosivos maestros y usuarios
   - 📊 **Incluye:** 37 explosivos, usuarios admin, índices adicionales
   - ⏱️ **Tiempo estimado:** 1 minuto

4. **`04_insertar_stock_inicial.sql`** *(OPCIONAL)*
   - 🎯 **Propósito:** Crear stock inicial de prueba (1000 unidades c/u)
   - 📊 **Incluye:** 37,000 unidades de prueba distribuidas
   - ⏱️ **Tiempo estimado:** 2-3 minutos

5. **`05_procedimientos_mantenimiento.sql`** *(OPCIONAL)*
   - 🎯 **Propósito:** Procedimientos de mantenimiento y utilidades
   - 📊 **Incluye:** Limpieza, optimización, reportes, backup
   - ⏱️ **Tiempo estimado:** 1 minuto

## 🚀 Instalación Rápida

### Opción 1: Instalación Completa con Datos de Prueba
```sql
-- 1. Crear estructura
:r 01_crear_estructura_completa.sql
GO

-- 2. Crear vistas
:r 02_crear_vistas_optimizadas.sql  
GO

-- 3. Insertar datos maestros
:r 03_insertar_datos_maestros.sql
GO

-- 4. Insertar stock inicial de prueba
:r 04_insertar_stock_inicial.sql
GO

-- 5. Crear procedimientos de mantenimiento
:r 05_procedimientos_mantenimiento.sql
GO
```

### Opción 2: Instalación Mínima (Solo Estructura)
```sql
-- 1. Crear estructura
:r 01_crear_estructura_completa.sql
GO

-- 2. Crear vistas  
:r 02_crear_vistas_optimizadas.sql
GO

-- 3. Insertar datos maestros (SIN stock inicial)
:r 03_insertar_datos_maestros.sql
GO
```

## 📊 Detalles de los Scripts

### 📋 01_crear_estructura_completa.sql

**Crea:**
- ✅ Base de datos `polvorin`
- ✅ Tabla `explosivos` (maestro)
- ✅ Tabla `ingresos` (movimientos de entrada)
- ✅ Tabla `salidas` (movimientos de salida) 
- ✅ Tabla `devoluciones` (movimientos de devolución)
- ✅ Tabla `stock_diario` (control diario)
- ✅ Tabla `usuarios` (control de acceso)
- ✅ Foreign keys y constraints
- ✅ Índices de optimización

### 🔍 02_crear_vistas_optimizadas.sql

**Crea:**
- ✅ `vw_stock_explosivos_powerbi` - Stock actual optimizado
- ✅ `vw_movimientos_diarios` - Resumen por día
- ✅ `vw_stock_historico_completo` - **Stock SIN limitantes de fecha**
- ✅ `vw_resumen_mensual` - Agregaciones mensuales
- ✅ `vw_alertas_stock` - Alertas de stock bajo
- ✅ `vw_auditoria_movimientos` - Auditoría completa

### 📦 03_insertar_datos_maestros.sql

**Inserta:**
- ✅ **37 explosivos** con códigos reales del sistema
- ✅ **Usuario admin** (username: `admin`, password: `admin123`)
- ✅ **Usuario de prueba** (username: `usuario1`, password: `admin123`)
- ✅ Índices adicionales para optimización
- ✅ Configuración inicial del sistema

### 🎯 04_insertar_stock_inicial.sql

**Crea:**
- ✅ **37 ingresos** de 1000 unidades cada uno
- ✅ **37,000 unidades totales** distribuidas
- ✅ Registros en tabla `ingresos` con fecha actual
- ✅ Registros en tabla `stock_diario` 
- ✅ Vale: `VALE-INICIAL-001`
- ✅ Guardia: `DIA`
- ✅ Responsable: `SISTEMA ADMINISTRADOR`

### 🔧 05_procedimientos_mantenimiento.sql

**Crea procedimientos:**
- ✅ `sp_limpiar_datos_completo` - Limpieza total de movimientos
- ✅ `sp_recalcular_stock_diario` - Recalcular stock por fechas
- ✅ `sp_reporte_estado_bd` - Reporte completo de estado
- ✅ `sp_generar_backup_datos` - Generar scripts de backup
- ✅ `sp_optimizar_bd` - Optimización de rendimiento

## 🗂️ Tablas Creadas

| Tabla | Propósito | Registros Típicos |
|-------|-----------|------------------|
| `explosivos` | Maestro de explosivos | 37 items |
| `ingresos` | Movimientos de entrada | Miles |
| `salidas` | Movimientos de salida | Miles |
| `devoluciones` | Movimientos de devolución | Cientos |
| `stock_diario` | Control diario de stock | Miles |
| `usuarios` | Control de acceso | Pocos |

## 🔗 Relaciones Principales

```
explosivos (1) ──→ (N) ingresos
explosivos (1) ──→ (N) salidas  
explosivos (1) ──→ (N) devoluciones
explosivos (1) ──→ (N) stock_diario
```

## 📈 Vistas Principales

### 🎯 Vista Principal: `vw_stock_historico_completo`
**⚠️ IMPORTANTE:** Esta vista **NO tiene limitantes de fecha** - calcula el stock total basándose en TODOS los movimientos históricos.

```sql
SELECT * FROM vw_stock_historico_completo;
-- Devuelve stock actual de todos los explosivos SIN filtros
```

### 📊 Vista PowerBI: `vw_stock_explosivos_powerbi`
Optimizada para consultas rápidas con stock de hoy vs ayer.

### 🚨 Vista de Alertas: `vw_alertas_stock`
Identifica explosivos con stock bajo o crítico.

## 🔑 Credenciales por Defecto

| Usuario | Password | Rol | Email |
|---------|----------|-----|--------|
| `admin` | `admin123` | `admin` | `admin@polvorin.com` |
| `usuario1` | `admin123` | `usuario` | `usuario@polvorin.com` |

## 🛠️ Comandos de Mantenimiento

### 🔍 Ver Estado de la BD
```sql
EXEC sp_reporte_estado_bd;
```

### 🧹 Limpiar Todos los Datos
```sql
EXEC sp_limpiar_datos_completo;
```

### 📊 Recalcular Stock Diario
```sql
EXEC sp_recalcular_stock_diario '2025-01-01', '2025-12-31';
```

### 🚀 Optimizar Base de Datos
```sql
EXEC sp_optimizar_bd;
```

## ⚙️ Configuración de Conexión

### Para SQL Server Local
```python
SQLSERVER_CONFIG = {
    'server': 'localhost',
    'database': 'polvorin',
    'username': 'tu_usuario',
    'password': 'tu_password',
    'driver': '{ODBC Driver 17 for SQL Server}'
}
```

### Para Azure SQL Database
```python
SQLSERVER_CONFIG = {
    'server': 'servidor.database.windows.net',
    'database': 'polvorin', 
    'username': 'admin_usuario',
    'password': 'password_seguro',
    'driver': '{ODBC Driver 17 for SQL Server}'
}
```

## 🎯 Características Importantes

### ✅ Sin Limitantes de Fecha
- Los cálculos principales de stock **NO tienen filtros de fecha**
- Se basan en TODO el historial de movimientos
- Compatibles con cualquier rango temporal

### ⚡ Optimizado para Rendimiento
- Índices en todas las columnas de consulta frecuente
- Vistas materializadas para consultas complejas
- Foreign keys para integridad referencial

### 🔒 Integridad de Datos
- Constraints de validación en todas las tablas
- Checks de cantidades positivas
- Validación de guardias (DIA/NOCHE)

### 📊 Compatible con PowerBI
- Vistas optimizadas para herramientas de BI
- Nombres de columnas descriptivos
- Agregaciones pre-calculadas

## 🚨 Notas Importantes

### ⚠️ Antes de Ejecutar en Producción
1. **Hacer backup** de la base de datos existente
2. **Revisar** los paths de archivos en `01_crear_estructura_completa.sql`
3. **Ajustar** las credenciales de usuario según necesidades
4. **Testear** en ambiente de desarrollo primero

### 🔧 Personalización
- **Explosivos:** Modificar lista en `03_insertar_datos_maestros.sql`
- **Stock inicial:** Ajustar cantidades en `04_insertar_stock_inicial.sql`
- **Usuarios:** Cambiar credenciales en `03_insertar_datos_maestros.sql`

### 📱 Compatibilidad
- ✅ SQL Server 2016+
- ✅ Azure SQL Database  
- ✅ SQL Server Express
- ✅ PowerBI Desktop/Service
- ✅ Flask/Python con pyodbc

---

## 🎉 ¡Sistema Listo!

Después de ejecutar estos scripts tendrás:
- 🗃️ Base de datos completa y optimizada
- 📊 37 explosivos maestros configurados  
- 👤 Usuarios de acceso creados
- 🎯 Stock inicial de prueba (opcional)
- 🔧 Herramientas de mantenimiento
- 📈 Vistas optimizadas sin limitantes de fecha

**¡Tu sistema de polvorín está listo para producción!** 🚀