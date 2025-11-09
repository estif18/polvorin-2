-- =========================================================
-- STOCK INICIAL - AZURE SQL DATABASE - PALLCA
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0 Azure
-- Descripción: Stock inicial de explosivos para polvorín PALLCA

PRINT '📊 Verificando conexión a PALLCA en Azure...';
SELECT DB_NAME() as BaseDatosActual;

-- =========================================================
-- 1. VERIFICAR DATOS MAESTROS
-- =========================================================

PRINT '🔍 Verificando datos maestros...';

DECLARE @count_explosivos INT;
DECLARE @count_usuarios INT;

SELECT @count_explosivos = COUNT(*) FROM explosivos WHERE activo = 1;
SELECT @count_usuarios = COUNT(*) FROM usuarios WHERE activo = 1;

IF @count_explosivos = 0
BEGIN
    PRINT '❌ ERROR: No hay explosivos en la base de datos';
    PRINT '⚠️  Ejecutar primero: 03_insertar_datos_maestros_azure.sql';
    RETURN;
END

IF @count_usuarios = 0
BEGIN
    PRINT '❌ ERROR: No hay usuarios en la base de datos';
    PRINT '⚠️  Ejecutar primero: 03_insertar_datos_maestros_azure.sql';
    RETURN;
END

PRINT CONCAT('✅ Explosivos disponibles: ', @count_explosivos);
PRINT CONCAT('✅ Usuarios disponibles: ', @count_usuarios);

-- =========================================================
-- 2. LIMPIAR MOVIMIENTOS EXISTENTES
-- =========================================================

PRINT '🧹 Limpiando movimientos existentes...';

-- Deshabilitar restricciones temporalmente
ALTER TABLE stock_diario NOCHECK CONSTRAINT ALL;
ALTER TABLE devoluciones NOCHECK CONSTRAINT ALL;
ALTER TABLE salidas NOCHECK CONSTRAINT ALL;
ALTER TABLE ingresos NOCHECK CONSTRAINT ALL;

-- Limpiar en orden
DELETE FROM stock_diario;
DELETE FROM devoluciones;
DELETE FROM salidas;
DELETE FROM ingresos;

-- Reiniciar contadores
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ingresos')
    DBCC CHECKIDENT ('ingresos', RESEED, 0);
    
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'salidas')
    DBCC CHECKIDENT ('salidas', RESEED, 0);
    
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'devoluciones')
    DBCC CHECKIDENT ('devoluciones', RESEED, 0);
    
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'stock_diario')
    DBCC CHECKIDENT ('stock_diario', RESEED, 0);

PRINT '✅ Movimientos limpiados';

-- =========================================================
-- 3. INSERTAR STOCK INICIAL VIA INGRESOS
-- =========================================================

PRINT '📦 Creando stock inicial mediante ingresos...';

-- Obtener ID del usuario administrador para los ingresos iniciales
DECLARE @admin_user NVARCHAR(100);
SELECT TOP 1 @admin_user = nombre FROM usuarios WHERE rol = 'admin' AND activo = 1;

IF @admin_user IS NULL
    SET @admin_user = 'Sistema';

-- Fecha de stock inicial (ayer para que aparezca como stock previo)
DECLARE @fecha_inicial DATE = DATEADD(DAY, -1, GETDATE());

-- Insertar ingresos iniciales por categorías
INSERT INTO ingresos (explosivo_id, cantidad, fecha_ingreso, guardia, numero_vale, recibido_por, observaciones, fecha_creacion)
SELECT 
    e.id as explosivo_id,
    CASE 
        -- EXPLOSIVOS PRINCIPALES (mayor cantidad)
        WHEN e.codigo LIKE 'EX%' THEN 
            CASE 
                WHEN e.codigo IN ('EX001', 'EX002') THEN 5000.00  -- ANFO y Emulsiones
                WHEN e.codigo = 'EX003' THEN 3000.00              -- Emulsión alta densidad  
                WHEN e.codigo = 'EX004' THEN 2000.00              -- Gelignite (cartuchos)
                WHEN e.codigo = 'EX005' THEN 1500.00              -- Pulvex
                ELSE 1000.00
            END
            
        -- INICIADORES Y MULTIPLICADORES
        WHEN e.codigo LIKE 'IN%' THEN
            CASE
                WHEN e.codigo IN ('IN002', 'IN003') THEN 2000.00  -- Cordón detonante (metros)
                WHEN e.codigo = 'IN001' THEN 500.00               -- Pentrita
                WHEN e.codigo IN ('IN004', 'IN005') THEN 200.00   -- Boosters
                ELSE 300.00
            END
            
        -- DETONADORES (cantidades moderadas)
        WHEN e.codigo LIKE 'DE%' THEN
            CASE
                WHEN e.codigo = 'DE001' THEN 1000.00              -- Instantáneos
                WHEN e.codigo IN ('DE002', 'DE003') THEN 800.00   -- Microrretardos
                WHEN e.codigo IN ('DE004', 'DE005') THEN 600.00   -- Retardos largos
                ELSE 400.00
            END
            
        -- ACCESORIOS (cantidades variables)
        WHEN e.codigo LIKE 'AC%' THEN
            CASE
                WHEN e.codigo = 'AC001' THEN 1500.00              -- Mecha (metros)
                WHEN e.codigo = 'AC002' THEN 500.00               -- Fulminantes
                WHEN e.codigo IN ('AC003', 'AC004') THEN 100.00   -- Conectores y cintas
                ELSE 200.00
            END
            
        -- HERRAMIENTAS (pocas unidades)
        WHEN e.codigo LIKE 'HE%' THEN
            CASE
                WHEN e.codigo IN ('HE001', 'HE002') THEN 20.00    -- Punzones y atacadores
                WHEN e.codigo IN ('HE003', 'HE004') THEN 5.00     -- Equipos electrónicos
                ELSE 10.00
            END
            
        -- SEGURIDAD (cantidades moderadas)
        WHEN e.codigo LIKE 'SE%' THEN
            CASE
                WHEN e.codigo = 'SE001' THEN 500.00               -- Banderolas (metros)
                WHEN e.codigo IN ('SE002', 'SE003', 'SE004') THEN 10.00  -- Equipos
                ELSE 15.00
            END
            
        ELSE 100.00  -- Valor por defecto
    END as cantidad,
    
    @fecha_inicial as fecha_ingreso,
    'GUARDIA_INICIAL' as guardia,
    CONCAT('INIT-', FORMAT(GETDATE(), 'yyyyMMdd'), '-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.descripcion, ' - Inventario base del polvorín') as observaciones,
    GETDATE() as fecha_creacion
    
FROM explosivos e
WHERE e.activo = 1
ORDER BY e.codigo;

PRINT CONCAT('✅ Insertados ', @@ROWCOUNT, ' ingresos de stock inicial');

-- =========================================================
-- 4. CREAR STOCK DIARIO INICIAL
-- =========================================================

PRINT '📊 Generando registro de stock diario inicial...';

-- Insertar stock diario basado en los ingresos
INSERT INTO stock_diario (explosivo_id, fecha, stock_inicial, ingresos_dia, salidas_dia, devoluciones_dia, stock_final, observaciones, fecha_creacion)
SELECT 
    i.explosivo_id,
    @fecha_inicial as fecha,
    0.00 as stock_inicial,                    -- Stock inicial era 0
    SUM(i.cantidad) as ingresos_dia,          -- Suma de ingresos del día
    0.00 as salidas_dia,                      -- Sin salidas el primer día
    0.00 as devoluciones_dia,                 -- Sin devoluciones el primer día
    SUM(i.cantidad) as stock_final,           -- Stock final = ingresos
    'STOCK INICIAL - Primer día de operaciones' as observaciones,
    GETDATE() as fecha_creacion
FROM ingresos i
WHERE CAST(i.fecha_ingreso AS DATE) = @fecha_inicial
GROUP BY i.explosivo_id;

PRINT CONCAT('✅ Generados ', @@ROWCOUNT, ' registros de stock diario');

-- =========================================================
-- 5. VERIFICACIÓN DE STOCK INICIAL
-- =========================================================

PRINT '';
PRINT '📊 VERIFICANDO STOCK INICIAL CREADO:';

-- Resumen por categorías
SELECT 
    CASE 
        WHEN e.codigo LIKE 'EX%' THEN '💥 EXPLOSIVOS'
        WHEN e.codigo LIKE 'IN%' THEN '🔥 INICIADORES' 
        WHEN e.codigo LIKE 'DE%' THEN '⚡ DETONADORES'
        WHEN e.codigo LIKE 'AC%' THEN '🔧 ACCESORIOS'
        WHEN e.codigo LIKE 'HE%' THEN '🛠️ HERRAMIENTAS'
        WHEN e.codigo LIKE 'SE%' THEN '🛡️ SEGURIDAD'
        ELSE '❓ OTROS'
    END as categoria,
    COUNT(DISTINCT e.id) as tipos_explosivos,
    SUM(i.cantidad) as stock_total,
    MIN(i.cantidad) as stock_minimo,
    MAX(i.cantidad) as stock_maximo
FROM explosivos e
JOIN ingresos i ON e.id = i.explosivo_id
WHERE CAST(i.fecha_ingreso AS DATE) = @fecha_inicial
GROUP BY 
    CASE 
        WHEN e.codigo LIKE 'EX%' THEN '💥 EXPLOSIVOS'
        WHEN e.codigo LIKE 'IN%' THEN '🔥 INICIADORES'
        WHEN e.codigo LIKE 'DE%' THEN '⚡ DETONADORES'
        WHEN e.codigo LIKE 'AC%' THEN '🔧 ACCESORIOS'
        WHEN e.codigo LIKE 'HE%' THEN '🛠️ HERRAMIENTAS'
        WHEN e.codigo LIKE 'SE%' THEN '🛡️ SEGURIDAD'
        ELSE '❓ OTROS'
    END
ORDER BY categoria;

-- Stock por explosivo (top 10)
PRINT '';
PRINT '🔝 TOP 10 EXPLOSIVOS CON MÁS STOCK:';
SELECT TOP 10
    e.codigo,
    e.descripcion,
    i.cantidad as stock_inicial,
    e.unidad
FROM explosivos e
JOIN ingresos i ON e.id = i.explosivo_id  
WHERE CAST(i.fecha_ingreso AS DATE) = @fecha_inicial
ORDER BY i.cantidad DESC;

-- =========================================================
-- 6. REHABILITAR RESTRICCIONES
-- =========================================================

PRINT '';
PRINT '🔧 Rehabilitando restricciones de integridad...';

ALTER TABLE ingresos CHECK CONSTRAINT ALL;
ALTER TABLE salidas CHECK CONSTRAINT ALL;
ALTER TABLE devoluciones CHECK CONSTRAINT ALL;
ALTER TABLE stock_diario CHECK CONSTRAINT ALL;

PRINT '✅ Restricciones rehabilitadas';

-- =========================================================
-- 7. PROBAR VISTA DE STOCK
-- =========================================================

PRINT '';
PRINT '🧪 Probando vista de stock actual...';

-- Verificar que la vista funciona
IF OBJECT_ID('v_stock_actual', 'V') IS NOT NULL
BEGIN
    DECLARE @stock_items INT;
    SELECT @stock_items = COUNT(*) FROM v_stock_actual WHERE stock_actual > 0;
    PRINT CONCAT('✅ Vista v_stock_actual funcionando: ', @stock_items, ' items con stock');
END
ELSE
BEGIN
    PRINT '⚠️  Vista v_stock_actual no existe. Ejecutar 02_crear_vistas_azure.sql';
END

-- =========================================================
-- RESUMEN FINAL
-- =========================================================

PRINT '';
PRINT '🎉 ¡STOCK INICIAL CREADO EXITOSAMENTE EN AZURE!';
PRINT '';
PRINT '📋 RESUMEN FINAL:';
PRINT CONCAT('   📦 Total ingresos iniciales: ', (SELECT COUNT(*) FROM ingresos WHERE CAST(fecha_ingreso AS DATE) = @fecha_inicial));
PRINT CONCAT('   📊 Registros stock diario: ', (SELECT COUNT(*) FROM stock_diario WHERE fecha = @fecha_inicial));
PRINT CONCAT('   💰 Valor total items: ', (SELECT COUNT(DISTINCT explosivo_id) FROM ingresos WHERE CAST(fecha_ingreso AS DATE) = @fecha_inicial));
PRINT CONCAT('   📅 Fecha stock inicial: ', FORMAT(@fecha_inicial, 'dd/MM/yyyy'));
PRINT '';
PRINT '🚀 SISTEMA LISTO PARA OPERACIONES';
PRINT '✅ Polvorín PALLCA operativo en Azure SQL Database';
PRINT '';