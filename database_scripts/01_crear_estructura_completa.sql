-- =========================================================
-- SCRIPT DE CREACIÓN COMPLETA DE BASE DE DATOS PALLCA
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0
-- Descripción: Script completo para crear toda la estructura
--              de base de datos del sistema pallca desde cero

USE master;
GO

-- =========================================================
-- 1. CREAR BASE DE DATOS DE FORMA SEGURA
-- =========================================================

PRINT '🔍 Verificando base de datos PALLCA...';

-- Verificar si la base de datos existe y está accesible
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'pallca')
BEGIN
    PRINT '⚠️  Base de datos PALLCA ya existe - verificando acceso...';
    
    -- Intentar cambiar a la base de datos para verificar que está accesible
    BEGIN TRY
        USE pallca;
        PRINT '✅ Base de datos accesible - continuando con creación de tablas';
    END TRY
    BEGIN CATCH
        PRINT '❌ Error accediendo a la base de datos existente';
        PRINT '   Error: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH
END
ELSE
BEGIN
    PRINT '🔄 Creando nueva base de datos PALLCA...';
    
    BEGIN TRY
        -- Crear nueva base de datos
        CREATE DATABASE pallca
        ON 
        ( NAME = 'pallca_data',
          FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\pallca.mdf',
          SIZE = 100MB,
          MAXSIZE = 1GB,
          FILEGROWTH = 10MB )
        LOG ON 
        ( NAME = 'pallca_log',
          FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\pallca.ldf',
          SIZE = 10MB,
          MAXSIZE = 100MB,
          FILEGROWTH = 5MB );

        PRINT '✅ Base de datos PALLCA creada exitosamente';
    END TRY
    BEGIN CATCH
        PRINT '❌ Error creando la base de datos';
        PRINT '   Error: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH
END

-- Cambiar a la base de datos
USE pallca;
GO

-- =========================================================
-- 2. CREAR TABLA EXPLOSIVOS (MAESTRO)
-- =========================================================

PRINT '📦 Verificando tabla EXPLOSIVOS...';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'explosivos')
BEGIN
    PRINT '🔄 Creando tabla EXPLOSIVOS...';
    
    CREATE TABLE explosivos (
        id INT IDENTITY(1,1) PRIMARY KEY,
        codigo NVARCHAR(20) NOT NULL UNIQUE,
        descripcion NVARCHAR(255) NOT NULL,
        unidad NVARCHAR(10) NOT NULL,
        fecha_creacion DATETIME2 DEFAULT GETDATE(),
        activo BIT DEFAULT 1
    );

    -- Índices para optimización
    CREATE INDEX IX_explosivos_codigo ON explosivos(codigo);
    CREATE INDEX IX_explosivos_activo ON explosivos(activo);

    PRINT '✅ Tabla EXPLOSIVOS creada';
END
ELSE
BEGIN
    PRINT '⚠️  Tabla EXPLOSIVOS ya existe - omitiendo';
END

-- =========================================================
-- 3. CREAR TABLA STOCK_DIARIO
-- =========================================================

PRINT '📊 Verificando tabla STOCK_DIARIO...';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'stock_diario')
BEGIN
    PRINT '🔄 Creando tabla STOCK_DIARIO...';
    
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

    -- Índices para optimización
    CREATE INDEX IX_stock_diario_fecha ON stock_diario(fecha);
    CREATE INDEX IX_stock_diario_explosivo_id ON stock_diario(explosivo_id);
    CREATE INDEX IX_stock_diario_fecha_explosivo ON stock_diario(fecha, explosivo_id);

    PRINT '✅ Tabla STOCK_DIARIO creada';
END
ELSE
BEGIN
    PRINT '⚠️  Tabla STOCK_DIARIO ya existe - omitiendo';
END

-- =========================================================
-- 4. CREAR TABLA INGRESOS
-- =========================================================

PRINT '📥 Verificando tabla INGRESOS...';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ingresos')
BEGIN
    PRINT '🔄 Creando tabla INGRESOS...';
    
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
        
        CONSTRAINT FK_ingresos_stock_diario 
            FOREIGN KEY (stock_diario_id) REFERENCES stock_diario(id),
            
        CONSTRAINT CK_ingresos_guardia 
            CHECK (guardia IN ('DIA', 'NOCHE')),
            
        CONSTRAINT CK_ingresos_cantidad_positiva 
            CHECK (cantidad > 0)
    );

    -- Índices para optimización
    CREATE INDEX IX_ingresos_explosivo_id ON ingresos(explosivo_id);
    CREATE INDEX IX_ingresos_fecha ON ingresos(fecha_ingreso);
    CREATE INDEX IX_ingresos_stock_diario_id ON ingresos(stock_diario_id);
    CREATE INDEX IX_ingresos_guardia ON ingresos(guardia);

    PRINT '✅ Tabla INGRESOS creada';
END
ELSE
BEGIN
    PRINT '⚠️  Tabla INGRESOS ya existe - omitiendo';
END

-- =========================================================
-- 5. CREAR TABLA SALIDAS
-- =========================================================

PRINT '📤 Verificando tabla SALIDAS...';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'salidas')
BEGIN
    PRINT '🔄 Creando tabla SALIDAS...';
    
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
        
        CONSTRAINT FK_salidas_stock_diario 
            FOREIGN KEY (stock_diario_id) REFERENCES stock_diario(id),
            
        CONSTRAINT CK_salidas_guardia 
            CHECK (guardia IN ('DIA', 'NOCHE')),
            
        CONSTRAINT CK_salidas_cantidad_positiva 
            CHECK (cantidad > 0)
    );

    -- Índices para optimización
    CREATE INDEX IX_salidas_explosivo_id ON salidas(explosivo_id);
    CREATE INDEX IX_salidas_fecha ON salidas(fecha_salida);
    CREATE INDEX IX_salidas_stock_diario_id ON salidas(stock_diario_id);
    CREATE INDEX IX_salidas_guardia ON salidas(guardia);
    CREATE INDEX IX_salidas_labor ON salidas(labor);

    PRINT '✅ Tabla SALIDAS creada';
END
ELSE
BEGIN
    PRINT '⚠️  Tabla SALIDAS ya existe - omitiendo';
END

-- =========================================================
-- 6. CREAR TABLA DEVOLUCIONES
-- =========================================================

PRINT '🔄 Verificando tabla DEVOLUCIONES...';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'devoluciones')
BEGIN
    PRINT '🔄 Creando tabla DEVOLUCIONES...';
    
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
        
        CONSTRAINT FK_devoluciones_stock_diario 
            FOREIGN KEY (stock_diario_id) REFERENCES stock_diario(id),
            
        CONSTRAINT CK_devoluciones_guardia 
            CHECK (guardia IN ('DIA', 'NOCHE')),
            
        CONSTRAINT CK_devoluciones_cantidad_positiva 
            CHECK (cantidad_devuelta > 0)
    );

    -- Índices para optimización
    CREATE INDEX IX_devoluciones_explosivo_id ON devoluciones(explosivo_id);
    CREATE INDEX IX_devoluciones_fecha ON devoluciones(fecha_devolucion);
    CREATE INDEX IX_devoluciones_stock_diario_id ON devoluciones(stock_diario_id);
    CREATE INDEX IX_devoluciones_guardia ON devoluciones(guardia);

    PRINT '✅ Tabla DEVOLUCIONES creada';
END
ELSE
BEGIN
    PRINT '⚠️  Tabla DEVOLUCIONES ya existe - omitiendo';
END

-- =========================================================
-- 7. CREAR TABLA USUARIOS (SI SE NECESITA)
-- =========================================================

PRINT '👤 Verificando tabla USUARIOS...';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'usuarios')
BEGIN
    PRINT '🔄 Creando tabla USUARIOS...';
    
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

    -- Índices
    CREATE INDEX IX_usuarios_username ON usuarios(username);
    CREATE INDEX IX_usuarios_activo ON usuarios(activo);

    PRINT '✅ Tabla USUARIOS creada';
END
ELSE
BEGIN
    PRINT '⚠️  Tabla USUARIOS ya existe - omitiendo';
END

-- =========================================================
-- RESUMEN DE CREACIÓN
-- =========================================================

PRINT '';
PRINT '🎉 ¡SCRIPT DE ESTRUCTURA EJECUTADO EXITOSAMENTE!';
PRINT '';
PRINT '📊 PROCESO COMPLETADO:';
PRINT '   ✅ Base de datos PALLCA verificada/creada';
PRINT '   ✅ Tabla explosivos (maestro de explosivos)';
PRINT '   ✅ Tabla stock_diario (control diario de stock)';
PRINT '   ✅ Tabla ingresos (registros de entrada)';
PRINT '   ✅ Tabla salidas (registros de salida)';
PRINT '   ✅ Tabla devoluciones (registros de devolución)';
PRINT '   ✅ Tabla usuarios (control de acceso)';
PRINT '';
PRINT '🔗 CARACTERÍSTICAS:';
PRINT '   ✅ Foreign keys entre todas las tablas';
PRINT '   ✅ Constraints de integridad';
PRINT '   ✅ Índices de optimización';
PRINT '   ✅ Verificación de existencia (no duplica tablas)';
PRINT '';
PRINT '🚀 SIGUIENTE PASO: Ejecutar script de datos maestros (03_insertar_datos_maestros.sql)';
PRINT '';

GO