-- Script SQL para crear primer ingreso de explosivos
-- Fecha: 2025-11-18
-- Sistema de Polvorín PALLCA

USE pallca;
GO

PRINT '🎯 Iniciando primer ingreso de explosivos...';

-- Verificar estado actual
PRINT '📊 Estado actual del sistema:';
SELECT 
    'Explosivos registrados' as Concepto,
    COUNT(*) as Cantidad
FROM explosivos
UNION ALL
SELECT 
    'Ingresos existentes' as Concepto,
    COUNT(*) as Cantidad  
FROM ingresos
UNION ALL
SELECT 
    'Stocks diarios' as Concepto,
    COUNT(*) as Cantidad
FROM stock_diario;

-- Fecha del ingreso inicial
DECLARE @fecha_ingreso DATE = GETDATE();
DECLARE @fecha_hora DATETIME = CAST(@fecha_ingreso AS DATETIME);

PRINT '📅 Fecha del ingreso: ' + CAST(@fecha_ingreso AS VARCHAR(10));

BEGIN TRANSACTION;

BEGIN TRY
    -- INSERTAR INGRESOS INICIALES
    PRINT '📦 Insertando ingresos iniciales...';
    
    INSERT INTO ingresos (explosivo_id, numero_vale, cantidad, fecha_ingreso, guardia, recibido_por, observaciones)
    VALUES
    -- EMULSIÓN - EMULNOR 3000
    (79, 'ING-INICIAL-0302008', 100, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial del sistema - Emulsión'),
    
    -- ANFO - SUPERFAM DOS
    (78, 'ING-INICIAL-0304003', 150, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial del sistema - ANFO'),
    
    -- FULMINANTE GUÍA ARMADA
    (81, 'ING-INICIAL-0303004', 200, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial del sistema - Fulminantes'),
    
    -- MECHA LENTA
    (82, 'ING-INICIAL-0305001', 500, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial del sistema - Mecha lenta'),
    
    -- CORDÓN DE IGNICIÓN
    (83, 'ING-INICIAL-0305004', 300, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial del sistema - Cordón ignición'),
    
    -- PENTACORD 3P
    (80, 'ING-INICIAL-0306003', 250, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial del sistema - Pentacord'),
    
    -- CARMEX DETONADOR
    (84, 'ING-INICIAL-0305011', 50, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial del sistema - Detonadores'),
    
    -- FANELES MS (Micro Segundo) - Cantidades diferenciadas
    (85, 'ING-INICIAL-0303071', 100, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 01'),
    (86, 'ING-INICIAL-0303072', 80, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 02'),
    (87, 'ING-INICIAL-0303073', 75, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 03'),
    (88, 'ING-INICIAL-0303074', 70, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 04'),
    (89, 'ING-INICIAL-0303075', 60, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 05'),
    (90, 'ING-INICIAL-0303076', 50, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 06'),
    (91, 'ING-INICIAL-0303077', 45, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 07'),
    (92, 'ING-INICIAL-0303078', 40, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 08'),
    (93, 'ING-INICIAL-0303079', 35, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 09'),
    (94, 'ING-INICIAL-0303080', 30, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 10'),
    (95, 'ING-INICIAL-0303081', 25, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 11'),
    (96, 'ING-INICIAL-0303082', 20, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 12'),
    (97, 'ING-INICIAL-0303083', 15, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 13'),
    (98, 'ING-INICIAL-0303084', 10, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 14'),
    (99, 'ING-INICIAL-0303085', 10, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL MS NO 15'),
    
    -- FANELES LP (Larga Persistencia) - Cantidades diferenciadas
    (100, 'ING-INICIAL-0303051', 80, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 01'),
    (101, 'ING-INICIAL-0303052', 70, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 02'),
    (102, 'ING-INICIAL-0303053', 65, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 03'),
    (103, 'ING-INICIAL-0303054', 60, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 04'),
    (104, 'ING-INICIAL-0303055', 50, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 05'),
    (105, 'ING-INICIAL-0303056', 45, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 06'),
    (106, 'ING-INICIAL-0303057', 40, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 07'),
    (107, 'ING-INICIAL-0303058', 35, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 08'),
    (108, 'ING-INICIAL-0303059', 30, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 09'),
    (109, 'ING-INICIAL-0303060', 25, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 10'),
    (110, 'ING-INICIAL-0303061', 20, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 11'),
    (111, 'ING-INICIAL-0303062', 15, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 12'),
    (112, 'ING-INICIAL-0303063', 10, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 13'),
    (113, 'ING-INICIAL-0303064', 8, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 14'),
    (114, 'ING-INICIAL-0303065', 5, @fecha_hora, 'DIA', 'Admin Sistema', 'Ingreso inicial - FANEL LP NO 15');

    PRINT '✅ Ingresos insertados correctamente';

    -- CREAR STOCKS DIARIOS CORRESPONDIENTES
    PRINT '📊 Creando stocks diarios...';
    
    INSERT INTO stock_diario (explosivo_id, fecha, guardia, stock_inicial, stock_final, responsable_guardia, observaciones)
    SELECT 
        i.explosivo_id,
        CAST(i.fecha_ingreso AS DATE) as fecha,
        i.guardia,
        i.cantidad as stock_inicial,
        i.cantidad as stock_final,
        i.recibido_por as responsable_guardia,
        'Stock inicial del sistema - Ingreso: ' + CAST(i.cantidad AS VARCHAR) + ' unidades'
    FROM ingresos i
    WHERE i.numero_vale LIKE 'ING-INICIAL-%'
    AND CAST(i.fecha_ingreso AS DATE) = @fecha_ingreso;

    PRINT '✅ Stocks diarios creados correctamente';

    -- COMMIT DE LA TRANSACCIÓN
    COMMIT TRANSACTION;
    
    PRINT '🎉 PRIMER INGRESO COMPLETADO EXITOSAMENTE!';
    
    -- MOSTRAR RESUMEN
    PRINT '📋 RESUMEN DEL PRIMER INGRESO:';
    
    SELECT 
        e.codigo,
        e.descripcion,
        i.cantidad,
        e.unidad,
        'Ingresado' as Estado
    FROM ingresos i
    INNER JOIN explosivos e ON i.explosivo_id = e.id
    WHERE i.numero_vale LIKE 'ING-INICIAL-%'
    AND CAST(i.fecha_ingreso AS DATE) = @fecha_ingreso
    ORDER BY e.codigo;
    
    -- TOTALES
    PRINT '📊 TOTALES:';
    SELECT 
        COUNT(*) as 'Explosivos Inicializados',
        SUM(cantidad) as 'Cantidad Total Ingresada'
    FROM ingresos 
    WHERE numero_vale LIKE 'ING-INICIAL-%'
    AND CAST(fecha_ingreso AS DATE) = @fecha_ingreso;

END TRY
BEGIN CATCH
    -- ROLLBACK EN CASO DE ERROR
    ROLLBACK TRANSACTION;
    
    PRINT '❌ ERROR al crear primer ingreso:';
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Message: ' + ERROR_MESSAGE();
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
    
END CATCH

GO

PRINT '✅ Script completado. Verifica los resultados arriba.';

-- OPCIONAL: Verificar que todo se creó correctamente
PRINT '🔍 Verificación final:';

SELECT 
    'Ingresos creados hoy' as Concepto,
    COUNT(*) as Cantidad
FROM ingresos 
WHERE CAST(fecha_ingreso AS DATE) = CAST(GETDATE() AS DATE)
UNION ALL
SELECT 
    'Stocks creados hoy' as Concepto,
    COUNT(*) as Cantidad
FROM stock_diario 
WHERE fecha = CAST(GETDATE() AS DATE);