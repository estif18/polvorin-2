-- Script final para eliminar explosivos antiguos respetando restricciones
-- Fecha: 2025-11-09

BEGIN TRANSACTION;

PRINT 'Eliminando explosivos antiguos y registros asociados...';

-- Primero, obtener los IDs de los stock_diario que referencias explosivos antiguos
DECLARE @stock_ids TABLE (stock_id INT);
INSERT INTO @stock_ids (stock_id)
SELECT s.id 
FROM stock_diario s 
INNER JOIN explosivos e ON s.explosivo_id = e.id
WHERE e.codigo NOT LIKE '030%';

PRINT 'Stock diarios identificados para eliminación';

-- 1. Eliminar salidas que referencian estos stock_diario
DELETE FROM salidas 
WHERE stock_diario_id IN (SELECT stock_id FROM @stock_ids);
PRINT 'Salidas eliminadas';

-- 2. Eliminar devoluciones que referencian explosivos antiguos directamente
DELETE FROM devoluciones 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Devoluciones eliminadas';

-- 3. Eliminar ingresos que referencian explosivos antiguos directamente  
DELETE FROM ingresos 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Ingresos eliminados';

-- 4. Ahora eliminar los stock_diario de explosivos antiguos
DELETE FROM stock_diario 
WHERE explosivo_id IN (
    SELECT id FROM explosivos WHERE codigo NOT LIKE '030%'
);
PRINT 'Stock diario eliminado';

-- 5. Finalmente eliminar los explosivos antiguos
DELETE FROM explosivos 
WHERE codigo NOT LIKE '030%';
PRINT 'Explosivos antiguos eliminados';

-- Verificar estado final
SELECT 'Resumen final:' as mensaje;
SELECT 
    COUNT(*) as total_explosivos_restantes
FROM explosivos;

SELECT 
    grupo, 
    COUNT(*) as cantidad 
FROM explosivos 
GROUP BY grupo 
ORDER BY grupo;

COMMIT TRANSACTION;

PRINT 'Proceso completado exitosamente';

-- Mostrar sample de explosivos restantes
SELECT TOP 5
    codigo,
    descripcion,
    grupo
FROM explosivos 
ORDER BY grupo, codigo;