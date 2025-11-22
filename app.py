#!/usr/bin/env python3
"""
Sistema de Registro de Polvorín - Aplicación Flask
Versión: 4.0 - Sistema Completo con CRUD
"""

from flask import Flask, render_template, request, jsonify, redirect, url_for, flash, session, send_file
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text, and_
from datetime import datetime, date, timedelta
from functools import wraps
import pyodbc
import os
import hashlib
import time
import uuid
import json

app = Flask(__name__)
app.secret_key = 'pallca_secret_key_2025'

# Configuración de sesiones para evitar duplicados
app.permanent_session_lifetime = timedelta(minutes=30)  # Transacciones expiran en 30 min

# Configuración de SQL Server Azure
SQLSERVER_CONFIG = {
    'server': 'pallca.database.windows.net',
    'database': 'pallca',
    'username': 'pract_seg_pal@santa-luisa.pe@pallca',
    'password': 'pallca/berlin/2025',
    'driver': '{ODBC Driver 17 for SQL Server}'
}

# Configurar SQLAlchemy para SQL Server
from urllib.parse import quote_plus

# URL encode para caracteres especiales en username y password
username_encoded = quote_plus(SQLSERVER_CONFIG['username'])
password_encoded = quote_plus(SQLSERVER_CONFIG['password'])

connection_string = (
    f"mssql+pyodbc://{username_encoded}:"
    f"{password_encoded}@{SQLSERVER_CONFIG['server']}/"
    f"{SQLSERVER_CONFIG['database']}?driver=ODBC+Driver+17+for+SQL+Server"
)

app.config['SQLALCHEMY_DATABASE_URI'] = connection_string
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    'pool_pre_ping': True,
    'pool_recycle': 300,
    # 'implicit_returning': False,  # Temporalmente comentado para debugging
}

db = SQLAlchemy(app)

# Modelos de base de datos (tablas ya existen)
class Explosivo(db.Model):
    __tablename__ = 'explosivos'
    
    id = db.Column(db.Integer, primary_key=True)
    codigo = db.Column(db.String(20), nullable=False, unique=True)
    descripcion = db.Column(db.String(200), nullable=False)
    unidad = db.Column(db.String(20), nullable=False)
    grupo = db.Column(db.String(50), nullable=True)  # Columna grupo añadida
    
    def __repr__(self):
        return f'<Explosivo {self.codigo}: {self.descripcion}>'

class StockDiario(db.Model):
    __tablename__ = 'stock_diario'
    
    id = db.Column(db.Integer, primary_key=True)
    explosivo_id = db.Column(db.Integer, db.ForeignKey('explosivos.id'), nullable=False)
    fecha = db.Column(db.Date, nullable=False)
    guardia = db.Column(db.String(10), nullable=False)  # 'dia' o 'noche'
    stock_inicial = db.Column(db.Integer, nullable=False)
    stock_final = db.Column(db.Integer, nullable=False)
    responsable_guardia = db.Column(db.String(100))
    observaciones = db.Column(db.String(500))
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relaciones
    explosivo = db.relationship('Explosivo', backref='stocks_diarios')

class Salida(db.Model):
    __tablename__ = 'salidas'
    
    id = db.Column(db.Integer, primary_key=True)
    explosivo_id = db.Column(db.Integer, db.ForeignKey('explosivos.id'), nullable=False)
    stock_diario_id = db.Column(db.Integer, db.ForeignKey('stock_diario.id'))
    labor = db.Column(db.String(200), nullable=False)
    tipo_actividad = db.Column(db.String(100))  # Nueva columna para tipo de actividad
    cantidad = db.Column(db.Integer, nullable=False)
    fecha_salida = db.Column(db.DateTime, default=datetime.utcnow)
    guardia = db.Column(db.String(10), nullable=False)
    responsable = db.Column(db.String(100))
    autorizado_por = db.Column(db.String(100))
    observaciones = db.Column(db.String(500))
    estado = db.Column(db.String(15), default='activo')  # 'activo', 'devuelto', 'utilizado'
    
    # Relaciones
    explosivo = db.relationship('Explosivo', backref='salidas')
    stock_diario = db.relationship('StockDiario', backref='salidas')

class Devolucion(db.Model):
    __tablename__ = 'devoluciones'
    
    id = db.Column(db.Integer, primary_key=True)
    salida_id = db.Column(db.Integer, db.ForeignKey('salidas.id'), nullable=True)  # Hacerlo opcional
    explosivo_id = db.Column(db.Integer, db.ForeignKey('explosivos.id'), nullable=True)  # Agregar explosivo_id
    stock_diario_id = db.Column(db.Integer, db.ForeignKey('stock_diario.id'))
    cantidad_devuelta = db.Column(db.Float, nullable=False)  # Cambiar a Float para decimales
    motivo = db.Column(db.String(500), nullable=False)
    fecha_devolucion = db.Column(db.DateTime, default=datetime.utcnow)
    guardia = db.Column(db.String(10), nullable=False)
    responsable = db.Column(db.String(100))
    recibido_por = db.Column(db.String(100))
    labor = db.Column(db.String(200))  # Nueva columna para labor de origen
    estado_material = db.Column(db.String(20), default='bueno')  # 'bueno', 'deteriorado'
    observaciones = db.Column(db.String(500))
    
    # Relaciones
    salida = db.relationship('Salida', backref='devoluciones')
    explosivo = db.relationship('Explosivo', backref='devoluciones')
    stock_diario = db.relationship('StockDiario', backref='devoluciones')

class Ingreso(db.Model):
    __tablename__ = 'ingresos'
    
    id = db.Column(db.Integer, primary_key=True)
    explosivo_id = db.Column(db.Integer, db.ForeignKey('explosivos.id'), nullable=False)
    stock_diario_id = db.Column(db.Integer, db.ForeignKey('stock_diario.id'))
    numero_vale = db.Column(db.String(50), nullable=True)  # Permite NULL
    cantidad = db.Column(db.Numeric(10, 2), nullable=False)  # decimal(10,2)
    fecha_ingreso = db.Column(db.DateTime, nullable=False)
    guardia = db.Column(db.String(10), nullable=False)
    recibido_por = db.Column(db.String(100), nullable=True)  # Permite NULL
    observaciones = db.Column(db.String(500), nullable=True)  # Permite NULL
    
    # Relaciones
    explosivo = db.relationship('Explosivo', backref='ingresos')
    stock_diario = db.relationship('StockDiario', backref='ingresos')

class TurnoGuardia(db.Model):
    __tablename__ = 'turnos_guardia'
    
    id = db.Column(db.Integer, primary_key=True)
    fecha = db.Column(db.Date, nullable=False)
    guardia = db.Column(db.String(10), nullable=False)  # 'dia' o 'noche'
    responsable = db.Column(db.String(100), nullable=False)
    hora_inicio = db.Column(db.Time)
    hora_fin = db.Column(db.Time)
    estado = db.Column(db.String(15), default='activo')  # 'activo', 'cerrado'
    observaciones = db.Column(db.String(500))
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow)

class Labor(db.Model):
    __tablename__ = 'labores'
    
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(200), nullable=False, unique=True)
    descripcion = db.Column(db.String(500))
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Labor {self.nombre}>'

class TipoActividad(db.Model):
    __tablename__ = 'tipos_actividad'
    
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False, unique=True)
    descripcion = db.Column(db.String(500))
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<TipoActividad {self.nombre}>'

class Usuario(db.Model):
    __tablename__ = 'usuarios'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), nullable=False, unique=True)
    password_hash = db.Column(db.String(128), nullable=False)
    nombre_completo = db.Column(db.String(100), nullable=False)
    cargo = db.Column(db.String(50), nullable=False)  # 'supervisor', 'encargado', 'administrador'
    nivel = db.Column(db.Integer, nullable=False, default=1)  # 1=Básico, 2=Intermedio, 3=Avanzado, 4=Administrador
    activo = db.Column(db.Boolean, default=True)
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow)
    ultimo_login = db.Column(db.DateTime)
    
    def set_password(self, password):
        """Establecer contraseña con hash"""
        self.password_hash = hashlib.sha256(password.encode()).hexdigest()
    
    def check_password(self, password):
        """Verificar contraseña"""
        return self.password_hash == hashlib.sha256(password.encode()).hexdigest()
    
    def get_nivel_nombre(self):
        """Obtener el nombre del nivel de acceso"""
        niveles = {1: 'Básico', 2: 'Intermedio', 3: 'Avanzado', 4: 'Administrador'}
        return niveles.get(self.nivel, 'Desconocido')
    
    def puede_administrar_usuarios(self):
        """Verificar si el usuario puede administrar otros usuarios"""
        return self.nivel >= 4  # Solo administradores
    
    def puede_editar_registros(self):
        """Verificar si el usuario puede editar registros"""
        return self.nivel >= 3  # Avanzado y administradores
    
    def puede_registrar_movimientos(self):
        """Verificar si el usuario puede registrar ingresos/salidas/devoluciones"""
        return self.nivel >= 2  # Intermedio, avanzado y administradores
    
    def es_solo_lectura(self):
        """Verificar si el usuario solo tiene permisos de lectura"""
        return self.nivel == 1  # Solo básico
    
    def __repr__(self):
        return f'<Usuario {self.username}: {self.nombre_completo} (Nivel {self.nivel})>'

class NivelAcceso(db.Model):
    __tablename__ = 'niveles_acceso'
    
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(50), nullable=False)
    descripcion = db.Column(db.String(200), nullable=False)
    permisos_descripcion = db.Column(db.String(500), nullable=False)
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<NivelAcceso {self.id}: {self.nombre}>'

# Funciones auxiliares
def obtener_guardia_actual():
    """Determinar la guardia actual basado en la hora"""
    hora_actual = datetime.now().hour
    
    if 6 <= hora_actual < 18:
        return "dia"
    else:
        return "noche"

def usuario_logueado():
    """Verificar si hay un usuario logueado"""
    return 'user_id' in session

def obtener_usuario_actual():
    """Obtener datos del usuario actual"""
    if not usuario_logueado():
        return None
    return db.session.get(Usuario, session['user_id'])

def require_login(f):
    """Decorador para requerir login"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not usuario_logueado():
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def require_login_api(f):
    """Decorador para requerir login en APIs (devuelve JSON)"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not usuario_logueado():
            return jsonify({'error': 'No autorizado', 'redirect': '/login'}), 401
        return f(*args, **kwargs)
    return decorated_function

def crear_usuario_admin_inicial():
    """Crear usuario administrador inicial si no existe"""
    admin = Usuario.query.filter_by(username='@dmin_almacen').first()
    if not admin:
        admin = Usuario(
            username='@dmin_almacen',
            nombre_completo='Administrador del Sistema',
            cargo='administrador',
            nivel=4  # Nivel administrador
        )
        admin.set_password('almacenp@llca')  # Contraseña del sistema
        db.session.add(admin)
        db.session.commit()
        print("Usuario administrador creado: @dmin_almacen / almacenp@llca (Nivel 4 - Administrador)")

def clasificar_explosivo_por_grupo(descripcion):
    """Clasificar explosivos por grupos según la descripción"""
    descripcion_upper = descripcion.upper()
    
    # Grupo 1: EXPLOSIVOS (prioridad más alta)
    # Buscar explosivos principales - incluyendo más patrones comunes
    explosivo_keywords = ['EXPLOSIVO', 'ANFO', 'EMULSION', 'DINAMITA', 'TNT', 'GELATINA']
    # También consideramos algunos que pueden ser explosivos sin tener la palabra explícita
    otros_explosivos = ['NITRATO', 'POLVORA', 'GELIGNITA']
    
    if any(keyword in descripcion_upper for keyword in explosivo_keywords + otros_explosivos):
        return 1
    
    # Grupo 2: FANELES MS 4.8 MTS
    if 'FANEL' in descripcion_upper and 'MS' in descripcion_upper and '4.8' in descripcion_upper:
        return 2
    
    # Grupo 3: FANELES LP 4.8 MTS  
    if 'FANEL' in descripcion_upper and 'LP' in descripcion_upper and '4.8' in descripcion_upper:
        return 3
    
    # Grupo 4: Otros FANELES
    if 'FANEL' in descripcion_upper:
        return 4
    
    # Grupo 5: Todos los demás (detonadores, cordones, accesorios, etc.)
    return 5

def obtener_explosivos_ordenados():
    """Obtener explosivos ordenados por grupo de la base de datos y luego por código"""
    explosivos = Explosivo.query.all()
    
    def orden_personalizado(explosivo):
        # Usar directamente la columna grupo de la base de datos
        grupo = explosivo.grupo or 'ZZZ'  # Si no tiene grupo, va al final
        
        # Dentro del grupo EXPLOSIVOS, SUPERFAM tiene prioridad especial
        if grupo == 'EXPLOSIVOS':
            desc_upper = explosivo.descripcion.upper()
            # SUPERFAM/ANFO aparece primero
            if 'SUPERFAM' in desc_upper or 'ANFO' in desc_upper:
                return (grupo, '0', explosivo.codigo)
            # Los demás van por código normal
            else:
                return (grupo, '1', explosivo.codigo)
        
        # Para otros grupos, ordenar por código
        return (grupo, '0', explosivo.codigo)
    
    # Ordenar usando la función personalizada
    explosivos_ordenados = sorted(explosivos, key=orden_personalizado)
    
    return explosivos_ordenados

def obtener_explosivo_id_de_devolucion(devolucion_id):
    """Obtener explosivo_id de una devolución a través de stock_diario"""
    try:
        result = db.session.query(StockDiario.explosivo_id).join(
            Devolucion, Devolucion.stock_diario_id == StockDiario.id
        ).filter(Devolucion.id == devolucion_id).first()
        
        return result.explosivo_id if result else None
    except Exception as e:
        print(f"Error obteniendo explosivo_id de devolución {devolucion_id}: {e}")
        return None

def calcular_stock_explosivo(explosivo_id):
    """Calcular stock actual de un explosivo usando vistas optimizadas o cálculo directo"""
    try:
        # Intentar usar vista_stock_powerbi si está disponible
        if usar_vista_stock_powerbi():
            stock_vista = obtener_stock_via_vista(explosivo_id)
            if stock_vista is not None:
                return stock_vista
        
        # Fallback: usar cálculo directo
        stock_directo = calcular_stock_explosivo_original(explosivo_id)
        return stock_directo
        
    except Exception as e:
        print(f"Error calculando stock para explosivo {explosivo_id}: {e}")
        # Último recurso
        return calcular_stock_explosivo_original(explosivo_id)

def calcular_stock_explosivo_original(explosivo_id):
    """Método original de cálculo como fallback"""
    try:
        # Calcular total de ingresos
        total_ingresos = db.session.query(db.func.sum(Ingreso.cantidad)).filter_by(explosivo_id=explosivo_id).scalar() or 0
        
        # Calcular total de salidas
        total_salidas = db.session.query(db.func.sum(Salida.cantidad)).filter_by(explosivo_id=explosivo_id).scalar() or 0
        
        # Calcular total de devoluciones directamente por explosivo_id (se suman al stock)
        total_devoluciones = db.session.query(db.func.sum(Devolucion.cantidad_devuelta)).filter_by(explosivo_id=explosivo_id).scalar() or 0
        
        # Stock actual = Ingresos - Salidas + Devoluciones
        stock_actual = int(total_ingresos) - int(total_salidas) + int(total_devoluciones)
        
        
        return max(stock_actual, 0)  # No permitir stock negativo
        
    except Exception as e:
        print(f"Error calculando stock original para explosivo {explosivo_id}: {e}")
        return 0

def obtener_stock_todos_explosivos_optimizado():
    """Obtener stock de todos los explosivos usando vistas optimizadas o cálculo directo"""
    try:
        # OPCIÓN 1: Usar vista v_stock_actual (más eficiente)
        if usar_vista_stock_powerbi():
            try:
                result = db.session.execute(text("""
                    SELECT 
                        id as explosivo_id,
                        codigo,
                        descripcion,
                        unidad,
                        stock_actual
                    FROM v_stock_actual
                    ORDER BY codigo
                """)).fetchall()
                
                stocks = {}
                for row in result:
                    stocks[row.descripcion] = {
                        'stock': int(row.stock_actual),
                        'explosivo_id': row.explosivo_id,
                        'descripcion': row.descripcion,
                        'unidad': row.unidad,
                        'codigo': row.codigo
                    }
                
                return stocks
                
            except Exception as e:
                print(f"Error usando vista v_stock_actual, fallback a cálculo: {e}")
        
        # FALLBACK: Usar consulta directa a explosivos (más lento pero confiable)
        explosivos = Explosivo.query.all()
        stocks = {}
        
        for explosivo in explosivos:
            stock = calcular_stock_explosivo_original(explosivo.id)
            stocks[explosivo.descripcion] = {
                'stock': int(stock),
                'explosivo_id': explosivo.id,
                'descripcion': explosivo.descripcion,
                'unidad': explosivo.unidad,
                'codigo': explosivo.codigo
            }
        
        return stocks
        
    except Exception as e:
        print(f"Error en obtener_stock_todos_explosivos_optimizado: {e}")
        return {}

def obtener_stock_diario_actual(explosivo_id, fecha_objetivo=None, retornar_objeto=False):
    """Obtener el stock diario actual para un explosivo en una fecha específica"""
    if fecha_objetivo is None:
        fecha_objetivo = date.today()
    
    # Convertir fecha_objetivo a date si es datetime
    if isinstance(fecha_objetivo, datetime):
        fecha_objetivo = fecha_objetivo.date()
    
    guardia = obtener_guardia_actual()
    
    stock_diario = StockDiario.query.filter_by(
        explosivo_id=explosivo_id,
        fecha=fecha_objetivo,
        guardia=guardia
    ).first()
    
    if stock_diario:
        return stock_diario if retornar_objeto else stock_diario.stock_inicial
    
    # Si no existe stock diario para esta fecha, inicializarlo automáticamente
    try:
        inicializar_stock_fecha_si_necesario(fecha_objetivo, guardia)
        
        # Buscar nuevamente después de la inicialización
        stock_diario = StockDiario.query.filter_by(
            explosivo_id=explosivo_id,
            fecha=fecha_objetivo,
            guardia=guardia
        ).first()
        
        if stock_diario:
            return stock_diario if retornar_objeto else stock_diario.stock_inicial
    except Exception as e:
        print(f"Error inicializando stock para fecha {fecha_objetivo}: {e}")
    
    if retornar_objeto:
        return None
    
    # Como último recurso, calcular usando el método original
    return calcular_stock_explosivo_original(explosivo_id)

def usar_vista_stock_powerbi():
    """Verificar si las vistas de stock están disponibles"""
    try:
        # Verificar vista principal v_stock_actual
        result = db.session.execute(text("""
            SELECT COUNT(*) as count
            FROM INFORMATION_SCHEMA.VIEWS 
            WHERE TABLE_NAME = 'v_stock_actual'
        """)).fetchone()
        
        if result and result.count > 0:
            # Verificar que la vista tiene datos
            result = db.session.execute(text("SELECT COUNT(*) as count FROM v_stock_actual")).fetchone()
            return result and result.count > 0
        
        # Fallback: verificar vista vw_stock_explosivos_powerbi
        result = db.session.execute(text("""
            SELECT COUNT(*) as count
            FROM INFORMATION_SCHEMA.VIEWS 
            WHERE TABLE_NAME = 'vw_stock_explosivos_powerbi'
        """)).fetchone()
        
        if result and result.count > 0:
            # Verificar que la vista tiene datos
            result = db.session.execute(text("SELECT COUNT(*) as count FROM vw_stock_explosivos_powerbi")).fetchone()
            return result and result.count > 0
            
        return False
    except Exception as e:
        print(f"Error verificando vistas de stock: {e}")
        return False

def obtener_stock_via_vista(explosivo_id, fecha_objetivo=None):
    """Obtener stock usando vistas optimizadas disponibles"""
    try:
        if fecha_objetivo is None:
            fecha_objetivo = date.today()
        
        if isinstance(fecha_objetivo, datetime):
            fecha_objetivo = fecha_objetivo.date()
        
        # OPCIÓN 1: Usar v_stock_actual (más simple y directa)
        try:
            result = db.session.execute(text("""
                SELECT stock_actual 
                FROM v_stock_actual 
                WHERE id = :explosivo_id
            """), {
                'explosivo_id': explosivo_id
            }).fetchone()
            
            if result:
                return float(result.stock_actual)
        except Exception as e:
            print(f"Error usando v_stock_actual: {e}")
        
        # OPCIÓN 2: Usar vw_stock_explosivos_powerbi con fecha
        try:
            guardia = obtener_guardia_actual()
            result = db.session.execute(text("""
                SELECT stock_inicial 
                FROM vw_stock_explosivos_powerbi 
                WHERE explosivo_id = :explosivo_id 
                AND fecha = :fecha 
                AND turno = :guardia
            """), {
                'explosivo_id': explosivo_id,
                'fecha': fecha_objetivo,
                'guardia': guardia
            }).fetchone()
            
            if result:
                return float(result.stock_inicial)
        except Exception as e:
            print(f"Error usando vw_stock_explosivos_powerbi: {e}")
        
        return None
        
    except Exception as e:
        print(f"Error general obteniendo stock via vista: {e}")
        return None

def inicializar_stock_fecha_si_necesario(fecha_objetivo, guardia):
    """Inicializar stock para una fecha y guardia específica si no existe"""
    from sqlalchemy import text
    
    # Convertir fecha_objetivo a date si es datetime
    if isinstance(fecha_objetivo, datetime):
        fecha_objetivo = fecha_objetivo.date()
    
    # Verificar si ya existe stock para esta fecha y guardia
    existe_stock = StockDiario.query.filter_by(fecha=fecha_objetivo, guardia=guardia).first()
    
    if not existe_stock:
        
        # OPTIMIZACIÓN: Obtener todos los stocks usando vista si está disponible
        if usar_vista_stock_powerbi():
            try:
                result = db.session.execute(text("""
                    SELECT id, stock_actual 
                    FROM v_stock_actual
                    ORDER BY id
                """)).fetchall()
                
                for row in result:
                    try:
                        nuevo_stock = StockDiario(
                            explosivo_id=row.id,
                            fecha=fecha_objetivo,
                            guardia=guardia,
                            stock_inicial=int(row.stock_actual),
                            stock_final=int(row.stock_actual),
                            responsable_guardia='Sistema',
                            observaciones=f'Inicializado automáticamente para fecha {fecha_objetivo} usando vista optimizada'
                        )
                        
                        db.session.add(nuevo_stock)
                        
                    except Exception as e:
                        continue
                
            except Exception as e:
                # Fallback al método original
                explosivos = Explosivo.query.all()
                for explosivo in explosivos:
                    try:
                        stock_actual = calcular_stock_explosivo_original(explosivo.id)
                        nuevo_stock = StockDiario(
                            explosivo_id=explosivo.id,
                            fecha=fecha_objetivo,
                            guardia=guardia,
                            stock_inicial=stock_actual,
                            stock_final=stock_actual,
                            responsable_guardia='Sistema',
                            observaciones=f'Inicializado automáticamente para fecha {fecha_objetivo} (cálculo directo)'
                        )
                        
                        db.session.add(nuevo_stock)
                        
                    except Exception as e:
                        continue
        else:
            # Si no hay vistas disponibles, usar método original
            explosivos = Explosivo.query.all()
            for explosivo in explosivos:
                try:
                    stock_actual = calcular_stock_explosivo_original(explosivo.id)
                    nuevo_stock = StockDiario(
                        explosivo_id=explosivo.id,
                        fecha=fecha_objetivo,
                        guardia=guardia,
                        stock_inicial=stock_actual,
                        stock_final=stock_actual,
                        responsable_guardia='Sistema',
                        observaciones=f'Inicializado automáticamente para fecha {fecha_objetivo}'
                    )
                    
                    db.session.add(nuevo_stock)
                    
                except Exception as e:
                    continue
        
        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise

# Rutas de la aplicación

# Rutas de autenticación
@app.route('/login', methods=['GET', 'POST'])
def login():
    """Página de login"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if not username or not password:
            flash('Por favor ingrese usuario y contraseña', 'error')
            return render_template('login.html')
        
        usuario = Usuario.query.filter_by(username=username, activo=True).first()
        
        if usuario and usuario.check_password(password):
            session['user_id'] = usuario.id
            session['username'] = usuario.username
            session['nombre_completo'] = usuario.nombre_completo
            session['cargo'] = usuario.cargo
            
            # Actualizar último login
            usuario.ultimo_login = datetime.now()
            db.session.commit()
            
            flash(f'Bienvenido {usuario.nombre_completo}', 'success')
            return redirect(url_for('index'))
        else:
            flash('Usuario o contraseña incorrectos', 'error')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    """Cerrar sesión"""
    session.clear()
    flash('Sesión cerrada correctamente', 'info')
    return redirect(url_for('login'))

@app.route('/usuarios')
@require_login
def listar_usuarios():
    """Listar usuarios (solo administradores)"""
    usuario_actual = obtener_usuario_actual()
    if usuario_actual.cargo != 'administrador':
        flash('No tiene permisos para acceder a esta sección', 'error')
        return redirect(url_for('index'))
    
    usuarios = Usuario.query.order_by(Usuario.nombre_completo).all()
    return render_template('usuarios.html', usuarios=usuarios)

@app.route('/usuarios/eliminar/<int:usuario_id>', methods=['POST', 'DELETE'])
@require_login
def eliminar_usuario(usuario_id):
    """Eliminar usuario (solo administradores)"""
    usuario_actual = obtener_usuario_actual()
    if not usuario_actual.puede_administrar_usuarios():
        return jsonify({'error': 'No tiene permisos para eliminar usuarios'}), 403
    
    try:
        # No permitir que el administrador se elimine a sí mismo
        if usuario_id == usuario_actual.id:
            return jsonify({'error': 'No puede eliminar su propia cuenta'}), 400
        
        usuario_a_eliminar = db.session.get(Usuario, usuario_id)
        if not usuario_a_eliminar:
            return jsonify({'error': 'Usuario no encontrado'}), 404
        
        # Guardar nombre para el mensaje de confirmación
        nombre_usuario = usuario_a_eliminar.nombre_completo
        username = usuario_a_eliminar.username
        
        # Eliminar usuario
        db.session.delete(usuario_a_eliminar)
        db.session.commit()
        
        return jsonify({
            'success': f'Usuario {username} ({nombre_usuario}) eliminado correctamente'
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error al eliminar usuario: {str(e)}'}), 500

@app.route('/usuarios/cambiar_estado/<int:usuario_id>', methods=['POST'])
@require_login
def cambiar_estado_usuario(usuario_id):
    """Activar/desactivar usuario (solo administradores)"""
    usuario_actual = obtener_usuario_actual()
    if not usuario_actual.puede_administrar_usuarios():
        return jsonify({'error': 'No tiene permisos para cambiar estado de usuarios'}), 403
    
    try:
        # No permitir que el administrador se desactive a sí mismo
        if usuario_id == usuario_actual.id:
            return jsonify({'error': 'No puede cambiar el estado de su propia cuenta'}), 400
        
        usuario = db.session.get(Usuario, usuario_id)
        if not usuario:
            return jsonify({'error': 'Usuario no encontrado'}), 404
        
        # Cambiar estado
        usuario.activo = not usuario.activo
        estado_texto = 'activado' if usuario.activo else 'desactivado'
        
        db.session.commit()
        
        return jsonify({
            'success': f'Usuario {usuario.username} {estado_texto} correctamente',
            'nuevo_estado': usuario.activo
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error al cambiar estado: {str(e)}'}), 500

@app.route('/usuarios/nuevo', methods=['GET', 'POST'])
@require_login
def nuevo_usuario():
    """Crear nuevo usuario (solo administradores)"""
    usuario_actual = obtener_usuario_actual()
    if not usuario_actual.puede_administrar_usuarios():
        flash('No tiene permisos para crear usuarios', 'error')
        return redirect(url_for('index'))
    
    if request.method == 'POST':
        try:
            username = request.form.get('username').strip()
            password = request.form.get('password')
            nombre_completo = request.form.get('nombre_completo').strip()
            cargo = request.form.get('cargo')
            nivel = int(request.form.get('nivel', 1))  # Nuevo campo nivel
            
            # Validaciones
            if not all([username, password, nombre_completo, cargo]):
                return jsonify({'error': 'Todos los campos son obligatorios'}), 400
            
            if Usuario.query.filter_by(username=username).first():
                return jsonify({'error': 'El nombre de usuario ya existe'}), 400
            
            if len(password) < 6:
                return jsonify({'error': 'La contraseña debe tener al menos 6 caracteres'}), 400
            
            if nivel not in [1, 2, 3, 4]:
                return jsonify({'error': 'Nivel de acceso inválido'}), 400
            
            # Crear nuevo usuario
            nuevo_usuario_obj = Usuario(
                username=username,
                nombre_completo=nombre_completo,
                cargo=cargo,
                nivel=nivel
            )
            nuevo_usuario_obj.set_password(password)
            
            db.session.add(nuevo_usuario_obj)
            db.session.commit()
            
            return jsonify({'success': f'Usuario {username} creado correctamente (Nivel {nivel} - {nuevo_usuario_obj.get_nivel_nombre()})'})
            
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Error al crear usuario: {str(e)}'}), 500
    
    # GET request - mostrar formulario
    niveles_acceso = NivelAcceso.query.order_by(NivelAcceso.id).all()
    return render_template('nuevo_usuario.html', niveles_acceso=niveles_acceso)

@app.route('/')
@require_login
def index():
    """Página principal - Dashboard simple"""
    fecha_actual = datetime.now()
    usuario_actual = obtener_usuario_actual()
    
    return render_template('index.html', 
                         fecha_actual=fecha_actual,
                         usuario_actual=usuario_actual)

@app.route('/explosivos')
@require_login
def listar_explosivos():
    """Listar todos los explosivos"""
    explosivos = obtener_explosivos_ordenados()
    # Usar index.html como template base o respuesta JSON
    if request.args.get('format') == 'json':
        return jsonify([{
            'id': e.id,
            'codigo': e.codigo,
            'descripcion': e.descripcion,
            'unidad': e.unidad
        } for e in explosivos])
    return redirect(url_for('simple_dashboard'))

@app.route('/salidas')
@require_login
def listar_salidas():
    """Listar salidas de explosivos"""
    page = request.args.get('page', 1, type=int)
    salidas = Salida.query.order_by(Salida.fecha_salida.desc()).paginate(
        page=page, per_page=20, error_out=False
    )
    # Retornar JSON o redirigir a dashboard
    if request.args.get('format') == 'json':
        return jsonify([{
            'id': s.id,
            'explosivo': s.explosivo.codigo,
            'labor': s.labor,
            'cantidad': int(s.cantidad),
            'fecha_salida': s.fecha_salida.isoformat(),
            'responsable': s.responsable
        } for s in salidas.items])
    return redirect(url_for('simple_dashboard'))

@app.route('/salidas/nueva', methods=['GET', 'POST'])
@require_login
def nueva_salida():
    """Registrar nueva salida de explosivos"""
    
    try:
        usuario_actual = obtener_usuario_actual()
    except Exception as e:
        return jsonify({'error': f'Error de autenticación: {str(e)}'}), 500
    
    if request.method == 'GET':
        try:
            explosivos = obtener_explosivos_ordenados()
            fecha_actual = datetime.now()
            guardia_actual = obtener_guardia_actual()
            return render_template('nueva_salida.html', 
                                 explosivos=explosivos,
                                 fecha_actual=fecha_actual,
                                 guardia_actual=guardia_actual,
                                 usuario_actual=usuario_actual)
        except Exception as e:
            return jsonify({'error': f'Error al cargar formulario: {str(e)}'}), 500
    
    if request.method == 'POST':
        if 'user_id' not in session:
            return jsonify({'error': 'Sesión expirada. Por favor, inicie sesión nuevamente.'}), 401
        
        transaction_id = str(uuid.uuid4())[:16]
        session_key = f'transaction_{transaction_id}'
        if session.get(session_key):
            return jsonify({'error': 'Esta transacción ya fue procesada. Evite hacer doble clic.'}), 400
        
        session[session_key] = True
        
        try:
            # Datos generales de la salida
            fecha_salida_str = request.form.get('fecha_salida')
            fecha_salida_str = request.form.get('fecha_salida')
            
            if fecha_salida_str:
                fecha_salida = datetime.strptime(fecha_salida_str, '%Y-%m-%d')
            else:
                fecha_salida = datetime.now()
                
            labor = request.form.get('labor', '')
            
            if not labor:
                return jsonify({'error': 'Debe especificar la labor'}), 400

            tipo_actividad = request.form.get('tipo_actividad', '')
            
            if not tipo_actividad:
                return jsonify({'error': 'Debe especificar el tipo de actividad'}), 400
            
            responsable = request.form.get('responsable', '').strip()  # Trabajador que recibe
            
            autorizado_por = usuario_actual.nombre_completo  # Usuario logueado que autoriza
            
            turno = request.form.get('turno', '')  # DIA o NOCHE
            
            if not turno:
                return jsonify({'error': 'Debe seleccionar un turno (DIA o NOCHE)'}), 400
            
            observaciones = request.form.get('observaciones', '')
            
            # Validar que el responsable no esté vacío
            if not responsable:
                return jsonify({'error': 'Debe especificar el nombre del trabajador que recibe los explosivos'}), 400
            
            # Parsear explosivos seleccionados
            explosivos_json = request.form.get('explosivos', '[]')
            
            try:
                explosivos_data = json.loads(explosivos_json)
            except json.JSONDecodeError as e:
                return jsonify({'error': f'Error en formato de datos: {str(e)}'}), 400
            
            if not explosivos_data:
                return jsonify({'error': 'Debe seleccionar al menos un explosivo'}), 400
            
            
            # OPTIMIZACIÓN 1: Obtener todos los IDs de explosivos de una vez y convertir a int
            explosivos_ids = [int(item['explosivo_id']) for item in explosivos_data]
            
            # OPTIMIZACIÓN 2: Obtener todos los stocks en lote usando vista
            stocks_lote = {}
            
            if usar_vista_stock_powerbi():
                try:
                    # Crear parámetros para SQL Server
                    params = {}
                    for i, exp_id in enumerate(explosivos_ids):
                        params[f'id_{i}'] = exp_id
                    
                    placeholders = ','.join([f':id_{i}' for i in range(len(explosivos_ids))])
                    
                    # USAR v_stock_actual que es la vista correcta
                    result = db.session.execute(text(f"""
                        SELECT 
                            id as explosivo_id, 
                            stock_actual
                        FROM v_stock_actual
                        WHERE id IN ({placeholders})
                    """), params).fetchall()
                    
                    for row in result:
                        stocks_lote[row.explosivo_id] = float(row.stock_actual)
                    
                    
                except Exception as e:
                    pass
            
            # Fallback: calcular stocks individualmente solo si la vista falló
            if not stocks_lote:
                for explosivo_id in explosivos_ids:
                    stocks_lote[explosivo_id] = calcular_stock_explosivo_original(explosivo_id)
            
            # OPTIMIZACIÓN 3: Inicializar stock diario si no existe
            guardia = obtener_guardia_actual()
            inicializar_stock_fecha_si_necesario(fecha_salida.date(), guardia)
            
            # OPTIMIZACIÓN 4: Obtener todos los stock_diario necesarios en una consulta
            stocks_diario_lote = {}
            
            try:
                # Consulta optimizada para obtener múltiples stock_diario
                
                stocks_diario_query = StockDiario.query.filter(
                    and_(
                        StockDiario.explosivo_id.in_(explosivos_ids),
                        StockDiario.fecha == fecha_salida.date(),
                        StockDiario.guardia == guardia
                    )
                ).all()
                
                for sd in stocks_diario_query:
                    stocks_diario_lote[sd.explosivo_id] = sd
                
                
            except Exception as e:
                return jsonify({'error': 'Error consultando stock diario'}), 500
            
            # OPTIMIZACIÓN 5: Validar todos en lote antes de insertar
            salidas_validas = []
            errores = []
            
            for item in explosivos_data:
                explosivo_id = int(item['explosivo_id'])  # Convertir a int para consistencia
                cantidad = int(item['cantidad'])
                
                # Verificar stock diario
                if explosivo_id not in stocks_diario_lote:
                    errores.append(f'No hay stock diario para explosivo ID {explosivo_id} en fecha {fecha_salida.date()}')
                    continue
                
                # Verificar stock disponible
                stock_disponible = stocks_lote.get(explosivo_id, 0)
                if cantidad > stock_disponible:
                    explosivo = db.session.get(Explosivo, explosivo_id)
                    nombre = explosivo.descripcion if explosivo else f'ID {explosivo_id}'
                    errores.append(f'{nombre}: Solicitado {cantidad}, disponible {stock_disponible}')
                    continue
                
                # Si pasa todas las validaciones, agregar a lista válida
                salidas_validas.append({
                    'explosivo_id': explosivo_id,
                    'stock_diario_id': stocks_diario_lote[explosivo_id].id,
                    'cantidad': cantidad
                })
            
            
            # OPTIMIZACIÓN 5: Insertar todas las salidas válidas en lote
            salidas_registradas = []
            if salidas_validas:
                
                try:
                    # Preparar inserción en lote
                    sql_insert_lote = text("""
                    INSERT INTO salidas (explosivo_id, stock_diario_id, labor, tipo_actividad, cantidad, fecha_salida, guardia, responsable, autorizado_por, observaciones)
                    VALUES (:explosivo_id, :stock_diario_id, :labor, :tipo_actividad, :cantidad, :fecha_salida, :guardia, :responsable, :autorizado_por, :observaciones)
                    """)
                    
                    # Ejecutar todas las inserciones en una sola transacción
                    for salida in salidas_validas:
                        db.session.execute(sql_insert_lote, {
                            'explosivo_id': salida['explosivo_id'],
                            'stock_diario_id': salida['stock_diario_id'],
                            'labor': labor,
                            'tipo_actividad': tipo_actividad,
                            'cantidad': salida['cantidad'],
                            'fecha_salida': fecha_salida,
                            'guardia': turno.lower(),
                            'responsable': responsable,
                            'autorizado_por': autorizado_por,
                            'observaciones': observaciones
                        })
                        
                        salidas_registradas.append({
                            'explosivo_id': salida['explosivo_id'],
                            'cantidad': salida['cantidad']
                        })
                    
                    
                except Exception as e:
                    error_msg = f'Error procesando salidas en lote: {str(e)}'
                    errores.append(error_msg)
            
            
            # Si hay salidas válidas, confirmar transacción
            if salidas_registradas:
                db.session.commit()
                
                mensaje_exito = f'Se registraron {len(salidas_registradas)} salidas exitosamente'
                if errores:
                    mensaje_exito += f'. {len(errores)} elementos tuvieron errores'
                
                response_data = {
                    'success': mensaje_exito,
                    'salidas_registradas': len(salidas_registradas),
                    'errores': errores
                }
                
                # Marcar transacción como completada exitosamente
                session[f'transaction_{transaction_id}_completed'] = True
                
                return jsonify(response_data)
            else:
                db.session.rollback()
                
                # Limpiar transacción fallida
                session.pop(session_key, None)
                
                return jsonify({
                    'error': 'No se pudo registrar ninguna salida',
                    'errores': errores
                }), 400
            
        except Exception as e:
            db.session.rollback()
            
            # Limpiar transacción fallida
            session.pop(session_key, None)
            
            return jsonify({'error': f'Error general al registrar salidas: {str(e)}'}), 500

@app.route('/devoluciones')
@require_login
def listar_devoluciones():
    """Listar devoluciones"""
    if request.args.get('format') == 'json':
        page = request.args.get('page', 1, type=int)
        devoluciones = Devolucion.query.order_by(Devolucion.fecha_devolucion.desc()).paginate(
            page=page, per_page=20, error_out=False
        )
        return jsonify([{
            'id': d.id,
            'salida_id': d.salida_id,
            'cantidad_devuelta': int(d.cantidad_devuelta),
            'motivo': d.motivo,
            'fecha_devolucion': d.fecha_devolucion.isoformat()
        } for d in devoluciones.items])
    return redirect(url_for('simple_dashboard'))

@app.route('/devoluciones/nueva', methods=['GET', 'POST'])
@require_login
def nueva_devolucion():
    """Registrar nueva devolución de explosivos"""
    usuario_actual = obtener_usuario_actual()
    
    if request.method == 'GET':
        explosivos = obtener_explosivos_ordenados()
        fecha_actual = datetime.now().strftime('%Y-%m-%d')
        guardia_actual = obtener_guardia_actual()
        usuarios = db.session.query(Usuario).all()
        
        # Calcular stock actual para todos los explosivos de una vez (más eficiente)
        stock_actual = {}
        codigos_explosivos = [e.codigo for e in explosivos]
        
        # OPTIMIZADO: Usar vista v_stock_actual para obtener todos los stocks eficientemente
        try:
            # Usar la vista v_stock_actual que ya tiene todo calculado
            from sqlalchemy import text
            
            # Crear la lista de códigos como string para SQL
            codigos_str = "'" + "','".join(codigos_explosivos) + "'"
            
            query = text(f"""
                SELECT codigo, stock_actual
                FROM v_stock_actual 
                WHERE codigo IN ({codigos_str})
            """)
            
            result = db.session.execute(query)
            for row in result:
                stock_actual[row.codigo] = float(row.stock_actual) if row.stock_actual else 0.0
            
                
        except Exception as e:
            print(f"Error optimizado con vista v_stock_actual, usando método individual: {e}")
            # Fallback al método individual si falla la consulta optimizada
            for explosivo in explosivos:
                stock_actual[explosivo.codigo] = calcular_stock_explosivo(explosivo.id)
        
        return render_template('nueva_devolucion.html', 
                             explosivos=explosivos,
                             fecha_actual=fecha_actual,
                             guardia_actual=guardia_actual,
                             usuario_actual=usuario_actual,
                             usuarios=usuarios,
                             stock_actual=stock_actual)
    
    if request.method == 'POST':
        
        # Verificar autenticación antes de proceder
        if 'user_id' not in session:
            return jsonify({'error': 'Sesión expirada. Por favor, inicie sesión nuevamente.'}), 401
        
        # Generar ID único para esta transacción basado en timestamp y datos básicos
        transaction_id = str(uuid.uuid4())[:16]  # ID único más simple
        
        # Verificar si esta transacción ya fue procesada (evitar duplicados)
        session_key = f'transaction_devolucion_{transaction_id}'
        if session.get(session_key):
            return jsonify({'error': 'Esta transacción ya fue procesada. Evite hacer doble clic.'}), 400
        
        # Marcar transacción como en proceso
        session[session_key] = True
        
        try:
            # Datos generales de la devolución
            fecha_devolucion_str = request.form.get('fecha_devolucion')
            if fecha_devolucion_str:
                fecha_devolucion = datetime.strptime(fecha_devolucion_str, '%Y-%m-%d')
            else:
                fecha_devolucion = datetime.now()
                
            labor_origen = request.form.get('labor_origen', '').strip()
            supervisor_responsable = request.form.get('supervisor_responsable', '').strip()
            motivo_devolucion = request.form.get('motivo_devolucion', '').strip()
            recibido_por = request.form.get('recibido_por', '').strip()
            turno = request.form.get('turno', '').strip()
            numero_vale = request.form.get('numero_vale', '').strip()
            observaciones = request.form.get('observaciones', '').strip()
            
            # Validar campos obligatorios
            if not labor_origen:
                return jsonify({'error': 'Debe especificar la labor de origen'}), 400
            if not supervisor_responsable:
                return jsonify({'error': 'Debe especificar el supervisor responsable'}), 400
            if not motivo_devolucion:
                return jsonify({'error': 'Debe seleccionar el motivo de la devolución'}), 400
            
            # Procesar explosivos del formulario
            explosivos_seleccionados = []
            for key, value in request.form.items():
                if key.startswith('cantidad_') and value and float(value) > 0:
                    codigo_explosivo = key.replace('cantidad_', '')
                    cantidad = float(value)
                    explosivos_seleccionados.append({
                        'codigo': codigo_explosivo,
                        'cantidad': cantidad
                    })
            
            if not explosivos_seleccionados:
                return jsonify({'error': 'Debe seleccionar al menos un explosivo para devolver'}), 400
            
            # Procesar cada explosivo seleccionado
            devoluciones_registradas = []
            errores = []
            
            for item in explosivos_seleccionados:
                codigo = item['codigo']
                cantidad = item['cantidad']
                
                try:
                    # Obtener el explosivo
                    explosivo = db.session.query(Explosivo).filter_by(codigo=codigo).first()
                    if not explosivo:
                        errores.append(f'Explosivo {codigo} no encontrado')
                        continue
                    
                    # Crear observaciones descriptivas completas
                    obs_completas = f"Devolución de {explosivo.descripcion} ({codigo}) - Labor: {labor_origen}"
                    if numero_vale:
                        obs_completas += f" - Vale: {numero_vale}"
                    if motivo_devolucion:
                        obs_completas += f" - Motivo: {motivo_devolucion}"
                    if observaciones:
                        obs_completas += f" - {observaciones}"
                    
                    # Inserción directa usando SQL para activar triggers (evitar OUTPUT clause)
                    from sqlalchemy import text
                    query = text("""
                        INSERT INTO devoluciones (
                            explosivo_id, cantidad_devuelta, motivo, fecha_devolucion, 
                            guardia, responsable, recibido_por, labor, estado_material, observaciones
                        ) VALUES (
                            :explosivo_id, :cantidad_devuelta, :motivo, :fecha_devolucion, 
                            :guardia, :responsable, :recibido_por, :labor, :estado_material, :observaciones
                        )
                    """)
                    
                    db.session.execute(query, {
                        'explosivo_id': explosivo.id,
                        'cantidad_devuelta': cantidad,
                        'motivo': motivo_devolucion,
                        'fecha_devolucion': fecha_devolucion,
                        'guardia': turno,
                        'responsable': supervisor_responsable,
                        'recibido_por': recibido_por,
                        'labor': labor_origen,
                        'estado_material': 'bueno',
                        'observaciones': obs_completas
                    })
                    
                    devoluciones_registradas.append({
                        'codigo': codigo,
                        'cantidad': cantidad,
                        'descripcion': explosivo.descripcion
                    })
                    
                    
                except Exception as e:
                    db.session.rollback()  # Rollback en caso de error individual
                    errores.append(f'Error procesando explosivo {codigo}: {str(e)}')
            
            # Confirmar transacción
            if devoluciones_registradas:
                db.session.commit()
                mensaje = f"✅ Devolución registrada exitosamente. {len(devoluciones_registradas)} explosivos procesados."
                
                # Marcar transacción como completada y limpiar session
                session[f'transaction_devolucion_{transaction_id}_completed'] = True
                session.pop(session_key, None)
                
                return jsonify({'success': mensaje})
            else:
                db.session.rollback()
                # Limpiar session en caso de error
                session.pop(session_key, None)
                
                return jsonify({'error': 'Errores: ' + '; '.join(errores)}), 400
                
        except Exception as e:
            db.session.rollback()
            
            # Limpiar session en caso de error
            session.pop(session_key, None)
            
            # Reiniciar la sesión para próximas operaciones
            db.session.close()
            return jsonify({'error': f'Error interno: {str(e)}'}), 500

@app.route('/ingresos')
@require_login
def listar_ingresos():
    """Listar ingresos de explosivos"""
    if request.args.get('format') == 'json':
        page = request.args.get('page', 1, type=int)
        ingresos = Ingreso.query.order_by(Ingreso.fecha_ingreso.desc()).paginate(
            page=page, per_page=20, error_out=False
        )
        return jsonify([{
            'id': i.id,
            'explosivo': i.explosivo.codigo,
            'numero_vale': i.numero_vale,
            'cantidad': int(i.cantidad),
            'fecha_ingreso': i.fecha_ingreso.isoformat(),
            'proveedor': i.proveedor
        } for i in ingresos.items])
    return redirect(url_for('simple_dashboard'))

@app.route('/ingresos/nuevo', methods=['GET', 'POST'])
@require_login
def nuevo_ingreso():
    """Registrar nuevo ingreso de explosivos"""
    usuario_actual = obtener_usuario_actual()
    
    if request.method == 'GET':
        explosivos = obtener_explosivos_ordenados()
        fecha_actual = datetime.now()
        hora_actual = fecha_actual.hour
        
        if 6 <= hora_actual < 14:
            guardia_actual = "Mañana (6:00 - 14:00)"
        elif 14 <= hora_actual < 22:
            guardia_actual = "Tarde (14:00 - 22:00)"
        else:
            guardia_actual = "Noche (22:00 - 6:00)"
        
        return render_template('nuevo_ingreso.html', 
                             explosivos=explosivos,
                             fecha_actual=fecha_actual,
                             guardia_actual=guardia_actual,
                             usuario_actual=usuario_actual)
    
    try:
        
        # Verificar autenticación antes de proceder
        if 'user_id' not in session:
            return jsonify({'error': 'Sesión expirada. Por favor, inicie sesión nuevamente.'}), 401
        
        # Generar ID único para esta transacción basado en timestamp y datos básicos
        transaction_id = str(uuid.uuid4())[:16]  # ID único más simple
        
        # Verificar si esta transacción ya fue procesada (evitar duplicados)
        session_key = f'transaction_ingreso_{transaction_id}'
        if session.get(session_key):
            return jsonify({'error': 'Esta transacción ya fue procesada. Evite hacer doble clic.'}), 400
        
        # Marcar transacción como en proceso
        session[session_key] = True
        
        # Asegurar que no hay transacciones pendientes
        try:
            db.session.rollback()
        except:
            pass
            
        
        # Obtener datos generales del formulario
        fecha_ingreso_str = request.form.get('fecha_ingreso')
        if fecha_ingreso_str:
            fecha_ingreso = datetime.strptime(fecha_ingreso_str, '%Y-%m-%d')
        else:
            fecha_ingreso = datetime.now()
            
        numero_vale = request.form.get('numero_vale', '').strip()
        # Si el vale está vacío, dejarlo como None para la base de datos
        if not numero_vale:
            numero_vale = None
        
        recibido_por = usuario_actual.nombre_completo  # Usar usuario logueado
        
        turno = request.form.get('turno', '')  # DIA o NOCHE
        
        if not turno:
            return jsonify({'error': 'Debe seleccionar un turno (DIA o NOCHE)'}), 400
            
        observaciones = request.form.get('observaciones', '').strip()
        
        
        # Obtener datos de explosivos seleccionados (formato JSON como en salidas)
        explosivos_data = []
        explosivos_json = request.form.get('explosivos', '[]')
        
        try:
            explosivos_data = json.loads(explosivos_json)
        except json.JSONDecodeError as e:
            return jsonify({'error': f'Error en formato de datos de explosivos: {str(e)}'}), 400
        
        
        if not explosivos_data:
            return jsonify({'error': 'Debe seleccionar al menos un explosivo con cantidad mayor a 0'}), 400
        
        resultados = []
        errores = []
        
        # Procesar cada explosivo
        for item in explosivos_data:
            try:
                explosivo_id = int(item['explosivo_id'])
                cantidad = int(item['cantidad'])
                
                # Verificar que el explosivo existe
                explosivo = db.session.get(Explosivo, explosivo_id)
                if not explosivo:
                    errores.append(f'Explosivo ID {explosivo_id} no existe')
                    continue
                
                # Crear nuevo ingreso usando SQL directo (compatible con triggers)
                query = text("""
                    INSERT INTO ingresos (explosivo_id, numero_vale, cantidad, fecha_ingreso, guardia, recibido_por, observaciones)
                    VALUES (:explosivo_id, :numero_vale, :cantidad, :fecha_ingreso, :guardia, :recibido_por, :observaciones)
                """)
                
                db.session.execute(query, {
                    'explosivo_id': explosivo_id,
                    'numero_vale': numero_vale,
                    'cantidad': cantidad,
                    'fecha_ingreso': fecha_ingreso,
                    'guardia': turno.lower(),  # Usar el turno seleccionado
                    'recibido_por': recibido_por,
                    'observaciones': observaciones
                })
                
                # Actualizar stock diario (crear o actualizar registro del día)
                stock_diario = obtener_stock_diario_actual(explosivo_id, retornar_objeto=True)
                if stock_diario:
                    stock_diario.stock_final += cantidad
                else:
                    # Crear nuevo registro de stock diario si no existe
                    nuevo_stock = StockDiario(
                        explosivo_id=explosivo_id,
                        fecha=date.today(),
                        stock_inicial=cantidad,
                        stock_final=cantidad
                    )
                    db.session.add(nuevo_stock)
                
                resultados.append(f'{cantidad} {explosivo.unidad} de {explosivo.descripcion}')
                
            except ValueError as e:
                errores.append(f'Error en explosivo {item.get("explosivo_id", "desconocido")}: valores inválidos')
            except Exception as e:
                errores.append(f'Error en explosivo {item.get("explosivo_id", "desconocido")}: {str(e)}')
        
        # Confirmar cambios en la base de datos
        db.session.commit()
        
        # Preparar respuesta
        if resultados:
            mensaje = f'Se registraron {len(resultados)} ingreso(s) correctamente:\n' + '\n'.join(f'• {r}' for r in resultados)
            if errores:
                mensaje += f'\n\nErrores encontrados:\n' + '\n'.join(f'• {e}' for e in errores)
            
            # Marcar transacción como completada y limpiar session
            session[f'transaction_ingreso_{transaction_id}_completed'] = True
            session.pop(session_key, None)
            
            return jsonify({'success': mensaje})
        else:
            mensaje_error = 'No se pudo registrar ningún ingreso.\n' + '\n'.join(f'• {e}' for e in errores)
            # Limpiar session en caso de error
            session.pop(session_key, None)
            return jsonify({'error': mensaje_error}), 400
    
    except ValueError as e:
        db.session.rollback()
        # Limpiar session en caso de error
        session.pop(session_key, None)
        return jsonify({'error': 'Valores numéricos inválidos'}), 400
    except Exception as e:
        import traceback
        db.session.rollback()
        # Limpiar session en caso de error
        session.pop(session_key, None)
        return jsonify({'error': f'Error interno del servidor: {str(e)}'}), 500

@app.route('/stock')
@require_login
def resumen_stock():
    """Resumen de stock por guardia"""
    hoy = date.today()
    guardia = obtener_guardia_actual()
    
    # Inicializar stock para hoy si es necesario
    inicializar_stock_fecha_si_necesario(hoy, guardia)
    
    # Obtener stock diario de hoy
    stocks_diarios = StockDiario.query.filter_by(
        fecha=hoy, 
        guardia=guardia
    ).join(Explosivo).order_by(Explosivo.codigo).all()
    
    # Retornar JSON o redirigir
    if request.args.get('format') == 'json':
        return jsonify([{
            'explosivo_codigo': sd.explosivo.codigo,
            'explosivo_descripcion': sd.explosivo.descripcion,
            'stock_inicial': int(sd.stock_inicial),
            'stock_final': int(sd.stock_final),
            'guardia': sd.guardia,
            'fecha': sd.fecha.isoformat()
        } for sd in stocks_diarios])
    
    return redirect(url_for('simple_dashboard'))

@app.route('/api/stock/<int:explosivo_id>')
@require_login_api
def api_stock_explosivo(explosivo_id):
    """API para obtener stock actual de un explosivo"""
    try:
        # Verificar que el explosivo existe
        explosivo = db.session.get(Explosivo, explosivo_id)
        if not explosivo:
            return jsonify({'error': 'Explosivo no encontrado'}), 404
        
        # Usar la misma función de cálculo que la página principal para consistencia
        stock_disponible = calcular_stock_explosivo(explosivo_id)
        hoy = date.today()
        guardia = obtener_guardia_actual()
        
        # Intentar obtener el stock diario para información adicional
        stock_diario = obtener_stock_diario_actual(explosivo_id, retornar_objeto=True)
        
        if stock_diario and hasattr(stock_diario, 'stock_inicial'):
            # Si existe stock diario, usar el inicial pero el final calculado
            return jsonify({
                'stock_disponible': int(stock_disponible),
                'stock_inicial': int(stock_diario.stock_inicial),
                'guardia': stock_diario.guardia,
                'fecha': stock_diario.fecha.isoformat(),
                'metodo': 'calculado_con_inicial_diario'
            })
        else:
            # Si no existe stock diario, usar todo calculado
            return jsonify({
                'stock_disponible': int(stock_disponible),
                'stock_inicial': int(stock_disponible),  # Asumimos que es el mismo
                'guardia': guardia,
                'fecha': hoy.isoformat(),
                'metodo': 'totalmente_calculado'
            })
            
    except Exception as e:
        print(f"Error obteniendo stock para explosivo {explosivo_id}: {e}")
        return jsonify({
            'stock_disponible': 0.0,
            'stock_inicial': 0.0,
            'guardia': obtener_guardia_actual(),
            'fecha': date.today().isoformat(),
            'error': True
        })

@app.route('/api/stock-masivo')
@require_login_api
def api_stock_masivo():
    """API optimizada para obtener stock usando vistas híbridas"""
    try:
        # Obtener IDs de explosivos solicitados (opcional)
        explosivos_ids = request.args.get('ids', '')
        
        if explosivos_ids:
            try:
                ids_list = [int(id.strip()) for id in explosivos_ids.split(',') if id.strip().isdigit()]
                if not ids_list:
                    return jsonify({'error': 'No se proporcionaron IDs válidos'}), 400
                
                # Limitar para evitar consultas muy largas
                if len(ids_list) > 50:
                    ids_list = ids_list[:50]
            except ValueError:
                return jsonify({'error': 'IDs malformados'}), 400
        else:
            # Obtener todos los IDs de explosivos disponibles
            explosivos_query = Explosivo.query.with_entities(Explosivo.id).all()
            ids_list = [row.id for row in explosivos_query]

        stocks = {}
        
        # Intentar usar vista optimizada si está disponible
        if usar_vista_stock_powerbi():
            try:
                from sqlalchemy import text
                
                # OPCIÓN 1: Usar v_stock_actual (más simple y directa)
                params = {}
                for i, explosivo_id in enumerate(ids_list):
                    params[f'id_{i}'] = explosivo_id
                
                placeholders = ','.join([f':id_{i}' for i in range(len(ids_list))])
                
                result = db.session.execute(text(f"""
                    SELECT 
                        id as explosivo_id,
                        codigo,
                        descripcion,
                        stock_actual
                    FROM v_stock_actual
                    WHERE id IN ({placeholders})
                """), params).fetchall()
                
                for row in result:
                    stocks[str(row.explosivo_id)] = {
                        'stock_disponible': int(row.stock_actual),
                        'codigo': row.codigo,
                        'descripcion': row.descripcion,
                        'metodo': 'vista_v_stock_actual'
                    }
                
                return jsonify(stocks)
                
            except Exception as vista_error:
                print(f"Error usando v_stock_actual, intentando vw_stock_explosivos_powerbi: {vista_error}")
                
                # OPCIÓN 2: Fallback a vw_stock_explosivos_powerbi
                try:
                    result = db.session.execute(text(f"""
                        SELECT DISTINCT
                            e.id as explosivo_id,
                            e.descripcion,
                            e.codigo,
                            COALESCE(v.stock_inicial, 0) as stock_disponible
                        FROM explosivos e
                        LEFT JOIN (
                            SELECT 
                                explosivo_id,
                                stock_inicial,
                                ROW_NUMBER() OVER (PARTITION BY explosivo_id ORDER BY fecha DESC) as rn
                            FROM vw_stock_explosivos_powerbi
                        ) v ON e.id = v.explosivo_id AND v.rn = 1
                        WHERE e.id IN ({placeholders})
                    """), params).fetchall()
                    
                    for row in result:
                        stocks[str(row.explosivo_id)] = {
                            'stock_disponible': int(row.stock_disponible),
                            'codigo': row.codigo,
                            'descripcion': row.descripcion,
                            'metodo': 'vista_vw_stock_explosivos_powerbi'
                        }
                    
                    return jsonify(stocks)
                    
                except Exception as vista_error2:
                    print(f"Error usando vw_stock_explosivos_powerbi, fallback a cálculo directo: {vista_error2}")
        
        # Fallback: usar cálculo directo (más lento pero confiable)
        explosivos = Explosivo.query.filter(Explosivo.id.in_(ids_list)).all()
        
        for explosivo in explosivos:
            try:
                stock = calcular_stock_explosivo_original(explosivo.id)  # Función más directa
                stocks[str(explosivo.id)] = {
                    'stock_disponible': int(stock),
                    'codigo': explosivo.codigo or explosivo.descripcion,
                    'metodo': 'calculo_directo'
                }
            except Exception as calc_error:
                print(f"Error calculando stock para {explosivo.id}: {calc_error}")
                stocks[str(explosivo.id)] = {
                    'stock_disponible': 0,
                    'codigo': explosivo.descripcion,
                    'metodo': 'error_fallback'
                }
        
        return jsonify(stocks)
        
    except Exception as e:
        print(f"Error en api_stock_masivo: {e}")
        import traceback
        traceback.print_exc()
        
        # Respuesta de emergencia
        return jsonify({
            'error': 'Error interno del servidor',
            'message': 'Contactar administrador',
            'stocks_disponibles': False
        }), 500

@app.route('/api/salidas_activas/<int:explosivo_id>')
@require_login_api
def api_salidas_activas(explosivo_id):
    """API para obtener salidas activas de un explosivo"""
    salidas = Salida.query.filter_by(
        explosivo_id=explosivo_id,
        estado='activo'
    ).order_by(Salida.fecha_salida.desc()).all()
    
    result = []
    for salida in salidas:
        result.append({
            'id': salida.id,
            'labor': salida.labor,
            'cantidad': int(salida.cantidad),
            'fecha_salida': salida.fecha_salida.isoformat(),
            'responsable': salida.responsable
        })
    
    return jsonify(result)

@app.route('/api/stock-masivo-simple')
@require_login_api
def api_stock_masivo_simple():
    """API de fallback usando consultas básicas sin vistas"""
    try:
        # Obtener IDs de explosivos solicitados (opcional)
        explosivos_ids = request.args.get('ids', '')
        
        if explosivos_ids:
            try:
                ids_list = [int(id.strip()) for id in explosivos_ids.split(',') if id.strip().isdigit()]
                if not ids_list:
                    return jsonify({'error': 'No se proporcionaron IDs válidos'}), 400
                
                # Usar consulta directa a tabla explosivos
                explosivos = Explosivo.query.filter(Explosivo.id.in_(ids_list)).all()
            except ValueError:
                return jsonify({'error': 'IDs malformados'}), 400
        else:
            # Todos los explosivos
            explosivos = Explosivo.query.all()
        
        stocks = {}
        
        for explosivo in explosivos:
            # Calcular stock usando función existente
            stock = calcular_stock_explosivo(explosivo.id)
            stocks[str(explosivo.id)] = {
                'stock_disponible': int(stock),
                'codigo': explosivo.nombre,
                'metodo': 'calculo_directo'
            }
        
        return jsonify(stocks)
        
    except Exception as e:
        print(f"Error en api_stock_masivo_simple: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# Ruta simple para mostrar lista de explosivos en JSON
@app.route('/api/explosivos')
@require_login_api
def api_explosivos():
    """API para obtener lista de explosivos"""
    explosivos = obtener_explosivos_ordenados()
    result = []
    for explosivo in explosivos:
        result.append({
            'id': explosivo.id,
            'codigo': explosivo.codigo,
            'descripcion': explosivo.descripcion,
            'unidad': explosivo.unidad
        })
    return jsonify(result)



# Página simple de inicio si no hay templates
@app.route('/simple')
def simple_dashboard():
    """Dashboard simple sin templates"""
    explosivos = Explosivo.query.all()
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Sistema de Polvorín</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            table { border-collapse: collapse; width: 100%; margin: 20px 0; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
            .header { color: #333; }
            .info { background-color: #e7f3ff; padding: 10px; margin: 10px 0; border-radius: 5px; }
        </style>
    </head>
    <body>
        <h1 class="header">🧨 Sistema de Registro de Polvorín v2.0</h1>
        
        <div class="info">
            <strong>📊 Estado:</strong> Conectado a SQL Server Azure<br>
            <strong>🕐 Guardia actual:</strong> """ + obtener_guardia_actual() + """<br>
            <strong>📅 Fecha:</strong> """ + str(date.today()) + """<br>
            <strong>💾 Base de datos:</strong> pallca (pallca.database.windows.net)
        </div>
        
        <h2>💥 Explosivos Registrados (""" + str(len(explosivos)) + """)</h2>
        <table>
            <tr>
                <th>ID</th>
                <th>Código</th>
                <th>Descripción</th>
                <th>Unidad</th>
            </tr>
    """
    
    for explosivo in explosivos:
        html += f"""
            <tr>
                <td>{explosivo.id}</td>
                <td>{explosivo.codigo}</td>
                <td>{explosivo.descripcion}</td>
                <td>{explosivo.unidad}</td>
            </tr>
        """
    
    html += """
        </table>
        
        <h2>🔗 APIs Disponibles</h2>
        <ul>
            <li><a href="/api/explosivos">/api/explosivos</a> - Lista de explosivos</li>
            <li>/api/stock/{id} - Stock de un explosivo</li>
            <li>/api/salidas_activas/{id} - Salidas activas de un explosivo</li>
        </ul>
        
        <div class="info">
            <strong>✅ Sistema funcionando correctamente</strong><br>
            Las tablas están creadas y los triggers automáticos están activos.<br>
            Stock calculado SEPARADAMENTE por cada explosivo según su descripción.
        </div>
    </body>
    </html>
    """
    
    return html

# Manejador de errores
@app.errorhandler(404)
def not_found_error(error):
    return jsonify({'error': 'Endpoint no encontrado'}), 404

@app.route('/api/stock-actual')
@require_login_api
def obtener_stock_actual():
    """Obtener stock actual de todos los explosivos usando vistas optimizadas o cálculo directo"""
    try:
        # Intentar usar v_stock_actual si está disponible
        if usar_vista_stock_powerbi():
            from sqlalchemy import text
            
            result = db.session.execute(text("""
                SELECT 
                    id,
                    descripcion,
                    codigo,
                    unidad,
                    stock_actual as stock_disponible
                FROM v_stock_actual
                ORDER BY descripcion
            """)).fetchall()
            
            resultado = []
            for row in result:
                resultado.append({
                    'id': row.id,
                    'codigo': row.codigo or row.descripcion,
                    'descripcion': row.descripcion,
                    'stock_disponible': int(row.stock_disponible),
                    'unidad': row.unidad
                })
            
            return jsonify(resultado)
        
        # Fallback: usar cálculo directo
        explosivos = Explosivo.query.all()
        resultado = []
        
        for explosivo in explosivos:
            stock = calcular_stock_explosivo_original(explosivo.id)
            resultado.append({
                'id': explosivo.id,
                'codigo': explosivo.codigo or explosivo.descripcion,
                'descripcion': explosivo.descripcion,
                'stock_disponible': int(stock),
                'unidad': explosivo.unidad
            })
        
        return jsonify(resultado)
        
    except Exception as e:
        print(f"Error en obtener_stock_actual: {e}")
        return jsonify({'error': str(e)}), 500

def obtener_stock_actual_original():
    """Método original como fallback"""
    explosivos = obtener_explosivos_ordenados()
    resultado = []
    
    for e in explosivos:
        try:
            # Calcular stock basándose directamente en ingresos y salidas
            stock_disponible = calcular_stock_explosivo(e.id)
            
            resultado.append({
                'id': e.id,
                'codigo': e.codigo,
                'descripcion': e.descripcion,
                'stock_disponible': stock_disponible,
                'unidad': e.unidad
            })
            
        except Exception as ex:
            # En caso de error, asignar stock 0 y continuar
            print(f"Error calculando stock para explosivo {e.id}: {ex}")
            resultado.append({
                'id': e.id,
                'codigo': e.codigo,
                'descripcion': e.descripcion,
                'stock_disponible': 0,
                'unidad': e.unidad
            })
    
    return jsonify(resultado)

@app.route('/api/resumen-dia')
@require_login_api
def obtener_resumen_dia():
    """Obtener resumen del día actual"""
    hoy = date.today()
    
    # Contar salidas del día
    salidas = Salida.query.filter(
        db.func.cast(Salida.fecha_salida, db.Date) == hoy
    ).count()
    
    # Contar ingresos del día
    ingresos = Ingreso.query.filter(
        db.func.cast(Ingreso.fecha_ingreso, db.Date) == hoy
    ).count()
    
    # Contar devoluciones del día (si existe la tabla)
    try:
        devoluciones = Devolucion.query.filter(
            db.func.cast(Devolucion.fecha_devolucion, db.Date) == hoy
        ).count()
    except:
        devoluciones = 0
    
    return jsonify({
        'salidas': salidas,
        'ingresos': ingresos,
        'devoluciones': devoluciones,
        'fecha': hoy.isoformat()
    })

@app.route('/api/historial-reciente')
@require_login_api
def obtener_historial_reciente():
    """Obtener historial reciente de movimientos"""
    try:
        # Obtener últimas 10 salidas
        salidas = db.session.query(
            Salida.fecha_salida.label('fecha'),
            db.literal('salida').label('tipo'),
            Explosivo.descripcion.label('explosivo'),
            Salida.cantidad,
            Explosivo.unidad,
            Salida.labor.label('destino')
        ).join(Explosivo).order_by(Salida.fecha_salida.desc()).limit(10).all()
        
        # Obtener últimas 5 ingresos
        ingresos = db.session.query(
            Ingreso.fecha_ingreso.label('fecha'),
            db.literal('ingreso').label('tipo'),
            Explosivo.descripcion.label('explosivo'),
            Ingreso.cantidad,
            Explosivo.unidad,
            Ingreso.recibido_por.label('destino')  # Usar recibido_por en lugar de proveedor
        ).join(Explosivo).order_by(Ingreso.fecha_ingreso.desc()).limit(5).all()
        
        # Combinar movimientos
        todos_movimientos = []
        
        for s in salidas:
            todos_movimientos.append({
                'fecha': s.fecha.strftime('%d/%m/%Y %H:%M'),
                'tipo': s.tipo,
                'explosivo': s.explosivo,
                'cantidad': int(s.cantidad),
                'unidad': s.unidad,
                'destino': s.destino
            })
        
        for i in ingresos:
            # Usar recibido_por o un valor por defecto
            destino_ingreso = i.destino if i.destino else 'Almacén'
            todos_movimientos.append({
                'fecha': i.fecha.strftime('%d/%m/%Y %H:%M'),
                'tipo': i.tipo,
                'explosivo': i.explosivo,
                'cantidad': int(i.cantidad),
                'unidad': i.unidad,
                'destino': f'Recibido por: {destino_ingreso}'
            })
        
        # Ordenar por fecha descendente (más reciente primero)
        # Convertir fecha string a datetime para ordenar correctamente
        from datetime import datetime
        
        def parse_fecha(fecha_str):
            try:
                return datetime.strptime(fecha_str, '%d/%m/%Y %H:%M')
            except:
                return datetime.min
        
        todos_movimientos.sort(key=lambda x: parse_fecha(x['fecha']), reverse=True)
        
        return jsonify(todos_movimientos[:15])
    except Exception as e:
        print(f"Error en historial reciente: {e}")
        import traceback
        traceback.print_exc()
        return jsonify([])

@app.errorhandler(404)
def page_not_found(error):
    """Maneja errores 404 - página no encontrada"""
    return jsonify({'error': 'Página no encontrada'}), 404

@app.route('/nuevo')
def ruta_nuevo_incorrecta():
    """Redirige /nuevo a la página principal"""
    return redirect(url_for('index'))

@app.route('/nueva')  
def ruta_nueva_incorrecta():
    """Redirige /nueva a la página principal"""
    return redirect(url_for('index'))

@app.route('/stock-diario')
@require_login
def ver_stock_diario():
    """Página para ver el stock diario usando datos reales de la base de datos"""
    fecha_filtro = request.args.get('fecha', date.today().isoformat())
    explosivo_filtro = request.args.get('explosivo_id', '')
    
    try:
        fecha_obj = datetime.strptime(fecha_filtro, '%Y-%m-%d').date()
    except:
        fecha_obj = date.today()
    
    from sqlalchemy import text
    
    try:
        # Consulta simplificada que filtra correctamente por fecha y turno
        query_base = """
            SELECT DISTINCT
                e.id as explosivo_id,
                e.codigo,
                e.descripcion,
                e.unidad,
                e.grupo,
                sd.fecha,
                sd.guardia as turno,
                sd.stock_inicial,
                sd.stock_final,
                sd.responsable_guardia,
                sd.observaciones,
                
                -- Ingresos del turno específico
                COALESCE((
                    SELECT SUM(i.cantidad) 
                    FROM ingresos i 
                    WHERE i.explosivo_id = e.id 
                    AND CAST(i.fecha_ingreso AS DATE) = sd.fecha 
                    AND i.guardia = sd.guardia
                ), 0) as total_ingresos,
                
                -- Salidas del turno específico  
                COALESCE((
                    SELECT SUM(s.cantidad)
                    FROM salidas s
                    WHERE s.explosivo_id = e.id
                    AND CAST(s.fecha_salida AS DATE) = sd.fecha
                    AND s.guardia = sd.guardia
                ), 0) as total_salidas,
                
                -- Devoluciones del turno específico
                COALESCE((
                    SELECT SUM(d.cantidad_devuelta)
                    FROM devoluciones d
                    INNER JOIN salidas s ON d.salida_id = s.id
                    WHERE s.explosivo_id = e.id
                    AND CAST(d.fecha_devolucion AS DATE) = sd.fecha
                    AND s.guardia = sd.guardia
                ), 0) as total_devoluciones,
                
                -- Detalle de labores del turno específico
                (
                    SELECT STRING_AGG(s.labor + ':' + CAST(s.cantidad AS VARCHAR), '|')
                    FROM salidas s
                    WHERE s.explosivo_id = e.id
                    AND CAST(s.fecha_salida AS DATE) = sd.fecha
                    AND s.guardia = sd.guardia
                    AND s.labor IS NOT NULL
                ) as labores_detalle
                
            FROM explosivos e
            INNER JOIN stock_diario sd ON e.id = sd.explosivo_id AND sd.fecha = :fecha
            WHERE e.activo = 1
            ORDER BY sd.guardia DESC, e.grupo, e.codigo
        """
        
        params = {'fecha': fecha_obj}
        
        if explosivo_filtro:
            query_base += " AND e.id = :explosivo_id"
            params['explosivo_id'] = int(explosivo_filtro)
        
        result = db.session.execute(text(query_base), params)
        stocks_data = result.fetchall()
        result.close()
        
        explosivos = obtener_explosivos_ordenados()
        
        datos_organizados = {}
        resumen_data = {
            'total_explosivos': 0,
            'total_diferencias_positivas': 0,
            'total_diferencias_negativas': 0,
            'total_diferencias_cero': 0,
            'stock_inicial_total': 0,
            'stock_final_total': 0,
            'diferencia_total': 0
        }
        
        for stock in stocks_data:
            codigo = stock.codigo
            turno_key = 'dia' if stock.turno == 'DIA' else 'noche'
            
            # Obtener movimientos del turno
            ingresos = float(stock.total_ingresos or 0)
            salidas = float(stock.total_salidas or 0)
            devoluciones = float(stock.total_devoluciones or 0)
            
            # Determinar stock inicial 
            stock_inicial = float(stock.stock_inicial or 0)
            
            # SIEMPRE calcular el stock final basado en la fórmula estándar
            stock_final = stock_inicial + ingresos - salidas + devoluciones
            
            # Calcular diferencia
            diferencia = stock_final - stock_inicial
            
            if diferencia > 0:
                tipo_diferencia = 'positiva'
                resumen_data['total_diferencias_positivas'] += 1
            elif diferencia < 0:
                tipo_diferencia = 'negativa'
                resumen_data['total_diferencias_negativas'] += 1
            else:
                tipo_diferencia = 'cero'
                resumen_data['total_diferencias_cero'] += 1
            
            # Procesar las labores específicas del turno
            labores_del_turno = {}
            if hasattr(stock, 'labores_detalle') and stock.labores_detalle:
                # Formato: "M-1005 V3:25|M-535 V5 N:15"
                for labor_detalle in stock.labores_detalle.split('|'):
                    if ':' in labor_detalle:
                        nombre_labor, cantidad_str = labor_detalle.split(':', 1)
                        try:
                            cantidad_labor = float(cantidad_str)
                            # Usar un número secuencial para el key
                            labor_key = f'labor_{len(labores_del_turno) + 1}'
                            labores_del_turno[labor_key] = {
                                'nombre': nombre_labor.strip(),
                                'cantidad': cantidad_labor
                            }
                        except ValueError:
                            continue
            
            # Si no hay labores específicas pero hay salidas, crear entrada genérica
            if not labores_del_turno and salidas > 0:
                labores_del_turno['labor_1'] = {
                    'nombre': 'Salidas del turno',
                    'cantidad': salidas
                }
            
            # Debug temporal para verificar datos
            print(f"📊 {codigo} {turno_key}: SI:{stock_inicial}, SF:{stock_final}, Ing:{ingresos}, Sal:{salidas}, Dev:{devoluciones}, Dif:{diferencia}")
            
            # Inicializar entrada para el explosivo si no existe
            if codigo not in datos_organizados:
                datos_organizados[codigo] = {
                    'explosivo': {
                        'id': stock.explosivo_id,
                        'codigo': stock.codigo,
                        'descripcion': stock.descripcion,
                        'unidad': stock.unidad,
                        'grupo': stock.grupo
                    },
                    'dia': None,
                    'noche': None
                }
            
            # Asignar datos al turno correspondiente
            datos_organizados[codigo][turno_key] = {
                'stock_inicial': stock_inicial,
                'stock_final': stock_final,
                'diferencia': diferencia,
                'tipo_diferencia': tipo_diferencia,
                'responsable_guardia': stock.responsable_guardia or obtener_guardia_actual(),
                'observaciones': stock.observaciones or f'Stock para {fecha_obj}',
                'ingresos_dia': ingresos,
                'salidas_total': salidas,
                'devoluciones_dia': devoluciones,
                'labores': labores_del_turno
            }
            
            resumen_data['stock_inicial_total'] += stock_inicial
            resumen_data['stock_final_total'] += stock_final
            resumen_data['diferencia_total'] += diferencia
        
        resumen_data['total_explosivos'] = len(datos_organizados)
        resumen = type('obj', (object,), resumen_data)
        
        # Obtener las labores que se usaron en la fecha específica, por turno
        try:
            query_labores_fecha = """
                SELECT DISTINCT 
                    s.guardia as turno,
                    s.labor
                FROM salidas s
                WHERE CAST(s.fecha_salida AS DATE) = :fecha
                ORDER BY s.guardia DESC, s.labor
            """
            
            result_labores = db.session.execute(text(query_labores_fecha), {'fecha': fecha_obj})
            labores_usadas = result_labores.fetchall()
            result_labores.close()
            
            # Organizar labores por turno
            labores_por_turno = {'dia': [], 'noche': []}
            for labor_data in labores_usadas:
                turno_key = 'dia' if labor_data.turno == 'DIA' else 'noche'
                if labor_data.labor not in labores_por_turno[turno_key]:
                    labores_por_turno[turno_key].append(labor_data.labor)
            
            # Si no hay labores en la fecha, usar todas las labores disponibles
            if not any(labores_por_turno.values()):
                labores_reales = Labor.query.all()
                nombres_labores = [labor.nombre for labor in labores_reales]
                labores_por_turno = {
                    'dia': nombres_labores,
                    'noche': nombres_labores
                }
            
            max_labores_por_turno = {
                'dia': len(labores_por_turno['dia']),
                'noche': len(labores_por_turno['noche'])
            }
            
        except Exception as e:
            # Fallback a valores por defecto si hay error
            labores_por_turno = {'dia': [], 'noche': []}
            max_labores_por_turno = {'dia': 0, 'noche': 0}
        
        return render_template('stock_diario_dinamico.html', 
                             datos=datos_organizados,
                             fecha_seleccionada=fecha_obj,
                             explosivos=explosivos,
                             explosivo_seleccionado=explosivo_filtro,
                             resumen=resumen,
                             labores_por_turno=labores_por_turno,
                             max_labores_por_turno=max_labores_por_turno)
    
    except Exception as e:
        try:
            db.session.rollback()
        except:
            pass
        
        explosivos = []
        try:
            explosivos = obtener_explosivos_ordenados()
        except:
            pass
        
        # Obtener las labores reales incluso en caso de error
        try:
            labores_reales = Labor.query.all()
            nombres_labores = [labor.nombre for labor in labores_reales]
            
            labores_por_turno_fallback = {
                'dia': nombres_labores,
                'noche': nombres_labores
            }
            max_labores_por_turno_fallback = {
                'dia': len(nombres_labores),
                'noche': len(nombres_labores)
            }
        except:
            labores_por_turno_fallback = {'dia': []}
            max_labores_por_turno_fallback = {'dia': 0}
            
        return render_template('stock_diario_dinamico.html', 
                             datos={},
                             fecha_seleccionada=fecha_obj,
                             explosivos=explosivos,
                             explosivo_seleccionado=explosivo_filtro,
                             resumen=None,
                             labores_por_turno=labores_por_turno_fallback,
                             max_labores_por_turno=max_labores_por_turno_fallback)

@app.route('/api/stock-diario-datos')
@require_login_api
def api_stock_diario_datos():
    """API para obtener datos de stock diario usando las vistas optimizadas"""
    fecha_filtro = request.args.get('fecha', date.today().isoformat())
    
    try:
        fecha_obj = datetime.strptime(fecha_filtro, '%Y-%m-%d').date()
    except:
        fecha_obj = date.today()
    
    from sqlalchemy import text
    
    try:
        # Usar la vista vw_stock_explosivos_powerbi optimizada para datos diarios
        query = """
            SELECT 
                codigo_explosivo,
                descripcion,
                fecha,
                turno,
                stock_inicial,
                stock_final
            FROM vw_stock_explosivos_powerbi 
            WHERE fecha = :fecha
            ORDER BY codigo_explosivo, turno DESC
        """
        
        result = db.session.execute(text(query), {'fecha': fecha_obj})
        stocks = result.fetchall()
        result.close()
        
        resultado = []
        for stock in stocks:
            # Calcular diferencia
            diferencia = float(stock.stock_final) - float(stock.stock_inicial)
            
            # Determinar tipo de diferencia
            if diferencia > 0:
                tipo_diferencia = 'positiva'
            elif diferencia < 0:
                tipo_diferencia = 'negativa'
            else:
                tipo_diferencia = 'cero'
            
            resultado.append({
                'codigo': stock.codigo_explosivo,
                'descripcion': stock.descripcion,
                'fecha': fecha_obj.isoformat(),
                'turno': stock.turno,
                'stock_inicial': float(stock.stock_inicial),
                'stock_final': float(stock.stock_final),
                'diferencia': diferencia,
                'tipo_diferencia': tipo_diferencia,
                'responsable_guardia': obtener_guardia_actual(),
                'observaciones': f'Vista optimizada - {fecha_obj}'
            })
        
        return jsonify(resultado)
    
    except Exception as e:
        # En caso de error, cerrar cualquier conexión pendiente
        try:
            db.session.rollback()
        except:
            pass
        
        print(f"Error en api_stock_diario_datos: {e}")
        return jsonify({'error': 'Error al obtener datos de stock diario'}), 500

def obtener_stock_historico_por_fecha(fecha_obj):
    """Obtener stock histórico calculado desde movimientos para una fecha específica"""
    from sqlalchemy import text
    
    try:
        # Obtener todos los explosivos que tuvieron movimientos hasta la fecha solicitada
        query_explosivos = """
            SELECT DISTINCT e.id, e.codigo, e.descripcion, e.unidad
            FROM explosivos e
            WHERE EXISTS (
                SELECT 1 FROM salidas WHERE explosivo_id = e.id AND CAST(fecha_salida AS DATE) <= :fecha
                UNION
                SELECT 1 FROM ingresos WHERE explosivo_id = e.id AND CAST(fecha_ingreso AS DATE) <= :fecha
                UNION
                SELECT 1 FROM devoluciones d 
                INNER JOIN salidas s ON d.salida_id = s.id
                WHERE s.explosivo_id = e.id AND CAST(d.fecha_devolucion AS DATE) <= :fecha
            )
            ORDER BY e.codigo
        """
        
        result = db.session.execute(text(query_explosivos), {'fecha': fecha_obj})
        explosivos = result.fetchall()
        result.close()
        
        resultado = []
        
        for explosivo in explosivos:
            # Calcular stock acumulado hasta el día anterior (final del turno noche del día anterior)
            dia_anterior = fecha_obj - timedelta(days=1)
            
            query_stock_anterior = """
                SELECT 
                    -- Total ingresos hasta día anterior
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM ingresos 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_ingreso AS DATE) <= :fecha_anterior
                    ), 0) as total_ingresos_anterior,
                    -- Total salidas hasta día anterior
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) <= :fecha_anterior
                    ), 0) as total_salidas_anterior,
                    -- Total devoluciones hasta día anterior
                    COALESCE((
                        SELECT SUM(d.cantidad_devuelta) 
                        FROM devoluciones d
                        INNER JOIN salidas s ON d.salida_id = s.id
                        WHERE s.explosivo_id = :explosivo_id 
                        AND CAST(d.fecha_devolucion AS DATE) <= :fecha_anterior
                    ), 0) as total_devoluciones_anterior
            """
            
            result_anterior = db.session.execute(text(query_stock_anterior), {
                'explosivo_id': explosivo.id,
                'fecha_anterior': dia_anterior
            })
            stock_anterior = result_anterior.fetchone()
            result_anterior.close()
            
            # Stock inicial del día = stock acumulado hasta día anterior
            stock_inicial_dia = (float(stock_anterior.total_ingresos_anterior) - 
                               float(stock_anterior.total_salidas_anterior) + 
                               float(stock_anterior.total_devoluciones_anterior))
            
            # Obtener movimientos del día específico separados por turno usando la columna guardia
            query_movimientos_turnos = """
                SELECT 
                    -- TURNO DÍA (usando columna guardia = 'dia')
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM ingresos 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_ingreso AS DATE) = :fecha
                        AND guardia = 'dia'
                    ), 0) as ingresos_dia,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'dia'
                    ), 0) as salidas_dia,
                    COALESCE((
                        SELECT SUM(d.cantidad_devuelta) 
                        FROM devoluciones d
                        INNER JOIN salidas s ON d.salida_id = s.id
                        WHERE s.explosivo_id = :explosivo_id 
                        AND CAST(d.fecha_devolucion AS DATE) = :fecha
                        AND d.guardia = 'dia'
                    ), 0) as devoluciones_dia,
                    -- TURNO NOCHE (usando columna guardia = 'noche')
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM ingresos 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_ingreso AS DATE) = :fecha
                        AND guardia = 'noche'
                    ), 0) as ingresos_noche,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'noche'
                    ), 0) as salidas_noche,
                    COALESCE((
                        SELECT SUM(d.cantidad_devuelta) 
                        FROM devoluciones d
                        INNER JOIN salidas s ON d.salida_id = s.id
                        WHERE s.explosivo_id = :explosivo_id 
                        AND CAST(d.fecha_devolucion AS DATE) = :fecha
                        AND d.guardia = 'noche'
                    ), 0) as devoluciones_noche,
                    -- SALIDAS POR LABOR (divididas por turno)
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'dia'
                        AND labor LIKE '%M-1005%'
                    ), 0) as labor_m1005_dia,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'dia'
                        AND labor LIKE '%P-554%'
                    ), 0) as labor_p554_dia,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'dia'
                        AND labor LIKE '%N-830%'
                    ), 0) as labor_n830_dia,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'dia'
                        AND labor LIKE '%M-535 V55%'
                    ), 0) as labor_m535v55_dia,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'dia'
                        AND labor LIKE '%M-535 V5 N%'
                    ), 0) as labor_m535v5n_dia,
                    -- SALIDAS POR LABOR TURNO NOCHE
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'noche'
                        AND labor LIKE '%M-1005%'
                    ), 0) as labor_m1005_noche,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'noche'
                        AND labor LIKE '%P-554%'
                    ), 0) as labor_p554_noche,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'noche'
                        AND labor LIKE '%N-830%'
                    ), 0) as labor_n830_noche,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'noche'
                        AND labor LIKE '%M-535 V55%'
                    ), 0) as labor_m535v55_noche,
                    COALESCE((
                        SELECT SUM(cantidad) 
                        FROM salidas 
                        WHERE explosivo_id = :explosivo_id 
                        AND CAST(fecha_salida AS DATE) = :fecha
                        AND guardia = 'noche'
                        AND labor LIKE '%M-535 V5 N%'
                    ), 0) as labor_m535v5n_noche
            """
            
            result_turnos = db.session.execute(text(query_movimientos_turnos), {
                'explosivo_id': explosivo.id,
                'fecha': fecha_obj
            })
            movimientos = result_turnos.fetchone()
            result_turnos.close()
            
            # Verificar si hubo movimientos en este día
            total_movimientos = (float(movimientos.ingresos_dia) + float(movimientos.salidas_dia) + float(movimientos.devoluciones_dia) +
                               float(movimientos.ingresos_noche) + float(movimientos.salidas_noche) + float(movimientos.devoluciones_noche))
            
            if total_movimientos > 0:
                
                # TURNO DÍA
                movimientos_netos_dia = (float(movimientos.ingresos_dia) - 
                                       float(movimientos.salidas_dia) + 
                                       float(movimientos.devoluciones_dia))
                
                stock_final_dia = stock_inicial_dia + movimientos_netos_dia
                
                # Determinar tipo de diferencia día
                if movimientos_netos_dia > 0:
                    tipo_diferencia_dia = 'positiva'
                elif movimientos_netos_dia < 0:
                    tipo_diferencia_dia = 'negativa'
                else:
                    tipo_diferencia_dia = 'cero'
                
                # Crear registro para turno día
                resultado.append({
                    'explosivo_id': explosivo.id,
                    'codigo': explosivo.codigo,
                    'explosivo_codigo': explosivo.codigo,
                    'descripcion': explosivo.descripcion,
                    'explosivo_descripcion': explosivo.descripcion,
                    'unidad': explosivo.unidad,
                    'explosivo_unidad': explosivo.unidad,
                    'fecha': fecha_obj.isoformat(),
                    'guardia': 'dia',
                    'guardia_nombre': 'Día (6:00-14:00)',
                    'stock_inicial': stock_inicial_dia,
                    'stock_final': stock_final_dia,
                    'diferencia': movimientos_netos_dia,
                    'tipo_diferencia': tipo_diferencia_dia,
                    'responsable_guardia': 'Histórico',
                    'observaciones': f'I:{movimientos.ingresos_dia}, S:{movimientos.salidas_dia}, D:{movimientos.devoluciones_dia}',
                    'es_turno_actual': False,
                    # Datos específicos para el nuevo formato
                    'salidas_total': float(movimientos.salidas_dia),
                    'devoluciones_dia': float(movimientos.devoluciones_dia),
                    'labor_m1005': float(movimientos.labor_m1005_dia),
                    'labor_p554': float(movimientos.labor_p554_dia),
                    'labor_n830': float(movimientos.labor_n830_dia),
                    'labor_m535v55': float(movimientos.labor_m535v55_dia),
                    'labor_m535v5n': float(movimientos.labor_m535v5n_dia)
                })
                
                # TURNO NOCHE
                movimientos_netos_noche = (float(movimientos.ingresos_noche) - 
                                         float(movimientos.salidas_noche) + 
                                         float(movimientos.devoluciones_noche))
                
                stock_final_noche = stock_final_dia + movimientos_netos_noche
                
                # Determinar tipo de diferencia noche
                if movimientos_netos_noche > 0:
                    tipo_diferencia_noche = 'positiva'
                elif movimientos_netos_noche < 0:
                    tipo_diferencia_noche = 'negativa'
                else:
                    tipo_diferencia_noche = 'cero'
                
                # Crear registro para turno noche
                resultado.append({
                    'explosivo_id': explosivo.id,
                    'codigo': explosivo.codigo,
                    'explosivo_codigo': explosivo.codigo,
                    'descripcion': explosivo.descripcion,
                    'explosivo_descripcion': explosivo.descripcion,
                    'unidad': explosivo.unidad,
                    'explosivo_unidad': explosivo.unidad,
                    'fecha': fecha_obj.isoformat(),
                    'guardia': 'noche',
                    'guardia_nombre': 'Noche (14:00-6:00)',
                    'stock_inicial': stock_final_dia,  # Stock inicial noche = stock final día
                    'stock_final': stock_final_noche,
                    'diferencia': movimientos_netos_noche,
                    'tipo_diferencia': tipo_diferencia_noche,
                    'responsable_guardia': 'Histórico',
                    'observaciones': f'I:{movimientos.ingresos_noche}, S:{movimientos.salidas_noche}, D:{movimientos.devoluciones_noche}',
                    'es_turno_actual': False,
                    # Datos específicos para el nuevo formato
                    'salidas_total': float(movimientos.salidas_noche),
                    'devoluciones_dia': float(movimientos.devoluciones_noche),
                    'labor_m1005': float(movimientos.labor_m1005_noche),
                    'labor_p554': float(movimientos.labor_p554_noche),
                    'labor_n830': float(movimientos.labor_n830_noche),
                    'labor_m535v55': float(movimientos.labor_m535v55_noche),
                    'labor_m535v5n': float(movimientos.labor_m535v5n_noche)
                })
        
        return resultado
    
    except Exception as e:
        print(f"Error en obtener_stock_historico_por_fecha: {e}")
        try:
            db.session.rollback()
        except:
            pass

@app.route('/api/stock-diario-excel')
@require_login
def descargar_stock_diario_excel():
    """Generar y descargar reporte de stock diario en Excel (CSV formato Excel)"""
    try:
        from datetime import datetime
        import io
        
        # Obtener parámetros
        fecha_filtro = request.args.get('fecha', date.today().isoformat())
        explosivo_filtro = request.args.get('explosivo_id', '')
        
        try:
            fecha_obj = datetime.strptime(fecha_filtro, '%Y-%m-%d').date()
        except:
            fecha_obj = date.today()
        
        # Obtener datos usando consulta directa similar a stock_diario
        from sqlalchemy import text
        
        query_base = """
            SELECT DISTINCT
                e.codigo,
                e.descripcion,
                e.unidad,
                sd.stock_inicial,
                -- Ingresos del turno específico
                COALESCE((
                    SELECT SUM(i.cantidad) 
                    FROM ingresos i 
                    WHERE i.explosivo_id = e.id 
                    AND CAST(i.fecha_ingreso AS DATE) = sd.fecha 
                    AND i.guardia = sd.guardia
                ), 0) as ingresos,
                
                -- Salidas del turno específico  
                COALESCE((
                    SELECT SUM(s.cantidad)
                    FROM salidas s
                    WHERE s.explosivo_id = e.id
                    AND CAST(s.fecha_salida AS DATE) = sd.fecha
                    AND s.guardia = sd.guardia
                ), 0) as total_sal_guardia,
                
                -- Devoluciones del turno específico
                COALESCE((
                    SELECT SUM(d.cantidad_devuelta)
                    FROM devoluciones d
                    INNER JOIN salidas s ON d.salida_id = s.id
                    WHERE s.explosivo_id = e.id
                    AND CAST(d.fecha_devolucion AS DATE) = sd.fecha
                    AND d.guardia = sd.guardia
                ), 0) as retorno,
                
                -- Detalle de labores del turno específico
                COALESCE((
                    SELECT STRING_AGG(s.labor + ':' + CAST(s.cantidad AS VARCHAR), '|')
                    FROM salidas s
                    WHERE s.explosivo_id = e.id
                    AND CAST(s.fecha_salida AS DATE) = sd.fecha
                    AND s.guardia = sd.guardia
                    AND s.labor IS NOT NULL
                ), '') as labores_detalle,
                
                sd.stock_final as stock_final_de_guardia,
                sd.fecha,
                sd.guardia as turno
                
            FROM explosivos e
            INNER JOIN stock_diario sd ON e.id = sd.explosivo_id AND sd.fecha = :fecha
            WHERE e.activo = 1
        """
        
        params = {'fecha': fecha_obj}
        
        if explosivo_filtro:
            explosivo_query = "SELECT codigo FROM explosivos WHERE id = :explosivo_id"
            explosivo_result = db.session.execute(text(explosivo_query), {'explosivo_id': int(explosivo_filtro)})
            explosivo_codigo = explosivo_result.fetchone()
            explosivo_result.close()
            
            if explosivo_codigo:
                query_base += " AND codigo = :codigo_explosivo"
                params['codigo_explosivo'] = explosivo_codigo[0]
        
        query_base += " ORDER BY codigo, turno DESC"
        
        result = db.session.execute(text(query_base), params)
        stocks_data = result.fetchall()
        result.close()
        
        # Crear CSV que Excel puede abrir
        csv_content = ""
        
        # Procesar datos para determinar el número máximo de labores
        datos_procesados = []
        max_labores = 0
        
        for stock in stocks_data:
            labores = {}
            if hasattr(stock, 'labores_detalle') and stock.labores_detalle:
                # Formato: "M-1005 V3:25|M-535 V5 N:15"
                for labor_detalle in stock.labores_detalle.split('|'):
                    if ':' in labor_detalle:
                        nombre_labor, cantidad_str = labor_detalle.split(':', 1)
                        try:
                            cantidad_labor = float(cantidad_str)
                            labor_key = f'labor_{len(labores) + 1}'
                            labores[labor_key] = {
                                'nombre': nombre_labor.strip(),
                                'cantidad': cantidad_labor
                            }
                        except ValueError:
                            continue
            
            # Actualizar el máximo número de labores
            max_labores = max(max_labores, len(labores))
            
            datos_procesados.append({
                'stock': stock,
                'labores': labores
            })
        
        # Si no hay labores en ningún registro, establecer mínimo de 1
        if max_labores == 0:
            max_labores = 1
        
        # Headers dinámicos
        csv_content += "Turno,Código,Descripción,Unidad,Stock Inicial,Total Salidas,"
        for i in range(1, max_labores + 1):
            csv_content += f"Labor {i} Nombre,Labor {i} Cantidad,"
        csv_content += "Retorno,Stock Final\n"
        
        # Datos con labores dinámicas
        for item in datos_procesados:
            stock = item['stock']
            labores = item['labores']
            
            csv_content += f"{stock.turno},"
            csv_content += f'"{stock.codigo}",'
            csv_content += f'"{stock.descripcion}",'
            csv_content += f'"{stock.unidad}",'
            csv_content += f"{stock.stock_inicial or 0},"
            csv_content += f"{stock.total_sal_guardia or 0},"
            
            # Agregar labores dinámicamente
            for i in range(1, max_labores + 1):
                labor_key = f'labor_{i}'
                if labor_key in labores:
                    csv_content += f'"{labores[labor_key]["nombre"]}",'
                    csv_content += f"{labores[labor_key]['cantidad']},"
                else:
                    csv_content += '"N/A",'
                    csv_content += "0,"
            
            csv_content += f"{stock.retorno or 0},"
            csv_content += f"{stock.stock_final_de_guardia or 0}\n"
        
        # Crear respuesta
        output = io.BytesIO()
        output.write(csv_content.encode('utf-8-sig'))  # BOM para Excel
        output.seek(0)
        
        filename = f"stock_diario_{fecha_obj.strftime('%Y-%m-%d')}.csv"
        
        return send_file(
            output,
            mimetype='text/csv',
            as_attachment=True,
            download_name=filename
        )
        
    except Exception as e:
        print(f"Error generando Excel: {e}")
        return jsonify({'error': f'Error generando Excel: {str(e)}'}), 500

# =====================================================
# RUTAS DE EDICIÓN Y CORRECCIÓN DE DATOS
# =====================================================

@app.route('/editar')
@require_login
def panel_edicion():
    """Panel principal de edición de datos"""
    if not es_admin():
        flash('Solo los administradores pueden editar datos', 'error')
        return redirect(url_for('index'))
    
    return render_template('panel_edicion.html')

@app.route('/editar/salidas')
@require_login
def listar_salidas_edicion():
    """Listar salidas para edición"""
    if not es_admin():
        flash('Solo los administradores pueden editar datos', 'error')
        return redirect(url_for('index'))
    
    try:
        # Obtener parámetros de filtro - AMPLIADO A 30 DÍAS
        fecha_desde = request.args.get('fecha_desde', (date.today() - timedelta(days=30)).isoformat())
        fecha_hasta = request.args.get('fecha_hasta', date.today().isoformat())
        explosivo_id = request.args.get('explosivo_id', '')
        
        # Consulta base - EXCLUIR registros marcados como eliminados
        query = db.session.query(Salida, Explosivo).join(Explosivo).filter(
            ~Salida.observaciones.like('%ELIMINADO:%')
        )
        
        # Aplicar filtros
        if fecha_desde:
            query = query.filter(Salida.fecha_salida >= fecha_desde)
        if fecha_hasta:
            query = query.filter(Salida.fecha_salida <= fecha_hasta + ' 23:59:59')
        if explosivo_id:
            query = query.filter(Salida.explosivo_id == int(explosivo_id))
        
        salidas = query.order_by(Salida.fecha_salida.desc()).limit(500).all()
        explosivos = Explosivo.query.order_by(Explosivo.codigo).all()
        
        return render_template('editar_salidas.html', 
                             salidas=salidas, 
                             explosivos=explosivos,
                             fecha_desde=fecha_desde,
                             fecha_hasta=fecha_hasta,
                             explosivo_id=explosivo_id)
    
    except Exception as e:
        print(f"Error en listar_salidas_edicion: {e}")
        flash('Error cargando salidas para edición', 'error')
        return redirect(url_for('panel_edicion'))

@app.route('/editar/salida/<int:salida_id>', methods=['GET', 'POST'])
@require_login
def editar_salida(salida_id):
    """Editar una salida específica"""
    if not es_admin():
        flash('Solo los administradores pueden editar datos', 'error')
        return redirect(url_for('index'))
    
    try:
        salida = Salida.query.get_or_404(salida_id)
        explosivos = Explosivo.query.order_by(Explosivo.codigo).all()
        
        if request.method == 'POST':
            # Crear backup antes de editar
            backup_data = {
                'id': salida.id,
                'explosivo_id_original': salida.explosivo_id,
                'cantidad_original': float(salida.cantidad),
                'fecha_salida_original': salida.fecha_salida.isoformat(),
                'guardia_original': salida.guardia,
                'labor_original': salida.labor,
                'motivo_original': salida.motivo,
                'fecha_edicion': datetime.now().isoformat(),
                'editado_por': session.get('username', 'unknown')
            }
            
            # Aplicar cambios
            salida.explosivo_id = int(request.form['explosivo_id'])
            salida.cantidad = float(request.form['cantidad'])
            salida.fecha_salida = datetime.strptime(request.form['fecha_salida'], '%Y-%m-%dT%H:%M')
            salida.guardia = request.form['guardia']
            salida.labor = request.form['labor'].strip() if request.form['labor'].strip() else None
            salida.motivo = request.form['motivo'].strip() if request.form['motivo'].strip() else None
            salida.destino = request.form.get('destino', '').strip()
            salida.responsable = request.form.get('responsable', '').strip()
            salida.observaciones = f"EDITADO: {datetime.now().strftime('%Y-%m-%d %H:%M')} por {session.get('username', 'admin')}. " + \
                                 f"Original: {backup_data['cantidad_original']} KG, {backup_data['fecha_salida_original']}, {backup_data['labor_original']}"
            
            db.session.commit()
            
            flash(f'Salida editada exitosamente. ID: {salida_id}', 'success')
            return redirect(url_for('listar_salidas_edicion'))
        
        return render_template('editar_salida_form.html', salida=salida, explosivos=explosivos)
    
    except Exception as e:
        db.session.rollback()
        print(f"Error editando salida {salida_id}: {e}")
        flash('Error editando la salida', 'error')
        return redirect(url_for('listar_salidas_edicion'))

@app.route('/editar/ingresos')
@require_login
def listar_ingresos_edicion():
    """Listar ingresos para edición"""
    if not es_admin():
        flash('Solo los administradores pueden editar datos', 'error')
        return redirect(url_for('index'))
    
    try:
        # Obtener parámetros de filtro - AMPLIADO A 30 DÍAS
        fecha_desde = request.args.get('fecha_desde', (date.today() - timedelta(days=30)).isoformat())
        fecha_hasta = request.args.get('fecha_hasta', date.today().isoformat())
        explosivo_id = request.args.get('explosivo_id', '')
        
        # Consulta base - EXCLUIR registros marcados como eliminados
        query = db.session.query(Ingreso, Explosivo).join(Explosivo).filter(
            ~Ingreso.observaciones.like('%ELIMINADO:%')
        )
        
        # Aplicar filtros
        if fecha_desde:
            query = query.filter(Ingreso.fecha_ingreso >= fecha_desde)
        if fecha_hasta:
            query = query.filter(Ingreso.fecha_ingreso <= fecha_hasta + ' 23:59:59')
        if explosivo_id:
            query = query.filter(Ingreso.explosivo_id == int(explosivo_id))
        
        ingresos = query.order_by(Ingreso.fecha_ingreso.desc()).limit(500).all()
        explosivos = Explosivo.query.order_by(Explosivo.codigo).all()
        
        return render_template('editar_ingresos.html', 
                             ingresos=ingresos, 
                             explosivos=explosivos,
                             fecha_desde=fecha_desde,
                             fecha_hasta=fecha_hasta,
                             explosivo_id=explosivo_id)
    
    except Exception as e:
        print(f"Error en listar_ingresos_edicion: {e}")
        flash('Error cargando ingresos para edición', 'error')
        return redirect(url_for('panel_edicion'))

@app.route('/editar/ingreso/<int:ingreso_id>', methods=['GET', 'POST'])
@require_login
def editar_ingreso(ingreso_id):
    """Editar un ingreso específico"""
    if not es_admin():
        flash('Solo los administradores pueden editar datos', 'error')
        return redirect(url_for('index'))
    
    try:
        ingreso = Ingreso.query.get_or_404(ingreso_id)
        explosivos = Explosivo.query.order_by(Explosivo.codigo).all()
        
        if request.method == 'POST':
            # Aplicar cambios solo a campos que existen en la tabla ingresos
            ingreso.explosivo_id = int(request.form['explosivo_id'])
            ingreso.cantidad = float(request.form['cantidad'])
            ingreso.fecha_ingreso = datetime.strptime(request.form['fecha_ingreso'], '%Y-%m-%dT%H:%M')
            ingreso.guardia = request.form['guardia']
            ingreso.numero_vale = request.form.get('numero_vale', '').strip() or None
            ingreso.recibido_por = request.form.get('recibido_por', '').strip() or None
            
            # Actualizar observaciones agregando información de la edición
            observaciones_originales = ingreso.observaciones or ''
            observaciones_edicion = f"EDITADO: {datetime.now().strftime('%Y-%m-%d %H:%M')} por {session.get('username', 'admin')}"
            
            if observaciones_originales:
                ingreso.observaciones = f"{observaciones_originales}\n{observaciones_edicion}"
            else:
                # Si no hay observaciones originales, usar las del formulario más la marca de edición
                observaciones_form = request.form.get('observaciones', '').strip()
                if observaciones_form:
                    ingreso.observaciones = f"{observaciones_form}\n{observaciones_edicion}"
                else:
                    ingreso.observaciones = observaciones_edicion
            
            db.session.commit()
            
            flash(f'Ingreso editado exitosamente. ID: {ingreso_id}', 'success')
            return redirect(url_for('listar_ingresos_edicion'))
        
        return render_template('editar_ingreso_form.html', ingreso=ingreso, explosivos=explosivos)
    
    except Exception as e:
        db.session.rollback()
        print(f"Error editando ingreso {ingreso_id}: {e}")
        flash('Error editando el ingreso', 'error')
        return redirect(url_for('listar_ingresos_edicion'))

@app.route('/editar/devoluciones')
@require_login
def listar_devoluciones_edicion():
    """Listar devoluciones para edición"""
    if not es_admin():
        flash('Solo los administradores pueden editar datos', 'error')
        return redirect(url_for('index'))
    
    try:
        # Obtener parámetros de filtro - AMPLIADO A 30 DÍAS
        fecha_desde = request.args.get('fecha_desde', (date.today() - timedelta(days=30)).isoformat())
        fecha_hasta = request.args.get('fecha_hasta', date.today().isoformat())
        explosivo_id = request.args.get('explosivo_id', '')
        
        # Consulta base - EXCLUIR registros marcados como eliminados
        query = db.session.query(Devolucion, Explosivo).join(Explosivo).filter(
            ~Devolucion.observaciones.like('%ELIMINADO:%')
        )
        
        # Aplicar filtros
        if fecha_desde:
            query = query.filter(Devolucion.fecha_devolucion >= fecha_desde)
        if fecha_hasta:
            query = query.filter(Devolucion.fecha_devolucion <= fecha_hasta + ' 23:59:59')
        if explosivo_id:
            query = query.filter(Devolucion.explosivo_id == int(explosivo_id))
        
        devoluciones = query.order_by(Devolucion.fecha_devolucion.desc()).limit(500).all()
        explosivos = Explosivo.query.order_by(Explosivo.codigo).all()
        
        return render_template('editar_devoluciones.html', 
                             devoluciones=devoluciones, 
                             explosivos=explosivos,
                             fecha_desde=fecha_desde,
                             fecha_hasta=fecha_hasta,
                             explosivo_id=explosivo_id)
    
    except Exception as e:
        print(f"Error en listar_devoluciones_edicion: {e}")
        flash('Error cargando devoluciones para edición', 'error')
        return redirect(url_for('panel_edicion'))

@app.route('/editar/devolucion/<int:devolucion_id>', methods=['GET', 'POST'])
@require_login
def editar_devolucion(devolucion_id):
    """Editar una devolución específica"""
    if not es_admin():
        flash('Solo los administradores pueden editar datos', 'error')
        return redirect(url_for('index'))
    
    try:
        devolucion = Devolucion.query.get_or_404(devolucion_id)
        explosivos = Explosivo.query.order_by(Explosivo.codigo).all()
        
        if request.method == 'POST':
            # Aplicar cambios
            devolucion.explosivo_id = int(request.form['explosivo_id'])
            devolucion.cantidad_devuelta = float(request.form['cantidad_devuelta'])
            devolucion.fecha_devolucion = datetime.strptime(request.form['fecha_devolucion'], '%Y-%m-%dT%H:%M')
            devolucion.motivo = request.form['motivo'].strip() if request.form['motivo'].strip() else None
            devolucion.labor = request.form.get('labor', '').strip()
            devolucion.responsable = request.form.get('responsable', '').strip()
            devolucion.recibido_por = request.form.get('recibido_por', '').strip()
            devolucion.estado_material = request.form.get('estado_material', 'bueno')
            devolucion.observaciones = request.form.get('observaciones', '').strip()
            
            db.session.commit()
            
            flash(f'Devolución editada exitosamente. ID: {devolucion_id}', 'success')
            return redirect(url_for('listar_devoluciones_edicion'))
        
        return render_template('editar_devolucion_form.html', devolucion=devolucion, explosivos=explosivos)
    
    except Exception as e:
        db.session.rollback()
        print(f"Error editando devolución {devolucion_id}: {e}")
        flash('Error editando la devolución', 'error')
        return redirect(url_for('listar_devoluciones_edicion'))

@app.route('/eliminar/salida/<int:salida_id>', methods=['POST'])
@require_login
def eliminar_salida(salida_id):
    """Eliminar una salida (solo administradores)"""
    if not es_admin():
        return jsonify({'error': 'Solo los administradores pueden eliminar registros'}), 403
    
    try:
        salida = Salida.query.get_or_404(salida_id)
        
        # Crear backup de información antes de eliminar
        backup_info = {
            'id': salida.id,
            'explosivo_id': salida.explosivo_id,
            'cantidad': salida.cantidad,
            'fecha_salida': salida.fecha_salida.strftime('%Y-%m-%d %H:%M:%S'),
            'labor': salida.labor,
            'guardia': salida.guardia,
            'responsable': salida.responsable,
            'observaciones': salida.observaciones,
            'eliminado_por': session.get('username', 'admin'),
            'fecha_eliminacion': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        print(f"ELIMINANDO SALIDA: {backup_info}")  # Log para auditoría
        
        # ELIMINAR FÍSICAMENTE el registro de la base de datos
        db.session.delete(salida)
        db.session.commit()
        
        return jsonify({'success': True, 'message': f'Salida {salida_id} eliminada exitosamente de la base de datos'})
    
    except Exception as e:
        db.session.rollback()
        print(f"Error eliminando salida {salida_id}: {e}")
        return jsonify({'error': 'Error eliminando la salida'}), 500

@app.route('/eliminar/ingreso/<int:ingreso_id>', methods=['POST'])
@require_login
def eliminar_ingreso(ingreso_id):
    """Eliminar un ingreso (solo administradores)"""
    if not es_admin():
        return jsonify({'error': 'Solo los administradores pueden eliminar registros'}), 403
    
    try:
        ingreso = Ingreso.query.get_or_404(ingreso_id)
        
        # Crear backup de información antes de eliminar
        backup_info = {
            'id': ingreso.id,
            'explosivo_id': ingreso.explosivo_id,
            'cantidad': ingreso.cantidad,
            'fecha_ingreso': ingreso.fecha_ingreso.strftime('%Y-%m-%d %H:%M:%S'),
            'guardia': ingreso.guardia,
            'numero_vale': ingreso.numero_vale,
            'recibido_por': ingreso.recibido_por,
            'observaciones': ingreso.observaciones,
            'eliminado_por': session.get('username', 'admin'),
            'fecha_eliminacion': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        print(f"ELIMINANDO INGRESO: {backup_info}")  # Log para auditoría
        
        # ELIMINAR FÍSICAMENTE el registro de la base de datos
        db.session.delete(ingreso)
        db.session.commit()
        
        return jsonify({'success': True, 'message': f'Ingreso {ingreso_id} eliminado exitosamente de la base de datos'})
    
    except Exception as e:
        db.session.rollback()
        print(f"Error eliminando ingreso {ingreso_id}: {e}")
        return jsonify({'error': 'Error eliminando el ingreso'}), 500

@app.route('/eliminar/devolucion/<int:devolucion_id>', methods=['POST'])
@require_login
def eliminar_devolucion(devolucion_id):
    """Eliminar una devolución (solo administradores)"""
    if not es_admin():
        return jsonify({'error': 'Solo los administradores pueden eliminar registros'}), 403
    
    try:
        devolucion = Devolucion.query.get_or_404(devolucion_id)
        
        # Crear backup de información antes de eliminar
        backup_info = {
            'id': devolucion.id,
            'explosivo_id': devolucion.explosivo_id,
            'cantidad_devuelta': devolucion.cantidad_devuelta,
            'fecha_devolucion': devolucion.fecha_devolucion.strftime('%Y-%m-%d %H:%M:%S'),
            'motivo': devolucion.motivo,
            'labor': devolucion.labor,
            'responsable': devolucion.responsable,
            'recibido_por': devolucion.recibido_por,
            'estado_material': devolucion.estado_material,
            'observaciones': devolucion.observaciones,
            'eliminado_por': session.get('username', 'admin'),
            'fecha_eliminacion': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        print(f"ELIMINANDO DEVOLUCIÓN: {backup_info}")  # Log para auditoría
        
        # ELIMINAR FÍSICAMENTE el registro de la base de datos
        db.session.delete(devolucion)
        db.session.commit()
        
        return jsonify({'success': True, 'message': f'Devolución {devolucion_id} eliminada exitosamente de la base de datos'})
    
    except Exception as e:
        db.session.rollback()
        print(f"Error eliminando devolución {devolucion_id}: {e}")
        return jsonify({'error': 'Error eliminando la devolución'}), 500

@app.route('/admin/limpiar-eliminados', methods=['POST'])
@require_login
def limpiar_registros_eliminados():
    """Limpiar registros marcados como eliminados pero que siguen en la BD"""
    if not es_admin():
        return jsonify({'error': 'Solo los administradores pueden realizar esta operación'}), 403
    
    try:
        # Buscar registros marcados como eliminados
        salidas_eliminadas = Salida.query.filter(Salida.observaciones.like('%ELIMINADO:%')).all()
        ingresos_eliminados = Ingreso.query.filter(Ingreso.observaciones.like('%ELIMINADO:%')).all()
        devoluciones_eliminadas = Devolucion.query.filter(Devolucion.observaciones.like('%ELIMINADO:%')).all()
        
        total_eliminados = len(salidas_eliminadas) + len(ingresos_eliminados) + len(devoluciones_eliminadas)
        
        if total_eliminados == 0:
            return jsonify({'message': 'No hay registros marcados como eliminados para limpiar'})
        
        # Log de lo que se va a eliminar
        print(f"LIMPIEZA: Eliminando {len(salidas_eliminadas)} salidas, {len(ingresos_eliminados)} ingresos, {len(devoluciones_eliminadas)} devoluciones")
        
        # Eliminar físicamente todos los registros marcados
        for salida in salidas_eliminadas:
            print(f"Eliminando salida ID {salida.id}: {salida.cantidad} KG, {salida.labor}")
            db.session.delete(salida)
            
        for ingreso in ingresos_eliminados:
            print(f"Eliminando ingreso ID {ingreso.id}: {ingreso.cantidad} KG")
            db.session.delete(ingreso)
            
        for devolucion in devoluciones_eliminadas:
            print(f"Eliminando devolución ID {devolucion.id}: {devolucion.cantidad_devuelta} KG")
            db.session.delete(devolucion)
        
        db.session.commit()
        
        return jsonify({
            'success': True, 
            'message': f'Se eliminaron {total_eliminados} registros marcados como eliminados',
            'detalle': {
                'salidas': len(salidas_eliminadas),
                'ingresos': len(ingresos_eliminados),
                'devoluciones': len(devoluciones_eliminadas)
            }
        })
    
    except Exception as e:
        db.session.rollback()
        print(f"Error limpiando registros eliminados: {e}")
        return jsonify({'error': 'Error limpiando registros eliminados'}), 500

@app.route('/api/estadisticas-edicion')
@require_login
def estadisticas_edicion():
    """API para obtener estadísticas rápidas de edición"""
    try:
        from datetime import timedelta
        fecha_limite = date.today() - timedelta(days=7)
        
        # Contar movimientos de los últimos 7 días
        total_salidas = db.session.query(Salida).filter(
            Salida.fecha_salida >= fecha_limite,
            ~Salida.observaciones.like('%ELIMINADO:%')  # Excluir registros marcados como eliminados
        ).count()
        
        total_ingresos = db.session.query(Ingreso).filter(
            Ingreso.fecha_ingreso >= fecha_limite
        ).count()
        
        total_devoluciones = db.session.query(Devolucion).filter(
            Devolucion.fecha_devolucion >= fecha_limite
        ).count()
        
        return jsonify({
            'success': True,
            'total_salidas': total_salidas,
            'total_ingresos': total_ingresos,
            'total_devoluciones': total_devoluciones
        })
    
    except Exception as e:
        print(f"Error en estadisticas_edicion: {e}")
        return jsonify({'error': 'Error obteniendo estadísticas'}), 500

@app.route('/gestionar/labores')
@require_login
def gestionar_labores():
    """Página para gestionar labores"""
    username = session.get('username')
    if not es_admin():
        flash('Acceso denegado. Solo administradores pueden gestionar labores.', 'danger')
        return redirect(url_for('index'))
    
    try:
        # Obtener todas las labores
        labores = Labor.query.order_by(Labor.nombre).all()
        
        return render_template('gestionar_labores.html',
                             user_name=username,
                             labores=labores)
    
    except Exception as e:
        print(f"Error en gestionar_labores: {e}")
        flash('Error cargando las labores', 'danger')
        return redirect(url_for('index'))

@app.route('/api/labores')
@require_login
def api_labores():
    """API para obtener labores con filtros y búsqueda"""
    try:
        # Parámetros de búsqueda
        buscar = request.args.get('buscar', '').strip()
        
        # Query base
        query = Labor.query
        
        # Aplicar filtro de búsqueda
        if buscar:
            query = query.filter(
                db.or_(
                    Labor.nombre.ilike(f'%{buscar}%'),
                    Labor.descripcion.ilike(f'%{buscar}%')
                )
            )
        
        # Ordenar
        labores = query.order_by(Labor.nombre).all()
        
        # Convertir a JSON
        result = []
        for labor in labores:
            result.append({
                'id': labor.id,
                'nombre': labor.nombre,
                'descripcion': labor.descripcion or '',
                'fecha_creacion': labor.fecha_creacion.strftime('%Y-%m-%d %H:%M') if labor.fecha_creacion else ''
            })
        
        return jsonify({
            'success': True,
            'labores': result,
            'total': len(result)
        })
    
    except Exception as e:
        print(f"Error en api_labores: {e}")
        return jsonify({'error': 'Error obteniendo labores'}), 500

@app.route('/api/buscar-labores')
@require_login
def buscar_labores():
    """API específica para búsqueda de labores (autocomplete)"""
    try:
        termino = request.args.get('q', '').strip()
        
        if len(termino) < 1:
            # Si no hay término, devolver todas las labores
            labores = Labor.query.order_by(Labor.nombre).limit(10).all()
        else:
            # Buscar labores que coincidan
            labores = Labor.query.filter(
                db.or_(
                    Labor.nombre.ilike(f'%{termino}%'),
                    Labor.descripcion.ilike(f'%{termino}%')
                )
            ).order_by(Labor.nombre).limit(10).all()
        
        # Formato para autocomplete
        result = []
        for labor in labores:
            result.append({
                'id': labor.id,
                'nombre': labor.nombre,
                'text': labor.nombre
            })
        
        return jsonify({'labores': result})
    
    except Exception as e:
        print(f"Error en buscar_labores: {e}")
        return jsonify({'labores': []}), 500

@app.route('/agregar-labor', methods=['POST'])
@require_login
def agregar_labor():
    """Agregar nueva labor"""
    username = session.get('username')
    if not es_admin():
        return jsonify({'error': 'Acceso denegado'}), 403
    
    try:
        nombre = request.form.get('nombre', '').strip()
        descripcion = request.form.get('descripcion', '').strip()
        
        # Validaciones
        if not nombre:
            return jsonify({'error': 'Nombre es obligatorio'}), 400
        
        # Verificar si ya existe
        existe = Labor.query.filter_by(nombre=nombre).first()
        if existe:
            return jsonify({'error': f'Ya existe una labor con nombre {nombre}'}), 400
        
        # Crear nueva labor
        nueva_labor = Labor(
            nombre=nombre,
            descripcion=descripcion,
            fecha_creacion=datetime.now()
        )
        
        db.session.add(nueva_labor)
        db.session.commit()
        
        flash(f'Labor {nombre} agregada exitosamente', 'success')
        return jsonify({'success': True, 'message': 'Labor agregada exitosamente'})
    
    except Exception as e:
        db.session.rollback()
        print(f"Error agregando labor: {e}")
        return jsonify({'error': 'Error agregando la labor'}), 500

@app.route('/editar-labor/<int:labor_id>', methods=['POST'])
@require_login
def editar_labor(labor_id):
    """Editar labor existente"""
    username = session.get('username')
    if not es_admin():
        return jsonify({'error': 'Acceso denegado'}), 403
    
    try:
        labor = Labor.query.get_or_404(labor_id)
        
        nombre = request.form.get('nombre', '').strip()
        descripcion = request.form.get('descripcion', '').strip()
        
        # Validaciones
        if not nombre:
            return jsonify({'error': 'Nombre es obligatorio'}), 400
        
        # Verificar si nombre ya existe (excluyendo la labor actual)
        existe = Labor.query.filter(
            Labor.nombre == nombre,
            Labor.id != labor_id
        ).first()
        if existe:
            return jsonify({'error': f'Ya existe otra labor con nombre {nombre}'}), 400
        
        # Actualizar labor
        labor.nombre = nombre
        labor.descripcion = descripcion
        
        db.session.commit()
        
        flash(f'Labor {nombre} actualizada exitosamente', 'success')
        return jsonify({'success': True, 'message': 'Labor actualizada exitosamente'})
    
    except Exception as e:
        db.session.rollback()
        print(f"Error editando labor {labor_id}: {e}")
        return jsonify({'error': 'Error editando la labor'}), 500

@app.route('/eliminar-labor/<int:labor_id>', methods=['POST'])
@require_login
def eliminar_labor(labor_id):
    """Eliminar labor"""
    username = session.get('username')
    if not es_admin():
        return jsonify({'error': 'Acceso denegado'}), 403
    
    try:
        labor = Labor.query.get_or_404(labor_id)
        
        # Eliminar la labor
        db.session.delete(labor)
        db.session.commit()
        
        flash(f'Labor {labor.nombre} eliminada exitosamente', 'success')
        return jsonify({'success': True, 'message': 'Labor eliminada exitosamente'})
    
    except Exception as e:
        db.session.rollback()
        print(f"Error eliminando labor {labor_id}: {e}")
        return jsonify({'error': 'Error eliminando la labor'}), 500

@app.route('/gestionar/tipos-actividad')
@require_login
def gestionar_tipos_actividad():
    """Página para gestionar tipos de actividad"""
    username = session.get('username')
    if not es_admin():
        flash('Acceso denegado. Solo administradores pueden gestionar tipos de actividad.', 'danger')
        return redirect(url_for('index'))
    
    try:
        # Obtener todos los tipos de actividad
        tipos_actividad = TipoActividad.query.order_by(TipoActividad.nombre).all()
        
        return render_template('gestionar_tipos_actividad.html',
                             user_name=username,
                             tipos_actividad=tipos_actividad)
    
    except Exception as e:
        print(f"Error en gestionar_tipos_actividad: {e}")
        flash('Error cargando los tipos de actividad', 'danger')
        return redirect(url_for('index'))

@app.route('/api/tipos-actividad')
@require_login
def api_tipos_actividad():
    """API para obtener tipos de actividad con filtros y búsqueda"""
    try:
        # Parámetros de búsqueda (soportar tanto 'buscar' como 'q')
        buscar = request.args.get('buscar', '').strip()
        q = request.args.get('q', '').strip()
        
        # Usar el parámetro que esté presente
        termino = buscar or q
        
        # Query base
        query = TipoActividad.query
        
        # Aplicar filtro de búsqueda
        if termino:
            query = query.filter(
                db.or_(
                    TipoActividad.nombre.ilike(f'%{termino}%'),
                    TipoActividad.descripcion.ilike(f'%{termino}%')
                )
            )
        
        # Ordenar
        tipos_actividad = query.order_by(TipoActividad.nombre).all()
        
        # Convertir a JSON
        result = []
        for tipo in tipos_actividad:
            result.append({
                'id': tipo.id,
                'nombre': tipo.nombre,
                'descripcion': tipo.descripcion or '',
                'fecha_creacion': tipo.fecha_creacion.strftime('%Y-%m-%d %H:%M') if tipo.fecha_creacion else ''
            })
        
        return jsonify({
            'success': True,
            'tipos_actividad': result,
            'total': len(result)
        })
    
    except Exception as e:
        print(f"Error en api_tipos_actividad: {e}")
        return jsonify({'error': 'Error obteniendo tipos de actividad'}), 500

@app.route('/api/buscar-tipos-actividad')
@require_login
def buscar_tipos_actividad():
    """API específica para búsqueda de tipos de actividad (autocomplete)"""
    try:
        termino = request.args.get('q', '').strip()
        
        if len(termino) < 2:
            # Si no hay término, devolver todos los tipos
            tipos_actividad = TipoActividad.query.order_by(TipoActividad.nombre).limit(10).all()
        else:
            # Buscar tipos que coincidan
            tipos_actividad = TipoActividad.query.filter(
                db.or_(
                    TipoActividad.nombre.ilike(f'%{termino}%'),
                    TipoActividad.descripcion.ilike(f'%{termino}%')
                )
            ).order_by(TipoActividad.nombre).limit(10).all()
        
        # Formato para autocomplete
        result = []
        for tipo in tipos_actividad:
            result.append({
                'id': tipo.id,
                'nombre': tipo.nombre,
                'text': tipo.nombre
            })
        
        return jsonify({'tipos_actividad': result})
    
    except Exception as e:
        print(f"Error en buscar_tipos_actividad: {e}")
        return jsonify({'tipos_actividad': []}), 500

@app.route('/agregar-tipo-actividad', methods=['POST'])
@require_login
def agregar_tipo_actividad():
    """Agregar nuevo tipo de actividad"""
    username = session.get('username')
    if not es_admin():
        return jsonify({'error': 'Acceso denegado'}), 403
    
    try:
        nombre = request.form.get('nombre', '').strip()
        descripcion = request.form.get('descripcion', '').strip()
        
        # Validaciones
        if not nombre:
            return jsonify({'error': 'Nombre es obligatorio'}), 400
        
        # Verificar si ya existe
        existe = TipoActividad.query.filter_by(nombre=nombre).first()
        if existe:
            return jsonify({'error': f'Ya existe un tipo de actividad con nombre {nombre}'}), 400
        
        # Crear nuevo tipo de actividad
        nuevo_tipo = TipoActividad(
            nombre=nombre,
            descripcion=descripcion,
            fecha_creacion=datetime.now()
        )
        
        db.session.add(nuevo_tipo)
        db.session.commit()
        
        flash(f'Tipo de actividad {nombre} agregado exitosamente', 'success')
        return jsonify({'success': True, 'message': 'Tipo de actividad agregado exitosamente'})
    
    except Exception as e:
        db.session.rollback()
        print(f"Error agregando tipo de actividad: {e}")
        return jsonify({'error': 'Error agregando el tipo de actividad'}), 500

@app.route('/editar-tipo-actividad/<int:tipo_id>', methods=['POST'])
@require_login
def editar_tipo_actividad(tipo_id):
    """Editar tipo de actividad existente"""
    username = session.get('username')
    if not es_admin():
        return jsonify({'error': 'Acceso denegado'}), 403
    
    try:
        tipo = TipoActividad.query.get_or_404(tipo_id)
        
        nombre = request.form.get('nombre', '').strip()
        descripcion = request.form.get('descripcion', '').strip()
        
        # Validaciones
        if not nombre:
            return jsonify({'error': 'Nombre es obligatorio'}), 400
        
        # Verificar si nombre ya existe (excluyendo el tipo actual)
        existe = TipoActividad.query.filter(
            TipoActividad.nombre == nombre,
            TipoActividad.id != tipo_id
        ).first()
        if existe:
            return jsonify({'error': f'Ya existe otro tipo de actividad con nombre {nombre}'}), 400
        
        # Actualizar tipo de actividad
        tipo.nombre = nombre
        tipo.descripcion = descripcion
        
        db.session.commit()
        
        flash(f'Tipo de actividad {nombre} actualizado exitosamente', 'success')
        return jsonify({'success': True, 'message': 'Tipo de actividad actualizado exitosamente'})
    
    except Exception as e:
        db.session.rollback()
        print(f"Error editando tipo de actividad {tipo_id}: {e}")
        return jsonify({'error': 'Error editando el tipo de actividad'}), 500

@app.route('/eliminar-tipo-actividad/<int:tipo_id>', methods=['POST'])
@require_login
def eliminar_tipo_actividad(tipo_id):
    """Eliminar tipo de actividad"""
    username = session.get('username')
    if not es_admin():
        return jsonify({'error': 'Acceso denegado'}), 403
    
    try:
        tipo = TipoActividad.query.get_or_404(tipo_id)
        
        # Verificar si hay salidas que usan este tipo de actividad
        salidas_usando = db.session.query(Salida).filter_by(tipo_actividad=tipo.nombre).count()
        if salidas_usando > 0:
            return jsonify({'error': f'No se puede eliminar. Hay {salidas_usando} salidas que usan este tipo de actividad'}), 400
        
        # Eliminar el tipo de actividad
        db.session.delete(tipo)
        db.session.commit()
        
        flash(f'Tipo de actividad {tipo.nombre} eliminado exitosamente', 'success')
        return jsonify({'success': True, 'message': 'Tipo de actividad eliminado exitosamente'})
    
    except Exception as e:
        db.session.rollback()
        print(f"Error eliminando tipo de actividad {tipo_id}: {e}")
        return jsonify({'error': 'Error eliminando el tipo de actividad'}), 500

def es_admin():
    """Verificar si el usuario actual es administrador"""
    try:
        username = session.get('username')
        if not username:
            return False
        
        usuario = Usuario.query.filter_by(username=username).first()
        return usuario and usuario.cargo.lower() in ['administrador', 'admin']
    except:
        return False

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({'error': 'Error interno del servidor'}), 500

if __name__ == '__main__':
    with app.app_context():
        # Crear tablas si no existen
        db.create_all()
        # Crear usuario administrador inicial
        crear_usuario_admin_inicial()
    
    # Configuración flexible para desarrollo/producción
    debug_mode = os.environ.get('FLASK_DEBUG', 'True').lower() == 'true'
    port = int(os.environ.get('PORT', 5000))
    
    app.run(debug=debug_mode, host='0.0.0.0', port=port)
