#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Función para recalcular automáticamente stock_diario cuando hay cambios
Mantiene la tabla sincronizada con los movimientos reales
"""

import sys
import os
sys.path.append('.')

from datetime import datetime, date, timedelta
from app import app, db, StockDiario, Explosivo, Ingreso, Salida, Devolucion
from sqlalchemy import text

def recalcular_stock_diario_completo(fecha_desde=None):
    """Recalcula completamente stock_diario desde una fecha"""
    
    with app.app_context():
        print("=== RECÁLCULO AUTOMÁTICO STOCK_DIARIO ===\n")
        
        if fecha_desde is None:
            # Obtener primera fecha con movimientos
            query_primera_fecha = text("""
                SELECT MIN(fecha_minima) as primera_fecha
                FROM (
                    SELECT MIN(CAST(fecha_ingreso AS DATE)) as fecha_minima FROM ingresos
                    UNION ALL
                    SELECT MIN(CAST(fecha_salida AS DATE)) as fecha_minima FROM salidas
                    UNION ALL  
                    SELECT MIN(CAST(fecha_devolucion AS DATE)) as fecha_minima FROM devoluciones
                ) fechas
            """)
            fecha_desde = db.session.execute(query_primera_fecha).scalar()
        
        if not fecha_desde:
            print("❌ No hay movimientos en la base de datos")
            return
        
        print(f"📅 Recalculando desde: {fecha_desde}")
        
        # Obtener todas las fechas con movimientos
        query_fechas = text("""
            SELECT DISTINCT fecha, COUNT(*) as movimientos
            FROM (
                SELECT CAST(fecha_ingreso AS DATE) as fecha FROM ingresos
                UNION ALL
                SELECT CAST(fecha_salida AS DATE) as fecha FROM salidas  
                UNION ALL
                SELECT CAST(d.fecha_devolucion AS DATE) as fecha FROM devoluciones d
            ) todas_fechas
            WHERE fecha >= :fecha_desde
            GROUP BY fecha
            ORDER BY fecha
        """)
        
        fechas_movimientos = db.session.execute(query_fechas, {'fecha_desde': fecha_desde}).fetchall()
        
        print(f"📊 Procesando {len(fechas_movimientos)} fechas con movimientos:")
        
        total_procesados = 0
        
        for fecha_row in fechas_movimientos:
            fecha_actual = fecha_row[0]
            print(f"\n🔧 Procesando {fecha_actual}...")
            
            # Procesar día y noche para esta fecha
            for guardia in ['dia', 'noche']:
                procesados = procesar_stock_fecha_guardia(fecha_actual, guardia)
                total_procesados += procesados
                
                if procesados > 0:
                    print(f"   ✅ {guardia}: {procesados} explosivos procesados")
        
        print(f"\n🎯 RECÁLCULO COMPLETADO:")
        print(f"   ✅ {total_procesados} registros procesados")
        print(f"   ✅ Stock_diario sincronizado con movimientos")
        print(f"   ✅ Continuidad automática establecida")

def procesar_stock_fecha_guardia(fecha, guardia):
    """Procesa stock para una fecha y guardia específica"""
    
    procesados = 0
    
    # Obtener explosivos que tuvieron movimientos en esta fecha/guardia
    query_explosivos = text("""
        SELECT DISTINCT explosivo_id
        FROM (
            SELECT explosivo_id FROM ingresos 
            WHERE CAST(fecha_ingreso AS DATE) = :fecha AND guardia = :guardia
            UNION
            SELECT explosivo_id FROM salidas
            WHERE CAST(fecha_salida AS DATE) = :fecha AND guardia = :guardia
            UNION  
            SELECT s.explosivo_id FROM devoluciones d
            JOIN salidas s ON d.salida_id = s.id
            WHERE CAST(d.fecha_devolucion AS DATE) = :fecha AND s.guardia = :guardia
        ) explosivos_con_movimientos
    """)
    
    explosivos_ids = db.session.execute(query_explosivos, {
        'fecha': fecha, 
        'guardia': guardia
    }).fetchall()
    
    for explosivo_row in explosivos_ids:
        explosivo_id = explosivo_row[0]
        
        # Calcular stock inicial
        stock_inicial = calcular_stock_inicial(explosivo_id, fecha, guardia)
        
        # Calcular movimientos del turno
        movimientos = calcular_movimientos_turno(explosivo_id, fecha, guardia)
        
        # Calcular stock final
        stock_final = stock_inicial + movimientos['ingresos'] + movimientos['devoluciones'] - movimientos['salidas']
        
        # Actualizar o crear registro
        stock_registro = StockDiario.query.filter_by(
            explosivo_id=explosivo_id,
            fecha=fecha,
            guardia=guardia
        ).first()
        
        if stock_registro:
            # Actualizar existente
            stock_registro.stock_inicial = stock_inicial
            stock_registro.stock_final = stock_final
            stock_registro.observaciones = f"Recalculado automáticamente - {datetime.now()}"
        else:
            # Crear nuevo
            stock_registro = StockDiario(
                explosivo_id=explosivo_id,
                fecha=fecha,
                guardia=guardia,
                stock_inicial=stock_inicial,
                stock_final=stock_final,
                responsable_guardia='Sistema',
                observaciones=f"Creado automáticamente - {datetime.now()}"
            )
            db.session.add(stock_registro)
        
        procesados += 1
    
    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise e
    
    return procesados

def calcular_stock_inicial(explosivo_id, fecha, guardia):
    """Calcula stock inicial correcto para un explosivo/fecha/guardia"""
    
    if guardia == 'dia':
        # Stock inicial día = stock final noche día anterior
        fecha_anterior = fecha - timedelta(days=1)
        
        stock_anterior = StockDiario.query.filter_by(
            explosivo_id=explosivo_id,
            fecha=fecha_anterior,
            guardia='noche'
        ).first()
        
        if stock_anterior:
            return stock_anterior.stock_final
        else:
            # Si es el primer día, stock inicial = 0
            return 0.0
    else:
        # Stock inicial noche = stock final día mismo día
        stock_dia = StockDiario.query.filter_by(
            explosivo_id=explosivo_id,
            fecha=fecha,
            guardia='dia'
        ).first()
        
        if stock_dia:
            return stock_dia.stock_final
        else:
            # Si no hay registro día, calcular desde stock inicial día
            return calcular_stock_inicial(explosivo_id, fecha, 'dia')

def calcular_movimientos_turno(explosivo_id, fecha, guardia):
    """Calcula movimientos de un turno específico"""
    
    # Ingresos
    query_ingresos = text("""
        SELECT COALESCE(SUM(cantidad), 0) as total
        FROM ingresos 
        WHERE explosivo_id = :explosivo_id
        AND CAST(fecha_ingreso AS DATE) = :fecha
        AND guardia = :guardia
    """)
    
    ingresos = db.session.execute(query_ingresos, {
        'explosivo_id': explosivo_id,
        'fecha': fecha,
        'guardia': guardia
    }).scalar() or 0.0
    
    # Salidas
    query_salidas = text("""
        SELECT COALESCE(SUM(cantidad), 0) as total
        FROM salidas
        WHERE explosivo_id = :explosivo_id
        AND CAST(fecha_salida AS DATE) = :fecha
        AND guardia = :guardia
    """)
    
    salidas = db.session.execute(query_salidas, {
        'explosivo_id': explosivo_id,
        'fecha': fecha,
        'guardia': guardia
    }).scalar() or 0.0
    
    # Devoluciones
    query_devoluciones = text("""
        SELECT COALESCE(SUM(d.cantidad_devuelta), 0) as total
        FROM devoluciones d
        JOIN salidas s ON d.salida_id = s.id
        WHERE s.explosivo_id = :explosivo_id
        AND CAST(d.fecha_devolucion AS DATE) = :fecha
        AND s.guardia = :guardia
    """)
    
    devoluciones = db.session.execute(query_devoluciones, {
        'explosivo_id': explosivo_id,
        'fecha': fecha,
        'guardia': guardia
    }).scalar() or 0.0
    
    return {
        'ingresos': float(ingresos),
        'salidas': float(salidas),
        'devoluciones': float(devoluciones)
    }

if __name__ == "__main__":
    recalcular_stock_diario_completo()