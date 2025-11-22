-- =========================================================
-- VISTA COMPLEMENTARIA: DETALLE DE LABORES PARA POWER BI
-- =========================================================
-- Fecha: Noviembre 2025
-- Descripción: Vista desnormalizada de labores por explosivo y turno
--              para crear visualizaciones detalladas en Power BI

USE pallca;
GO

PRINT '📊 Creando vista complementaria: Detalle de Labores...';

-- Eliminar vista si existe
IF OBJECT_ID('vw_labores_detalle_powerbi', 'V') IS NOT NULL
    DROP VIEW vw_labores_detalle_powerbi;
GO

CREATE VIEW vw_labores_detalle_powerbi AS
SELECT 
    -- Identificadores
    s.id as salida_id,
    s.explosivo_id,
    e.codigo,
    e.descripcion,
    e.unidad,
    e.grupo,
    
    -- Información temporal
    CAST(s.fecha_salida AS DATE) as fecha,
    s.guardia as turno,
    
    -- Información de la labor
    s.labor,
    s.tipo_actividad,
    s.cantidad,
    
    -- Información de responsabilidad
    s.responsable,
    s.autorizado_por,
    
    -- Detalles adicionales
    s.observaciones,
    s.estado,
    
    -- Información de stock del día
    sd.stock_inicial,
    sd.stock_final,
    sd.responsable_guardia,
    
    -- Cálculos útiles para Power BI
    YEAR(s.fecha_salida) as anio,
    MONTH(s.fecha_salida) as mes,
    DAY(s.fecha_salida) as dia,
    DATENAME(WEEKDAY, s.fecha_salida) as dia_semana,
    DATENAME(MONTH, s.fecha_salida) as nombre_mes,
    
    -- Período para agrupaciones
    FORMAT(s.fecha_salida, 'yyyy-MM') as periodo_mes,
    FORMAT(s.fecha_salida, 'yyyy-\QQ') as periodo_trimestre,
    
    -- Ranking de labor por explosivo y día
    ROW_NUMBER() OVER (
        PARTITION BY s.explosivo_id, CAST(s.fecha_salida AS DATE), s.guardia 
        ORDER BY s.cantidad DESC
    ) as ranking_labor,
    
    -- Porcentaje de uso de esta labor en el día
    CASE 
        WHEN SUM(s.cantidad) OVER (PARTITION BY s.explosivo_id, CAST(s.fecha_salida AS DATE), s.guardia) > 0
        THEN (s.cantidad * 100.0) / SUM(s.cantidad) OVER (PARTITION BY s.explosivo_id, CAST(s.fecha_salida AS DATE), s.guardia)
        ELSE 0 
    END as porcentaje_uso_dia,
    
    -- Total usado del explosivo en el día
    SUM(s.cantidad) OVER (
        PARTITION BY s.explosivo_id, CAST(s.fecha_salida AS DATE), s.guardia
    ) as total_explosivo_dia,
    
    -- Timestamps
    s.fecha_salida as timestamp_salida,
    GETDATE() as fecha_consulta

FROM salidas s
INNER JOIN explosivos e ON s.explosivo_id = e.id
LEFT JOIN stock_diario sd ON s.explosivo_id = sd.explosivo_id 
                          AND CAST(s.fecha_salida AS DATE) = sd.fecha
                          AND s.guardia = sd.guardia
WHERE e.activo = 1
AND s.labor IS NOT NULL;

GO

PRINT '✅ Vista vw_labores_detalle_powerbi creada exitosamente';

-- Verificar que la vista funciona
PRINT '🔍 Verificando vista con datos de prueba...';

SELECT TOP 10
    codigo,
    descripcion,
    fecha,
    turno,
    labor,
    cantidad,
    ranking_labor,
    ROUND(porcentaje_uso_dia, 2) as porcentaje_uso,
    responsable
FROM vw_labores_detalle_powerbi
WHERE fecha >= DATEADD(DAY, -7, GETDATE())
ORDER BY fecha DESC, codigo, ranking_labor;

PRINT '✅ Vista verificada correctamente';

GO