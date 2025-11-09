-- Script simplificado para Azure SQL Database - Agregar columna nivel
-- Sistema de Registro de Polvorin PALLCA
-- Fecha: 2025-11-09

PRINT 'Iniciando modificación de tabla usuarios - Agregar columna nivel'

-- Verificar si la columna nivel ya existe
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'nivel')
BEGIN
    PRINT 'Agregando columna nivel a tabla usuarios...'
    
    -- Agregar la nueva columna nivel (sin DEFAULT, lo agregamos después)
    ALTER TABLE usuarios ADD nivel INT NULL
    
    PRINT 'Columna nivel agregada, estableciendo valores por defecto...'
    
    -- Establecer valor por defecto para registros existentes
    UPDATE usuarios SET nivel = 1 WHERE nivel IS NULL
    
    -- Ahora hacer la columna NOT NULL
    ALTER TABLE usuarios ALTER COLUMN nivel INT NOT NULL
    
    -- Agregar constraint para validar valores de nivel
    ALTER TABLE usuarios 
    ADD CONSTRAINT CK_usuarios_nivel 
    CHECK (nivel IN (1, 2, 3, 4))
    
    PRINT 'Columna nivel configurada exitosamente'
END
ELSE
BEGIN
    PRINT 'La columna nivel ya existe en la tabla usuarios'
END

-- Crear tabla de referencia para niveles de acceso
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'niveles_acceso')
BEGIN
    PRINT 'Creando tabla de referencia niveles_acceso...'
    
    CREATE TABLE niveles_acceso (
        id INT PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL,
        descripcion VARCHAR(200) NOT NULL,
        permisos_descripcion VARCHAR(500) NOT NULL,
        fecha_creacion DATETIME2 DEFAULT GETDATE()
    )
    
    PRINT 'Insertando niveles predefinidos...'
    
    -- Insertar niveles predefinidos
    INSERT INTO niveles_acceso (id, nombre, descripcion, permisos_descripcion) VALUES
    (1, 'Basico', 'Usuario basico con acceso de solo lectura', 'Ver stocks, consultar reportes basicos, sin permisos de modificacion'),
    (2, 'Intermedio', 'Usuario operativo con permisos de registro', 'Ver stocks, registrar ingresos/salidas/devoluciones, consultar reportes'),
    (3, 'Avanzado', 'Supervisor con permisos extendidos', 'Todos los permisos de nivel intermedio + editar registros, gestionar labores y tipos de actividad'),
    (4, 'Administrador', 'Acceso completo al sistema', 'Todos los permisos + gestion de usuarios, configuracion del sistema, acceso a todas las funciones')
    
    PRINT 'Tabla niveles_acceso creada con datos iniciales'
END
ELSE
BEGIN
    PRINT 'La tabla niveles_acceso ya existe'
END

-- Actualizar usuarios existentes con nivel basado en cargo
PRINT 'Actualizando nivel de usuarios existentes basado en cargo actual...'

UPDATE usuarios 
SET nivel = 
    CASE 
        WHEN cargo = 'administrador' THEN 4
        WHEN cargo = 'supervisor' THEN 3
        WHEN cargo = 'encargado' THEN 2
        ELSE 1
    END
WHERE nivel = 1

-- Verificar resultados
PRINT 'Verificando resultados:'
SELECT 
    u.id,
    u.username,
    u.nombre_completo,
    u.cargo,
    u.nivel,
    na.nombre AS nivel_nombre,
    na.descripcion AS nivel_descripcion
FROM usuarios u
LEFT JOIN niveles_acceso na ON u.nivel = na.id
ORDER BY u.nivel DESC, u.username

PRINT 'Modificacion de tabla usuarios completada exitosamente'