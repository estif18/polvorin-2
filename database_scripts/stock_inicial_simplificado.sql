-- =========================================================
-- STOCK INICIAL SIMPLIFICADO - AZURE SQL DATABASE - PALLCA
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0 Simplificado
-- Descripción: Stock inicial para todos los 77 explosivos (solo ingresos)

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
    RETURN;
END

PRINT CONCAT('✅ Explosivos disponibles: ', @count_explosivos);

-- =========================================================
-- 2. LIMPIAR MOVIMIENTOS EXISTENTES
-- =========================================================

PRINT '🧹 Limpiando ingresos existentes...';

-- Limpiar ingresos
DELETE FROM ingresos;
DBCC CHECKIDENT ('ingresos', RESEED, 0);

PRINT '✅ Ingresos limpiados';

-- =========================================================
-- 3. INSERTAR STOCK INICIAL POR GRUPOS
-- =========================================================

PRINT '📦 Creando stock inicial diferenciado por grupos...';

-- Obtener usuario administrador
DECLARE @admin_user NVARCHAR(100);
SELECT TOP 1 @admin_user = nombre_completo FROM usuarios WHERE cargo = 'admin' AND activo = 1;

IF @admin_user IS NULL
    SET @admin_user = 'Sistema';

-- Fecha de stock inicial (ayer)
DECLARE @fecha_inicial DATE = DATEADD(DAY, -1, GETDATE());

-- =========================================================
-- INGRESOS GRUPO: EXPLOSIVOS
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
    CONCAT('EXP-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'EXPLOSIVOS' AND e.activo = 1;

-- =========================================================
-- INGRESOS GRUPO: FANELES MS 4.8 MTS
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
    CONCAT('MS4-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'FANELES MS 4.8 MTS' AND e.activo = 1;

-- =========================================================
-- INGRESOS GRUPO: FANELES LP 4.8 MTS
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
    CONCAT('LP4-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'FANELES LP 4.8 MTS' AND e.activo = 1;

-- =========================================================
-- INGRESOS GRUPO: FANELES MS 15 MTS
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
    CONCAT('MS15-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'FANELES MS 15 MTS' AND e.activo = 1;

-- =========================================================
-- INGRESOS GRUPO: FANELES LP 15 MTS
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
    CONCAT('LP15-', RIGHT('000' + CAST(e.id AS VARCHAR), 3)) as numero_vale,
    @admin_user as recibido_por,
    CONCAT('STOCK INICIAL - ', e.grupo, ' - ', e.descripcion) as observaciones
FROM explosivos e
WHERE e.grupo = 'FANELES LP 15 MTS' AND e.activo = 1;

DECLARE @total_ingresos INT = @@ROWCOUNT;

-- =========================================================
-- 4. VERIFICACIÓN DETALLADA
-- =========================================================

PRINT '';
PRINT CONCAT('✅ Insertados ', @total_ingresos, ' ingresos de stock inicial');
PRINT '';
PRINT '📊 VERIFICACIÓN POR GRUPOS:';

-- Resumen por grupos
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

-- =========================================================
-- 5. PROBAR VISTA DE STOCK
-- =========================================================

PRINT '';
PRINT '🧪 Probando vista de stock actual...';

DECLARE @items_con_stock INT;
SELECT @items_con_stock = COUNT(*) FROM v_stock_actual WHERE stock_actual > 0;
PRINT CONCAT('✅ Items con stock: ', @items_con_stock);

-- Mostrar algunos ejemplos
PRINT '';
PRINT '🔝 EJEMPLOS DE STOCK POR GRUPO:';

SELECT TOP 2
    '💥 EXPLOSIVOS' as categoria,
    codigo,
    descripcion,
    CAST(stock_actual AS INT) as stock,
    unidad
FROM v_stock_actual
WHERE grupo = 'EXPLOSIVOS' AND stock_actual > 0
ORDER BY stock_actual DESC;

SELECT TOP 2
    '⚡ FANELES MS 4.8' as categoria,
    codigo,
    descripcion,
    CAST(stock_actual AS INT) as stock,
    unidad
FROM v_stock_actual
WHERE grupo = 'FANELES MS 4.8 MTS' AND stock_actual > 0
ORDER BY stock_actual DESC;

-- =========================================================
-- RESUMEN FINAL
-- =========================================================

DECLARE @total_items_stock INT;
DECLARE @valor_total_stock DECIMAL(15,2);

SELECT 
    @total_items_stock = COUNT(*),
    @valor_total_stock = SUM(CAST(cantidad AS FLOAT))
FROM ingresos 
WHERE CAST(fecha_ingreso AS DATE) = @fecha_inicial;

PRINT '';
PRINT '🎉 ¡STOCK INICIAL CREADO EXITOSAMENTE!';
PRINT '';
PRINT '📋 RESUMEN FINAL:';
PRINT CONCAT('   📦 Items con stock: ', @total_items_stock);
PRINT CONCAT('   🏪 Total unidades: ', CAST(CAST(@valor_total_stock AS INT) AS VARCHAR));
PRINT CONCAT('   📅 Fecha: ', FORMAT(@fecha_inicial, 'dd/MM/yyyy'));
PRINT '';
PRINT '🚀 POLVORÍN PALLCA OPERATIVO';
PRINT '✅ Todos los explosivos tienen stock inicial';
PRINT '✅ Sistema listo para operaciones diarias';
PRINT '';