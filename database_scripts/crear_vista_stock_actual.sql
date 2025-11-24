-- Script para crear vista v_stock_actual
-- Esta vista es crítica para el funcionamiento del sistema

-- 1. Eliminar vista si existe
IF OBJECT_ID('v_stock_actual', 'V') IS NOT NULL
    DROP VIEW v_stock_actual;
GO

-- 2. Crear vista v_stock_actual
CREATE VIEW v_stock_actual AS
WITH stock_calculado AS (
    SELECT 
        e.id,
        e.codigo,
        e.descripcion,
        e.unidad,
        e.grupo,
        
        -- Calcular stock usando movimientos
        ISNULL(
            (SELECT SUM(CAST(i.cantidad AS DECIMAL(10,2))) 
             FROM ingresos i 
             WHERE i.explosivo_id = e.id), 0
        ) - ISNULL(
            (SELECT SUM(CAST(s.cantidad AS DECIMAL(10,2))) 
             FROM salidas s 
             WHERE s.explosivo_id = e.id), 0
        ) + ISNULL(
            (SELECT SUM(CAST(d.cantidad_devuelta AS DECIMAL(10,2))) 
             FROM devoluciones d 
             WHERE d.explosivo_id = e.id), 0
        ) AS stock_actual
    FROM explosivos e
)
SELECT 
    id,
    codigo,
    descripcion,
    unidad,
    CASE 
        WHEN stock_actual < 0 THEN 0 
        ELSE CAST(stock_actual AS INT)
    END AS stock_actual,
    grupo,
    GETDATE() AS fecha_calculo
FROM stock_calculado;
GO

-- 3. Verificar que la vista se creó correctamente
SELECT COUNT(*) AS total_explosivos FROM v_stock_actual;

-- 4. Mostrar primeros registros
SELECT TOP 5 
    codigo,
    descripcion,
    stock_actual,
    grupo
FROM v_stock_actual
ORDER BY codigo;

PRINT 'Vista v_stock_actual creada exitosamente';