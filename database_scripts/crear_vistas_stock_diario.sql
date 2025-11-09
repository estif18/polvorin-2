-- Vista para Stock Diario por Turno
-- Esta vista organiza y presenta los datos de stock diario de forma optimizada

USE pallca;
GO

-- Eliminar vista si existe
IF OBJECT_ID('vista_stock_diario_turnos', 'V') IS NOT NULL
    DROP VIEW vista_stock_diario_turnos;
GO

CREATE VIEW vista_stock_diario_turnos AS
SELECT 
    sd.id,
    sd.explosivo_id,
    e.codigo as explosivo_codigo,
    e.descripcion as explosivo_descripcion,
    e.unidad as explosivo_unidad,
    sd.fecha,
    sd.guardia,
    CASE 
        WHEN sd.guardia = 'dia' THEN 'Día'
        WHEN sd.guardia = 'noche' THEN 'Noche'
        ELSE sd.guardia
    END as guardia_nombre,
    CAST(sd.stock_inicial as DECIMAL(10,2)) as stock_inicial,
    CAST(sd.stock_final as DECIMAL(10,2)) as stock_final,
    CAST((sd.stock_final - sd.stock_inicial) as DECIMAL(10,2)) as diferencia,
    CASE 
        WHEN sd.stock_final > sd.stock_inicial THEN 'positiva'
        WHEN sd.stock_final < sd.stock_inicial THEN 'negativa'
        ELSE 'cero'
    END as tipo_diferencia,
    sd.responsable_guardia,
    sd.observaciones,
    sd.fecha_registro,
    -- Campos adicionales para ordenamiento y agrupación
    CASE 
        WHEN sd.guardia = 'dia' THEN 1
        WHEN sd.guardia = 'noche' THEN 2
        ELSE 3
    END as orden_guardia,
    -- Calcular si es el turno actual
    CASE 
        WHEN sd.fecha = CAST(GETDATE() AS DATE) AND 
             ((sd.guardia = 'dia' AND DATEPART(HOUR, GETDATE()) BETWEEN 6 AND 17) OR
              (sd.guardia = 'noche' AND (DATEPART(HOUR, GETDATE()) >= 18 OR DATEPART(HOUR, GETDATE()) <= 5)))
        THEN 1
        ELSE 0
    END as es_turno_actual
FROM stock_diario sd
INNER JOIN explosivos e ON sd.explosivo_id = e.id;
GO

-- Crear vista resumen por fecha
IF OBJECT_ID('vista_resumen_stock_diario', 'V') IS NOT NULL
    DROP VIEW vista_resumen_stock_diario;
GO

CREATE VIEW vista_resumen_stock_diario AS
SELECT 
    fecha,
    COUNT(DISTINCT explosivo_id) as total_explosivos,
    COUNT(*) as total_registros,
    COUNT(DISTINCT CASE WHEN guardia = 'dia' THEN explosivo_id END) as explosivos_turno_dia,
    COUNT(DISTINCT CASE WHEN guardia = 'noche' THEN explosivo_id END) as explosivos_turno_noche,
    SUM(CAST(stock_inicial as DECIMAL(10,2))) as stock_inicial_total,
    SUM(CAST(stock_final as DECIMAL(10,2))) as stock_final_total,
    SUM(CAST((stock_final - stock_inicial) as DECIMAL(10,2))) as diferencia_total,
    COUNT(CASE WHEN stock_final > stock_inicial THEN 1 END) as movimientos_positivos,
    COUNT(CASE WHEN stock_final < stock_inicial THEN 1 END) as movimientos_negativos,
    COUNT(CASE WHEN stock_final = stock_inicial THEN 1 END) as sin_movimientos
FROM stock_diario
GROUP BY fecha;
GO

-- Crear índices para mejorar performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_stock_diario_fecha_guardia')
    CREATE INDEX IX_stock_diario_fecha_guardia ON stock_diario(fecha, guardia);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_stock_diario_explosivo_fecha')
    CREATE INDEX IX_stock_diario_explosivo_fecha ON stock_diario(explosivo_id, fecha);
GO

PRINT 'Vistas de stock diario creadas exitosamente:';
PRINT '- vista_stock_diario_turnos: Vista principal con datos detallados';
PRINT '- vista_resumen_stock_diario: Vista de resumen por fecha';
PRINT '- Índices optimizados creados';