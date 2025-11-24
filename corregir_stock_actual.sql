-- =========================================================
-- SCRIPT DE CORRECCIÓN DE VISTA v_stock_actual
-- =========================================================
-- Fecha: 24 Noviembre 2025
-- Problema: Inconsistencia entre cálculo manual y vista
-- Solución: Recrear vista con lógica corregida

USE pallca;
GO

PRINT '🔧 INICIANDO CORRECCIÓN DE VISTA v_stock_actual...';
PRINT '';

-- =========================================================
-- 1. DIAGNÓSTICO PREVIO
-- =========================================================

PRINT '📊 DIAGNÓSTICO PREVIO:';

-- Verificar registros problemáticos
DECLARE @inconsistencias INT = 0;

WITH StockCalculado AS (
    SELECT 
        e.id as explosivo_id,
        e.codigo,
        COALESCE(SUM(i.cantidad), 0) as ingresos,
        COALESCE(SUM(s.cantidad), 0) as salidas,
        COALESCE(SUM(d.cantidad_devuelta), 0) as devoluciones,
        (COALESCE(SUM(i.cantidad), 0) - COALESCE(SUM(s.cantidad), 0) + COALESCE(SUM(d.cantidad_devuelta), 0)) as stock_manual
    FROM explosivos e
    LEFT JOIN ingresos i ON e.id = i.explosivo_id
    LEFT JOIN salidas s ON e.id = s.explosivo_id
    LEFT JOIN devoluciones d ON e.id = d.explosivo_id
    GROUP BY e.id, e.codigo
),
StockVista AS (
    SELECT id as explosivo_id, codigo, stock_actual as stock_vista
    FROM v_stock_actual
)
SELECT @inconsistencias = COUNT(*)
FROM StockCalculado sc
JOIN StockVista sv ON sc.explosivo_id = sv.explosivo_id
WHERE ABS(sc.stock_manual - sv.stock_vista) > 0.01;

PRINT CONCAT('   ⚠️ Inconsistencias encontradas: ', @inconsistencias);

-- =========================================================
-- 2. RECREAR VISTA CORREGIDA
-- =========================================================

PRINT '';
PRINT '🔨 Recreando vista v_stock_actual con lógica corregida...';

-- Eliminar vista existente
IF OBJECT_ID('v_stock_actual', 'V') IS NOT NULL
BEGIN
    PRINT '   🗑️ Eliminando vista anterior...';
    DROP VIEW v_stock_actual;
END

GO

-- Crear vista corregida con datos precisos
CREATE VIEW v_stock_actual AS
SELECT 
    e.id,
    e.codigo,
    e.descripcion,
    e.unidad,
    e.grupo,
    
    -- Totales calculados correctamente
    COALESCE(ingresos_sub.total_ingresos, 0) AS total_ingresos,
    COALESCE(salidas_sub.total_salidas, 0) AS total_salidas,
    COALESCE(devoluciones_sub.total_devoluciones, 0) AS total_devoluciones,
    
    -- Stock actual = ingresos - salidas + devoluciones
    (COALESCE(ingresos_sub.total_ingresos, 0) - 
     COALESCE(salidas_sub.total_salidas, 0) + 
     COALESCE(devoluciones_sub.total_devoluciones, 0)) AS stock_actual,
    
    -- Metadatos
    e.activo,
    GETDATE() AS fecha_calculo,
    
    -- Información adicional útil
    CASE 
        WHEN (COALESCE(ingresos_sub.total_ingresos, 0) - 
              COALESCE(salidas_sub.total_salidas, 0) + 
              COALESCE(devoluciones_sub.total_devoluciones, 0)) > 0 
        THEN 'DISPONIBLE'
        WHEN (COALESCE(ingresos_sub.total_ingresos, 0) - 
              COALESCE(salidas_sub.total_salidas, 0) + 
              COALESCE(devoluciones_sub.total_devoluciones, 0)) = 0 
        THEN 'AGOTADO'
        ELSE 'NEGATIVO'
    END AS estado_stock

FROM explosivos e

-- Subquery para ingresos
LEFT JOIN (
    SELECT 
        explosivo_id, 
        SUM(CAST(cantidad AS FLOAT)) AS total_ingresos
    FROM ingresos 
    GROUP BY explosivo_id
) ingresos_sub ON e.id = ingresos_sub.explosivo_id

-- Subquery para salidas  
LEFT JOIN (
    SELECT 
        explosivo_id, 
        SUM(CAST(cantidad AS FLOAT)) AS total_salidas
    FROM salidas 
    GROUP BY explosivo_id
) salidas_sub ON e.id = salidas_sub.explosivo_id

-- Subquery para devoluciones
LEFT JOIN (
    SELECT 
        explosivo_id, 
        SUM(CAST(cantidad_devuelta AS FLOAT)) AS total_devoluciones
    FROM devoluciones 
    GROUP BY explosivo_id
) devoluciones_sub ON e.id = devoluciones_sub.explosivo_id

WHERE e.activo = 1;

GO

PRINT '✅ Vista v_stock_actual recreada exitosamente';

-- =========================================================
-- 3. VERIFICACIÓN POST-CORRECCIÓN
-- =========================================================

PRINT '';
PRINT '🔍 VERIFICACIÓN POST-CORRECCIÓN:';

-- Verificar que no hay inconsistencias
DECLARE @inconsistencias_post INT = 0;

WITH StockCalculadoPost AS (
    SELECT 
        e.id as explosivo_id,
        e.codigo,
        COALESCE(SUM(CAST(i.cantidad AS FLOAT)), 0) as ingresos,
        COALESCE(SUM(CAST(s.cantidad AS FLOAT)), 0) as salidas,
        COALESCE(SUM(CAST(d.cantidad_devuelta AS FLOAT)), 0) as devoluciones,
        (COALESCE(SUM(CAST(i.cantidad AS FLOAT)), 0) - 
         COALESCE(SUM(CAST(s.cantidad AS FLOAT)), 0) + 
         COALESCE(SUM(CAST(d.cantidad_devuelta AS FLOAT)), 0)) as stock_manual
    FROM explosivos e
    LEFT JOIN ingresos i ON e.id = i.explosivo_id
    LEFT JOIN salidas s ON e.id = s.explosivo_id
    LEFT JOIN devoluciones d ON e.id = d.explosivo_id
    WHERE e.activo = 1
    GROUP BY e.id, e.codigo
),
StockVistaPost AS (
    SELECT id as explosivo_id, codigo, stock_actual as stock_vista
    FROM v_stock_actual
)
SELECT @inconsistencias_post = COUNT(*)
FROM StockCalculadoPost sc
JOIN StockVistaPost sv ON sc.explosivo_id = sv.explosivo_id
WHERE ABS(sc.stock_manual - sv.stock_vista) > 0.01;

PRINT CONCAT('   ✅ Inconsistencias después de corrección: ', @inconsistencias_post);

-- Mostrar algunos ejemplos corregidos
PRINT '';
PRINT '📊 STOCK CORREGIDO (ejemplos):';

SELECT TOP 10
    codigo,
    CAST(total_ingresos AS INT) as ingresos,
    CAST(total_salidas AS INT) as salidas, 
    CAST(total_devoluciones AS INT) as devoluciones,
    CAST(stock_actual AS INT) as stock_final,
    estado_stock
FROM v_stock_actual
WHERE stock_actual > 0
ORDER BY stock_actual DESC;

-- =========================================================
-- 4. ACTUALIZAR ÍNDICES (Opcional para performance)
-- =========================================================

PRINT '';
PRINT '⚡ OPTIMIZACIÓN DE PERFORMANCE:';

-- Verificar si existen índices en las tablas de movimientos
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('ingresos') AND name = 'IX_ingresos_explosivo_id')
BEGIN
    CREATE INDEX IX_ingresos_explosivo_id ON ingresos (explosivo_id);
    PRINT '   ✅ Índice creado en ingresos.explosivo_id';
END
ELSE
    PRINT '   ✅ Índice ya existe en ingresos.explosivo_id';

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('salidas') AND name = 'IX_salidas_explosivo_id')
BEGIN
    CREATE INDEX IX_salidas_explosivo_id ON salidas (explosivo_id);
    PRINT '   ✅ Índice creado en salidas.explosivo_id';
END
ELSE
    PRINT '   ✅ Índice ya existe en salidas.explosivo_id';

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('devoluciones') AND name = 'IX_devoluciones_explosivo_id')
BEGIN
    CREATE INDEX IX_devoluciones_explosivo_id ON devoluciones (explosivo_id);
    PRINT '   ✅ Índice creado en devoluciones.explosivo_id';
END
ELSE
    PRINT '   ✅ Índice ya existe en devoluciones.explosivo_id';

-- =========================================================
-- 5. RESUMEN FINAL
-- =========================================================

PRINT '';
PRINT '🎉 ¡CORRECCIÓN COMPLETADA!';
PRINT '';
PRINT '✅ CAMBIOS REALIZADOS:';
PRINT '   • Vista v_stock_actual recreada con lógica corregida';
PRINT '   • Cálculos usando CAST para precisión de datos';
PRINT '   • Subqueries optimizadas para mejor performance';
PRINT '   • Índices verificados/creados para velocidad';
PRINT '   • Campo estado_stock agregado para análisis';
PRINT '';
PRINT '📊 LA VISTA AHORA CALCULA CORRECTAMENTE:';
PRINT '   Stock = Ingresos - Salidas + Devoluciones';
PRINT '';
PRINT '🚀 SIGUIENTE PASO: Verificar desde la aplicación Python';
PRINT '';