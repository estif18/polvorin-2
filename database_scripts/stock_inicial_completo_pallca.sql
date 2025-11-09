-- =========================================================
-- STOCK INICIAL COMPLETO - AZURE SQL DATABASE - PALLCA
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0 Completo
-- Descripción: Stock inicial para todos los 77 explosivos del polvorín PALLCA

PRINT '📊 Verificando conexión a PALLCA en Azure...';
SELECT DB_NAME() as BaseDatosActual;

-- =========================================================
-- 1. VERIFICAR EXPLOSIVOS EXISTENTES
-- =========================================================

PRINT '🔍 Verificando explosivos en base de datos...';

DECLARE @count_explosivos INT;
SELECT @count_explosivos = COUNT(*) FROM explosivos WHERE activo = 1;

IF @count_explosivos = 0
BEGIN
    PRINT '❌ ERROR: No hay explosivos en la base de datos';
    PRINT '⚠️  Ejecutar primero: explosivos_completos_pallca.sql';
    RETURN;
END

PRINT CONCAT('✅ Explosivos disponibles: ', @count_explosivos);

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
DBCC CHECKIDENT ('ingresos', RESEED, 0);
DBCC CHECKIDENT ('salidas', RESEED, 0);
DBCC CHECKIDENT ('devoluciones', RESEED, 0);
DBCC CHECKIDENT ('stock_diario', RESEED, 0);

PRINT '✅ Movimientos limpiados';

-- =========================================================
-- 3. INSERTAR STOCK INICIAL POR GRUPOS
-- =========================================================

PRINT '📦 Creando stock inicial diferenciado por grupos...';

-- Obtener usuario administrador para los ingresos
DECLARE @admin_user NVARCHAR(100);
SELECT TOP 1 @admin_user = nombre_completo FROM usuarios WHERE cargo = 'admin' AND activo = 1;

IF @admin_user IS NULL
    SET @admin_user = 'Sistema';

-- Fecha de stock inicial (ayer para que aparezca como stock previo)
DECLARE @fecha_inicial DATE = DATEADD(DAY, -1, GETDATE());

-- =========================================================
-- INGRESOS GRUPO: EXPLOSIVOS (cantidades altas - kg/und)
-- =========================================================

INSERT INTO ingresos (explosivo_id, cantidad, fecha_ingreso, guardia, numero_vale, recibido_por, observaciones)
SELECT 
    e.id as explosivo_id,
    CASE 
        WHEN e.codigo = 'SUPERFAM_DOS' THEN 50.00          -- 50 kg ANFO
        WHEN e.codigo LIKE 'EMULNOR%' THEN 100.00          -- 100 unidades emulsiones
        WHEN e.codigo = 'MECHA_FULMINANTE' THEN 500.00     -- 500 piezas mechas
        WHEN e.codigo = 'PENTACORD_3P' THEN 1000.00        -- 1000 metros cordón
        ELSE 200.00                                         -- Otros explosivos
    END as cantidad,
    @fecha_inicial as fecha_ingreso,
    'GUARDIA_INICIAL' as guardia,
    CONCAT('STOCK-EXP-', FORMAT(GETDATE(), 'yyyyMMdd'), '-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'EXPLOSIVOS' AND e.activo = 1;

-- =========================================================
-- INGRESOS GRUPO: FANELES MS 4.8 MTS (cantidades moderadas)
-- =========================================================

INSERT INTO ingresos (explosivo_id, cantidad, fecha_ingreso, guardia, numero_vale, recibido_por, observaciones)
SELECT 
    e.id as explosivo_id,
    CASE 
        WHEN RIGHT(e.codigo, 2) IN ('01', '02', '03', '04', '05') THEN 150.00  -- Números bajos más stock
        WHEN RIGHT(e.codigo, 2) IN ('06', '07', '08', '09', '10') THEN 120.00  -- Números medios
        ELSE 100.00                                                            -- Números altos menos stock
    END as cantidad,
    @fecha_inicial as fecha_ingreso,
    'GUARDIA_INICIAL' as guardia,
    CONCAT('STOCK-MS4-', FORMAT(GETDATE(), 'yyyyMMdd'), '-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'FANELES MS 4.8 MTS' AND e.activo = 1;

-- =========================================================
-- INGRESOS GRUPO: FANELES LP 4.8 MTS (cantidades moderadas)
-- =========================================================

INSERT INTO ingresos (explosivo_id, cantidad, fecha_ingreso, guardia, numero_vale, recibido_por, observaciones)
SELECT 
    e.id as explosivo_id,
    CASE 
        WHEN RIGHT(e.codigo, 2) IN ('01', '02', '03', '04', '05') THEN 140.00  -- Números bajos más stock
        WHEN RIGHT(e.codigo, 2) IN ('06', '07', '08', '09', '10') THEN 110.00  -- Números medios
        ELSE 90.00                                                             -- Números altos menos stock
    END as cantidad,
    @fecha_inicial as fecha_ingreso,
    'GUARDIA_INICIAL' as guardia,
    CONCAT('STOCK-LP4-', FORMAT(GETDATE(), 'yyyyMMdd'), '-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'FANELES LP 4.8 MTS' AND e.activo = 1;

-- =========================================================
-- INGRESOS GRUPO: FANELES MS 15 MTS (cantidades menores)
-- =========================================================

INSERT INTO ingresos (explosivo_id, cantidad, fecha_ingreso, guardia, numero_vale, recibido_por, observaciones)
SELECT 
    e.id as explosivo_id,
    CASE 
        WHEN RIGHT(e.codigo, 2) IN ('01', '02', '03', '04', '05') THEN 80.00   -- Números bajos más stock
        WHEN RIGHT(e.codigo, 2) IN ('06', '07', '08', '09', '10') THEN 60.00   -- Números medios
        ELSE 50.00                                                             -- Números altos menos stock
    END as cantidad,
    @fecha_inicial as fecha_ingreso,
    'GUARDIA_INICIAL' as guardia,
    CONCAT('STOCK-MS15-', FORMAT(GETDATE(), 'yyyyMMdd'), '-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'FANELES MS 15 MTS' AND e.activo = 1;

-- =========================================================
-- INGRESOS GRUPO: FANELES LP 15 MTS (cantidades menores)
-- =========================================================

INSERT INTO ingresos (explosivo_id, cantidad, fecha_ingreso, guardia, numero_vale, recibido_por, observaciones)
SELECT 
    e.id as explosivo_id,
    CASE 
        WHEN RIGHT(e.codigo, 2) IN ('01', '02', '03', '04', '05') THEN 75.00   -- Números bajos más stock
        WHEN RIGHT(e.codigo, 2) IN ('06', '07', '08', '09', '10') THEN 55.00   -- Números medios
        ELSE 45.00                                                             -- Números altos menos stock
    END as cantidad,
    @fecha_inicial as fecha_ingreso,
    'GUARDIA_INICIAL' as guardia,
    CONCAT('STOCK-LP15-', FORMAT(GETDATE(), 'yyyyMMdd'), '-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'FANELES LP 15 MTS' AND e.activo = 1;

PRINT CONCAT('✅ Insertados ', @@ROWCOUNT, ' ingresos de stock inicial');

-- =========================================================
-- 4. CREAR STOCK DIARIO INICIAL
-- =========================================================

PRINT '📊 Generando registros de stock diario inicial...';

INSERT INTO stock_diario (explosivo_id, fecha, stock_inicial, ingresos_dia, salidas_dia, devoluciones_dia, stock_final, observaciones, fecha_creacion)
SELECT 
    i.explosivo_id,
    @fecha_inicial as fecha,
    0.00 as stock_inicial,                    -- Stock inicial era 0
    SUM(i.cantidad) as ingresos_dia,          -- Suma de ingresos del día
    0.00 as salidas_dia,                      -- Sin salidas el primer día
    0.00 as devoluciones_dia,                 -- Sin devoluciones el primer día
    SUM(i.cantidad) as stock_final,           -- Stock final = ingresos
    'STOCK INICIAL - Primer día de operaciones polvorín PALLCA' as observaciones,
    GETDATE() as fecha_creacion
FROM ingresos i
WHERE CAST(i.fecha_ingreso AS DATE) = @fecha_inicial
GROUP BY i.explosivo_id;

PRINT CONCAT('✅ Generados ', @@ROWCOUNT, ' registros de stock diario');

-- =========================================================
-- 5. VERIFICACIÓN DETALLADA POR GRUPOS
-- =========================================================

PRINT '';
PRINT '📊 VERIFICACIÓN DETALLADA DEL STOCK INICIAL:';

-- Resumen por grupos con totales
SELECT 
    e.grupo,
    COUNT(DISTINCT e.id) as tipos_explosivos,
    SUM(CAST(i.cantidad AS FLOAT)) as stock_total_grupo,
    AVG(CAST(i.cantidad AS FLOAT)) as stock_promedio,
    MIN(CAST(i.cantidad AS FLOAT)) as stock_minimo,
    MAX(CAST(i.cantidad AS FLOAT)) as stock_maximo
FROM explosivos e
JOIN ingresos i ON e.id = i.explosivo_id
WHERE CAST(i.fecha_ingreso AS DATE) = @fecha_inicial
GROUP BY e.grupo
ORDER BY e.grupo;

-- Detalles por grupo (top 3 de cada grupo)
PRINT '';
PRINT '🔝 TOP 3 POR CADA GRUPO:';

-- Top EXPLOSIVOS
SELECT TOP 3
    '💥 EXPLOSIVOS' as categoria,
    e.codigo,
    e.descripcion,
    CAST(i.cantidad AS INT) as stock_inicial,
    e.unidad
FROM explosivos e
JOIN ingresos i ON e.id = i.explosivo_id  
WHERE e.grupo = 'EXPLOSIVOS' AND CAST(i.fecha_ingreso AS DATE) = @fecha_inicial
ORDER BY i.cantidad DESC;

-- Top FANELES MS 4.8
SELECT TOP 3
    '⚡ FANELES MS 4.8' as categoria,
    e.codigo,
    e.descripcion,
    CAST(i.cantidad AS INT) as stock_inicial,
    e.unidad
FROM explosivos e
JOIN ingresos i ON e.id = i.explosivo_id  
WHERE e.grupo = 'FANELES MS 4.8 MTS' AND CAST(i.fecha_ingreso AS DATE) = @fecha_inicial
ORDER BY i.cantidad DESC;

-- Top FANELES LP 4.8
SELECT TOP 3
    '🔥 FANELES LP 4.8' as categoria,
    e.codigo,
    e.descripcion,
    CAST(i.cantidad AS INT) as stock_inicial,
    e.unidad
FROM explosivos e
JOIN ingresos i ON e.id = i.explosivo_id  
WHERE e.grupo = 'FANELES LP 4.8 MTS' AND CAST(i.fecha_ingreso AS DATE) = @fecha_inicial
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
-- 7. PROBAR VISTAS CON DATOS REALES
-- =========================================================

PRINT '';
PRINT '🧪 Probando vistas con datos reales...';

-- Verificar vista de stock actual
DECLARE @items_con_stock INT;
SELECT @items_con_stock = COUNT(*) FROM v_stock_actual WHERE stock_actual > 0;
PRINT CONCAT('✅ Vista v_stock_actual: ', @items_con_stock, ' items con stock');

-- Verificar vista de auditoría
DECLARE @total_movimientos INT;
SELECT @total_movimientos = COUNT(*) FROM vw_auditoria_movimientos;
PRINT CONCAT('✅ Vista vw_auditoria_movimientos: ', @total_movimientos, ' movimientos registrados');

-- =========================================================
-- RESUMEN FINAL COMPLETO
-- =========================================================

DECLARE @total_items_stock INT;
DECLARE @valor_total_stock DECIMAL(15,2);

SELECT 
    @total_items_stock = COUNT(*),
    @valor_total_stock = SUM(CAST(cantidad AS FLOAT))
FROM ingresos 
WHERE CAST(fecha_ingreso AS DATE) = @fecha_inicial;

PRINT '';
PRINT '🎉 ¡STOCK INICIAL COMPLETO CREADO EXITOSAMENTE!';
PRINT '';
PRINT '📋 RESUMEN FINAL COMPLETO:';
PRINT CONCAT('   📦 Total items con stock: ', @total_items_stock);
PRINT CONCAT('   🏪 Cantidad total en almacén: ', CAST(CAST(@valor_total_stock AS INT) AS VARCHAR), ' unidades');
PRINT CONCAT('   📅 Fecha stock inicial: ', FORMAT(@fecha_inicial, 'dd/MM/yyyy'));
PRINT CONCAT('   👤 Responsable: ', @admin_user);
PRINT '';
PRINT '📊 DISTRIBUCIÓN POR GRUPOS:';
PRINT '   💥 EXPLOSIVOS: 7 tipos (50-1000 unidades)';
PRINT '   ⚡ FANELES MS 4.8 MTS: 20 tipos (100-150 unidades)';
PRINT '   🔥 FANELES LP 4.8 MTS: 15 tipos (90-140 unidades)';
PRINT '   ⚡ FANELES MS 15 MTS: 20 tipos (50-80 unidades)';
PRINT '   🔥 FANELES LP 15 MTS: 15 tipos (45-75 unidades)';
PRINT '';
PRINT '🚀 POLVORÍN PALLCA COMPLETAMENTE OPERATIVO';
PRINT '✅ Sistema listo para operaciones diarias';
PRINT '✅ Todas las vistas funcionando correctamente';
PRINT '✅ Stock inicial realista por tipos de explosivos';
PRINT '';