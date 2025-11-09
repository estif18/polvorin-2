-- =========================================================
-- SCRIPT DE MANTENIMIENTO Y UTILIDADES
-- =========================================================
-- Fecha: Noviembre 2025
-- Versión: 1.0
-- Descripción: Scripts de mantenimiento, limpieza y utilidades
--              para administración de la base de datos

USE pallca;
GO

-- =========================================================
-- 1. LIMPIAR TODOS LOS DATOS (CONSERVAR ESTRUCTURA)
-- =========================================================

CREATE OR ALTER PROCEDURE sp_limpiar_datos_completo
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '🧹 INICIANDO LIMPIEZA COMPLETA DE DATOS...';
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Limpiar en orden de dependencias
        DELETE FROM stock_diario;
        DELETE FROM devoluciones;
        DELETE FROM salidas; 
        DELETE FROM ingresos;
        
        -- Reiniciar contadores identity
        DBCC CHECKIDENT ('ingresos', RESEED, 0);
        DBCC CHECKIDENT ('salidas', RESEED, 0);
        DBCC CHECKIDENT ('devoluciones', RESEED, 0);
        DBCC CHECKIDENT ('stock_diario', RESEED, 0);
        
        COMMIT TRANSACTION;
        
        PRINT '✅ Limpieza completa exitosa';
        PRINT '   📊 Todos los movimientos eliminados';
        PRINT '   🔄 Contadores identity reiniciados';
        PRINT '   📦 Explosivos maestros conservados';
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT '❌ Error en limpieza: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =========================================================
-- 2. RECALCULAR STOCK DIARIO
-- =========================================================

CREATE OR ALTER PROCEDURE sp_recalcular_stock_diario
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Si no se especifican fechas, usar rango completo
    IF @fecha_inicio IS NULL SET @fecha_inicio = '2020-01-01';
    IF @fecha_fin IS NULL SET @fecha_fin = CAST(GETDATE() AS DATE);
    
    PRINT CONCAT('📊 Recalculando stock diario desde ', @fecha_inicio, ' hasta ', @fecha_fin);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Eliminar registros existentes del rango
        DELETE FROM stock_diario 
        WHERE fecha BETWEEN @fecha_inicio AND @fecha_fin;
        
        -- Recalcular y insertar
        WITH fechas AS (
            -- Generar todas las fechas con movimientos
            SELECT DISTINCT CAST(fecha_ingreso AS DATE) as fecha FROM ingresos
            WHERE CAST(fecha_ingreso AS DATE) BETWEEN @fecha_inicio AND @fecha_fin
            UNION
            SELECT DISTINCT CAST(fecha_salida AS DATE) as fecha FROM salidas
            WHERE CAST(fecha_salida AS DATE) BETWEEN @fecha_inicio AND @fecha_fin
            UNION
            SELECT DISTINCT CAST(fecha_devolucion AS DATE) as fecha FROM devoluciones
            WHERE CAST(fecha_devolucion AS DATE) BETWEEN @fecha_inicio AND @fecha_fin
        ),
        stock_calculado AS (
            SELECT 
                f.fecha,
                e.id as explosivo_id,
                
                -- Stock inicial (todo lo anterior a esta fecha)
                COALESCE(
                    (SELECT SUM(i2.cantidad) FROM ingresos i2 WHERE i2.explosivo_id = e.id AND CAST(i2.fecha_ingreso AS DATE) < f.fecha), 0
                ) -
                COALESCE(
                    (SELECT SUM(s2.cantidad) FROM salidas s2 WHERE s2.explosivo_id = e.id AND CAST(s2.fecha_salida AS DATE) < f.fecha), 0
                ) +
                COALESCE(
                    (SELECT SUM(d2.cantidad_devuelta) FROM devoluciones d2 WHERE d2.explosivo_id = e.id AND CAST(d2.fecha_devolucion AS DATE) < f.fecha), 0
                ) as stock_inicial,
                
                -- Movimientos del día
                COALESCE((SELECT SUM(cantidad) FROM ingresos WHERE explosivo_id = e.id AND CAST(fecha_ingreso AS DATE) = f.fecha), 0) as ingresos_dia,
                COALESCE((SELECT SUM(cantidad) FROM salidas WHERE explosivo_id = e.id AND CAST(fecha_salida AS DATE) = f.fecha), 0) as salidas_dia,
                COALESCE((SELECT SUM(cantidad_devuelta) FROM devoluciones WHERE explosivo_id = e.id AND CAST(fecha_devolucion AS DATE) = f.fecha), 0) as devoluciones_dia
                
            FROM fechas f
            CROSS JOIN explosivos e
            WHERE e.activo = 1
        )
        INSERT INTO stock_diario (fecha, explosivo_id, stock_inicial, ingresos_dia, salidas_dia, devoluciones_dia, stock_final)
        SELECT 
            fecha,
            explosivo_id,
            stock_inicial,
            ingresos_dia,
            salidas_dia,
            devoluciones_dia,
            stock_inicial + ingresos_dia - salidas_dia + devoluciones_dia as stock_final
        FROM stock_calculado;
        
        DECLARE @registros_creados INT = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        PRINT CONCAT('✅ Stock diario recalculado: ', @registros_creados, ' registros');
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT '❌ Error recalculando stock: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =========================================================
-- 3. REPORTE DE ESTADO DE LA BASE DE DATOS
-- =========================================================

CREATE OR ALTER PROCEDURE sp_reporte_estado_bd
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '📊 REPORTE DE ESTADO DE BASE DE DATOS POLVORÍN';
    PRINT '===============================================';
    PRINT '';
    
    -- Conteos generales
    DECLARE @total_explosivos INT = (SELECT COUNT(*) FROM explosivos WHERE activo = 1);
    DECLARE @total_ingresos INT = (SELECT COUNT(*) FROM ingresos);
    DECLARE @total_salidas INT = (SELECT COUNT(*) FROM salidas);
    DECLARE @total_devoluciones INT = (SELECT COUNT(*) FROM devoluciones);
    DECLARE @total_stock_diario INT = (SELECT COUNT(*) FROM stock_diario);
    
    PRINT '📦 DATOS MAESTROS:';
    PRINT CONCAT('   Explosivos activos: ', @total_explosivos);
    PRINT '';
    
    PRINT '📊 MOVIMIENTOS:';
    PRINT CONCAT('   Total ingresos: ', @total_ingresos);
    PRINT CONCAT('   Total salidas: ', @total_salidas);  
    PRINT CONCAT('   Total devoluciones: ', @total_devoluciones);
    PRINT CONCAT('   Registros stock diario: ', @total_stock_diario);
    PRINT '';
    
    -- Rangos de fechas
    DECLARE @primera_fecha DATE = (
        SELECT MIN(fecha_mov) FROM (
            SELECT MIN(CAST(fecha_ingreso AS DATE)) as fecha_mov FROM ingresos
            UNION ALL
            SELECT MIN(CAST(fecha_salida AS DATE)) as fecha_mov FROM salidas
            UNION ALL
            SELECT MIN(CAST(fecha_devolucion AS DATE)) as fecha_mov FROM devoluciones
        ) fechas
    );
    
    DECLARE @ultima_fecha DATE = (
        SELECT MAX(fecha_mov) FROM (
            SELECT MAX(CAST(fecha_ingreso AS DATE)) as fecha_mov FROM ingresos
            UNION ALL
            SELECT MAX(CAST(fecha_salida AS DATE)) as fecha_mov FROM salidas
            UNION ALL
            SELECT MAX(CAST(fecha_devolucion AS DATE)) as fecha_mov FROM devoluciones
        ) fechas
    );
    
    PRINT '📅 RANGO DE FECHAS:';
    PRINT CONCAT('   Primera fecha: ', ISNULL(FORMAT(@primera_fecha, 'dd/MM/yyyy'), 'N/A'));
    PRINT CONCAT('   Última fecha: ', ISNULL(FORMAT(@ultima_fecha, 'dd/MM/yyyy'), 'N/A'));
    PRINT '';
    
    -- Stock total
    DECLARE @stock_total DECIMAL(18,2) = (
        SELECT SUM(stock_actual) FROM vw_stock_historico_completo
    );
    
    PRINT '💰 STOCK TOTAL ACTUAL:';
    PRINT CONCAT('   Total unidades: ', FORMAT(@stock_total, 'N2'));
    PRINT '';
    
    -- Alertas de stock
    DECLARE @alertas_criticas INT = (
        SELECT COUNT(*) FROM vw_alertas_stock 
        WHERE nivel_alerta IN ('CRITICO_NEGATIVO', 'SIN_STOCK')
    );
    
    PRINT '⚠️  ALERTAS:';
    PRINT CONCAT('   Alertas críticas: ', @alertas_criticas);
    PRINT '';
    
    -- Tamaño de la base de datos
    SELECT 
        name as tabla,
        rows as filas,
        CAST(ROUND(((SUM(reserved) * 8.00) / 1024.00), 2) AS NUMERIC(36, 2)) AS tamaño_mb
    FROM sys.tables t
    INNER JOIN sys.partitions p ON t.object_id = p.object_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    INNER JOIN sys.dm_db_partition_stats ps ON p.partition_id = ps.partition_id
    WHERE t.name IN ('explosivos', 'ingresos', 'salidas', 'devoluciones', 'stock_diario')
    GROUP BY t.name, p.rows
    ORDER BY tamaño_mb DESC;
    
    PRINT '';
    PRINT '✅ Reporte completado';
END
GO

-- =========================================================
-- 4. BACKUP DE DATOS A SCRIPTS
-- =========================================================

CREATE OR ALTER PROCEDURE sp_generar_backup_datos
    @incluir_movimientos BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '💾 GENERANDO BACKUP DE DATOS...';
    PRINT '';
    
    -- Backup explosivos
    PRINT '-- BACKUP EXPLOSIVOS ' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm');
    PRINT 'DELETE FROM explosivos;';
    PRINT 'INSERT INTO explosivos (codigo, descripcion, unidad) VALUES';
    
    SELECT 
        CASE 
            WHEN ROW_NUMBER() OVER (ORDER BY codigo) = COUNT(*) OVER() 
            THEN CONCAT('(''', codigo, ''', ''', descripcion, ''', ''', unidad, ''');')
            ELSE CONCAT('(''', codigo, ''', ''', descripcion, ''', ''', unidad, '''),')
        END
    FROM explosivos 
    WHERE activo = 1
    ORDER BY codigo;
    
    IF @incluir_movimientos = 1
    BEGIN
        PRINT '';
        PRINT '-- BACKUP INGRESOS';
        
        SELECT TOP 5
            CONCAT(
                'INSERT INTO ingresos (explosivo_id, cantidad, fecha_ingreso, numero_vale, recibido_por, guardia, observaciones) VALUES (',
                explosivo_id, ', ', cantidad, ', ''', fecha_ingreso, ''', ''', 
                ISNULL(numero_vale, ''), ''', ''', ISNULL(recibido_por, ''), ''', ''',
                guardia, ''', ''', ISNULL(observaciones, ''), ''');'
            )
        FROM ingresos
        ORDER BY fecha_ingreso DESC;
        
        PRINT '-- ... (más registros)';
    END
    
    PRINT '';
    PRINT '✅ Backup generado (revisar salida para copiar)';
END
GO

-- =========================================================
-- 5. OPTIMIZAR BASE DE DATOS
-- =========================================================

CREATE OR ALTER PROCEDURE sp_optimizar_bd
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '🚀 OPTIMIZANDO BASE DE DATOS...';
    
    -- Actualizar estadísticas
    UPDATE STATISTICS explosivos;
    UPDATE STATISTICS ingresos;
    UPDATE STATISTICS salidas; 
    UPDATE STATISTICS devoluciones;
    UPDATE STATISTICS stock_diario;
    
    PRINT '✅ Estadísticas actualizadas';
    
    -- Reorganizar índices
    ALTER INDEX ALL ON explosivos REORGANIZE;
    ALTER INDEX ALL ON ingresos REORGANIZE;
    ALTER INDEX ALL ON salidas REORGANIZE;
    ALTER INDEX ALL ON devoluciones REORGANIZE;
    ALTER INDEX ALL ON stock_diario REORGANIZE;
    
    PRINT '✅ Índices reorganizados';
    
    -- Shrink database (usar con cuidado)
    -- DBCC SHRINKDATABASE(pallca, 10);
    
    PRINT '✅ Optimización completada';
END
GO

-- =========================================================
-- PROCEDIMIENTOS CREADOS
-- =========================================================

PRINT '';
PRINT '🎉 ¡SCRIPTS DE MANTENIMIENTO CREADOS!';
PRINT '';
PRINT '🔧 PROCEDIMIENTOS DISPONIBLES:';
PRINT '   ✅ sp_limpiar_datos_completo - Limpia todos los movimientos';
PRINT '   ✅ sp_recalcular_stock_diario - Recalcula stock por fechas';
PRINT '   ✅ sp_reporte_estado_bd - Reporte completo de estado';
PRINT '   ✅ sp_generar_backup_datos - Genera scripts de backup';
PRINT '   ✅ sp_optimizar_bd - Optimiza rendimiento';
PRINT '';
PRINT '📖 EJEMPLOS DE USO:';
PRINT '   EXEC sp_reporte_estado_bd;';
PRINT '   EXEC sp_limpiar_datos_completo;';
PRINT '   EXEC sp_recalcular_stock_diario ''2025-01-01'', ''2025-12-31'';';
PRINT '';

GO