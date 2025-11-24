#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sincronización automática simplificada para stock_diario
Evita imports circulares usando importación dinámica
"""

def trigger_sincronizacion_stock(movimiento_tipo, explosivo_id, fecha, guardia):
    """
    Función wrapper simple para sincronización automática
    Se llama desde app.py después de crear/modificar movimientos
    """
    
    try:
        # Import dinámico para evitar circular import
        import importlib
        
        # Intentar importar desde recalcular_stock_automatico
        recalcular_module = importlib.import_module('recalcular_stock_automatico')
        
        # Llamar función específica para una fecha/guardia
        with recalcular_module.app.app_context():
            procesados = recalcular_module.procesar_stock_fecha_guardia(fecha, guardia)
            
            if procesados > 0:
                print(f"🔄 Auto-sincronizado: {procesados} explosivos en {fecha} {guardia}")
                return True
            else:
                # Si no hay procesados, al menos verificar continuidad
                verificar_continuidad_basica(fecha, guardia, explosivo_id)
                return True
                
    except Exception as e:
        print(f"⚠️ Error en sincronización automática: {e}")
        return False

def verificar_continuidad_basica(fecha, guardia, explosivo_id):
    """Verifica continuidad básica para un explosivo específico"""
    
    try:
        # Import dinámico
        import importlib
        from datetime import timedelta
        
        app_module = importlib.import_module('app')
        app = app_module.app
        db = app_module.db
        StockDiario = app_module.StockDiario
        
        with app.app_context():
            if guardia == 'noche':
                # Stock inicial noche = stock final día
                stock_dia = StockDiario.query.filter_by(
                    explosivo_id=explosivo_id,
                    fecha=fecha,
                    guardia='dia'
                ).first()
                
                stock_noche = StockDiario.query.filter_by(
                    explosivo_id=explosivo_id,
                    fecha=fecha,
                    guardia='noche'
                ).first()
                
                if stock_dia and stock_noche:
                    if stock_noche.stock_inicial != stock_dia.stock_final:
                        stock_noche.stock_inicial = stock_dia.stock_final
                        # Recalcular final si no hay movimientos noche
                        if stock_noche.stock_final == stock_noche.stock_inicial:
                            stock_noche.stock_final = stock_dia.stock_final
                        db.session.commit()
                        print(f"✅ Continuidad corregida: {fecha} {guardia} explosivo {explosivo_id}")
            
            elif guardia == 'dia':
                # Stock inicial día = stock final noche día anterior
                fecha_anterior = fecha - timedelta(days=1)
                
                stock_anterior = StockDiario.query.filter_by(
                    explosivo_id=explosivo_id,
                    fecha=fecha_anterior,
                    guardia='noche'
                ).first()
                
                stock_actual = StockDiario.query.filter_by(
                    explosivo_id=explosivo_id,
                    fecha=fecha,
                    guardia='dia'
                ).first()
                
                if stock_anterior and stock_actual:
                    if stock_actual.stock_inicial != stock_anterior.stock_final:
                        stock_actual.stock_inicial = stock_anterior.stock_final
                        db.session.commit()
                        print(f"✅ Continuidad corregida: {fecha} {guardia} explosivo {explosivo_id}")
                
    except Exception as e:
        print(f"⚠️ Error verificando continuidad: {e}")

# Función de compatibilidad para imports existentes
def sincronizar_stock_despues_movimiento(movimiento_tipo, explosivo_id, fecha, guardia):
    """Función de compatibilidad que llama a la función principal"""
    return trigger_sincronizacion_stock(movimiento_tipo, explosivo_id, fecha, guardia)