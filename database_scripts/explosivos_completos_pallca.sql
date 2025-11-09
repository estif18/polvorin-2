-- =========================================================
-- INSERTAR EXPLOSIVOS COMPLETOS - AZURE SQL DATABASE - PALLCA
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0 Completa
-- Descripción: TODOS los explosivos del polvorín PALLCA organizados por grupos

PRINT '📊 Verificando conexión a PALLCA en Azure...';
SELECT DB_NAME() as BaseDatosActual;

-- =========================================================
-- LIMPIAR Y REINICIAR EXPLOSIVOS
-- =========================================================

PRINT '🧹 Limpiando explosivos existentes...';
DELETE FROM explosivos;
DBCC CHECKIDENT ('explosivos', RESEED, 0);

-- =========================================================
-- INSERTAR TODOS LOS EXPLOSIVOS POR GRUPOS
-- =========================================================

PRINT '💥 Insertando catálogo COMPLETO de explosivos PALLCA...';

INSERT INTO explosivos (codigo, descripcion, unidad, grupo, activo, fecha_creacion) VALUES
-- =========================================================
-- GRUPO: EXPLOSIVOS (7 items)
-- =========================================================
('SUPERFAM_DOS', 'SUPERFAM DOS AE (ANFO)', 'Kg', 'EXPLOSIVOS', 1, GETDATE()),
('EMULNOR_3000_1', 'EMULNOR 3000 1 1/4" X 8"', 'Und', 'EXPLOSIVOS', 1, GETDATE()),
('EMULNOR_5000_1', 'EMULNOR 5000 1 1/4" X 8"', 'Und', 'EXPLOSIVOS', 1, GETDATE()),
('EMULNOR_1000', 'EMULNOR 1000 1 1/8" X 16"', 'Und', 'EXPLOSIVOS', 1, GETDATE()),
('EMULNOR_5000_2', 'EMULNOR 5000 2" X 12', 'Und', 'EXPLOSIVOS', 1, GETDATE()),
('MECHA_FULMINANTE', 'MECHA LENTA + FULMINATE', 'Pza', 'EXPLOSIVOS', 1, GETDATE()),
('PENTACORD_3P', 'PENTACORD 3P', 'Mts', 'EXPLOSIVOS', 1, GETDATE()),

-- =========================================================
-- GRUPO: FANELES MS 4.8 MTS (20 items: NO 01-20)
-- =========================================================
('FANEL_MS_4_01', 'FANEL MS 4.8 MTRS NO 01', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_02', 'FANEL MS 4.8 MTRS NO 02', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_03', 'FANEL MS 4.8 MTRS NO 03', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_04', 'FANEL MS 4.8 MTRS NO 04', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_05', 'FANEL MS 4.8 MTRS NO 05', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_06', 'FANEL MS 4.8 MTRS NO 06', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_07', 'FANEL MS 4.8 MTRS NO 07', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_08', 'FANEL MS 4.8 MTRS NO 08', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_09', 'FANEL MS 4.8 MTRS NO 09', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_10', 'FANEL MS 4.8 MTRS NO 10', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_11', 'FANEL MS 4.8 MTRS NO 11', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_12', 'FANEL MS 4.8 MTRS NO 12', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_13', 'FANEL MS 4.8 MTRS NO 13', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_14', 'FANEL MS 4.8 MTRS NO 14', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_15', 'FANEL MS 4.8 MTRS NO 15', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_16', 'FANEL MS 4.8 MTRS NO 16', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_17', 'FANEL MS 4.8 MTRS NO 17', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_18', 'FANEL MS 4.8 MTRS NO 18', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_19', 'FANEL MS 4.8 MTRS NO 19', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),
('FANEL_MS_4_20', 'FANEL MS 4.8 MTRS NO 20', 'Pza', 'FANELES MS 4.8 MTS', 1, GETDATE()),

-- =========================================================
-- GRUPO: FANELES LP 4.8 MTS (15 items: NO 01-15)
-- =========================================================
('FANEL_LP_4_01', 'FANEL LP 4.8 MTRS NO 01', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_02', 'FANEL LP 4.8 MTRS NO 02', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_03', 'FANEL LP 4.8 MTRS NO 03', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_04', 'FANEL LP 4.8 MTRS NO 04', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_05', 'FANEL LP 4.8 MTRS NO 05', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_06', 'FANEL LP 4.8 MTRS NO 06', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_07', 'FANEL LP 4.8 MTRS NO 07', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_08', 'FANEL LP 4.8 MTRS NO 08', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_09', 'FANEL LP 4.8 MTRS NO 09', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_10', 'FANEL LP 4.8 MTRS NO 10', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_11', 'FANEL LP 4.8 MTRS NO 11', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_12', 'FANEL LP 4.8 MTRS NO 12', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_13', 'FANEL LP 4.8 MTRS NO 13', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_14', 'FANEL LP 4.8 MTRS NO 14', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),
('FANEL_LP_4_15', 'FANEL LP 4.8 MTRS NO 15', 'Pza', 'FANELES LP 4.8 MTS', 1, GETDATE()),

-- =========================================================
-- GRUPO: FANELES MS 15 MTS (20 items: NO 01-20)
-- =========================================================
('FANEL_MS_15_01', 'FANEL MS 15 MTRS NO 01', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_02', 'FANEL MS 15 MTRS NO 02', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_03', 'FANEL MS 15 MTRS NO 03', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_04', 'FANEL MS 15 MTRS NO 04', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_05', 'FANEL MS 15 MTRS NO 05', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_06', 'FANEL MS 15 MTRS NO 06', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_07', 'FANEL MS 15 MTRS NO 07', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_08', 'FANEL MS 15 MTRS NO 08', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_09', 'FANEL MS 15 MTRS NO 09', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_10', 'FANEL MS 15 MTRS NO 10', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_11', 'FANEL MS 15 MTRS NO 11', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_12', 'FANEL MS 15 MTRS NO 12', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_13', 'FANEL MS 15 MTRS NO 13', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_14', 'FANEL MS 15 MTRS NO 14', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_15', 'FANEL MS 15 MTRS NO 15', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_16', 'FANEL MS 15 MTRS NO 16', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_17', 'FANEL MS 15 MTRS NO 17', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_18', 'FANEL MS 15 MTRS NO 18', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_19', 'FANEL MS 15 MTRS NO 19', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),
('FANEL_MS_15_20', 'FANEL MS 15 MTRS NO 20', 'Pza', 'FANELES MS 15 MTS', 1, GETDATE()),

-- =========================================================
-- GRUPO: FANELES LP 15 MTS (15 items: NO 01-15)
-- =========================================================
('FANEL_LP_15_01', 'FANEL LP 15 MTRS NO 01', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_02', 'FANEL LP 15 MTRS NO 02', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_03', 'FANEL LP 15 MTRS NO 03', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_04', 'FANEL LP 15 MTRS NO 04', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_05', 'FANEL LP 15 MTRS NO 05', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_06', 'FANEL LP 15 MTRS NO 06', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_07', 'FANEL LP 15 MTRS NO 07', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_08', 'FANEL LP 15 MTRS NO 08', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_09', 'FANEL LP 15 MTRS NO 09', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_10', 'FANEL LP 15 MTRS NO 10', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_11', 'FANEL LP 15 MTRS NO 11', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_12', 'FANEL LP 15 MTRS NO 12', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_13', 'FANEL LP 15 MTRS NO 13', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_14', 'FANEL LP 15 MTRS NO 14', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE()),
('FANEL_LP_15_15', 'FANEL LP 15 MTRS NO 15', 'Pza', 'FANELES LP 15 MTS', 1, GETDATE());

DECLARE @total_insertados INT = @@ROWCOUNT;

-- =========================================================
-- VERIFICACIÓN Y RESUMEN
-- =========================================================

PRINT '';
PRINT '📊 VERIFICACIÓN DE EXPLOSIVOS INSERTADOS:';

-- Conteo por grupos
SELECT 
    grupo,
    COUNT(*) as cantidad_items,
    MIN(descripcion) as primer_item,
    MAX(descripcion) as ultimo_item
FROM explosivos 
WHERE activo = 1
GROUP BY grupo
ORDER BY grupo;

-- Resumen total
DECLARE @total_explosivos INT;
SELECT @total_explosivos = COUNT(*) FROM explosivos WHERE activo = 1;

PRINT '';
PRINT '🎉 ¡CATÁLOGO COMPLETO INSERTADO EXITOSAMENTE!';
PRINT '';
PRINT CONCAT('📦 TOTAL EXPLOSIVOS: ', CAST(@total_explosivos AS VARCHAR), ' items');
PRINT '';
PRINT '📋 DISTRIBUCIÓN POR GRUPOS:';
PRINT '   💥 EXPLOSIVOS: 7 items';
PRINT '   ⚡ FANELES MS 4.8 MTS: 20 items';
PRINT '   🔥 FANELES LP 4.8 MTS: 15 items';
PRINT '   ⚡ FANELES MS 15 MTS: 20 items';
PRINT '   🔥 FANELES LP 15 MTS: 15 items';
PRINT '';
PRINT '✅ SISTEMA LISTO PARA OPERACIONES COMPLETAS';
PRINT '✅ Todos los explosivos del polvorín PALLCA registrados';
PRINT '';