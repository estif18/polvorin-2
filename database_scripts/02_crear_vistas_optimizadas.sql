-- =========================================================
-- SCRIPT DE VISTAS OPTIMIZADAS PARA POWERBI Y REPORTES
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0
-- Descripción: Vistas optimizadas para consultas rápidas,
--              reportes y integración con PowerBI

USE pallca;
GO

-- =========================================================
-- 1. VISTA STOCK_EXPLOSIVOS_POWERBI
-- =========================================================

PRINT '📊 Creando vista STOCK_EXPLOSIVOS_POWERBI...';
GO

CREATE OR ALTER VIEW vw_stock_explosivos_powerbi AS
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

PRINT '✅ Vista STOCK_EXPLOSIVOS_POWERBI creada';

-- =========================================================
-- 2. VISTA MOVIMIENTOS_DIARIOS
-- =========================================================

PRINT '📅 Creando vista MOVIMIENTOS_DIARIOS...';
GO

CREATE OR ALTER VIEW vw_movimientos_diarios AS
SELECT 
    CAST(fecha_mov AS DATE) as fecha,
    explosivo_id,
    e.codigo,
    e.descripcion,
    e.unidad,
    SUM(ingresos) as total_ingresos,
    SUM(salidas) as total_salidas,
    SUM(devoluciones) as total_devoluciones,
    SUM(ingresos) - SUM(salidas) + SUM(devoluciones) as movimiento_neto
FROM (
    -- Ingresos
    SELECT 
        CAST(fecha_ingreso AS DATE) as fecha_mov,
        explosivo_id,
        cantidad as ingresos,
        0 as salidas,
        0 as devoluciones
    FROM ingresos
    
    UNION ALL
    
    -- Salidas (como negativos para el movimiento neto)
    SELECT 
        CAST(fecha_salida AS DATE) as fecha_mov,
        explosivo_id,
        0 as ingresos,
        cantidad as salidas,
        0 as devoluciones
    FROM salidas
    
    UNION ALL
    
    -- Devoluciones
    SELECT 
        CAST(fecha_devolucion AS DATE) as fecha_mov,
        explosivo_id,
        0 as ingresos,
        0 as salidas,
        cantidad_devuelta as devoluciones
    FROM devoluciones
) movimientos
JOIN explosivos e ON movimientos.explosivo_id = e.id
WHERE e.activo = 1
GROUP BY CAST(fecha_mov AS DATE), explosivo_id, e.codigo, e.descripcion, e.unidad;
GO

PRINT '✅ Vista MOVIMIENTOS_DIARIOS creada';

-- =========================================================
-- 3. VISTA STOCK_HISTORICO_COMPLETO
-- =========================================================

PRINT '📈 Creando vista STOCK_HISTORICO_COMPLETO...';
GO

CREATE OR ALTER VIEW vw_stock_historico_completo AS
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

PRINT '✅ Vista STOCK_HISTORICO_COMPLETO creada';

-- =========================================================
-- 4. VISTA RESUMEN_MENSUAL
-- =========================================================

PRINT '📆 Creando vista RESUMEN_MENSUAL...';
GO

CREATE OR ALTER VIEW vw_resumen_mensual AS
SELECT 
    YEAR(fecha) as anio,
    MONTH(fecha) as mes,
    DATENAME(MONTH, fecha) + ' ' + CAST(YEAR(fecha) AS VARCHAR) as mes_nombre,
    explosivo_id,
    codigo,
    descripcion,
    unidad,
    SUM(total_ingresos) as ingresos_mes,
    SUM(total_salidas) as salidas_mes,
    SUM(total_devoluciones) as devoluciones_mes,
    SUM(total_ingresos) - SUM(total_salidas) + SUM(total_devoluciones) as movimiento_neto_mes,
    COUNT(*) as dias_con_movimiento
FROM vw_movimientos_diarios
GROUP BY 
    YEAR(fecha), 
    MONTH(fecha), 
    DATENAME(MONTH, fecha) + ' ' + CAST(YEAR(fecha) AS VARCHAR),
    explosivo_id, 
    codigo, 
    descripcion, 
    unidad;
GO

PRINT '✅ Vista RESUMEN_MENSUAL creada';

-- =========================================================
-- 5. VISTA ALERTAS_STOCK
-- =========================================================

PRINT '⚠️  Creando vista ALERTAS_STOCK...';
GO

CREATE OR ALTER VIEW vw_alertas_stock AS
SELECT 
    explosivo_id,
    codigo,
    descripcion,
    unidad,
    stock_actual,
    CASE 
        WHEN stock_actual < 0 THEN 'CRITICO_NEGATIVO'
        WHEN stock_actual = 0 THEN 'SIN_STOCK'
        WHEN stock_actual <= 100 THEN 'STOCK_BAJO'
        WHEN stock_actual <= 500 THEN 'STOCK_MEDIO'
        ELSE 'STOCK_OK'
    END as nivel_alerta,
    
    CASE 
        WHEN stock_actual < 0 THEN '🔴 Stock negativo - Revisar urgente'
        WHEN stock_actual = 0 THEN '⚠️ Sin stock disponible'
        WHEN stock_actual <= 100 THEN '🟡 Stock bajo - Considerar reposición'
        WHEN stock_actual <= 500 THEN '🟢 Stock medio'
        ELSE '✅ Stock adecuado'
    END as mensaje_alerta,
    
    estado_stock,
    fecha_consulta
    
FROM vw_stock_historico_completo
WHERE estado_stock IN ('SIN_STOCK', 'STOCK_NEGATIVO') 
   OR stock_actual <= 500;
GO

PRINT '✅ Vista ALERTAS_STOCK creada';

-- =========================================================
-- 6. VISTA AUDITORIA_MOVIMIENTOS
-- =========================================================

PRINT '🔍 Creando vista AUDITORIA_MOVIMIENTOS...';
GO

CREATE OR ALTER VIEW vw_auditoria_movimientos AS
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
    i.observaciones,
    i.fecha_creacion
FROM ingresos i
JOIN explosivos e ON i.explosivo_id = e.id

UNION ALL

SELECT 
    'SALIDA' as tipo_movimiento,
    s.id as movimiento_id,
    s.explosivo_id,
    e.codigo,
    e.descripcion,
    s.cantidad,
    e.unidad,
    s.fecha_salida as fecha_movimiento,
    s.guardia,
    s.numero_vale as numero_vale,
    s.solicitado_por as responsable,
    s.labor,
    s.observaciones,
    s.fecha_creacion
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
    d.numero_vale_original as numero_vale,
    d.devuelto_por as responsable,
    NULL as labor,
    d.observaciones,
    d.fecha_creacion
FROM devoluciones d
JOIN explosivos e ON d.explosivo_id = e.id;
GO

PRINT '✅ Vista AUDITORIA_MOVIMIENTOS creada';

-- =========================================================
-- RESUMEN DE VISTAS CREADAS
-- =========================================================

PRINT '';
PRINT '🎉 ¡VISTAS CREADAS EXITOSAMENTE!';
PRINT '';
PRINT '📊 VISTAS DISPONIBLES:';
PRINT '   ✅ vw_stock_explosivos_powerbi (optimizada para PowerBI)';
PRINT '   ✅ vw_movimientos_diarios (resumen por día)';
PRINT '   ✅ vw_stock_historico_completo (stock total SIN filtros de fecha)';
PRINT '   ✅ vw_resumen_mensual (agregaciones mensuales)';
PRINT '   ✅ vw_alertas_stock (alertas de stock bajo)';
PRINT '   ✅ vw_auditoria_movimientos (auditoría completa)';
PRINT '';
PRINT '🚀 CARACTERÍSTICAS:';
PRINT '   ✅ Sin limitantes de fecha en cálculos principales';
PRINT '   ✅ Optimizadas para consultas rápidas';
PRINT '   ✅ Compatibles con PowerBI y reportes';
PRINT '   ✅ Incluyen auditoría y alertas';
PRINT '';

GO