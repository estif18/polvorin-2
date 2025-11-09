-- =========================================================
-- INSERTAR DATOS MAESTROS - AZURE SQL DATABASE - PALLCA (FINAL)
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0 Azure Final
-- Descripción: Datos maestros para explosivos y usuarios en Azure SQL Database

PRINT '📊 Verificando conexión a PALLCA en Azure...';
SELECT DB_NAME() as BaseDatosActual;

-- =========================================================
-- 1. LIMPIAR TABLAS EXISTENTES
-- =========================================================

PRINT '🧹 Limpiando tablas existentes...';

-- Deshabilitar restricciones temporalmente
ALTER TABLE ingresos NOCHECK CONSTRAINT ALL;
ALTER TABLE salidas NOCHECK CONSTRAINT ALL; 
ALTER TABLE devoluciones NOCHECK CONSTRAINT ALL;
ALTER TABLE stock_diario NOCHECK CONSTRAINT ALL;

-- Eliminar datos existentes (en orden por FK)
DELETE FROM stock_diario;
DELETE FROM devoluciones;
DELETE FROM salidas;
DELETE FROM ingresos;
DELETE FROM usuarios WHERE username != 'admin';
DELETE FROM explosivos;

PRINT '✅ Tablas limpiadas';

-- =========================================================
-- 2. REINICIAR SECUENCIAS DE IDENTIDAD
-- =========================================================

PRINT '🔄 Reiniciando secuencias de identidad...';

-- Reiniciar contadores de identidad
DBCC CHECKIDENT ('explosivos', RESEED, 0);
DBCC CHECKIDENT ('ingresos', RESEED, 0);
DBCC CHECKIDENT ('salidas', RESEED, 0);
DBCC CHECKIDENT ('devoluciones', RESEED, 0);
DBCC CHECKIDENT ('usuarios', RESEED, 0);
DBCC CHECKIDENT ('stock_diario', RESEED, 0);

PRINT '✅ Secuencias reiniciadas';

-- =========================================================
-- 3. INSERTAR EXPLOSIVOS MAESTROS
-- =========================================================

PRINT '💥 Insertando catálogo de explosivos...';

INSERT INTO explosivos (codigo, descripcion, unidad, activo, fecha_creacion) VALUES
-- EXPLOSIVOS REALES DEL POLVORIN PALLCA
('0302008', 'EMULNOR 3000 1 1/4 " X 8"', 'PZA', 1, GETDATE()),
('0303004', 'FULMINANTE GUIA ARMADA', 'PZA', 1, GETDATE()),
('0303051', 'FANEL LP 4.8 MTRS NO 01', 'PZA', 1, GETDATE()),
('0303052', 'FANEL LP 4.8 MTRS NO 02', 'PZA', 1, GETDATE()),
('0303053', 'FANEL LP 4.8 MTRS NO 03', 'PZA', 1, GETDATE()),
('0303054', 'FANEL LP 4.8 MTRS NO 04', 'PZA', 1, GETDATE()),
('0303055', 'FANEL LP 4.8 MTRS NO 05', 'PZA', 1, GETDATE()),
('0303056', 'FANEL LP 4.8 MTRS NO 06', 'PZA', 1, GETDATE()),
('0303057', 'FANEL LP 4.8 MTRS NO 07', 'PZA', 1, GETDATE()),
('0303058', 'FANEL LP 4.8 MTRS NO 08', 'PZA', 1, GETDATE()),
('0303059', 'FANEL LP 4.8 MTRS NO 09', 'PZA', 1, GETDATE()),
('0303060', 'FANEL LP 4.8 MTRS NO 10', 'PZA', 1, GETDATE()),
('0303061', 'FANEL LP 4.8 MTRS NO 11', 'PZA', 1, GETDATE()),
('0303062', 'FANEL LP 4.8 MTRS NO 12', 'PZA', 1, GETDATE()),
('0303063', 'FANEL LP 4.8 MTRS NO 13', 'PZA', 1, GETDATE()),
('0303064', 'FANEL LP 4.8 MTRS NO 14', 'PZA', 1, GETDATE()),
('0303065', 'FANEL LP 4.8 MTRS NO 15', 'PZA', 1, GETDATE()),
('0303071', 'FANEL MS 4.8 MTRS NO 01', 'PZA', 1, GETDATE()),
('0303072', 'FANEL MS 4.8 MTRS NO 02', 'PZA', 1, GETDATE()),
('0303073', 'FANEL MS 4.8 MTRS NO 03', 'PZA', 1, GETDATE()),
('0303074', 'FANEL MS 4.8 MTRS NO 04', 'PZA', 1, GETDATE()),
('0303075', 'FANEL MS 4.8 MTRS NO 05', 'PZA', 1, GETDATE()),
('0303076', 'FANEL MS 4.8 MTRS NO 06', 'PZA', 1, GETDATE()),
('0303077', 'FANEL MS 4.8 MTRS NO 07', 'PZA', 1, GETDATE()),
('0303078', 'FANEL MS 4.8 MTRS NO 08', 'PZA', 1, GETDATE()),
('0303079', 'FANEL MS 4.8 MTRS NO 09', 'PZA', 1, GETDATE()),
('0303080', 'FANEL MS 4.8 MTRS NO 10', 'PZA', 1, GETDATE()),
('0303081', 'FANEL MS 4.8 MTRS NO 11', 'PZA', 1, GETDATE()),
('0303082', 'FANEL MS 4.8 MTRS NO 12', 'PZA', 1, GETDATE()),
('0303083', 'FANEL MS 4.8 MTRS NO 13', 'PZA', 1, GETDATE()),
('0303084', 'FANEL MS 4.8 MTRS NO 14', 'PZA', 1, GETDATE()),
('0303085', 'FANEL MS 4.8 MTRS NO 15', 'PZA', 1, GETDATE()),
('0304003', 'SUPERFAM DOS (ANFO)', 'SACOS', 1, GETDATE()),
('0305001', 'MECHA LENTA CJA X 1000 MTS', 'MTR', 1, GETDATE()),
('0305004', 'CORDON DE IGNICION X 1500 MTS', 'MTR', 1, GETDATE()),
('0305011', 'CARMEX DETONADOR ENSAMBLADO 2.40 MT X300 PZAS', 'PZA', 1, GETDATE()),
('0306003', 'PENTACORD 3P CAJA X 1500 MTRS (1 caja= 1500 m)', 'MTR', 1, GETDATE());

DECLARE @count_explosivos INT = @@ROWCOUNT;

PRINT '✅ Explosivos insertados correctamente';

-- =========================================================
-- 4. INSERTAR USUARIOS DEL SISTEMA
-- =========================================================

PRINT '👥 Insertando usuarios del sistema...';

-- Insertar usuarios con la estructura correcta de la tabla
INSERT INTO usuarios (username, password_hash, nombre_completo, cargo, activo, fecha_creacion) VALUES
-- ADMINISTRADORES
('admin', 'temporal_hash_admin', 'Administrador Principal', 'admin', 1, GETDATE()),
('jefe_ops', 'temporal_hash_jefe', 'Jefe de Operaciones', 'admin', 1, GETDATE()),

-- SUPERVISORES DE GUARDIA
('supervisor_a', 'temporal_hash_sup_a', 'Supervisor Guardia A', 'supervisor', 1, GETDATE()),
('supervisor_b', 'temporal_hash_sup_b', 'Supervisor Guardia B', 'supervisor', 1, GETDATE()),
('supervisor_c', 'temporal_hash_sup_c', 'Supervisor Guardia C', 'supervisor', 1, GETDATE()),
('supervisor_d', 'temporal_hash_sup_d', 'Supervisor Guardia D', 'supervisor', 1, GETDATE()),

-- OPERADORES DE POLVORÍN
('polvorinero_1', 'temporal_hash_pol1', 'Polvorinero Principal', 'operador', 1, GETDATE()),
('polvorinero_2', 'temporal_hash_pol2', 'Polvorinero Auxiliar', 'operador', 1, GETDATE()),

-- PERSONAL DE VOLADURA
('voladura_jefe', 'temporal_hash_vol_jefe', 'Voladura Jefe', 'supervisor', 1, GETDATE()),
('voladura_op1', 'temporal_hash_vol1', 'Voladura Operador 1', 'operador', 1, GETDATE()),
('voladura_op2', 'temporal_hash_vol2', 'Voladura Operador 2', 'operador', 1, GETDATE()),
('voladura_op3', 'temporal_hash_vol3', 'Voladura Operador 3', 'operador', 1, GETDATE()),

-- PERSONAL DE SEGURIDAD
('seguridad_a', 'temporal_hash_seg_a', 'Seguridad Turno A', 'operador', 1, GETDATE()),
('seguridad_b', 'temporal_hash_seg_b', 'Seguridad Turno B', 'operador', 1, GETDATE()),

-- PERSONAL DE ALMACÉN
('almacen_1', 'temporal_hash_alm1', 'Almacenero Principal', 'operador', 1, GETDATE()),
('almacen_2', 'temporal_hash_alm2', 'Almacenero Auxiliar', 'operador', 1, GETDATE());

DECLARE @count_usuarios INT = @@ROWCOUNT;

PRINT '✅ Usuarios insertados correctamente';

-- =========================================================
-- 5. VERIFICACIÓN DE DATOS INSERTADOS
-- =========================================================

PRINT '';
PRINT '📊 VERIFICANDO DATOS INSERTADOS:';

-- Contar explosivos por tipo
SELECT 
    LEFT(codigo, 4) as tipo,
    CASE 
        WHEN LEFT(codigo, 4) = '0302' THEN 'Emulsiones'
        WHEN LEFT(codigo, 4) = '0303' THEN 'Detonadores FANEL' 
        WHEN LEFT(codigo, 4) = '0304' THEN 'ANFO'
        WHEN LEFT(codigo, 4) = '0305' THEN 'Accesorios'
        WHEN LEFT(codigo, 4) = '0306' THEN 'Cordón Detonante'
        ELSE 'Otros'
    END as categoria,
    COUNT(*) as cantidad
FROM explosivos 
WHERE activo = 1
GROUP BY LEFT(codigo, 4)
ORDER BY LEFT(codigo, 4);

-- Contar usuarios por cargo
SELECT 
    cargo,
    COUNT(*) as cantidad
FROM usuarios 
WHERE activo = 1
GROUP BY cargo
ORDER BY cargo;

-- =========================================================
-- 6. HABILITAR RESTRICCIONES
-- =========================================================

PRINT '🔧 Rehabilitando restricciones de integridad...';

-- Rehabilitar todas las restricciones
ALTER TABLE ingresos CHECK CONSTRAINT ALL;
ALTER TABLE salidas CHECK CONSTRAINT ALL;
ALTER TABLE devoluciones CHECK CONSTRAINT ALL;
ALTER TABLE stock_diario CHECK CONSTRAINT ALL;

PRINT '✅ Restricciones rehabilitadas';

-- =========================================================
-- RESUMEN FINAL
-- =========================================================

DECLARE @total_explosivos INT;
DECLARE @total_usuarios INT;

SELECT @total_explosivos = COUNT(*) FROM explosivos WHERE activo = 1;
SELECT @total_usuarios = COUNT(*) FROM usuarios WHERE activo = 1;

PRINT '';
PRINT '🎉 ¡DATOS MAESTROS INSERTADOS EXITOSAMENTE EN AZURE!';
PRINT '';
PRINT '📋 RESUMEN:';
PRINT CONCAT('   💥 Explosivos: ', CAST(@total_explosivos AS VARCHAR));
PRINT CONCAT('   👥 Usuarios: ', CAST(@total_usuarios AS VARCHAR));
PRINT '';
PRINT '⚠️  IMPORTANTE: ';
PRINT '   🔑 Las contraseñas de usuarios son TEMPORALES';
PRINT '   🔑 Cambiar contraseñas en primera conexión';
PRINT '   🔑 Usuario admin: username = admin';
PRINT '   📦 Códigos originales del polvorín PALLCA';
PRINT '';
PRINT '🚀 SIGUIENTE PASO: Ejecutar script de stock inicial';
PRINT '';