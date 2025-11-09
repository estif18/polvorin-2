-- Script para actualizar vistas de stock incluyendo devoluciones
-- Ejecutar este script en SQL Server Management Studio o Azure Data Studio

-- 1. Eliminar vista stock_actual si existe
IF OBJECT_ID('stock_actual', 'V') IS NOT NULL
    DROP VIEW stock_actual;
GO

-- 2. Crear nueva vista stock_actual con devoluciones incluidas
CREATE VIEW stock_actual AS
SELECT 
    e.codigo,
    e.descripcion,
    e.unidad,
    ISNULL(ingresos.total, 0) as total_ingresos,
    ISNULL(salidas.total, 0) as total_salidas,
    ISNULL(devoluciones.total, 0) as total_devoluciones,
    (ISNULL(ingresos.total, 0) - ISNULL(salidas.total, 0) + ISNULL(devoluciones.total, 0)) as stock_final
FROM explosivos e
LEFT JOIN (
    SELECT explosivo_id, SUM(cantidad) as total
    FROM ingresos
    GROUP BY explosivo_id
) ingresos ON e.id = ingresos.explosivo_id
LEFT JOIN (
    SELECT explosivo_id, SUM(cantidad) as total
    FROM salidas
    GROUP BY explosivo_id
) salidas ON e.id = salidas.explosivo_id
LEFT JOIN (
    SELECT explosivo_id, SUM(cantidad_devuelta) as total
    FROM devoluciones
    WHERE explosivo_id IS NOT NULL
    GROUP BY explosivo_id
) devoluciones ON e.id = devoluciones.explosivo_id;
GO

-- 3. Eliminar vista stock_por_explosivo si existe
IF OBJECT_ID('stock_por_explosivo', 'V') IS NOT NULL
    DROP VIEW stock_por_explosivo;
GO

-- 4. Crear nueva vista stock_por_explosivo con devoluciones incluidas
CREATE VIEW stock_por_explosivo AS
SELECT 
    e.id as explosivo_id,
    e.codigo,
    e.descripcion,
    e.unidad,
    e.grupo,
    ISNULL(ingresos.total, 0) as total_ingresos,
    ISNULL(salidas.total, 0) as total_salidas,
    ISNULL(devoluciones.total, 0) as total_devoluciones,
    (ISNULL(ingresos.total, 0) - ISNULL(salidas.total, 0) + ISNULL(devoluciones.total, 0)) as stock_actual
FROM explosivos e
LEFT JOIN (
    SELECT explosivo_id, SUM(cantidad) as total
    FROM ingresos
    GROUP BY explosivo_id
) ingresos ON e.id = ingresos.explosivo_id
LEFT JOIN (
    SELECT explosivo_id, SUM(cantidad) as total
    FROM salidas
    GROUP BY explosivo_id
) salidas ON e.id = salidas.explosivo_id
LEFT JOIN (
    SELECT explosivo_id, SUM(cantidad_devuelta) as total
    FROM devoluciones
    WHERE explosivo_id IS NOT NULL
    GROUP BY explosivo_id
) devoluciones ON e.id = devoluciones.explosivo_id;
GO

-- 5. Verificar que las vistas fueron creadas correctamente
PRINT 'Verificando vista stock_actual:';
SELECT TOP 5 codigo, total_ingresos, total_salidas, total_devoluciones, stock_final 
FROM stock_actual 
WHERE codigo IN ('0303063', '0303064', '0303065', '0303071', '0303072')
ORDER BY codigo;

PRINT 'Verificando vista stock_por_explosivo:';
SELECT TOP 5 codigo, total_ingresos, total_salidas, total_devoluciones, stock_actual 
FROM stock_por_explosivo 
WHERE codigo IN ('0303063', '0303064', '0303065', '0303071', '0303072')
ORDER BY codigo;

PRINT 'Vistas actualizadas exitosamente!';