-- Script corregido para inicializar stock de todos los explosivos nuevos
-- Fecha: 2025-11-09
-- Se agregarán 50 unidades a cada explosivo

BEGIN TRANSACTION;

PRINT 'Inicializando stock inicial de 50 unidades para cada explosivo...';

DECLARE @fecha_actual DATETIME = GETDATE();

-- Verificar explosivos actuales
SELECT 'Explosivos a inicializar:' as mensaje;
SELECT 
    COUNT(*) as total_explosivos
FROM explosivos;

-- Crear stock_diario inicial para cada explosivo
INSERT INTO stock_diario (
    explosivo_id,
    fecha,
    guardia,
    stock_inicial,
    stock_final,
    responsable_guardia,
    observaciones,
    fecha_registro
)
SELECT 
    e.id,
    CAST(@fecha_actual AS DATE),
    'DIA',
    50,
    50,
    'Sistema',
    'Stock inicial automatico - ' + e.descripcion + ' (' + e.codigo + ')',
    @fecha_actual
FROM explosivos e;

PRINT 'Stock diario creado para todos los explosivos';

-- Crear registros de ingreso correspondientes
DECLARE @explosivo_id INT;
DECLARE @stock_diario_id INT;
DECLARE @codigo VARCHAR(20);
DECLARE @descripcion VARCHAR(255);

DECLARE stock_cursor CURSOR FOR
SELECT 
    sd.explosivo_id,
    sd.id,
    e.codigo,
    e.descripcion
FROM stock_diario sd
INNER JOIN explosivos e ON sd.explosivo_id = e.id
WHERE sd.fecha = CAST(@fecha_actual AS DATE)
  AND sd.observaciones LIKE 'Stock inicial automatico%';

OPEN stock_cursor;
FETCH NEXT FROM stock_cursor INTO @explosivo_id, @stock_diario_id, @codigo, @descripcion;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Insertar ingreso de 50 unidades
    INSERT INTO ingresos (
        explosivo_id,
        stock_diario_id,
        numero_vale,
        cantidad,
        fecha_ingreso,
        guardia,
        recibido_por,
        observaciones
    ) VALUES (
        @explosivo_id,
        @stock_diario_id,
        'INICIAL-001',
        50,
        @fecha_actual,
        'DIA',
        'Sistema',
        'Ingreso inicial - ' + @descripcion + ' (' + @codigo + ')'
    );

    PRINT CONCAT('Ingreso creado para: ', @codigo, ' - ', @descripcion, ' (50 unidades)');

    FETCH NEXT FROM stock_cursor INTO @explosivo_id, @stock_diario_id, @codigo, @descripcion;
END;

CLOSE stock_cursor;
DEALLOCATE stock_cursor;

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
WHERE fecha = CAST(@fecha_actual AS DATE)
  AND observaciones LIKE 'Stock inicial automatico%';

-- Mostrar sample del stock creado por grupo
SELECT 'Stock inicial por grupo:' as mensaje;
SELECT 
    e.grupo,
    COUNT(*) as cantidad_items,
    SUM(sd.stock_final) as stock_total_grupo
FROM stock_diario sd
INNER JOIN explosivos e ON sd.explosivo_id = e.id
WHERE sd.fecha = CAST(@fecha_actual AS DATE)
  AND sd.observaciones LIKE 'Stock inicial automatico%'
GROUP BY e.grupo
ORDER BY e.grupo;

-- Mostrar muestra de los primeros registros
SELECT 'Muestra de stock creado:' as mensaje;
SELECT TOP 10
    e.codigo,
    e.descripcion,
    sd.stock_final,
    e.unidad,
    e.grupo
FROM stock_diario sd
INNER JOIN explosivos e ON sd.explosivo_id = e.id
WHERE sd.fecha = CAST(@fecha_actual AS DATE)
  AND sd.observaciones LIKE 'Stock inicial automatico%'
ORDER BY e.grupo, e.codigo;

COMMIT TRANSACTION;

PRINT 'Stock inicial creado exitosamente';
PRINT 'Todos los explosivos tienen ahora 50 unidades en stock';