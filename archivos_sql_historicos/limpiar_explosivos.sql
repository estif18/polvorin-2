-- Script para desactivar explosivos antiguos y mantener solo los nuevos
-- Fecha: 2025-11-09

-- Desactivar todos los explosivos con códigos antiguos (que no empiezan con 030)
UPDATE explosivos 
SET activo = 0 
WHERE codigo NOT LIKE '030%' 
  AND activo = 1;

-- Verificar que solo estén activos los nuevos explosivos
SELECT 
    grupo, 
    COUNT(*) as cantidad_activos 
FROM explosivos 
WHERE activo = 1 
GROUP BY grupo 
ORDER BY grupo;

-- Mostrar resumen total
SELECT 
    activo,
    COUNT(*) as total
FROM explosivos 
GROUP BY activo;

-- Mostrar los explosivos activos para verificar
SELECT 
    codigo, 
    descripcion, 
    unidad, 
    grupo 
FROM explosivos 
WHERE activo = 1 
ORDER BY grupo, codigo;

PRINT 'Actualización completada';
PRINT 'Explosivos antiguos desactivados, solo los nuevos códigos 030xxxx están activos';