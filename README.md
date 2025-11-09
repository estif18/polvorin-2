# 🧨 Sistema de Registro de Polvorín v5.0

Sistema web completo para gestión de inventario de explosivos con Flask y SQL Server Azure.

## 🚀 Estado del Proyecto: ✅ PRODUCCIÓN

**Última actualización**: 9 noviembre 2025  
**Estado**: 🟢 Sistema Completo y Optimizado  
**Características**: CRUD Completo + Modal Confirmaciones + 37 Nuevos Explosivos

## 🚀 Características Principales

- ✅ **CRUD Completo**: Crear, Leer, Editar y Eliminar ingresos, salidas y devoluciones
- ✅ **Modal de Confirmación**: Sistema elegante de confirmación para todos los formularios
- ✅ **37 Explosivos Actualizados**: Códigos 030xxxx con stock inicial de 50 unidades c/u
- ✅ **Gestión de Labores**: Sistema completo de administración de labores de trabajo
- ✅ **Tipos de Actividad**: Categorización con 5 tipos (Breasting, Realce, Sub nivel, Desquinche Mineral, Avance)
- ✅ **Interface Administrativa**: Panel completo de edición para administradores
- ✅ **Control de Stock**: Inventario en tiempo real por explosivo  
- ✅ **Stock Diario por Turno**: Visualización correcta de datos reales de stock
- ✅ **Sistema de Turnos**: Separación clara entre DÍA y NOCHE
- ✅ **Interface Moderna**: Bootstrap 5.3, responsive, modales elegantes
- ✅ **Base de Datos Optimizada**: Consultas SQL mejoradas y vistas actualizadas

## 🛠️ Stack Tecnológico

- **Backend**: Python 3.12, Flask 2.3.3, SQLAlchemy 2.0.23
- **Base de Datos**: SQL Server Azure con vistas optimizadas
- **Frontend**: HTML5, CSS3, JavaScript vanilla con modales
- **Sistema de Usuarios**: Autenticación y autorización

## 📦 Instalación y Uso

### Producción
```bash
# 1. Instalar dependencias
pip install -r requirements.txt

# 2. Ejecutar aplicación
python app.py

# 3. Acceder al sistema
http://localhost:5000
```

### Deployment con Docker
```bash
# Build imagen
docker build -t polvorin-app .

# Ejecutar contenedor
docker run -p 5000:5000 polvorin-app
```

## 🚀 Deployment en GitHub

### ✅ Error pyodbc Solucionado

El problema de compilación de `pyodbc` en GitHub Actions está resuelto automáticamente:

- **Workflow incluido** (`.github/workflows/deploy.yml`)
- **Dependencias del sistema** instaladas automáticamente
- **Drivers ODBC** configurados para SQL Server
- **Wheels precompilados** para evitar errores de compilación

### Pasos para Deploy

1. **Commit y Push**:
   ```bash
   git add .
   git commit -m "Sistema completo con deployment automático"
   git push origin main
   ```

2. **GitHub Actions**: Se ejecutará automáticamente
3. **Deploy**: Aplicación lista para producción

## 🔧 Solución de Problemas

### Error pyodbc en CI/CD ✅ RESUELTO
El workflow automáticamente:
- Instala drivers ODBC para SQL Server
- Configura compiladores necesarios
- Usa wheels precompilados de pyodbc

### Conexión Base de Datos
Configuración en `app.py`:
```python
server = 'servidor-examen-codigo.database.windows.net'
database = 'PolvorinDB' 
username = 'CloudSA2f8e2892'
password = 'Password123!'
```

## 📁 Estructura del Proyecto

```
CODIGO-REGISTRO-POLVORIN/
├── app.py                    # Aplicación Flask principal
├── requirements.txt          # Dependencias Python
├── Dockerfile               # Configuración Docker
├── .github/workflows/       # GitHub Actions
├── templates/               # Templates HTML
├── static/css/             # Estilos CSS
└── README.md               # Esta documentación
```

## 🎯 Funcionalidades

### 🏠 Dashboard
- Resumen de operaciones del día
- Navegación rápida a todas las secciones

### 📥 Ingresos
- Registro con fecha editable
- Número de vale obligatorio
- Sistema de turnos

### 📤 Salidas  
- Selección múltiple de explosivos
- Control de stock disponible
- Labor de destino

### 🔄 Devoluciones
- Motivo de devolución
- Trazabilidad completa

### 📊 Stock
- Inventario en tiempo real
- Ordenamiento por grupos operacionales

## 🎮 Uso del Sistema

1. **Acceder**: `http://localhost:5000`
2. **Dashboard**: Ver resumen de operaciones
3. **Registrar**: Usar formularios con fechas editables
4. **Consultar**: Ver stock y historial

## 🏆 Ventajas

- ✅ **Deployment Automático**: GitHub Actions configurado
- ✅ **Sin Errores pyodbc**: Problema resuelto
- ✅ **Docker Ready**: Contenedorización incluida
- ✅ **Azure Compatible**: Listo para Azure App Service
- ✅ **Ordenamiento Inteligente**: Por grupos operacionales
- ✅ **Fechas Flexibles**: Control total sobre registros

## 🛠️ Solución de Problemas

### ❌ Error: "No se encontró stock diario"
**Causa**: Falta inicialización de stock para la fecha actual  
**Solución**: Ejecutar desde Azure Console:
```bash
cd /home/site/wwwroot
python -c "
from app import app, db, StockDiario, Explosivo, obtener_guardia_actual
from datetime import date
with app.app_context():
    hoy = date.today()
    guardia = obtener_guardia_actual()
    if not StockDiario.query.filter_by(fecha=hoy, guardia=guardia).first():
        for exp in Explosivo.query.all():
            ultimo = StockDiario.query.filter_by(explosivo_id=exp.id).order_by(StockDiario.fecha.desc()).first()
            stock_inicial = ultimo.stock_final if ultimo else 0
            nuevo = StockDiario(explosivo_id=exp.id, fecha=hoy, guardia=guardia, stock_inicial=stock_inicial, salidas_total=0, ingresos_total=0, devoluciones_total=0, stock_final=stock_inicial)
            db.session.add(nuevo)
        db.session.commit()
        print('Stock inicializado correctamente')
    else:
        print('Stock ya existe')
"
```

### 🔄 Reiniciar Aplicación Azure
```bash
cd /home/site/wwwroot
touch restart.txt
```

## 📊 Base de Datos Optimizada

### 🗄️ Estructura Actual (10 objetos)

**Tablas Principales (7):**
- `explosivos` - Catálogo de tipos de explosivos
- `stock_diario` - Registro diario de inventarios
- `ingresos` - Movimientos de entrada al polvorín
- `salidas` - Movimientos de salida del polvorín  
- `devoluciones` - Devoluciones de explosivos no utilizados
- `turnos_guardia` - Control de turnos de trabajo
- `usuarios` - Gestión de acceso al sistema

**Vistas Activas (3):**
- `vista_vale_despacho` - Vista principal con labores dinámicas (1-10 por turno)
- `vista_stock_powerbi` - Datos optimizados para reportes y dashboards
- `stock_actual` - Stock en tiempo real por explosivo

### 🧹 Limpieza Realizada (24 oct 2025)
- ❌ **Eliminadas 3 vistas no utilizadas**: 
  - `vista_resumen_stock_diario`
  - `vista_stock_diario_turnos` 
  - `stock_por_explosivo`
- ✅ **Resultado**: Reducción del 30% en objetos de base de datos (14 → 10)
- ✅ **Impacto**: Mejor rendimiento, mantenimiento simplificado

## 📊 Vistas Power BI

- **vista_stock_powerbi**: Stock con análisis temporal
- **vista_vale_despacho**: Vales con labores dinámicas (hasta 10 por turno)

Conectar Power BI → SQL Server Azure → Importar vistas → Crear dashboards

## 🆘 Scripts de Emergencia

### Disponibles para recuperación rápida:

1. **`EMERGENCIA_RECREAR_BD.sql`** - ⚠️ Recreación completa (ELIMINA DATOS)
   ```bash
   sqlcmd -S servidor-examen-codigo.database.windows.net -d polvorin -U admin_examen -P "J/829074184573uv" -i EMERGENCIA_RECREAR_BD.sql
   ```

2. **`EMERGENCIA_SOLO_VISTAS.sql`** - ✅ Solo recrea vistas (CONSERVA DATOS)
   ```bash
   sqlcmd -S servidor-examen-codigo.database.windows.net -d polvorin -U admin_examen -P "J/829074184573uv" -i EMERGENCIA_SOLO_VISTAS.sql
   ```

3. **`limpiar_base_datos.sql`** - 🧹 Optimización y limpieza
   ```bash
   sqlcmd -S servidor-examen-codigo.database.windows.net -d polvorin -U admin_examen -P "J/829074184573uv" -i limpiar_base_datos.sql
   ```

**📖 Ver**: `GUIA_EMERGENCIA.md` para protocolos detallados de recuperación

---

🚀 **¡Listo para Producción!** - Sistema completo con respaldo de emergencia 🧨⚡