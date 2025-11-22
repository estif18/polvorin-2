-- =========================================================
-- VISTA PARA POWER BI: STOCK DIARIO SIMPLIFICADA
-- =========================================================

USE pallca;
GO

PRINT '📊 Creando vista simplificada para Power BI: Stock Diario...';

-- Eliminar vista si existe
IF OBJECT_ID('vw_stock_diario_powerbi', 'V') IS NOT NULL
    DROP VIEW vw_stock_diario_powerbi;
GO

CREATE VIEW vw_stock_diario_powerbi AS
WITH movimientos_diarios AS (
    -- Ingresos por día y guardia
    SELECT 
        explosivo_id,
        CAST(fecha_ingreso AS DATE) as fecha,
        guardia,
        SUM(cantidad) as total_ingresos
    FROM ingresos 
    GROUP BY explosivo_id, CAST(fecha_ingreso AS DATE), guardia
),
salidas_diarias AS (
    -- Salidas por día y guardia
    SELECT 
        explosivo_id,
        CAST(fecha_salida AS DATE) as fecha,
        guardia,
        SUM(cantidad) as total_salidas
    FROM salidas 
    GROUP BY explosivo_id, CAST(fecha_salida AS DATE), guardia
),
devoluciones_diarias AS (
    -- Devoluciones por día y guardia
    SELECT 
        explosivo_id,
        CAST(fecha_devolucion AS DATE) as fecha,
        guardia,
        SUM(cantidad_devuelta) as total_devoluciones
    FROM devoluciones 
    GROUP BY explosivo_id, CAST(fecha_devolucion AS DATE), guardia
),
labores_resumen AS (
    -- Resumen de labores por día y guardia
    SELECT 
        explosivo_id,
        CAST(fecha_salida AS DATE) as fecha,
        guardia,
        COUNT(DISTINCT ISNULL(labor, 'Sin Labor')) as cantidad_labores,
        STRING_AGG(
            CONCAT(ISNULL(labor, 'Sin Labor'), ' (', CAST(SUM(cantidad) AS VARCHAR), ')'), 
            '; '
        ) WITHIN GROUP (ORDER BY SUM(cantidad) DESC) as detalle_labores
    FROM salidas
    GROUP BY explosivo_id, CAST(fecha_salida AS DATE), guardia
)
SELECT 
    -- Identificadores
    sd.id as stock_diario_id,
    e.id as explosivo_id,
    e.codigo,
    e.descripcion,
    e.unidad,
    e.grupo,
    
    -- Información temporal
    sd.fecha,
    sd.guardia as turno,
    
    -- Stocks
    sd.stock_inicial,
    sd.stock_final,
    
    -- Movimientos del turno específico
    COALESCE(ing.total_ingresos, 0) as total_ingresos,
    COALESCE(sal.total_salidas, 0) as total_salidas,
    COALESCE(dev.total_devoluciones, 0) as total_devoluciones,
    
    -- Cálculos
    (sd.stock_final - sd.stock_inicial) as diferencia,
    (sd.stock_inicial + COALESCE(ing.total_ingresos, 0) - COALESCE(sal.total_salidas, 0) + COALESCE(dev.total_devoluciones, 0)) as stock_calculado,
    
    -- Clasificación de diferencia
    CASE 
        WHEN (sd.stock_final - sd.stock_inicial) > 0 THEN 'POSITIVA'
        WHEN (sd.stock_final - sd.stock_inicial) < 0 THEN 'NEGATIVA'
        ELSE 'CERO'
    END as tipo_diferencia,
    
    -- Información adicional
    sd.responsable_guardia,
    sd.observaciones,
    
    -- Detalle de labores
    COALESCE(lab.detalle_labores, 'Sin labores') as labores_resumen,
    COALESCE(lab.cantidad_labores, 0) as cantidad_labores,
    
    -- Indicadores para filtros de Power BI
    CASE WHEN e.activo = 1 THEN 'ACTIVO' ELSE 'INACTIVO' END as estado_explosivo,
    
    -- Información de tiempo para Power BI
    YEAR(sd.fecha) as anio,
    MONTH(sd.fecha) as mes,
    DAY(sd.fecha) as dia,
    DATENAME(WEEKDAY, sd.fecha) as dia_semana,
    DATENAME(MONTH, sd.fecha) as nombre_mes,
    
    -- Período para agrupaciones
    FORMAT(sd.fecha, 'yyyy-MM') as periodo_mes,
    FORMAT(sd.fecha, 'yyyy-\QQ') as periodo_trimestre,
    
    -- Timestamps para auditoría
    sd.fecha_registro as stock_diario_creado,
    GETDATE() as fecha_consulta

FROM stock_diario sd
INNER JOIN explosivos e ON sd.explosivo_id = e.id
LEFT JOIN movimientos_diarios ing ON sd.explosivo_id = ing.explosivo_id AND sd.fecha = ing.fecha AND sd.guardia = ing.guardia
LEFT JOIN salidas_diarias sal ON sd.explosivo_id = sal.explosivo_id AND sd.fecha = sal.fecha AND sd.guardia = sal.guardia
LEFT JOIN devoluciones_diarias dev ON sd.explosivo_id = dev.explosivo_id AND sd.fecha = dev.fecha AND sd.guardia = dev.guardia
LEFT JOIN labores_resumen lab ON sd.explosivo_id = lab.explosivo_id AND sd.fecha = lab.fecha AND sd.guardia = lab.guardia
WHERE e.activo = 1;

GO

PRINT '✅ Vista vw_stock_diario_powerbi creada exitosamente';

-- Verificar que la vista funciona
PRINT '🔍 Verificando vista con datos de prueba...';

SELECT TOP 5 
    codigo,
    descripcion,
    fecha,
    turno,
    stock_inicial,
    total_ingresos,
    total_salidas,
    total_devoluciones,
    stock_final,
    diferencia,
    tipo_diferencia,
    cantidad_labores
FROM vw_stock_diario_powerbi
ORDER BY fecha DESC, codigo;

PRINT '✅ Vista verificada correctamente';