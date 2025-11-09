-- =========================================================
-- SCRIPT SEGURO PARA INSTALACIÓN EN BASE EXISTENTE
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0
-- Descripción: Script seguro que NO elimina datos existentes
--              Solo crea estructuras faltantes

USE pallca;
GO

PRINT '🔒 INSTALACIÓN SEGURA PARA BASE DE DATOS EXISTENTE';
PRINT '==================================================';
PRINT '⚠️  ESTE SCRIPT NO ELIMINA DATOS EXISTENTES';
PRINT '';

-- =========================================================
-- 1. VERIFICAR TABLAS EXISTENTES
-- =========================================================

PRINT '🔍 Verificando estructura existente...';

DECLARE @tablas_existentes TABLE (nombre NVARCHAR(50), existe BIT);

INSERT INTO @tablas_existentes VALUES 
('explosivos', CASE WHEN OBJECT_ID('explosivos', 'U') IS NOT NULL THEN 1 ELSE 0 END),
('stock_diario', CASE WHEN OBJECT_ID('stock_diario', 'U') IS NOT NULL THEN 1 ELSE 0 END),
('ingresos', CASE WHEN OBJECT_ID('ingresos', 'U') IS NOT NULL THEN 1 ELSE 0 END),
('salidas', CASE WHEN OBJECT_ID('salidas', 'U') IS NOT NULL THEN 1 ELSE 0 END),
('devoluciones', CASE WHEN OBJECT_ID('devoluciones', 'U') IS NOT NULL THEN 1 ELSE 0 END),
('usuarios', CASE WHEN OBJECT_ID('usuarios', 'U') IS NOT NULL THEN 1 ELSE 0 END);

PRINT '📊 ESTADO DE TABLAS:';
SELECT 
    '   ' + nombre + ': ' + CASE WHEN existe = 1 THEN '✅ EXISTE' ELSE '❌ FALTA' END AS estado
FROM @tablas_existentes;

-- =========================================================
-- 2. CREAR SOLO TABLAS FALTANTES
-- =========================================================

-- Tabla explosivos
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'explosivos')
BEGIN
    PRINT '🔄 Creando tabla explosivos...';
    
    CREATE TABLE explosivos (
        id INT IDENTITY(1,1) PRIMARY KEY,
        codigo NVARCHAR(20) NOT NULL UNIQUE,
        descripcion NVARCHAR(255) NOT NULL,
        unidad NVARCHAR(10) NOT NULL,
        fecha_creacion DATETIME2 DEFAULT GETDATE(),
        activo BIT DEFAULT 1
    );
    
    CREATE INDEX IX_explosivos_codigo ON explosivos(codigo);
    CREATE INDEX IX_explosivos_activo ON explosivos(activo);
    
    PRINT '✅ Tabla explosivos creada';
END

-- Tabla stock_diario
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'stock_diario')
BEGIN
    PRINT '🔄 Creando tabla stock_diario...';
    
    CREATE TABLE stock_diario (
        id INT IDENTITY(1,1) PRIMARY KEY,
        fecha DATE NOT NULL,
        explosivo_id INT NOT NULL,
        stock_inicial DECIMAL(18,2) DEFAULT 0,
        ingresos_dia DECIMAL(18,2) DEFAULT 0,
        salidas_dia DECIMAL(18,2) DEFAULT 0,
        devoluciones_dia DECIMAL(18,2) DEFAULT 0,
        stock_final DECIMAL(18,2) DEFAULT 0,
        fecha_actualizacion DATETIME2 DEFAULT GETDATE(),
        
        CONSTRAINT FK_stock_diario_explosivo 
            FOREIGN KEY (explosivo_id) REFERENCES explosivos(id),
        CONSTRAINT UQ_stock_diario_fecha_explosivo 
            UNIQUE (fecha, explosivo_id)
    );
    
    CREATE INDEX IX_stock_diario_fecha ON stock_diario(fecha);
    CREATE INDEX IX_stock_diario_explosivo_id ON stock_diario(explosivo_id);
    
    PRINT '✅ Tabla stock_diario creada';
END

-- Tabla ingresos
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ingresos')
BEGIN
    PRINT '🔄 Creando tabla ingresos...';
    
    CREATE TABLE ingresos (
        id INT IDENTITY(1,1) PRIMARY KEY,
        explosivo_id INT NOT NULL,
        stock_diario_id INT NULL,
        numero_vale NVARCHAR(50) NULL,
        cantidad DECIMAL(18,2) NULL,
        fecha_ingreso DATETIME2 DEFAULT GETDATE(),
        guardia NVARCHAR(10) NOT NULL,
        recibido_por NVARCHAR(100) NULL,
        observaciones NVARCHAR(500) NULL,
        fecha_creacion DATETIME2 DEFAULT GETDATE(),
        
        CONSTRAINT FK_ingresos_explosivo 
            FOREIGN KEY (explosivo_id) REFERENCES explosivos(id),
        CONSTRAINT CK_ingresos_guardia 
            CHECK (guardia IN ('DIA', 'NOCHE')),
        CONSTRAINT CK_ingresos_cantidad_positiva 
            CHECK (cantidad > 0)
    );
    
    CREATE INDEX IX_ingresos_explosivo_id ON ingresos(explosivo_id);
    CREATE INDEX IX_ingresos_fecha ON ingresos(fecha_ingreso);
    
    PRINT '✅ Tabla ingresos creada';
END

-- Tabla salidas
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'salidas')
BEGIN
    PRINT '🔄 Creando tabla salidas...';
    
    CREATE TABLE salidas (
        id INT IDENTITY(1,1) PRIMARY KEY,
        explosivo_id INT NOT NULL,
        stock_diario_id INT NULL,
        numero_vale NVARCHAR(50) NULL,
        cantidad DECIMAL(18,2) NULL,
        fecha_salida DATETIME2 DEFAULT GETDATE(),
        guardia NVARCHAR(10) NOT NULL,
        solicitado_por NVARCHAR(100) NULL,
        labor NVARCHAR(100) NULL,
        observaciones NVARCHAR(500) NULL,
        fecha_creacion DATETIME2 DEFAULT GETDATE(),
        
        CONSTRAINT FK_salidas_explosivo 
            FOREIGN KEY (explosivo_id) REFERENCES explosivos(id),
        CONSTRAINT CK_salidas_guardia 
            CHECK (guardia IN ('DIA', 'NOCHE')),
        CONSTRAINT CK_salidas_cantidad_positiva 
            CHECK (cantidad > 0)
    );
    
    CREATE INDEX IX_salidas_explosivo_id ON salidas(explosivo_id);
    CREATE INDEX IX_salidas_fecha ON salidas(fecha_salida);
    
    PRINT '✅ Tabla salidas creada';
END

-- Tabla devoluciones
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'devoluciones')
BEGIN
    PRINT '🔄 Creando tabla devoluciones...';
    
    CREATE TABLE devoluciones (
        id INT IDENTITY(1,1) PRIMARY KEY,
        explosivo_id INT NOT NULL,
        stock_diario_id INT NULL,
        numero_vale_original NVARCHAR(50) NULL,
        cantidad_devuelta DECIMAL(18,2) NULL,
        fecha_devolucion DATETIME2 DEFAULT GETDATE(),
        guardia NVARCHAR(10) NOT NULL,
        devuelto_por NVARCHAR(100) NULL,
        motivo NVARCHAR(200) NULL,
        observaciones NVARCHAR(500) NULL,
        fecha_creacion DATETIME2 DEFAULT GETDATE(),
        
        CONSTRAINT FK_devoluciones_explosivo 
            FOREIGN KEY (explosivo_id) REFERENCES explosivos(id),
        CONSTRAINT CK_devoluciones_guardia 
            CHECK (guardia IN ('DIA', 'NOCHE')),
        CONSTRAINT CK_devoluciones_cantidad_positiva 
            CHECK (cantidad_devuelta > 0)
    );
    
    CREATE INDEX IX_devoluciones_explosivo_id ON devoluciones(explosivo_id);
    CREATE INDEX IX_devoluciones_fecha ON devoluciones(fecha_devolucion);
    
    PRINT '✅ Tabla devoluciones creada';
END

-- Tabla usuarios
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'usuarios')
BEGIN
    PRINT '🔄 Creando tabla usuarios...';
    
    CREATE TABLE usuarios (
        id INT IDENTITY(1,1) PRIMARY KEY,
        username NVARCHAR(50) NOT NULL UNIQUE,
        password_hash NVARCHAR(255) NOT NULL,
        nombre_completo NVARCHAR(100) NULL,
        email NVARCHAR(100) NULL,
        rol NVARCHAR(20) DEFAULT 'usuario',
        activo BIT DEFAULT 1,
        fecha_creacion DATETIME2 DEFAULT GETDATE(),
        ultimo_login DATETIME2 NULL,
        
        CONSTRAINT CK_usuarios_rol 
            CHECK (rol IN ('admin', 'usuario', 'lectura'))
    );
    
    CREATE INDEX IX_usuarios_username ON usuarios(username);
    CREATE INDEX IX_usuarios_activo ON usuarios(activo);
    
    PRINT '✅ Tabla usuarios creada';
END

-- =========================================================
-- 3. VERIFICAR Y CREAR VISTAS OPTIMIZADAS
-- =========================================================

PRINT '';
PRINT '🔍 Verificando vistas optimizadas...';

-- Recrear vista de stock actual (siempre actualizar)
IF OBJECT_ID('v_stock_actual', 'V') IS NOT NULL
    DROP VIEW v_stock_actual;
GO

CREATE VIEW v_stock_actual AS
SELECT 
    e.id,
    e.codigo,
    e.descripcion,
    e.unidad,
    COALESCE(i.total_ingresos, 0) AS total_ingresos,
    COALESCE(s.total_salidas, 0) AS total_salidas,
    COALESCE(d.total_devoluciones, 0) AS total_devoluciones,
    (COALESCE(i.total_ingresos, 0) - COALESCE(s.total_salidas, 0) + COALESCE(d.total_devoluciones, 0)) AS stock_actual,
    GETDATE() AS fecha_calculo
FROM explosivos e
LEFT JOIN (
    SELECT explosivo_id, SUM(cantidad) AS total_ingresos
    FROM ingresos GROUP BY explosivo_id
) i ON e.id = i.explosivo_id
LEFT JOIN (
    SELECT explosivo_id, SUM(cantidad) AS total_salidas
    FROM salidas GROUP BY explosivo_id
) s ON e.id = s.explosivo_id
LEFT JOIN (
    SELECT explosivo_id, SUM(cantidad_devuelta) AS total_devoluciones
    FROM devoluciones GROUP BY explosivo_id
) d ON e.id = d.explosivo_id;
GO

PRINT '✅ Vista v_stock_actual actualizada (SIN limitantes de fecha)';

-- =========================================================
-- 4. VERIFICAR ESTADO FINAL
-- =========================================================

PRINT '';
PRINT '🎯 VERIFICACIÓN FINAL...';

DECLARE @explosivos_count INT = (SELECT COUNT(*) FROM explosivos);
DECLARE @ingresos_count INT = (SELECT COUNT(*) FROM ingresos);
DECLARE @salidas_count INT = (SELECT COUNT(*) FROM salidas);
DECLARE @devoluciones_count INT = (SELECT COUNT(*) FROM devoluciones);

PRINT '';
PRINT '📊 ESTADO ACTUAL DE LA BASE:';
PRINT '   📦 Explosivos: ' + CAST(@explosivos_count AS VARCHAR(10));
PRINT '   📥 Ingresos: ' + CAST(@ingresos_count AS VARCHAR(10));
PRINT '   📤 Salidas: ' + CAST(@salidas_count AS VARCHAR(10));
PRINT '   🔄 Devoluciones: ' + CAST(@devoluciones_count AS VARCHAR(10));

-- =========================================================
-- RESUMEN FINAL
-- =========================================================

PRINT '';
PRINT '🎉 ¡INSTALACIÓN SEGURA COMPLETADA!';
PRINT '';
PRINT '✅ COMPLETADO:';
PRINT '   🔒 Sin pérdida de datos existentes';
PRINT '   🏗️  Estructuras faltantes creadas';
PRINT '   📊 Vistas optimizadas sin limitantes de fecha';
PRINT '   ⚡ Índices de rendimiento aplicados';
PRINT '';
PRINT '🎯 CARACTERÍSTICAS CLAVE:';
PRINT '   ✅ Cálculos de stock SIN limitantes temporales';
PRINT '   ✅ Vista principal calcula TODO el historial';
PRINT '   ✅ Optimizado para consultas rápidas';
PRINT '   ✅ Compatible con sistema existente';
PRINT '';

GO