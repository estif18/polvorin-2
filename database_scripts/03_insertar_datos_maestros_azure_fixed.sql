-- =========================================================
-- INSERTAR DATOS MAESTROS - AZURE SQL DATABASE - PALLCA (FIXED)
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0 Azure Fixed
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
DELETE FROM usuarios WHERE email != 'admin@pallca.com';
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
-- EXPLOSIVOS PRIMARIOS
('EX001', 'ANFO (Nitrato de Amonio + Fuel Oil)', 'kg', 1, GETDATE()),
('EX002', 'Emulnor 3000 - Emulsión explosiva', 'kg', 1, GETDATE()),
('EX003', 'Emulnor 5000 - Emulsión alta densidad', 'kg', 1, GETDATE()),
('EX004', 'Gelignite 60% - Dinamita gelatinosa', 'cartucho', 1, GETDATE()),
('EX005', 'Pulvex - Explosivo pulverulento', 'kg', 1, GETDATE()),

-- INICIADORES Y MULTIPLICADORES  
('IN001', 'Pentrita (PETN) - Multiplicador', 'kg', 1, GETDATE()),
('IN002', 'Cord-ex 5gr/m - Cordón detonante', 'm', 1, GETDATE()),
('IN003', 'Cord-ex 10gr/m - Cordón detonante reforzado', 'm', 1, GETDATE()),
('IN004', 'Booster 400gr - Multiplicador cilíndrico', 'unidad', 1, GETDATE()),
('IN005', 'Booster 200gr - Multiplicador pequeño', 'unidad', 1, GETDATE()),

-- DETONADORES
('DE001', 'Detonador N°8 - Instantáneo', 'unidad', 1, GETDATE()),
('DE002', 'Detonador retardo 25ms - Microrretardo', 'unidad', 1, GETDATE()),
('DE003', 'Detonador retardo 50ms - Retardo corto', 'unidad', 1, GETDATE()),
('DE004', 'Detonador retardo 100ms - Retardo medio', 'unidad', 1, GETDATE()),
('DE005', 'Detonador retardo 200ms - Retardo largo', 'unidad', 1, GETDATE()),

-- ACCESORIOS DE VOLADURA
('AC001', 'Mecha de seguridad - 1.2cm/min', 'm', 1, GETDATE()),
('AC002', 'Fulminante N°8 - Para mecha', 'unidad', 1, GETDATE()),
('AC003', 'Conectores para cordón detonante', 'unidad', 1, GETDATE()),
('AC004', 'Cinta aislante para voladura', 'rollo', 1, GETDATE()),

-- HERRAMIENTAS Y EQUIPOS
('HE001', 'Punzón de cobre para taladros', 'unidad', 1, GETDATE()),
('HE002', 'Atacador de madera', 'unidad', 1, GETDATE()),
('HE003', 'Ohmetro digital para pruebas', 'unidad', 1, GETDATE()),
('HE004', 'Multitester explosivista', 'unidad', 1, GETDATE()),

-- MATERIALES DE SEGURIDAD
('SE001', 'Banderolas de señalización', 'm', 1, GETDATE()),
('SE002', 'Silbato de evacuación', 'unidad', 1, GETDATE()),
('SE003', 'Radio comunicador UHF', 'unidad', 1, GETDATE()),
('SE004', 'Lámpara antiexplosión', 'unidad', 1, GETDATE());

DECLARE @count_explosivos INT = @@ROWCOUNT;

PRINT '✅ Explosivos insertados correctamente';

-- =========================================================
-- 4. INSERTAR USUARIOS DEL SISTEMA
-- =========================================================

PRINT '👥 Insertando usuarios del sistema...';

-- Nota: Las contraseñas deben hashearse en la aplicación Python
INSERT INTO usuarios (nombre, email, rol, activo, fecha_creacion, password_hash) VALUES
-- ADMINISTRADORES
('Administrador Principal', 'admin@pallca.com', 'admin', 1, GETDATE(), 'temporal_hash_admin'),
('Jefe de Operaciones', 'jefe.operaciones@pallca.com', 'admin', 1, GETDATE(), 'temporal_hash_jefe'),

-- SUPERVISORES DE GUARDIA
('Supervisor Guardia A', 'supervisor.a@pallca.com', 'supervisor', 1, GETDATE(), 'temporal_hash_sup_a'),
('Supervisor Guardia B', 'supervisor.b@pallca.com', 'supervisor', 1, GETDATE(), 'temporal_hash_sup_b'), 
('Supervisor Guardia C', 'supervisor.c@pallca.com', 'supervisor', 1, GETDATE(), 'temporal_hash_sup_c'),
('Supervisor Guardia D', 'supervisor.d@pallca.com', 'supervisor', 1, GETDATE(), 'temporal_hash_sup_d'),

-- OPERADORES DE POLVORÍN
('Polvorinero Principal', 'polvorinero.principal@pallca.com', 'operador', 1, GETDATE(), 'temporal_hash_pol1'),
('Polvorinero Auxiliar', 'polvorinero.auxiliar@pallca.com', 'operador', 1, GETDATE(), 'temporal_hash_pol2'),

-- PERSONAL DE VOLADURA
('Voladura Jefe', 'voladura.jefe@pallca.com', 'supervisor', 1, GETDATE(), 'temporal_hash_vol_jefe'),
('Voladura Operador 1', 'voladura.op1@pallca.com', 'operador', 1, GETDATE(), 'temporal_hash_vol1'),
('Voladura Operador 2', 'voladura.op2@pallca.com', 'operador', 1, GETDATE(), 'temporal_hash_vol2'),
('Voladura Operador 3', 'voladura.op3@pallca.com', 'operador', 1, GETDATE(), 'temporal_hash_vol3'),

-- PERSONAL DE SEGURIDAD
('Seguridad Turno A', 'seguridad.a@pallca.com', 'operador', 1, GETDATE(), 'temporal_hash_seg_a'),
('Seguridad Turno B', 'seguridad.b@pallca.com', 'operador', 1, GETDATE(), 'temporal_hash_seg_b'),

-- PERSONAL DE ALMACÉN
('Almacenero Principal', 'almacen.principal@pallca.com', 'operador', 1, GETDATE(), 'temporal_hash_alm1'),
('Almacenero Auxiliar', 'almacen.auxiliar@pallca.com', 'operador', 1, GETDATE(), 'temporal_hash_alm2');

DECLARE @count_usuarios INT = @@ROWCOUNT;

PRINT '✅ Usuarios insertados correctamente';

-- =========================================================
-- 5. VERIFICACIÓN DE DATOS INSERTADOS
-- =========================================================

PRINT '';
PRINT '📊 VERIFICANDO DATOS INSERTADOS:';

-- Contar explosivos por tipo
SELECT 
    LEFT(codigo, 2) as tipo,
    CASE 
        WHEN LEFT(codigo, 2) = 'EX' THEN 'Explosivos'
        WHEN LEFT(codigo, 2) = 'IN' THEN 'Iniciadores'
        WHEN LEFT(codigo, 2) = 'DE' THEN 'Detonadores' 
        WHEN LEFT(codigo, 2) = 'AC' THEN 'Accesorios'
        WHEN LEFT(codigo, 2) = 'HE' THEN 'Herramientas'
        WHEN LEFT(codigo, 2) = 'SE' THEN 'Seguridad'
        ELSE 'Otros'
    END as categoria,
    COUNT(*) as cantidad
FROM explosivos 
WHERE activo = 1
GROUP BY LEFT(codigo, 2)
ORDER BY LEFT(codigo, 2);

-- Contar usuarios por rol
SELECT 
    rol,
    COUNT(*) as cantidad
FROM usuarios 
WHERE activo = 1
GROUP BY rol
ORDER BY rol;

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
PRINT '   🔑 Usuario admin por defecto: admin@pallca.com';
PRINT '';
PRINT '🚀 SIGUIENTE PASO: Ejecutar script de stock inicial';
PRINT '';