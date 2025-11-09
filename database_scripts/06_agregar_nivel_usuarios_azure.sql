-- Script para agregar columna 'nivel' a tabla usuarios
-- Sistema de Registro de Polvorin PALLCA - Azure SQL Database
-- Fecha: 2025-11-09
-- Propósito: Separar concepto de cargo (puesto) del nivel de acceso en el sistema

PRINT 'Iniciando modificación de tabla usuarios - Agregar columna nivel'
GO

-- Verificar que la tabla usuarios existe
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'usuarios')
BEGIN
    PRINT 'ERROR: La tabla usuarios no existe'
    RETURN
END
GO

-- Verificar si la columna nivel ya existe
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'nivel')
BEGIN
    PRINT 'Agregando columna nivel a tabla usuarios...'
    
    -- Agregar la nueva columna nivel
    ALTER TABLE usuarios 
    ADD nivel INT NOT NULL DEFAULT 1
    GO
    
    -- Agregar constraint para validar valores de nivel
    ALTER TABLE usuarios 
    ADD CONSTRAINT CK_usuarios_nivel 
    CHECK (nivel IN (1, 2, 3, 4))
    GO
    
    PRINT 'Columna nivel agregada exitosamente'
END
ELSE
BEGIN
    PRINT 'La columna nivel ya existe en la tabla usuarios'
END
GO

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
    GO
    
    -- Insertar niveles predefinidos
    INSERT INTO niveles_acceso (id, nombre, descripcion, permisos_descripcion) VALUES
    (1, 'Básico', 'Usuario básico con acceso de solo lectura', 'Ver stocks, consultar reportes básicos, sin permisos de modificación'),
    (2, 'Intermedio', 'Usuario operativo con permisos de registro', 'Ver stocks, registrar ingresos/salidas/devoluciones, consultar reportes'),
    (3, 'Avanzado', 'Supervisor con permisos extendidos', 'Todos los permisos de nivel intermedio + editar registros, gestionar labores y tipos de actividad'),
    (4, 'Administrador', 'Acceso completo al sistema', 'Todos los permisos + gestión de usuarios, configuración del sistema, acceso a todas las funciones')
    GO
    
    PRINT 'Tabla niveles_acceso creada con datos iniciales'
END
ELSE
BEGIN
    PRINT 'La tabla niveles_acceso ya existe'
END
GO

-- Actualizar usuarios existentes con nivel por defecto basado en cargo
PRINT 'Actualizando nivel de usuarios existentes basado en cargo actual...'

UPDATE usuarios 
SET nivel = CASE 
    WHEN cargo = 'administrador' THEN 4
    WHEN cargo = 'supervisor' THEN 3
    WHEN cargo = 'encargado' THEN 2
    ELSE 1
END
WHERE nivel = 1  -- Solo actualizar si aún tienen el valor por defecto
GO

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
GO

PRINT 'Modificación de tabla usuarios completada exitosamente'
PRINT '=============================================='
PRINT 'NIVELES DE ACCESO CONFIGURADOS:'
PRINT '1 = Básico (solo lectura)'
PRINT '2 = Intermedio (operativo)'
PRINT '3 = Avanzado (supervisor)'
PRINT '4 = Administrador (acceso completo)'
PRINT '=============================================='
GO