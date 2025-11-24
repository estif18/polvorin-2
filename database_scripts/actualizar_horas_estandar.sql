-- Script para actualizar movimientos existentes a horas estándar
-- Convierte registros existentes para usar DÍA=8AM, NOCHE=8PM

PRINT 'Iniciando actualización de horas estándar...'

-- 1. Actualizar SALIDAS existentes
PRINT 'Actualizando salidas...'

UPDATE salidas
SET fecha_salida = CASE 
    WHEN guardia = 'dia' THEN 
        DATEADD(HOUR, 8, CAST(CAST(fecha_salida AS DATE) AS DATETIME))
    WHEN guardia = 'noche' THEN 
        DATEADD(HOUR, 20, CAST(CAST(fecha_salida AS DATE) AS DATETIME))
    ELSE fecha_salida
END
WHERE guardia IN ('dia', 'noche')
  AND (
    (guardia = 'dia' AND DATEPART(HOUR, fecha_salida) != 8) OR
    (guardia = 'noche' AND DATEPART(HOUR, fecha_salida) != 20)
  );

PRINT CONCAT('Salidas actualizadas: ', @@ROWCOUNT)

-- 2. Actualizar INGRESOS existentes  
PRINT 'Actualizando ingresos...'

-- Primero, necesitamos determinar la guardia para ingresos que no la tienen explícita
-- Asumimos que ingresos entre 6AM-6PM son de día, el resto de noche
UPDATE ingresos
SET fecha_ingreso = CASE 
    WHEN DATEPART(HOUR, fecha_ingreso) BETWEEN 6 AND 17 THEN 
        -- Es turno día, usar 8AM
        DATEADD(HOUR, 8, CAST(CAST(fecha_ingreso AS DATE) AS DATETIME))
    ELSE 
        -- Es turno noche, usar 8PM
        DATEADD(HOUR, 20, CAST(CAST(fecha_ingreso AS DATE) AS DATETIME))
END
WHERE 
    (DATEPART(HOUR, fecha_ingreso) BETWEEN 6 AND 17 AND DATEPART(HOUR, fecha_ingreso) != 8) OR
    (NOT (DATEPART(HOUR, fecha_ingreso) BETWEEN 6 AND 17) AND DATEPART(HOUR, fecha_ingreso) != 20);

PRINT CONCAT('Ingresos actualizados: ', @@ROWCOUNT)

-- 3. Actualizar DEVOLUCIONES existentes
PRINT 'Actualizando devoluciones...'

UPDATE devoluciones
SET fecha_devolucion = CASE 
    WHEN guardia = 'dia' THEN 
        DATEADD(HOUR, 8, CAST(CAST(fecha_devolucion AS DATE) AS DATETIME))
    WHEN guardia = 'noche' THEN 
        DATEADD(HOUR, 20, CAST(CAST(fecha_devolucion AS DATE) AS DATETIME))
    WHEN DATEPART(HOUR, fecha_devolucion) BETWEEN 6 AND 17 THEN 
        -- No tiene guardia explícita, pero es horario de día
        DATEADD(HOUR, 8, CAST(CAST(fecha_devolucion AS DATE) AS DATETIME))
    ELSE 
        -- No tiene guardia explícita, es horario de noche
        DATEADD(HOUR, 20, CAST(CAST(fecha_devolucion AS DATE) AS DATETIME))
END
WHERE 
    (guardia = 'dia' AND DATEPART(HOUR, fecha_devolucion) != 8) OR
    (guardia = 'noche' AND DATEPART(HOUR, fecha_devolucion) != 20) OR
    (guardia IS NULL AND (
        (DATEPART(HOUR, fecha_devolucion) BETWEEN 6 AND 17 AND DATEPART(HOUR, fecha_devolucion) != 8) OR
        (NOT (DATEPART(HOUR, fecha_devolucion) BETWEEN 6 AND 17) AND DATEPART(HOUR, fecha_devolucion) != 20)
    ));

PRINT CONCAT('Devoluciones actualizadas: ', @@ROWCOUNT)

-- 4. Verificación de resultados
PRINT 'Verificando resultados...'

-- Verificar salidas
SELECT 
    'SALIDAS' as tabla,
    'DIA' as turno,
    COUNT(*) as total,
    COUNT(CASE WHEN DATEPART(HOUR, fecha_salida) = 8 THEN 1 END) as con_hora_estandar
FROM salidas 
WHERE guardia = 'dia'
UNION ALL
SELECT 
    'SALIDAS',
    'NOCHE',
    COUNT(*),
    COUNT(CASE WHEN DATEPART(HOUR, fecha_salida) = 20 THEN 1 END)
FROM salidas 
WHERE guardia = 'noche'
UNION ALL
-- Verificar ingresos
SELECT 
    'INGRESOS',
    'DIA',
    COUNT(*),
    COUNT(CASE WHEN DATEPART(HOUR, fecha_ingreso) = 8 THEN 1 END)
FROM ingresos 
WHERE DATEPART(HOUR, fecha_ingreso) BETWEEN 6 AND 18
UNION ALL
SELECT 
    'INGRESOS',
    'NOCHE', 
    COUNT(*),
    COUNT(CASE WHEN DATEPART(HOUR, fecha_ingreso) = 20 THEN 1 END)
FROM ingresos 
WHERE NOT (DATEPART(HOUR, fecha_ingreso) BETWEEN 6 AND 18)
UNION ALL
-- Verificar devoluciones
SELECT 
    'DEVOLUCIONES',
    'DIA',
    COUNT(*),
    COUNT(CASE WHEN DATEPART(HOUR, fecha_devolucion) = 8 THEN 1 END)
FROM devoluciones 
WHERE guardia = 'dia' OR (guardia IS NULL AND DATEPART(HOUR, fecha_devolucion) BETWEEN 6 AND 18)
UNION ALL
SELECT 
    'DEVOLUCIONES',
    'NOCHE',
    COUNT(*), 
    COUNT(CASE WHEN DATEPART(HOUR, fecha_devolucion) = 20 THEN 1 END)
FROM devoluciones 
WHERE guardia = 'noche' OR (guardia IS NULL AND NOT (DATEPART(HOUR, fecha_devolucion) BETWEEN 6 AND 18));

PRINT '✅ Actualización de horas estándar completada'
PRINT ''
PRINT '📊 BENEFICIOS OBTENIDOS:'
PRINT '   • Turnos DÍA ahora registrados a las 8:00 AM'
PRINT '   • Turnos NOCHE ahora registrados a las 8:00 PM'  
PRINT '   • Gráficas pueden distinguir claramente entre turnos'
PRINT '   • Análisis temporal más preciso y consistente'
PRINT '   • Consultas por turno más eficientes'