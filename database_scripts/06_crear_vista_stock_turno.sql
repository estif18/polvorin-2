-- Vista optimizada para stock diario por turno
-- Fecha: 2025-11-18

USE pallca;
GO

-- Eliminar la vista si existe
IF OBJECT_ID('vw_stock_diario_turno', 'V') IS NOT NULL
    DROP VIEW vw_stock_diario_turno;
GO

PRINT '🔄 Creando vista vw_stock_diario_turno...';

CREATE VIEW vw_stock_diario_turno AS
SELECT 
    -- Información del explosivo
    e.id as explosivo_id,
    e.codigo,
    e.descripcion,
    e.unidad,
    e.grupo,
    
    -- Información del turno y fecha
    sd.fecha,
    sd.guardia as turno,
    sd.stock_inicial,
    sd.stock_final,
    sd.responsable_guardia,
    sd.observaciones,
    
    -- Movimientos específicos del turno
    COALESCE(mov.total_ingresos, 0) as total_ingresos,
    COALESCE(mov.total_salidas, 0) as total_salidas,
    COALESCE(mov.total_devoluciones, 0) as total_devoluciones,
    
    -- Detalle de labores (salidas específicas)
    mov.labores_json,
    
    -- Cálculos derivados
    CASE 
        WHEN sd.stock_final IS NOT NULL THEN sd.stock_final - sd.stock_inicial
        ELSE COALESCE(mov.total_ingresos, 0) - COALESCE(mov.total_salidas, 0) + COALESCE(mov.total_devoluciones, 0)
    END as diferencia_calculada

FROM explosivos e
INNER JOIN stock_diario sd ON e.id = sd.explosivo_id
LEFT JOIN (
    SELECT 
        explosivo_id,
        fecha_turno,
        guardia_turno,
        
        -- Ingresos del turno
        SUM(CASE WHEN tipo_movimiento = 'INGRESO' THEN cantidad ELSE 0 END) as total_ingresos,
        
        -- Salidas del turno
        SUM(CASE WHEN tipo_movimiento = 'SALIDA' THEN cantidad ELSE 0 END) as total_salidas,
        
        -- Devoluciones del turno
        SUM(CASE WHEN tipo_movimiento = 'DEVOLUCION' THEN cantidad ELSE 0 END) as total_devoluciones,
        
        -- JSON con detalle de labores
        CASE 
            WHEN COUNT(CASE WHEN tipo_movimiento = 'SALIDA' AND labor IS NOT NULL THEN 1 END) > 0 
            THEN '[' + STRING_AGG(
                CASE WHEN tipo_movimiento = 'SALIDA' AND labor IS NOT NULL 
                     THEN '{"labor":"' + labor + '","cantidad":' + CAST(cantidad AS VARCHAR) + '}'
                     ELSE NULL 
                END, ','
            ) + ']'
            ELSE '[]'
        END as labores_json
        
    FROM (
        -- Ingresos
        SELECT 
            i.explosivo_id,
            CAST(i.fecha_ingreso AS DATE) as fecha_turno,
            i.guardia as guardia_turno,
            'INGRESO' as tipo_movimiento,
            i.cantidad,
            NULL as labor
        FROM ingresos i
        WHERE i.cantidad > 0
        
        UNION ALL
        
        -- Salidas
        SELECT 
            s.explosivo_id,
            CAST(s.fecha_salida AS DATE) as fecha_turno,
            s.guardia as guardia_turno,
            'SALIDA' as tipo_movimiento,
            s.cantidad,
            s.labor
        FROM salidas s
        WHERE s.cantidad > 0
        
        UNION ALL
        
        -- Devoluciones (toman la fecha y turno de la salida original)
        SELECT 
            d.explosivo_id,
            CAST(d.fecha_devolucion AS DATE) as fecha_turno,
            s.guardia as guardia_turno,
            'DEVOLUCION' as tipo_movimiento,
            d.cantidad_devuelta as cantidad,
            NULL as labor
        FROM devoluciones d
        INNER JOIN salidas s ON d.salida_id = s.id
        WHERE d.cantidad_devuelta > 0
        
    ) movimientos_unificados
    
    GROUP BY explosivo_id, fecha_turno, guardia_turno
    
) mov ON e.id = mov.explosivo_id 
       AND sd.fecha = mov.fecha_turno 
       AND sd.guardia = mov.guardia_turno

WHERE e.activo = 1;

GO

PRINT '✅ Vista vw_stock_diario_turno creada exitosamente';

-- Crear índices para optimización
PRINT '🔄 Creando índices para optimización...';

-- Índice compuesto en stock_diario
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_stock_diario_explosivo_fecha_guardia')
BEGIN
    CREATE INDEX IX_stock_diario_explosivo_fecha_guardia 
    ON stock_diario(explosivo_id, fecha, guardia);
    PRINT '✅ Índice IX_stock_diario_explosivo_fecha_guardia creado';
END

-- Índice en salidas para labor y fecha
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_salidas_fecha_guardia_labor')
BEGIN
    CREATE INDEX IX_salidas_fecha_guardia_labor 
    ON salidas(fecha_salida, guardia, labor);
    PRINT '✅ Índice IX_salidas_fecha_guardia_labor creado';
END

-- Verificar que la vista funciona
PRINT '🧪 Probando la vista...';

SELECT TOP 5
    codigo,
    descripcion,
    fecha,
    turno,
    total_ingresos,
    total_salidas,
    total_devoluciones,
    labores_json
FROM vw_stock_diario_turno
ORDER BY fecha DESC, turno DESC;

PRINT '✅ Vista vw_stock_diario_turno lista para usar';