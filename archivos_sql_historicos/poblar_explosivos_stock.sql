-- =====================================================
-- SCRIPT PARA POBLAR EXPLOSIVOS Y STOCK INICIAL
-- Fecha de registro: 01/10/2025, Turno: Noche
-- Generado automáticamente desde captura de pantalla
-- =====================================================

USE pallca;
GO

-- =====================================================
-- PASO 1: INSERTAR/ACTUALIZAR EXPLOSIVOS
-- =====================================================

-- Primero verificamos y agregamos explosivos que no existan
PRINT 'Insertando explosivos faltantes...';

-- Función para insertar explosivo si no existe
DECLARE @explosivos TABLE (
    codigo VARCHAR(20),
    descripcion VARCHAR(500),
    unidad VARCHAR(20),
    grupo VARCHAR(50)
);

INSERT INTO @explosivos (codigo, descripcion, unidad, grupo) VALUES
('0304002', 'SUPERFAM (ANFO)', 'KG', 'ANFO'),
('0302008', 'EMULNOR 3000 1 1/4 " X 8"', 'UND', 'EMULSION'),
('0306003', 'PENTACORD 3P CAJA X 1500 MTRS (1 caja= 1500 m)', 'CJA', 'CORDON'),
('0303004', 'FULMINANTE GUIA ARMADA', 'UND', 'FULMINANTE'),
('0305001', 'MECHA LENTA CJA X 1000 MTS', 'CJA', 'MECHA'),
('0303051', 'FANEL MS 4.8 MTRS NO 01', 'UND', 'FANEL MS'),
('0303052', 'FANEL MS 4.8 MTRS NO 02', 'UND', 'FANEL MS'),
('0303053', 'FANEL MS 4.8 MTRS NO 03', 'UND', 'FANEL MS'),
('0303054', 'FANEL MS 4.8 MTRS NO 04', 'UND', 'FANEL MS'),
('0303055', 'FANEL MS 4.8 MTRS NO 05', 'UND', 'FANEL MS'),
('0303056', 'FANEL MS 4.8 MTRS NO 06', 'UND', 'FANEL MS'),
('0303057', 'FANEL MS 4.8 MTRS NO 07', 'UND', 'FANEL MS'),
('0303058', 'FANEL MS 4.8 MTRS NO 08', 'UND', 'FANEL MS'),
('0303059', 'FANEL MS 4.8 MTRS NO 09', 'UND', 'FANEL MS'),
('0303060', 'FANEL MS 4.8 MTRS NO 10', 'UND', 'FANEL MS'),
('0303061', 'FANEL MS 4.8 MTRS NO 11', 'UND', 'FANEL MS'),
('0303062', 'FANEL MS 4.8 MTRS NO 12', 'UND', 'FANEL MS'),
('0303063', 'FANEL MS 4.8 MTRS NO 13', 'UND', 'FANEL MS'),
('0303064', 'FANEL MS 4.8 MTRS NO 14', 'UND', 'FANEL MS'),
('0303065', 'FANEL MS 4.8 MTRS NO 15', 'UND', 'FANEL MS'),
('0303071', 'FANEL LP 4.8 MTRS NO 01', 'UND', 'FANEL LP'),
('0303072', 'FANEL LP 4.8 MTRS NO 02', 'UND', 'FANEL LP'),
('0303073', 'FANEL LP 4.8 MTRS NO 03', 'UND', 'FANEL LP'),
('0303074', 'FANEL LP 4.8 MTRS NO 04', 'UND', 'FANEL LP'),
('0303075', 'FANEL LP 4.8 MTRS NO 05', 'UND', 'FANEL LP'),
('0303076', 'FANEL LP 4.8 MTRS NO 06', 'UND', 'FANEL LP'),
('0303077', 'FANEL LP 4.8 MTRS NO 07', 'UND', 'FANEL LP'),
('0303078', 'FANEL LP 4.8 MTRS NO 08', 'UND', 'FANEL LP'),
('0303079', 'FANEL LP 4.8 MTRS NO 09', 'UND', 'FANEL LP'),
('0303080', 'FANEL LP 4.8 MTRS NO 10', 'UND', 'FANEL LP'),
('0303081', 'FANEL LP 4.8 MTRS NO 11', 'UND', 'FANEL LP'),
('0303082', 'FANEL LP 4.8 MTRS NO 12', 'UND', 'FANEL LP'),
('0303083', 'FANEL LP 4.8 MTRS NO 13', 'UND', 'FANEL LP'),
('0303084', 'FANEL LP 4.8 MTRS NO 14', 'UND', 'FANEL LP'),
('0303085', 'FANEL LP 4.8 MTRS NO 15', 'UND', 'FANEL LP');

-- Insertar explosivos que no existan
INSERT INTO explosivos (codigo, descripcion, unidad, grupo)
SELECT t.codigo, t.descripcion, t.unidad, t.grupo
FROM @explosivos t
LEFT JOIN explosivos e ON e.codigo = t.codigo
WHERE e.id IS NULL;

PRINT 'Explosivos insertados correctamente.';

-- =====================================================
-- PASO 2: REGISTRAR INGRESOS INICIALES (01/10/2025)
-- =====================================================

PRINT 'Registrando ingresos del inventario inicial...';

-- Tabla temporal con los datos del inventario
DECLARE @inventario TABLE (
    codigo VARCHAR(20),
    cantidad DECIMAL(10,2)
);

INSERT INTO @inventario (codigo, cantidad) VALUES
('0304002', 3.00),   -- SUPERFAM (ANFO)
('0302008', 46.00),  -- EMULNOR 3000 1 1/4 " X 8"
('0306003', 20.00),  -- PENTACORD 3P CAJA X 1500 MTRS
('0303004', 2.00),   -- FULMINANTE GUIA ARMADA
('0305001', 24.00),  -- MECHA LENTA CJA X 1000 MTS
('0303051', 2.00),   -- FANEL MS 4.8 MTRS NO 01
('0303054', 2.00),   -- FANEL MS 4.8 MTRS NO 04
('0303057', 2.00),   -- FANEL MS 4.8 MTRS NO 07
('0303060', 2.00),   -- FANEL MS 4.8 MTRS NO 10
('0303071', 2.00),   -- FANEL LP 4.8 MTRS NO 01
('0303072', 2.00),   -- FANEL LP 4.8 MTRS NO 02
('0303074', 4.00),   -- FANEL LP 4.8 MTRS NO 04
('0303076', 4.00),   -- FANEL LP 4.8 MTRS NO 06
('0303077', 4.00),   -- FANEL LP 4.8 MTRS NO 07
('0303078', 4.00),   -- FANEL LP 4.8 MTRS NO 08
('0303079', 4.00),   -- FANEL LP 4.8 MTRS NO 09
('0303081', 3.00),   -- FANEL LP 4.8 MTRS NO 11
('0303082', 8.00),   -- FANEL LP 4.8 MTRS NO 12
('0303084', 4.00),   -- FANEL LP 4.8 MTRS NO 14
('0303085', 3.00);   -- FANEL LP 4.8 MTRS NO 15

-- Insertar ingresos para el inventario inicial
INSERT INTO ingresos (
    explosivo_id, 
    numero_vale, 
    cantidad, 
    fecha_ingreso, 
    guardia, 
    recibido_por, 
    observaciones
)
SELECT 
    e.id,
    'INICIAL-' + e.codigo,
    i.cantidad,
    '2025-10-01 22:00:00',  -- 01/10/2025 turno noche
    'noche',
    'Sistema_Administrador',
    'Stock inicial del sistema - ' + e.descripcion
FROM @inventario i
INNER JOIN explosivos e ON e.codigo = i.codigo
WHERE i.cantidad > 0;

PRINT 'Ingresos del inventario inicial registrados correctamente.';

-- =====================================================
-- PASO 3: CREAR STOCK DIARIO INICIAL
-- =====================================================

PRINT 'Creando registros de stock diario...';

-- Insertar stock diario para el 01/10/2025
INSERT INTO stock_diario (
    explosivo_id,
    fecha,
    guardia,
    stock_inicial,
    stock_final,
    responsable_guardia,
    observaciones
)
SELECT 
    e.id,
    '2025-10-01',
    'noche',
    i.cantidad,
    i.cantidad,
    'Supervisor_Noche',
    'Stock inicial del sistema'
FROM @inventario i
INNER JOIN explosivos e ON e.codigo = i.codigo
WHERE i.cantidad > 0;

PRINT 'Stock diario inicial creado correctamente.';

-- =====================================================
-- PASO 4: VERIFICACIÓN Y REPORTE
-- =====================================================

PRINT '=====================================================';
PRINT 'REPORTE DE INSERCIÓN COMPLETADO';
PRINT '=====================================================';

-- Mostrar resumen de explosivos insertados
SELECT 
    'EXPLOSIVOS REGISTRADOS' as TIPO,
    COUNT(*) as CANTIDAD
FROM explosivos
WHERE codigo IN (
    SELECT codigo FROM @explosivos
);

-- Mostrar resumen de ingresos
SELECT 
    'INGRESOS REGISTRADOS' as TIPO,
    COUNT(*) as CANTIDAD,
    SUM(cantidad) as TOTAL_CANTIDAD
FROM ingresos
WHERE numero_vale LIKE 'INICIAL-%'
  AND CAST(fecha_ingreso AS DATE) = '2025-10-01';

-- Mostrar resumen de stock diario
SELECT 
    'STOCK DIARIO CREADO' as TIPO,
    COUNT(*) as CANTIDAD,
    SUM(stock_inicial) as TOTAL_STOCK
FROM stock_diario
WHERE fecha = '2025-10-01'
  AND guardia = 'noche';

-- Mostrar detalle de explosivos con stock
SELECT 
    e.codigo,
    e.descripcion,
    e.unidad,
    COALESCE(sd.stock_final, 0) as STOCK_ACTUAL
FROM explosivos e
LEFT JOIN stock_diario sd ON e.id = sd.explosivo_id 
    AND sd.fecha = '2025-10-01' 
    AND sd.guardia = 'noche'
WHERE e.codigo IN (
    SELECT codigo FROM @explosivos
)
ORDER BY e.codigo;

PRINT '=====================================================';
PRINT 'PROCESO COMPLETADO EXITOSAMENTE';
PRINT 'Fecha: 01/10/2025, Turno: Noche';
PRINT '=====================================================';