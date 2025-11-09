# 🚀 Guía de Instalación - Sistema Polvorín v4.0

## 📋 Requisitos Previos

- Python 3.8 o superior
- SQL Server Azure (o SQL Server local)
- Git (opcional)

## 🔧 Instalación Paso a Paso

### 1. Descargar el Proyecto
```bash
# Opción A: Con Git
git clone [URL-del-repositorio]
cd CODIGO-REGISTRO-POLVORIN

# Opción B: Descargar ZIP
# Descomprimir el archivo en la carpeta deseada
```

### 2. Instalar Dependencias
```bash
pip install -r requirements.txt
```

### 3. Configurar Base de Datos

Ejecutar en orden los siguientes scripts SQL:

```sql
-- 1. Ejecutar vista_dinamica.sql
sqlcmd -S "tu-servidor.database.windows.net" -d "tu-base-datos" -U "tu-usuario" -P "tu-contraseña" -i vista_dinamica.sql

-- 2. Ejecutar agregar_tipos_actividad.sql
sqlcmd -S "tu-servidor.database.windows.net" -d "tu-base-datos" -U "tu-usuario" -P "tu-contraseña" -i agregar_tipos_actividad.sql
```

### 4. Configurar Conexión en app.py

Editar las líneas 14-18 en `app.py`:

```python
server = 'tu-servidor.database.windows.net'
database = 'tu-base-datos'
username = 'tu-usuario'
password = 'tu-contraseña'
```

### 5. Crear Usuario Administrador

```bash
python -c "
from app import app, db, Usuario
with app.app_context():
    admin = Usuario(username='admin', password='admin123', rol='administrador')
    db.session.add(admin)
    db.session.commit()
    print('Usuario admin creado exitosamente')
"
```

### 6. Ejecutar la Aplicación

```bash
python app.py
```

La aplicación estará disponible en: `http://127.0.0.1:5000`

## 👤 Credenciales por Defecto

- **Usuario**: admin
- **Contraseña**: admin123

## 🌐 Configuración para Producción

Para usar en producción, cambiar en `app.py`:

```python
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)  # debug=False para producción
```

## 📁 Estructura del Proyecto

```
CODIGO-REGISTRO-POLVORIN/
├── app.py                 # Aplicación principal Flask
├── requirements.txt       # Dependencias Python
├── vista_dinamica.sql     # Script de vistas dinámicas
├── agregar_tipos_actividad.sql # Script tipos de actividad
├── static/               # Archivos CSS, JS, imágenes
├── templates/            # Plantillas HTML
└── database_scripts/     # Scripts adicionales de BD
```

## 🔧 Características Principales

- **Panel Administrativo**: `/editar` - Gestión completa de datos
- **Dashboard**: `/` - Resumen y estadísticas
- **Gestión de Labores**: Crear, editar, eliminar labores
- **Tipos de Actividad**: 5 categorías predefinidas
- **Reportes**: Excel, PDF, impresión
- **Stock en Tiempo Real**: Inventario actualizado

## 🆘 Solución de Problemas

### Error de Conexión a BD
Verificar credenciales en `app.py` líneas 14-18

### Error de Módulos
```bash
pip install --upgrade -r requirements.txt
```

### Puerto Ocupado
Cambiar puerto en la última línea de `app.py`:
```python
app.run(host='0.0.0.0', port=8000, debug=True)  # Cambiar 5000 por 8000
```

## 📞 Soporte

Para soporte técnico, revisar los logs en la consola donde se ejecuta `python app.py`