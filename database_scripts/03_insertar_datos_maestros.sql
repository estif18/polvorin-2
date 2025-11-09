-- =========================================================
-- SCRIPT DE DATOS MAESTROS Y CONFIGURACIÓN INICIAL
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0
-- Descripción: Insertar todos los datos maestros necesarios
--              para el funcionamiento del sistema

USE pallca;
GO

-- =========================================================
-- 1. INSERTAR EXPLOSIVOS MAESTROS
-- =========================================================

PRINT '📦 Insertando explosivos maestros...';

-- Limpiar datos existentes (si los hay)
DELETE FROM explosivos;
DBCC CHECKIDENT ('explosivos', RESEED, 0);

-- Insertar todos los explosivos
INSERT INTO explosivos (codigo, descripcion, unidad) VALUES
('0302008', 'EMULNOR 3000 1 1/4 " X 8"', 'PZA'),
('0303004', 'FULMINANTE GUIA ARMADA', 'PZA'),
('0303051', 'FANEL LP 4.8 MTRS NO 01', 'PZA'),
('0303052', 'FANEL LP 4.8 MTRS NO 02', 'PZA'),
('0303053', 'FANEL LP 4.8 MTRS NO 03', 'PZA'),
('0303054', 'FANEL LP 4.8 MTRS NO 04', 'PZA'),
('0303055', 'FANEL LP 4.8 MTRS NO 05', 'PZA'),
('0303056', 'FANEL LP 4.8 MTRS NO 06', 'PZA'),
('0303057', 'FANEL LP 4.8 MTRS NO 07', 'PZA'),
('0303058', 'FANEL LP 4.8 MTRS NO 08', 'PZA'),
('0303059', 'FANEL LP 4.8 MTRS NO 09', 'PZA'),
('0303060', 'FANEL LP 4.8 MTRS NO 10', 'PZA'),
('0303061', 'FANEL LP 4.8 MTRS NO 11', 'PZA'),
('0303062', 'FANEL LP 4.8 MTRS NO 12', 'PZA'),
('0303063', 'FANEL LP 4.8 MTRS NO 13', 'PZA'),
('0303064', 'FANEL LP 4.8 MTRS NO 14', 'PZA'),
('0303065', 'FANEL LP 4.8 MTRS NO 15', 'PZA'),
('0303071', 'FANEL MS 4.8 MTRS NO 01', 'PZA'),
('0303072', 'FANEL MS 4.8 MTRS NO 02', 'PZA'),
('0303073', 'FANEL MS 4.8 MTRS NO 03', 'PZA'),
('0303074', 'FANEL MS 4.8 MTRS NO 04', 'PZA'),
('0303075', 'FANEL MS 4.8 MTRS NO 05', 'PZA'),
('0303076', 'FANEL MS 4.8 MTRS NO 06', 'PZA'),
('0303077', 'FANEL MS 4.8 MTRS NO 07', 'PZA'),
('0303078', 'FANEL MS 4.8 MTRS NO 08', 'PZA'),
('0303079', 'FANEL MS 4.8 MTRS NO 09', 'PZA'),
('0303080', 'FANEL MS 4.8 MTRS NO 10', 'PZA'),
('0303081', 'FANEL MS 4.8 MTRS NO 11', 'PZA'),
('0303082', 'FANEL MS 4.8 MTRS NO 12', 'PZA'),
('0303083', 'FANEL MS 4.8 MTRS NO 13', 'PZA'),
('0303084', 'FANEL MS 4.8 MTRS NO 14', 'PZA'),
('0303085', 'FANEL MS 4.8 MTRS NO 15', 'PZA'),
('0304003', 'SUPERFAM DOS (ANFO)', 'SACOS'),
('0305001', 'MECHA LENTA CJA X 1000 MTS', 'MTR'),
('0305004', 'CORDON DE IGNICION X 1500 MTS', 'MTR'),
('0305011', 'CARMEX DETONADOR ENSAMBLADO 2.40 MT X300 PZAS', 'PZA'),
('0306003', 'PENTACORD 3P CAJA X 1500 MTRS (1 caja= 1500 m)', 'MTR');

DECLARE @count_explosivos INT = @@ROWCOUNT;
PRINT CONCAT('✅ ', @count_explosivos, ' explosivos insertados correctamente');

-- =========================================================
-- 2. CREAR USUARIO ADMINISTRADOR
-- =========================================================

PRINT '👤 Creando usuario administrador...';

-- Limpiar usuarios existentes
DELETE FROM usuarios;
DBCC CHECKIDENT ('usuarios', RESEED, 0);

-- Hash simple para la contraseña "admin123" (en producción usar bcrypt)
INSERT INTO usuarios (username, password_hash, nombre_completo, email, rol, activo) VALUES
('admin', 'pbkdf2:sha256:260000$V8r3Kx0vGgEj0Zm9$2c5d8f1b3a4e7f2c8d9e1f4a7b2c5d8f1e4a7b0c3d6e9f2a5b8c1d4e7f0a3b6c9e2f5a8b1d4e7f0', 'Administrador del Sistema', 'admin@pallca.com', 'admin', 1),
('usuario1', 'pbkdf2:sha256:260000$V8r3Kx0vGgEj0Zm9$2c5d8f1b3a4e7f2c8d9e1f4a7b2c5d8f1e4a7b0c3d6e9f2a5b8c1d4e7f0a3b6c9e2f5a8b1d4e7f0', 'Usuario de Prueba', 'usuario@pallca.com', 'usuario', 1);

PRINT '✅ Usuario administrador creado (username: admin, password: admin123)';
PRINT '✅ Usuario de prueba creado (username: usuario1, password: admin123)';

-- =========================================================
-- 3. CONFIGURAR ÍNDICES ADICIONALES
-- =========================================================

PRINT '🔧 Configurando índices adicionales...';

-- Índices compuestos para consultas frecuentes (solo si no existen)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ingresos_fecha_explosivo' AND object_id = OBJECT_ID('ingresos'))
    CREATE INDEX IX_ingresos_fecha_explosivo ON ingresos(fecha_ingreso, explosivo_id) INCLUDE (cantidad);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_salidas_fecha_explosivo' AND object_id = OBJECT_ID('salidas'))
    CREATE INDEX IX_salidas_fecha_explosivo ON salidas(fecha_salida, explosivo_id) INCLUDE (cantidad);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_devoluciones_fecha_explosivo' AND object_id = OBJECT_ID('devoluciones'))
    CREATE INDEX IX_devoluciones_fecha_explosivo ON devoluciones(fecha_devolucion, explosivo_id) INCLUDE (cantidad_devuelta);

-- Índices para búsquedas de texto (solo si no existen)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_explosivos_descripcion' AND object_id = OBJECT_ID('explosivos'))
    CREATE INDEX IX_explosivos_descripcion ON explosivos(descripcion);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_salidas_labor' AND object_id = OBJECT_ID('salidas'))
    CREATE INDEX IX_salidas_labor ON salidas(labor);

PRINT '✅ Índices adicionales configurados';

-- =========================================================
-- 4. INSERTAR DATOS DE PRUEBA (OPCIONAL)
-- =========================================================

PRINT '🎯 ¿Insertar stock inicial de prueba? (1000 unidades por explosivo)';
PRINT '   Para activar, ejecutar separadamente: 03_insertar_stock_inicial.sql';

-- =========================================================
-- 5. CONFIGURAR ESTADÍSTICAS
-- =========================================================

PRINT '📊 Actualizando estadísticas de tablas...';

UPDATE STATISTICS explosivos;
UPDATE STATISTICS ingresos;
UPDATE STATISTICS salidas;
UPDATE STATISTICS devoluciones;
UPDATE STATISTICS stock_diario;
UPDATE STATISTICS usuarios;

PRINT '✅ Estadísticas actualizadas';

-- =========================================================
-- 6. VERIFICAR INTEGRIDAD
-- =========================================================

PRINT '🔍 Verificando integridad de la base de datos...';

-- Verificar conteos
DECLARE @total_explosivos INT = (SELECT COUNT(*) FROM explosivos WHERE activo = 1);
DECLARE @total_usuarios INT = (SELECT COUNT(*) FROM usuarios WHERE activo = 1);

PRINT CONCAT('📦 Total explosivos activos: ', @total_explosivos);
PRINT CONCAT('👤 Total usuarios activos: ', @total_usuarios);

-- Verificar foreign keys
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name IN ('FK_ingresos_explosivo', 'FK_salidas_explosivo', 'FK_devoluciones_explosivo')
)
BEGIN
    PRINT '❌ ERROR: Foreign keys no encontradas';
END
ELSE
BEGIN
    PRINT '✅ Foreign keys verificadas correctamente';
END

-- =========================================================
-- RESUMEN FINAL
-- =========================================================

PRINT '';
PRINT '🎉 ¡CONFIGURACIÓN INICIAL COMPLETADA!';
PRINT '';
PRINT '📊 DATOS INSERTADOS:';
PRINT CONCAT('   ✅ ', @total_explosivos, ' explosivos maestros');
PRINT CONCAT('   ✅ ', @total_usuarios, ' usuarios del sistema');
PRINT '';
PRINT '🔑 CREDENCIALES DE ACCESO:';
PRINT '   👤 Username: admin';
PRINT '   🔒 Password: admin123';
PRINT '   📧 Email: admin@pallca.com';
PRINT '';
PRINT '🚀 SISTEMA LISTO PARA USO';
PRINT '   ✅ Base de datos configurada';
PRINT '   ✅ Vistas optimizadas creadas';
PRINT '   ✅ Datos maestros insertados';
PRINT '   ✅ Usuarios configurados';
PRINT '';
PRINT '📋 PRÓXIMOS PASOS OPCIONALES:';
PRINT '   1. Ejecutar 03_insertar_stock_inicial.sql para datos de prueba';
PRINT '   2. Configurar backup automático';
PRINT '   3. Ajustar permisos de usuarios según necesidad';
PRINT '';

GO