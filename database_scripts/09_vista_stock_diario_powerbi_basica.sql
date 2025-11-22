-- =========================================================
-- VISTA PARA POWER BI: STOCK DIARIO BÁSICA
-- =========================================================

USE pallca;
GO

PRINT '📊 Creando vista básica para Power BI: Stock Diario...';

-- Eliminar vista si existe
IF OBJECT_ID('vw_stock_diario_powerbi', 'V') IS NOT NULL
    DROP VIEW vw_stock_diario_powerbi;
GO

CREATE VIEW vw_stock_diario_powerbi AS
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
    
    -- Movimientos del turno específico (subconsultas individuales)
    COALESCE((
        SELECT SUM(cantidad) 
        FROM ingresos 
        WHERE explosivo_id = sd.explosivo_id 
        AND CAST(fecha_ingreso AS DATE) = sd.fecha 
        AND guardia = sd.guardia
    ), 0) as total_ingresos,
    
    COALESCE((
        SELECT SUM(cantidad)
        FROM salidas
        WHERE explosivo_id = sd.explosivo_id
        AND CAST(fecha_salida AS DATE) = sd.fecha
        AND guardia = sd.guardia
    ), 0) as total_salidas,
    
    COALESCE((
        SELECT SUM(cantidad_devuelta)
        FROM devoluciones
        WHERE explosivo_id = sd.explosivo_id
        AND CAST(fecha_devolucion AS DATE) = sd.fecha
        AND guardia = sd.guardia
    ), 0) as total_devoluciones,
    
    -- Cálculos
    (sd.stock_final - sd.stock_inicial) as diferencia,
    
    -- Clasificación de diferencia
    CASE 
        WHEN (sd.stock_final - sd.stock_inicial) > 0 THEN 'POSITIVA'
        WHEN (sd.stock_final - sd.stock_inicial) < 0 THEN 'NEGATIVA'
        ELSE 'CERO'
    END as tipo_diferencia,
    
    -- Información adicional
    sd.responsable_guardia,
    sd.observaciones,
    
    -- Conteo simple de labores
    COALESCE((
        SELECT COUNT(DISTINCT ISNULL(labor, 'Sin Labor'))
        FROM salidas
        WHERE explosivo_id = sd.explosivo_id
        AND CAST(fecha_salida AS DATE) = sd.fecha
        AND guardia = sd.guardia
    ), 0) as cantidad_labores,
    
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
    cantidad_labores,
    anio,
    mes,
    periodo_mes
FROM vw_stock_diario_powerbi
ORDER BY fecha DESC, codigo;

PRINT '✅ Vista verificada correctamente';