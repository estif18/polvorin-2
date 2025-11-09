-- =========================================================
-- VISTAS OPTIMIZADAS PARA AZURE SQL DATABASE - PALLCA
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0 Azure
-- Descripción: Vistas optimizadas específicamente para Azure SQL Database

PRINT '📊 Verificando conexión a PALLCA en Azure...';
SELECT DB_NAME() as BaseDatosActual;

-- =========================================================
-- 1. VISTA STOCK_EXPLOSIVOS_POWERBI
-- =========================================================

PRINT '📊 Creando vista STOCK_EXPLOSIVOS_POWERBI...';

-- Eliminar si existe
IF OBJECT_ID('vw_stock_explosivos_powerbi', 'V') IS NOT NULL
    DROP VIEW vw_stock_explosivos_powerbi;

GO

-- Crear vista
CREATE VIEW vw_stock_explosivos_powerbi AS
SELECT 
    e.id,
    e.codigo,
    e.descripcion,
    e.unidad,
    
    -- Stock inicial (hasta ayer)
    COALESCE(sd_ayer.stock_final, 0) as stock_inicial_hoy,
    
    -- Movimientos de hoy
    COALESCE(ing_hoy.ingresos_hoy, 0) as ingresos_hoy,
    COALESCE(sal_hoy.salidas_hoy, 0) as salidas_hoy,
    COALESCE(dev_hoy.devoluciones_hoy, 0) as devoluciones_hoy,
    
    -- Stock actual calculado
    COALESCE(sd_ayer.stock_final, 0) + 
    COALESCE(ing_hoy.ingresos_hoy, 0) - 
    COALESCE(sal_hoy.salidas_hoy, 0) + 
    COALESCE(dev_hoy.devoluciones_hoy, 0) as stock_actual,
    
    -- Información adicional
    CAST(GETDATE() AS DATE) as fecha_consulta,
    GETDATE() as timestamp_consulta

FROM explosivos e

-- Stock de ayer (último día con registro)
LEFT JOIN (
    SELECT 
        explosivo_id,
        stock_final,
        ROW_NUMBER() OVER (PARTITION BY explosivo_id ORDER BY fecha DESC) as rn
    FROM stock_diario
    WHERE fecha < CAST(GETDATE() AS DATE)
) sd_ayer ON e.id = sd_ayer.explosivo_id AND sd_ayer.rn = 1

-- Ingresos de hoy
LEFT JOIN (
    SELECT 
        explosivo_id,
        SUM(cantidad) as ingresos_hoy
    FROM ingresos
    WHERE CAST(fecha_ingreso AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY explosivo_id
) ing_hoy ON e.id = ing_hoy.explosivo_id

-- Salidas de hoy
LEFT JOIN (
    SELECT 
        explosivo_id,
        SUM(cantidad) as salidas_hoy
    FROM salidas
    WHERE CAST(fecha_salida AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY explosivo_id
) sal_hoy ON e.id = sal_hoy.explosivo_id

-- Devoluciones de hoy
LEFT JOIN (
    SELECT 
        explosivo_id,
        SUM(cantidad_devuelta) as devoluciones_hoy
    FROM devoluciones
    WHERE CAST(fecha_devolucion AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY explosivo_id
) dev_hoy ON e.id = dev_hoy.explosivo_id

WHERE e.activo = 1;

GO

PRINT '✅ Vista vw_stock_explosivos_powerbi creada';

-- =========================================================
-- 2. VISTA STOCK_HISTORICO_COMPLETO
-- =========================================================

PRINT '📈 Creando vista STOCK_HISTORICO_COMPLETO...';

-- Eliminar si existe
IF OBJECT_ID('vw_stock_historico_completo', 'V') IS NOT NULL
    DROP VIEW vw_stock_historico_completo;

GO

-- Crear vista
CREATE VIEW vw_stock_historico_completo AS
WITH stock_calculado AS (
    SELECT 
        e.id as explosivo_id,
        e.codigo,
        e.descripcion,
        e.unidad,
        
        -- Totales históricos (SIN FILTRO DE FECHA)
        COALESCE(SUM(i.cantidad), 0) as total_ingresos,
        COALESCE(SUM(s.cantidad), 0) as total_salidas,
        COALESCE(SUM(d.cantidad_devuelta), 0) as total_devoluciones,
        
        -- Stock calculado total
        COALESCE(SUM(i.cantidad), 0) - 
        COALESCE(SUM(s.cantidad), 0) + 
        COALESCE(SUM(d.cantidad_devuelta), 0) as stock_actual,
        
        -- Últimas fechas de movimiento
        MAX(i.fecha_ingreso) as ultimo_ingreso,
        MAX(s.fecha_salida) as ultima_salida,
        MAX(d.fecha_devolucion) as ultima_devolucion
        
    FROM explosivos e
    LEFT JOIN ingresos i ON e.id = i.explosivo_id
    LEFT JOIN salidas s ON e.id = s.explosivo_id  
    LEFT JOIN devoluciones d ON e.id = d.explosivo_id
    WHERE e.activo = 1
    GROUP BY e.id, e.codigo, e.descripcion, e.unidad
)
SELECT 
    *,
    CASE 
        WHEN stock_actual > 0 THEN 'CON_STOCK'
        WHEN stock_actual = 0 THEN 'SIN_STOCK'
        ELSE 'STOCK_NEGATIVO'
    END as estado_stock,
    
    CASE 
        WHEN ultimo_ingreso IS NULL AND ultima_salida IS NULL AND ultima_devolucion IS NULL 
        THEN 'SIN_MOVIMIENTOS'
        ELSE 'CON_MOVIMIENTOS'
    END as estado_movimientos,
    
    GETDATE() as fecha_consulta
    
FROM stock_calculado;

GO

PRINT '✅ Vista vw_stock_historico_completo creada';

-- =========================================================
-- 3. VISTA AUDITORIA_MOVIMIENTOS
-- =========================================================

PRINT '🔍 Creando vista AUDITORIA_MOVIMIENTOS...';

-- Eliminar si existe
IF OBJECT_ID('vw_auditoria_movimientos', 'V') IS NOT NULL
    DROP VIEW vw_auditoria_movimientos;

GO

-- Crear vista
CREATE VIEW vw_auditoria_movimientos AS
SELECT 
    'INGRESO' as tipo_movimiento,
    i.id as movimiento_id,
    i.explosivo_id,
    e.codigo,
    e.descripcion,
    i.cantidad,
    e.unidad,
    i.fecha_ingreso as fecha_movimiento,
    i.guardia,
    i.numero_vale as numero_vale,
    i.recibido_por as responsable,
    NULL as labor,
    i.observaciones
FROM ingresos i
JOIN explosivos e ON i.explosivo_id = e.id

UNION ALL

SELECT 
    'SALIDA' as tipo_movimiento,
    s.id as movimiento_id,
    s.explosivo_id,
    e.codigo,
    e.descripcion,
    CAST(s.cantidad AS FLOAT) as cantidad,
    e.unidad,
    s.fecha_salida as fecha_movimiento,
    s.guardia,
    NULL as numero_vale,
    s.responsable as responsable,
    s.labor,
    s.observaciones
FROM salidas s
JOIN explosivos e ON s.explosivo_id = e.id

UNION ALL

SELECT 
    'DEVOLUCION' as tipo_movimiento,
    d.id as movimiento_id,
    d.explosivo_id,
    e.codigo,
    e.descripcion,
    d.cantidad_devuelta as cantidad,
    e.unidad,
    d.fecha_devolucion as fecha_movimiento,
    d.guardia,
    NULL as numero_vale,
    d.responsable as responsable,
    d.labor,
    d.observaciones
FROM devoluciones d
JOIN explosivos e ON d.explosivo_id = e.id;

GO

PRINT '✅ Vista vw_auditoria_movimientos creada';

-- =========================================================
-- 4. VISTA STOCK_ACTUAL (Compatibility)
-- =========================================================

PRINT '📊 Creando vista v_stock_actual (compatibilidad)...';

-- Eliminar si existe
IF OBJECT_ID('v_stock_actual', 'V') IS NOT NULL
    DROP VIEW v_stock_actual;

GO

-- Crear vista de compatibilidad
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
WHERE e.activo = 1;

GO

PRINT '✅ Vista v_stock_actual creada';

-- =========================================================
-- RESUMEN FINAL
-- =========================================================

PRINT '';
PRINT '🎉 ¡VISTAS AZURE CREADAS EXITOSAMENTE!';
PRINT '';
PRINT '📊 VISTAS DISPONIBLES:';
PRINT '   ✅ vw_stock_explosivos_powerbi (optimizada para PowerBI)';
PRINT '   ✅ vw_stock_historico_completo (stock total SIN filtros)';
PRINT '   ✅ vw_auditoria_movimientos (auditoría completa)';
PRINT '   ✅ v_stock_actual (compatibilidad con aplicación)';
PRINT '';
PRINT '🚀 SIGUIENTE PASO: Ejecutar 03_insertar_datos_maestros.sql';
PRINT '';