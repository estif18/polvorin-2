-- Script para eliminar completamente explosivos antiguos y sus movimientos
-- Fecha: 2025-11-09
-- CUIDADO: Este script eliminará datos de forma permanente

BEGIN TRANSACTION;

PRINT 'Iniciando eliminación de explosivos antiguos y sus movimientos...';

-- 1. Primero identificar los explosivos antiguos (que no tienen códigos 030xxxx)
SELECT 'Explosivos a eliminar:' as mensaje;
SELECT 
    id,
    codigo, 
    descripcion,
    grupo
FROM explosivos 
WHERE codigo NOT LIKE '030%'
ORDER BY grupo, codigo;

DECLARE @count_antiguos int;
SELECT @count_antiguos = COUNT(*) FROM explosivos WHERE codigo NOT LIKE '030%';
PRINT CONCAT('Total de explosivos antiguos a eliminar: ', @count_antiguos);

-- 2. Eliminar movimientos de stock relacionados con explosivos antiguos
DELETE FROM movimientos_stock 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Movimientos de stock eliminados';

-- 3. Eliminar detalles de devoluciones
DELETE FROM devoluciones 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Devoluciones eliminadas';

-- 4. Eliminar detalles de salidas
DELETE FROM salidas 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Salidas eliminadas';

-- 5. Eliminar detalles de ingresos
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
SELECT 'Estado final:' as mensaje;

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
    'Movimientos stock restantes' as tabla,
    COUNT(*) as total
FROM movimientos_stock;

-- Mostrar explosivos actuales por grupo
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