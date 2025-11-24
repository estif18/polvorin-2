# 🧨 Sistema de Gestión de Polvorín - Pallca

## 📋 Descripción
Sistema completo de gestión de inventario de explosivos desarrollado en Flask con base de datos SQL Server Azure. Incluye funcionalidades avanzadas de registro, seguimiento y control de stock con sincronización automática.

## 🚀 Características Principales

### ✅ **Funcionalidades Core**
- **Gestión de Explosivos**: Registro y administración completa de tipos de explosivos
- **Control de Stock**: Seguimiento en tiempo real con vista dinámica
- **Registro de Movimientos**: Ingresos, salidas y devoluciones con trazabilidad completa
- **Gestión de Turnos**: Seguimiento por guardia (día/noche) con continuidad automática
- **Sistema de Usuarios**: Autenticación y control de acceso por roles

### 🔧 **Características Avanzadas**
- **Vista Dinámica**: `vw_stock_diario_simple` para datos siempre consistentes
- **Sincronización Automática**: Actualización en tiempo real después de movimientos
- **Detección de Inconsistencias**: Validación automática de datos
- **Exportación Excel**: Reportes detallados por fecha y explosivo
- **API REST**: Endpoints para integración con sistemas externos

## 📁 Estructura del Proyecto

```
polvorin-2-main/
├── app.py                              # Aplicación principal Flask
├── crear_admin.py                      # Script creación usuario admin
├── crear_vista_simple.py               # Script creación vista dinámica
├── recalcular_stock_automatico.py      # Recálculo completo de stock
├── sincronizacion_simple.py            # Sincronización automática
├── requirements.txt                    # Dependencias Python
├── database_scripts/                   # Scripts de base de datos
├── static/                            # Archivos estáticos (CSS, JS)
├── templates/                         # Plantillas HTML
├── INSTALACION.md                     # Guía de instalación
└── SINCRONIZACION_AUTOMATICA.md       # Documentación técnica
```

## 🛠️ Tecnologías Utilizadas
- **Backend**: Python Flask + SQLAlchemy
- **Base de Datos**: SQL Server Azure
- **Frontend**: HTML5, CSS3, JavaScript, Bootstrap
- **Conectividad**: pyodbc (SQL Server driver)

## ⚙️ Instalación y Configuración

### 1. **Prerequisitos**
```bash
Python 3.8+
SQL Server Azure
ODBC Driver 17 for SQL Server
```

### 2. **Instalación**
```bash
# Clonar repositorio
git clone [repositorio]
cd polvorin-2-main

# Instalar dependencias
pip install -r requirements.txt

# Configurar base de datos (ver INSTALACION.md)
# Ejecutar scripts en database_scripts/ en orden numérico

# Crear usuario admin
python crear_admin.py

# Crear vista dinámica
python crear_vista_simple.py
```

### 3. **Ejecución**
```bash
python app.py
```
Acceder a: `http://localhost:5000`

## 🔧 Configuración de Base de Datos

### Conexión SQL Server Azure
```python
# Configuración en app.py
SQLSERVER_CONFIG = {
    'server': 'pallca.database.windows.net',
    'database': 'pallca', 
    'username': 'usuario@pallca',
    'password': 'password'
}
```

### Vista Dinámica Principal
```sql
-- vw_stock_diario_simple: Vista principal para stock diario
-- Calcula automáticamente movimientos y detecta inconsistencias
-- Se actualiza automáticamente con cambios en movimientos
```

## 📊 Funcionalidades del Sistema

### **Gestión de Stock**
- ✅ Stock diario por turno con continuidad automática
- ✅ Vista dinámica con validación en tiempo real  
- ✅ Sincronización automática después de movimientos
- ✅ Detección automática de inconsistencias

### **Registro de Movimientos** 
- ✅ Ingresos con número de vale y proveedor
- ✅ Salidas por labor y tipo de actividad
- ✅ Devoluciones con trazabilidad completa
- ✅ Actualización automática de stock

### **Reportes y Exportación**
- ✅ Stock diario por fecha y turno
- ✅ Exportación a Excel con detalle de labores
- ✅ Filtros por explosivo y rango de fechas
- ✅ API REST para integraciones

## 🔧 Mantenimiento

### **Sincronización Automática**
El sistema incluye sincronización automática que:
- Se ejecuta después de cada movimiento (ingreso/salida/devolución)
- Actualiza la vista dinámica automáticamente
- Mantiene continuidad entre turnos día/noche
- Detecta y reporta inconsistencias

### **Recálculo Manual** 
Si necesitas recalcular todo el stock:
```bash
python recalcular_stock_automatico.py
```

### **Verificación de Estado**
La vista `vw_stock_diario_simple` incluye el campo `estado_consistencia`:
- `'OK'`: Datos consistentes
- `'INCONSISTENTE'`: Requiere revisión

## 🎯 Estado Actual del Sistema

### ✅ **Sistema Completamente Operativo**
- Vista dinámica implementada y funcionando
- Sincronización automática activa
- Datos consistentes y validados
- APIs actualizadas para usar vista dinámica
- Base de datos limpia sin registros obsoletos

### 📊 **Métricas de Calidad**
- **100% consistencia** en vista dinámica
- **Sincronización automática** después de movimientos
- **0 registros inconsistentes** detectados
- **Performance optimizada** con vista pre-calculada

## 🚀 Próximas Mejoras Sugeridas

1. **Dashboard Analítico**: Gráficos y métricas de consumo
2. **Alertas Automáticas**: Notificaciones por stock bajo
3. **Integración PowerBI**: Conectores directos para reportes
4. **Mobile App**: Aplicación móvil para registro en campo
5. **Auditoría Avanzada**: Trazabilidad completa de cambios

## 📞 Soporte Técnico

Para soporte técnico o consultas sobre el sistema:
- Documentación completa en `SINCRONIZACION_AUTOMATICA.md`
- Guía de instalación en `INSTALACION.md`
- Scripts de mantenimiento incluidos en el proyecto

---

*Sistema desarrollado y optimizado para operaciones de minería con altos estándares de seguridad y trazabilidad.*