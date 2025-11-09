-- =========================================================
-- SCRIPT DE STOCK INICIAL PARA PRUEBAS
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0
-- Descripción: Insertar stock inicial de 1000 unidades 
--              por cada explosivo para pruebas del sistema

USE pallca;
GO

-- =========================================================
-- VERIFICAR PRERREQUISITOS
-- =========================================================

PRINT '🔍 Verificando prerrequisitos...';

DECLARE @count_explosivos INT = (SELECT COUNT(*) FROM explosivos WHERE activo = 1);

IF @count_explosivos = 0
BEGIN
    PRINT '❌ ERROR: No hay explosivos en la base de datos';
    PRINT '   Ejecute primero: 03_insertar_datos_maestros.sql';
    RETURN;
END

PRINT CONCAT('✅ Encontrados ', @count_explosivos, ' explosivos para procesar');

-- =========================================================
-- LIMPIAR DATOS EXISTENTES (SI LOS HAY)
-- =========================================================

PRINT '🧹 Limpiando datos existentes...';

-- Limpiar en orden de dependencias
DELETE FROM stock_diario;
DELETE FROM devoluciones;
DELETE FROM salidas;
DELETE FROM ingresos;

-- Reiniciar identity
DBCC CHECKIDENT ('ingresos', RESEED, 0);
DBCC CHECKIDENT ('salidas', RESEED, 0);
DBCC CHECKIDENT ('devoluciones', RESEED, 0);
DBCC CHECKIDENT ('stock_diario', RESEED, 0);

PRINT '✅ Datos existentes limpiados';

-- =========================================================
-- INSERTAR STOCK INICIAL
-- =========================================================

PRINT '📦 Insertando stock inicial de 1000 unidades por explosivo...';

DECLARE @fecha_ingreso DATETIME2 = '2025-11-08 10:00:00';
DECLARE @ingresos_insertados INT = 0;

-- Cursor para procesar cada explosivo
DECLARE cursor_explosivos CURSOR FOR
    SELECT id, codigo, descripcion, unidad
    FROM explosivos
    WHERE activo = 1
    ORDER BY codigo;

DECLARE @exp_id INT, @codigo NVARCHAR(20), @descripcion NVARCHAR(255), @unidad NVARCHAR(10);

OPEN cursor_explosivos;
FETCH NEXT FROM cursor_explosivos INTO @exp_id, @codigo, @descripcion, @unidad;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Insertar ingreso de 1000 unidades
    INSERT INTO ingresos (
        explosivo_id,
        cantidad,
        fecha_ingreso,
        numero_vale,
        recibido_por,
        guardia,
        observaciones
    )
    VALUES (
        @exp_id,
        1000.00,
        @fecha_ingreso,
        'VALE-INICIAL-001',
        'SISTEMA ADMINISTRADOR',
        'DIA',
        CONCAT('STOCK INICIAL - 1000 ', @unidad, ' de ', LEFT(@descripcion, 50))
    );
    
    SET @ingresos_insertados = @ingresos_insertados + 1;
    
    -- Mostrar progreso cada 10 items
    IF @ingresos_insertados % 10 = 0
    BEGIN
        PRINT CONCAT('   📊 Procesados: ', @ingresos_insertados, '/', @count_explosivos);
    END
    
    FETCH NEXT FROM cursor_explosivos INTO @exp_id, @codigo, @descripcion, @unidad;
END

CLOSE cursor_explosivos;
DEALLOCATE cursor_explosivos;

PRINT CONCAT('✅ ', @ingresos_insertados, ' ingresos de stock inicial creados');

-- =========================================================
-- CREAR REGISTRO DE STOCK DIARIO
-- =========================================================

PRINT '📊 Creando registros de stock diario...';

DECLARE @fecha_stock DATE = CAST(@fecha_ingreso AS DATE);
DECLARE @stocks_creados INT = 0;

-- Insertar stock diario para cada explosivo
INSERT INTO stock_diario (
    fecha,
    explosivo_id,
    stock_inicial,
    ingresos_dia,
    salidas_dia,
    devoluciones_dia,
    stock_final
)
SELECT 
    @fecha_stock,
    e.id,
    0 as stock_inicial,  -- Comenzamos desde 0
    1000.00 as ingresos_dia,
    0 as salidas_dia,
    0 as devoluciones_dia,
    1000.00 as stock_final
FROM explosivos e
WHERE e.activo = 1;

SET @stocks_creados = @@ROWCOUNT;
PRINT CONCAT('✅ ', @stocks_creados, ' registros de stock diario creados');

-- =========================================================
-- VERIFICAR DATOS INSERTADOS
-- =========================================================

PRINT '🔍 Verificando datos insertados...';

-- Verificar ingresos
DECLARE @total_ingresos INT = (SELECT COUNT(*) FROM ingresos);
DECLARE @suma_cantidades DECIMAL(18,2) = (SELECT SUM(cantidad) FROM ingresos);

PRINT CONCAT('📥 Total ingresos registrados: ', @total_ingresos);
PRINT CONCAT('📊 Suma total de cantidades: ', FORMAT(@suma_cantidades, 'N2'), ' unidades');

-- Verificar stock diario
DECLARE @total_stocks INT = (SELECT COUNT(*) FROM stock_diario);
PRINT CONCAT('📈 Total registros stock diario: ', @total_stocks);

-- Mostrar muestra de datos
PRINT '';
PRINT '📋 MUESTRA DE STOCK CREADO:';

SELECT TOP 5
    e.codigo,
    e.descripcion,
    i.cantidad,
    e.unidad,
    i.numero_vale,
    i.guardia
FROM ingresos i
JOIN explosivos e ON i.explosivo_id = e.id
ORDER BY e.codigo;

-- =========================================================
-- CALCULAR STOCK TOTAL
-- =========================================================

PRINT '';
PRINT '📊 CALCULANDO STOCK TOTAL...';

-- Vista de stock actual usando la lógica sin filtros de fecha
SELECT 
    COUNT(*) as total_explosivos_con_stock,
    SUM(stock_calculado) as stock_total_unidades
FROM (
    SELECT 
        e.id,
        COALESCE(SUM(i.cantidad), 0) - 
        COALESCE(SUM(s.cantidad), 0) + 
        COALESCE(SUM(d.cantidad_devuelta), 0) as stock_calculado
    FROM explosivos e
    LEFT JOIN ingresos i ON e.id = i.explosivo_id
    LEFT JOIN salidas s ON e.id = s.explosivo_id
    LEFT JOIN devoluciones d ON e.id = d.explosivo_id
    WHERE e.activo = 1
    GROUP BY e.id
) stock_por_explosivo;

-- =========================================================
-- RESUMEN FINAL
-- =========================================================

PRINT '';
PRINT '🎉 ¡STOCK INICIAL CREADO EXITOSAMENTE!';
PRINT '';
PRINT '📊 RESUMEN:';
PRINT CONCAT('   📦 Explosivos procesados: ', @count_explosivos);
PRINT CONCAT('   📥 Ingresos creados: ', @total_ingresos);
PRINT CONCAT('   📈 Registros stock diario: ', @total_stocks);
PRINT CONCAT('   🎯 Unidades por explosivo: 1,000');
PRINT CONCAT('   📊 Total unidades: ', FORMAT(@suma_cantidades, 'N2'));
PRINT '';
PRINT '📅 DETALLES DEL INGRESO:';
PRINT CONCAT('   🗓️  Fecha: ', FORMAT(@fecha_ingreso, 'dd/MM/yyyy HH:mm'));
PRINT '   🏷️  Vale: VALE-INICIAL-001';
PRINT '   👤 Recibido por: SISTEMA ADMINISTRADOR';
PRINT '   🌅 Guardia: DIA';
PRINT '';
PRINT '✅ SISTEMA LISTO PARA OPERACIONES';
PRINT '   🎯 Todas las funcionalidades disponibles';
PRINT '   📊 Stock disponible para pruebas';
PRINT '   🔄 Listo para registrar salidas y devoluciones';
PRINT '';

GO