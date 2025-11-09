-- =========================================================
-- SCRIPT DE POBLADO INICIAL DE DATOS MAESTROS
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0
-- Descripción: Poblar con los datos maestros básicos del sistema

USE pallca;
GO

PRINT '📊 POBLANDO DATOS MAESTROS DEL SISTEMA POLVORÍN';
PRINT '=' * 44;

-- =========================================================
-- 1. POBLAR TABLA EXPLOSIVOS
-- =========================================================

PRINT '📦 Poblando explosivos maestros...';

-- Verificar si ya hay datos
IF NOT EXISTS (SELECT 1 FROM explosivos)
BEGIN
    PRINT '🔄 Insertando catálogo de explosivos...';
    
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
    
    DECLARE @total_explosivos INT = @@ROWCOUNT;
    PRINT '✅ ' + CAST(@total_explosivos AS VARCHAR(10)) + ' explosivos insertados';
END
ELSE
BEGIN
    DECLARE @count_existentes INT = (SELECT COUNT(*) FROM explosivos);
    PRINT '⚠️  Ya existen ' + CAST(@count_existentes AS VARCHAR(10)) + ' explosivos - omitiendo inserción';
END

-- =========================================================
-- 2. CREAR USUARIO ADMINISTRADOR INICIAL
-- =========================================================

PRINT '👤 Verificando usuario administrador...';

-- Verificar si ya existe usuario admin
IF NOT EXISTS (SELECT 1 FROM usuarios WHERE username = 'admin')
BEGIN
    PRINT '🔄 Creando usuario administrador inicial...';
    
    -- Crear usuario admin con password hash para "admin123"
    INSERT INTO usuarios (username, password_hash, nombre_completo, email, rol, activo)
    VALUES (
        'admin',
        'pbkdf2:sha256:600000$salt$hash_example', -- Cambiar por hash real en producción
        'Administrador del Sistema',
        'admin@pallca.com',
        'admin',
        1
    );
    
    PRINT '✅ Usuario administrador creado (username: admin)';
    PRINT '⚠️  IMPORTANTE: Cambiar la contraseña en el primer login';
END
ELSE
BEGIN
    PRINT '⚠️  Usuario administrador ya existe - omitiendo';
END

-- =========================================================
-- 3. VERIFICAR INTEGRIDAD DE DATOS
-- =========================================================

PRINT '🔍 Verificando integridad de datos...';

-- Contar registros en cada tabla
DECLARE @explosivos_count INT = (SELECT COUNT(*) FROM explosivos);
DECLARE @usuarios_count INT = (SELECT COUNT(*) FROM usuarios);
DECLARE @ingresos_count INT = (SELECT COUNT(*) FROM ingresos);
DECLARE @salidas_count INT = (SELECT COUNT(*) FROM salidas);
DECLARE @devoluciones_count INT = (SELECT COUNT(*) FROM devoluciones);

PRINT '';
PRINT '📊 RESUMEN DE DATOS EN BASE:';
PRINT '   📦 Explosivos: ' + CAST(@explosivos_count AS VARCHAR(10));
PRINT '   👤 Usuarios: ' + CAST(@usuarios_count AS VARCHAR(10));
PRINT '   📥 Ingresos: ' + CAST(@ingresos_count AS VARCHAR(10));
PRINT '   📤 Salidas: ' + CAST(@salidas_count AS VARCHAR(10));
PRINT '   🔄 Devoluciones: ' + CAST(@devoluciones_count AS VARCHAR(10));

-- =========================================================
-- 4. OPCIONAL: CREAR STOCK INICIAL HIPOTÉTICO
-- =========================================================

PRINT '';
PRINT '💡 STOCK INICIAL OPCIONAL';
PRINT '=========================';
PRINT 'Para crear stock inicial de 1000 unidades por explosivo:';
PRINT '1. Ejecutar el script Python: crear_stock_inicial.py';
PRINT 'O';
PRINT '2. Usar la función manual desde la aplicación web';
PRINT '';

-- =========================================================
-- RESUMEN FINAL
-- =========================================================

PRINT '🎉 ¡DATOS MAESTROS CONFIGURADOS EXITOSAMENTE!';
PRINT '';
PRINT '✅ COMPLETADO:';
PRINT '   📦 Catálogo de explosivos (37 items)';
PRINT '   👤 Usuario administrador inicial';
PRINT '   🔍 Verificación de integridad';
PRINT '';
PRINT '🚀 SIGUIENTE PASO:';
PRINT '   1. Ejecutar aplicación: python app.py';
PRINT '   2. Acceder con usuario: admin';
PRINT '   3. Crear stock inicial si es necesario';
PRINT '';

GO