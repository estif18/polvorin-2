-- =========================================================
-- SCRIPT PARA CORREGIR ESTRUCTURA DE PALLCA
-- =========================================================
-- Fecha: Noviembre 2025
-- Descripción: Agregar columnas faltantes y corregir vistas

USE pallca;
GO

-- Verificar estructura actual de explosivos
PRINT '🔍 Verificando estructura actual de explosivos...';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'explosivos'
ORDER BY ORDINAL_POSITION;

-- Agregar columna 'activo' a explosivos si no existe
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'explosivos' AND COLUMN_NAME = 'activo')
BEGIN
    PRINT '🔧 Agregando columna activo a explosivos...';
    ALTER TABLE explosivos ADD activo BIT NOT NULL DEFAULT 1;
    PRINT '✅ Columna activo agregada';
END
ELSE
BEGIN
    PRINT '⚠️  Columna activo ya existe en explosivos';
END

-- Agregar columna 'fecha_creacion' a explosivos si no existe
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'explosivos' AND COLUMN_NAME = 'fecha_creacion')
BEGIN
    PRINT '🔧 Agregando columna fecha_creacion a explosivos...';
    ALTER TABLE explosivos ADD fecha_creacion DATETIME2 NOT NULL DEFAULT GETDATE();
    PRINT '✅ Columna fecha_creacion agregada';
END
ELSE
BEGIN
    PRINT '⚠️  Columna fecha_creacion ya existe en explosivos';
END

-- Verificar que las columnas fueron agregadas
PRINT '🔍 Verificando estructura después de cambios...';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'explosivos'
ORDER BY ORDINAL_POSITION;

GO

-- Recrear la vista v_stock_actual solo si las columnas existen
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'explosivos' AND COLUMN_NAME = 'activo')
BEGIN
    PRINT '🔧 Recreando vista v_stock_actual...';
    
    -- Eliminar vista si existe
    IF OBJECT_ID('v_stock_actual', 'V') IS NOT NULL
        DROP VIEW v_stock_actual;
    
    -- Crear vista nueva
    EXEC('
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
        e.activo,
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
    ) d ON e.id = d.explosivo_id
    WHERE e.activo = 1');
    
    PRINT '✅ Vista v_stock_actual creada correctamente';
END
ELSE
BEGIN
    PRINT '❌ No se puede crear la vista: falta la columna activo';
END

-- Agregar índice en la columna activo si existe
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'explosivos' AND COLUMN_NAME = 'activo')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_explosivos_activo' AND object_id = OBJECT_ID('explosivos'))
    BEGIN
        CREATE INDEX IX_explosivos_activo ON explosivos(activo);
        PRINT '✅ Índice IX_explosivos_activo creado';
    END
    ELSE
    BEGIN
        PRINT '⚠️  Índice IX_explosivos_activo ya existe';
    END
END

PRINT '';
PRINT '🎉 ¡SCRIPT DE CORRECCIÓN COMPLETADO!';
PRINT '';

GO