-- Script corregido para eliminar explosivos antiguos y sus movimientos
-- Fecha: 2025-11-09
-- CUIDADO: Este script eliminará datos de forma permanente

BEGIN TRANSACTION;

PRINT 'Iniciando eliminación de explosivos antiguos y sus movimientos...';

-- 1. Verificar las tablas que tienen referencia a explosivos
SELECT 'Verificando referencias a explosivos antiguos...' as mensaje;

SELECT 
    'Ingresos con explosivos antiguos' as tabla,
    COUNT(*) as cantidad
FROM ingresos 
WHERE explosivo_id IN (SELECT id FROM explosivos WHERE codigo NOT LIKE '030%')
UNION ALL
SELECT 
    'Salidas con explosivos antiguos' as tabla,
    COUNT(*) as cantidad
FROM salidas 
WHERE explosivo_id IN (SELECT id FROM explosivos WHERE codigo NOT LIKE '030%')
UNION ALL
SELECT 
    'Devoluciones con explosivos antiguos' as tabla,
    COUNT(*) as cantidad
FROM devoluciones 
WHERE explosivo_id IN (SELECT id FROM explosivos WHERE codigo NOT LIKE '030%')
UNION ALL
SELECT 
    'Stock diario con explosivos antiguos' as tabla,
    COUNT(*) as cantidad
FROM stock_diario 
WHERE explosivo_id IN (SELECT id FROM explosivos WHERE codigo NOT LIKE '030%');

-- 2. Eliminar registros de stock_diario relacionados con explosivos antiguos
DELETE FROM stock_diario 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Registros de stock_diario eliminados';

-- 3. Eliminar devoluciones
DELETE FROM devoluciones 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Devoluciones eliminadas';

-- 4. Eliminar salidas
DELETE FROM salidas 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Salidas eliminadas';

-- 5. Eliminar ingresos
DELETE FROM ingresos 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Ingresos eliminados';

-- 6. Finalmente eliminar los explosivos antiguos
DELETE FROM explosivos 
WHERE codigo NOT LIKE '030%';
PRINT 'Explosivos antiguos eliminados';

-- Verificar el estado final
SELECT 'Estado final después de la limpieza:' as mensaje;

SELECT 
    'Explosivos restantes' as tabla,
    COUNT(*) as total
FROM explosivos
UNION ALL
SELECT 
    'Ingresos restantes' as tabla,
    COUNT(*) as total
FROM ingresos
UNION ALL
SELECT 
    'Salidas restantes' as tabla,
    COUNT(*) as total
FROM salidas
UNION ALL
SELECT 
    'Devoluciones restantes' as tabla,
    COUNT(*) as total
FROM devoluciones
UNION ALL
SELECT 
    'Stock diario restante' as tabla,
    COUNT(*) as total
FROM stock_diario;

-- Mostrar explosivos finales por grupo
PRINT 'Explosivos restantes por grupo:';
SELECT 
    grupo, 
    COUNT(*) as cantidad 
FROM explosivos 
WHERE activo = 1 
GROUP BY grupo 
ORDER BY grupo;

-- Confirmar la transacción
COMMIT TRANSACTION;

PRINT 'Eliminación completada exitosamente';
PRINT 'Solo quedan los explosivos con códigos 030xxxx';

-- Verificación final - mostrar explosivos actuales
SELECT TOP 10
    codigo,
    descripcion,
    unidad,
    grupo
FROM explosivos 
WHERE activo = 1
ORDER BY grupo, codigo;