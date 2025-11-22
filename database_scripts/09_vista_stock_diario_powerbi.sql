-- =========================================================
-- VISTA PARA POWER BI: STOCK DIARIO COMPLETO
-- =========================================================
-- Fecha: Noviembre 2025
-- Descripción: Vista que replica la funcionalidad de stock diario
--              de la aplicación web para usar en Power BI

USE pallca;
GO

PRINT '📊 Creando vista para Power BI: Stock Diario...';

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
    
    -- Movimientos del turno específico
    COALESCE((
        SELECT SUM(i.cantidad) 
        FROM ingresos i 
        WHERE i.explosivo_id = e.id 
        AND CAST(i.fecha_ingreso AS DATE) = sd.fecha 
        AND i.guardia = sd.guardia
    ), 0) as total_ingresos,
    
    COALESCE((
        SELECT SUM(s.cantidad)
        FROM salidas s
        WHERE s.explosivo_id = e.id
        AND CAST(s.fecha_salida AS DATE) = sd.fecha
        AND s.guardia = sd.guardia
    ), 0) as total_salidas,
    
    COALESCE((
        SELECT SUM(d.cantidad_devuelta)
        FROM devoluciones d
        WHERE d.explosivo_id = e.id
        AND CAST(d.fecha_devolucion AS DATE) = sd.fecha
        AND d.guardia = sd.guardia
    ), 0) as total_devoluciones,
    
    -- Cálculo de diferencia
    (sd.stock_final - sd.stock_inicial) as diferencia,
    
    -- Stock calculado vs registrado
    (sd.stock_inicial + 
     COALESCE((SELECT SUM(i.cantidad) FROM ingresos i WHERE i.explosivo_id = e.id AND CAST(i.fecha_ingreso AS DATE) = sd.fecha AND i.guardia = sd.guardia), 0) - 
     COALESCE((SELECT SUM(s.cantidad) FROM salidas s WHERE s.explosivo_id = e.id AND CAST(s.fecha_salida AS DATE) = sd.fecha AND s.guardia = sd.guardia), 0) + 
     COALESCE((SELECT SUM(d.cantidad_devuelta) FROM devoluciones d WHERE d.explosivo_id = e.id AND CAST(d.fecha_devolucion AS DATE) = sd.fecha AND d.guardia = sd.guardia), 0)
    ) as stock_calculado,
    
    -- Clasificación de diferencia
    CASE 
        WHEN (sd.stock_final - sd.stock_inicial) > 0 THEN 'POSITIVA'
        WHEN (sd.stock_final - sd.stock_inicial) < 0 THEN 'NEGATIVA'
        ELSE 'CERO'
    END as tipo_diferencia,
    
    -- Información adicional
    sd.responsable_guardia,
    sd.labor,
    sd.observaciones,
    
    -- Detalle de labores del turno (para Power BI puede ser útil como texto)
    (
        SELECT STRING_AGG(s.labor + ' (' + CAST(SUM(s.cantidad) AS VARCHAR) + ')', '; ')
        FROM salidas s
        WHERE s.explosivo_id = e.id
        AND CAST(s.fecha_salida AS DATE) = sd.fecha
        AND s.guardia = sd.guardia
        AND s.labor IS NOT NULL
        GROUP BY s.labor
    ) as labores_resumen,
    
    -- Conteo de labores diferentes
    (
        SELECT COUNT(DISTINCT s.labor)
        FROM salidas s
        WHERE s.explosivo_id = e.id
        AND CAST(s.fecha_salida AS DATE) = sd.fecha
        AND s.guardia = sd.guardia
        AND s.labor IS NOT NULL
    ) as cantidad_labores,
    
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
    sd.fecha_creacion as stock_diario_creado,
    GETDATE() as fecha_consulta

FROM stock_diario sd
INNER JOIN explosivos e ON sd.explosivo_id = e.id
WHERE e.activo = 1;

GO

PRINT '✅ Vista vw_stock_diario_powerbi creada exitosamente';

-- Crear índices para optimizar consultas de Power BI
PRINT '🚀 Creando índices para Power BI...';

-- Los índices en vistas no son directos, pero podemos recomendar índices en las tablas base
PRINT 'Recomendaciones de índices para las tablas base:';
PRINT '- CREATE INDEX IX_stock_diario_fecha_guardia ON stock_diario(fecha, guardia);';
PRINT '- CREATE INDEX IX_ingresos_explosivo_fecha ON ingresos(explosivo_id, fecha_ingreso);';
PRINT '- CREATE INDEX IX_salidas_explosivo_fecha ON salidas(explosivo_id, fecha_salida);';
PRINT '- CREATE INDEX IX_devoluciones_explosivo_fecha ON devoluciones(explosivo_id, fecha_devolucion);';

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
    labores_resumen,
    cantidad_labores
FROM vw_stock_diario_powerbi
WHERE fecha >= DATEADD(DAY, -7, GETDATE())
ORDER BY fecha DESC, codigo;

PRINT '✅ Vista verificada correctamente';