#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para crear una vista simplificada de stock diario dinámico
Compatible con SQL Server sin funciones avanzadas
"""

import sys
import os
sys.path.append('.')

from datetime import datetime, date
from app import app, db
from sqlalchemy import text

def crear_vista_simple():
    """Crea vista simple para stock diario dinámico"""
    
    with app.app_context():
        print("=== CREACIÓN DE VISTA SIMPLE STOCK DIARIO ===\n")
        
        # Primero eliminar vista si existe
        try:
            drop_vista_sql = "DROP VIEW IF EXISTS vw_stock_diario_simple"
            db.session.execute(text(drop_vista_sql))
            print("🗑️ Vista anterior eliminada")
        except Exception as e:
            print(f"📝 Vista no existía previamente: {e}")
        
        # Vista simplificada compatible con SQL Server
        vista_sql = """
        CREATE VIEW vw_stock_diario_simple AS
        SELECT 
            sd.explosivo_id,
            e.codigo,
            e.descripcion,
            e.unidad,
            sd.fecha,
            sd.guardia,
            sd.stock_inicial,
            sd.stock_final,
            
            -- Ingresos del turno
            COALESCE((
                SELECT SUM(i.cantidad)
                FROM ingresos i
                WHERE i.explosivo_id = sd.explosivo_id
                AND CAST(i.fecha_ingreso AS DATE) = sd.fecha
                AND i.guardia = sd.guardia
            ), 0.0) as ingresos,
            
            -- Salidas del turno
            COALESCE((
                SELECT SUM(s.cantidad)
                FROM salidas s
                WHERE s.explosivo_id = sd.explosivo_id
                AND CAST(s.fecha_salida AS DATE) = sd.fecha
                AND s.guardia = sd.guardia
            ), 0.0) as salidas,
            
            -- Devoluciones del turno
            COALESCE((
                SELECT SUM(d.cantidad_devuelta)
                FROM devoluciones d
                JOIN salidas s ON d.salida_id = s.id
                WHERE s.explosivo_id = sd.explosivo_id
                AND CAST(d.fecha_devolucion AS DATE) = sd.fecha
                AND s.guardia = sd.guardia
            ), 0.0) as devoluciones,
            
            -- Información adicional
            sd.responsable_guardia,
            sd.observaciones,
            
            -- Stock calculado dinámicamente para verificación
            (sd.stock_inicial + 
             COALESCE((SELECT SUM(i.cantidad) FROM ingresos i WHERE i.explosivo_id = sd.explosivo_id AND CAST(i.fecha_ingreso AS DATE) = sd.fecha AND i.guardia = sd.guardia), 0) +
             COALESCE((SELECT SUM(d.cantidad_devuelta) FROM devoluciones d JOIN salidas s ON d.salida_id = s.id WHERE s.explosivo_id = sd.explosivo_id AND CAST(d.fecha_devolucion AS DATE) = sd.fecha AND s.guardia = sd.guardia), 0) -
             COALESCE((SELECT SUM(s.cantidad) FROM salidas s WHERE s.explosivo_id = sd.explosivo_id AND CAST(s.fecha_salida AS DATE) = sd.fecha AND s.guardia = sd.guardia), 0)
            ) as stock_final_calculado,
            
            -- Verificación de consistencia
            CASE 
                WHEN ABS(sd.stock_final - 
                    (sd.stock_inicial + 
                     COALESCE((SELECT SUM(i.cantidad) FROM ingresos i WHERE i.explosivo_id = sd.explosivo_id AND CAST(i.fecha_ingreso AS DATE) = sd.fecha AND i.guardia = sd.guardia), 0) +
                     COALESCE((SELECT SUM(d.cantidad_devuelta) FROM devoluciones d JOIN salidas s ON d.salida_id = s.id WHERE s.explosivo_id = sd.explosivo_id AND CAST(d.fecha_devolucion AS DATE) = sd.fecha AND s.guardia = sd.guardia), 0) -
                     COALESCE((SELECT SUM(s.cantidad) FROM salidas s WHERE s.explosivo_id = sd.explosivo_id AND CAST(s.fecha_salida AS DATE) = sd.fecha AND s.guardia = sd.guardia), 0)
                    )) <= 0.01 
                THEN 'OK' 
                ELSE 'INCONSISTENTE' 
            END as estado_consistencia
            
        FROM stock_diario sd
        JOIN explosivos e ON sd.explosivo_id = e.id
        WHERE e.activo = 1
        """
        
        print("🔧 VISTA SIMPLE GENERADA:")
        print("   • Basada en tabla stock_diario existente")
        print("   • Calcula movimientos dinámicamente")
        print("   • Incluye verificación de consistencia") 
        print("   • Compatible con SQL Server")
        
        confirm = input("\n¿Crear vista simple stock diario? (si/no): ").strip().lower()
        
        if confirm == 'si':
            try:
                # Crear vista
                db.session.execute(text(vista_sql))
                db.session.commit()
                
                print("✅ Vista 'vw_stock_diario_simple' creada exitosamente")
                
                # Probar vista
                print("\n🧪 Probando vista...")
                test_query = text("""
                    SELECT TOP 5 
                        fecha, guardia, codigo, descripcion,
                        stock_inicial, stock_final, stock_final_calculado,
                        estado_consistencia
                    FROM vw_stock_diario_simple
                    ORDER BY fecha DESC, guardia, codigo
                """)
                
                resultados = db.session.execute(test_query).fetchall()
                
                if resultados:
                    print("✅ Vista funciona correctamente:")
                    for row in resultados:
                        fecha, guardia, codigo, desc, inicial, final, calculado, estado = row
                        print(f"   📅 {fecha} {guardia} - {codigo}: {inicial} → {final} (calc: {calculado}) [{estado}]")
                        
                    # Verificar inconsistencias
                    inconsistentes_query = text("""
                        SELECT COUNT(*) as total_inconsistentes
                        FROM vw_stock_diario_simple
                        WHERE estado_consistencia = 'INCONSISTENTE'
                    """)
                    
                    inconsistentes = db.session.execute(inconsistentes_query).scalar()
                    
                    if inconsistentes > 0:
                        print(f"\n⚠️ Se detectaron {inconsistentes} registros inconsistentes")
                        print("   Ejecuta: python recalcular_stock_automatico.py")
                    else:
                        print("\n✅ Todos los registros son consistentes")
                        
                else:
                    print("⚠️ Vista creada pero sin datos")
                    
            except Exception as e:
                db.session.rollback()
                print(f"❌ Error creando vista: {e}")
                return False
        else:
            print("❌ Operación cancelada")
            return False
            
        return True

if __name__ == "__main__":
    crear_vista_simple()