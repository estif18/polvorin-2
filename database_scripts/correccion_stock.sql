-- Script de Corrección y Sincronización de Stock
-- Corrige inconsistencias entre vista v_stock_actual y stock_diario

PRINT 'Iniciando corrección de stock...'

-- 1. Crear tabla temporal para comparación
IF OBJECT_ID('tempdb..#stock_comparison') IS NOT NULL
    DROP TABLE #stock_comparison;

CREATE TABLE #stock_comparison (
    explosivo_id INT,
    codigo VARCHAR(20),
    descripcion VARCHAR(200),
    stock_calculado INT,
    stock_diario_actual INT,
    diferencia INT,
    necesita_actualizacion BIT
);

-- 2. Llenar tabla de comparación
INSERT INTO #stock_comparison
SELECT 
    v.id as explosivo_id,
    v.codigo,
    v.descripcion,
    v.stock_actual as stock_calculado,
    ISNULL(sd.stock_final, 0) as stock_diario_actual,
    (v.stock_actual - ISNULL(sd.stock_final, 0)) as diferencia,
    CASE 
        WHEN v.stock_actual != ISNULL(sd.stock_final, 0) THEN 1
        ELSE 0
    END as necesita_actualizacion
FROM v_stock_actual v
LEFT JOIN (
    SELECT DISTINCT 
        explosivo_id,
        LAST_VALUE(stock_final) OVER (
            PARTITION BY explosivo_id 
            ORDER BY fecha DESC, guardia DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) as stock_final
    FROM stock_diario 
    WHERE fecha = (SELECT MAX(fecha) FROM stock_diario)
) sd ON v.id = sd.explosivo_id;

-- 3. Mostrar inconsistencias encontradas
PRINT 'Inconsistencias encontradas:'
SELECT 
    codigo,
    descripcion,
    stock_calculado,
    stock_diario_actual,
    diferencia
FROM #stock_comparison
WHERE necesita_actualizacion = 1
ORDER BY ABS(diferencia) DESC;

-- 4. Corregir stock_diario para la fecha actual
DECLARE @fecha_hoy DATE = CAST(GETDATE() AS DATE);
DECLARE @guardia_actual VARCHAR(10);

-- Determinar guardia actual
IF DATEPART(HOUR, GETDATE()) BETWEEN 6 AND 17
    SET @guardia_actual = 'dia'
ELSE
    SET @guardia_actual = 'noche';

PRINT CONCAT('Fecha: ', @fecha_hoy, ' - Guardia: ', @guardia_actual);

-- 5. Actualizar stock_final en stock_diario
UPDATE sd
SET 
    stock_final = sc.stock_calculado,
    observaciones = CONCAT(
        ISNULL(sd.observaciones, ''), 
        ' [CORREGIDO: ', GETDATE(), ' - Diff: ', sc.diferencia, ']'
    )
FROM stock_diario sd
INNER JOIN #stock_comparison sc ON sd.explosivo_id = sc.explosivo_id
WHERE sd.fecha = @fecha_hoy 
  AND sd.guardia = @guardia_actual
  AND sc.necesita_actualizacion = 1;

PRINT CONCAT('Registros de stock_diario actualizados: ', @@ROWCOUNT);

-- 6. Crear registros faltantes si no existen para hoy
INSERT INTO stock_diario (
    explosivo_id,
    fecha,
    guardia,
    stock_inicial,
    stock_final,
    observaciones,
    fecha_registro
)
SELECT 
    sc.explosivo_id,
    @fecha_hoy,
    @guardia_actual,
    sc.stock_calculado,
    sc.stock_calculado,
    CONCAT('CREADO POR SINCRONIZACIÓN - ', GETDATE()),
    GETDATE()
FROM #stock_comparison sc
WHERE sc.explosivo_id NOT IN (
    SELECT explosivo_id 
    FROM stock_diario 
    WHERE fecha = @fecha_hoy AND guardia = @guardia_actual
);

PRINT CONCAT('Registros nuevos creados: ', @@ROWCOUNT);

-- 7. Verificación final
PRINT 'Verificación final:'
SELECT 
    'ANTES' as estado,
    COUNT(CASE WHEN necesita_actualizacion = 1 THEN 1 END) as inconsistencias
FROM #stock_comparison
UNION ALL
SELECT 
    'DESPUÉS',
    COUNT(*)
FROM (
    SELECT v.id
    FROM v_stock_actual v
    INNER JOIN stock_diario sd ON v.id = sd.explosivo_id
    WHERE sd.fecha = @fecha_hoy 
      AND sd.guardia = @guardia_actual
      AND v.stock_actual != sd.stock_final
) x;

-- 8. Limpiar
DROP TABLE #stock_comparison;

PRINT '✅ Corrección de stock completada';