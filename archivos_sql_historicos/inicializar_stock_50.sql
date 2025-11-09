-- Script para inicializar stock de todos los explosivos nuevos
-- Fecha: 2025-11-09
-- Se agregarán 50 unidades a cada explosivo

BEGIN TRANSACTION;

PRINT 'Inicializando stock inicial de 50 unidades para cada explosivo...';

DECLARE @fecha_actual DATETIME = GETDATE();
DECLARE @usuario_sistema INT = 1; -- ID del usuario admin/sistema

-- Verificar explosivos actuales
SELECT 'Explosivos a inicializar:' as mensaje;
SELECT 
    id,
    codigo, 
    descripcion,
    unidad,
    grupo
FROM explosivos 
ORDER BY grupo, codigo;

DECLARE @total_explosivos INT;
SELECT @total_explosivos = COUNT(*) FROM explosivos;
PRINT CONCAT('Total de explosivos: ', @total_explosivos);

-- Insertar un registro de ingreso por cada explosivo
DECLARE @explosivo_id INT;
DECLARE @codigo VARCHAR(20);
DECLARE @descripcion VARCHAR(255);
DECLARE @unidad VARCHAR(10);

DECLARE explosivos_cursor CURSOR FOR
SELECT id, codigo, descripcion, unidad
FROM explosivos
ORDER BY grupo, codigo;

OPEN explosivos_cursor;
FETCH NEXT FROM explosivos_cursor INTO @explosivo_id, @codigo, @descripcion, @unidad;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Insertar ingreso de 50 unidades
    INSERT INTO ingresos (
        explosivo_id,
        cantidad,
        fecha_ingreso,
        recibido_por,
        numero_vale,
        turno,
        observaciones,
        usuario_id,
        fecha_creacion
    ) VALUES (
        @explosivo_id,
        50,
        @fecha_actual,
        'Sistema',
        'INICIAL-001',
        'DIA',
        CONCAT('Stock inicial - ', @descripcion, ' (', @codigo, ')'),
        @usuario_sistema,
        @fecha_actual
    );

    -- Crear/actualizar stock_diario
    INSERT INTO stock_diario (
        explosivo_id,
        fecha,
        stock_inicial,
        ingresos_cantidad,
        salidas_cantidad,
        devoluciones_cantidad,
        stock_final,
        fecha_actualizacion
    ) VALUES (
        @explosivo_id,
        CAST(@fecha_actual AS DATE),
        0,
        50,
        0,
        0,
        50,
        @fecha_actual
    );

    PRINT CONCAT('Stock inicializado para: ', @codigo, ' - ', @descripcion, ' (50 ', @unidad, ')');

    FETCH NEXT FROM explosivos_cursor INTO @explosivo_id, @codigo, @descripcion, @unidad;
END;

CLOSE explosivos_cursor;
DEALLOCATE explosivos_cursor;

-- Verificar que se crearon los registros correctamente
PRINT 'Verificando registros creados...';

SELECT 'Resumen de ingresos creados:' as mensaje;
SELECT 
    COUNT(*) as total_ingresos_iniciales
FROM ingresos 
WHERE numero_vale = 'INICIAL-001';

SELECT 'Resumen de stock_diario creado:' as mensaje;
SELECT 
    COUNT(*) as total_stock_diario,
    SUM(stock_final) as total_stock_sistema
FROM stock_diario
WHERE fecha = CAST(@fecha_actual AS DATE);

-- Mostrar sample del stock creado
SELECT 'Sample del stock inicial creado:' as mensaje;
SELECT TOP 5
    e.codigo,
    e.descripcion,
    sd.stock_final,
    e.unidad
FROM stock_diario sd
INNER JOIN explosivos e ON sd.explosivo_id = e.id
WHERE sd.fecha = CAST(@fecha_actual AS DATE)
ORDER BY e.grupo, e.codigo;

COMMIT TRANSACTION;

PRINT 'Stock inicial creado exitosamente';
PRINT 'Todos los explosivos tienen ahora 50 unidades en stock';