#!/usr/bin/env python3
"""
Script de pruebas para verificar horas estandarizadas de turnos
Verifica que día=8AM y noche=8PM para mejor seguimiento en gráficas
"""

import sys
import os
from datetime import datetime, date, time

# Agregar el directorio del proyecto al path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import *

def test_horas_estandar():
    """Probar las nuevas funciones de horas estándar"""
    print("=== TEST: Horas Estándar de Turnos ===")
    
    try:
        with app.app_context():
            fecha_test = date(2025, 11, 24)
            
            # Test 1: Turno día = 8AM
            hora_dia = obtener_hora_estandar_turno("dia", fecha_test)
            print(f"✅ Turno DÍA: {hora_dia.strftime('%Y-%m-%d %H:%M:%S')}")
            
            if hora_dia.hour == 8 and hora_dia.minute == 0:
                print("   ✓ Hora correcta: 8:00 AM")
            else:
                print("   ❌ Hora incorrecta - esperaba 8:00 AM")
                return False
            
            # Test 2: Turno noche = 8PM
            hora_noche = obtener_hora_estandar_turno("noche", fecha_test)
            print(f"✅ Turno NOCHE: {hora_noche.strftime('%Y-%m-%d %H:%M:%S')}")
            
            if hora_noche.hour == 20 and hora_noche.minute == 0:
                print("   ✓ Hora correcta: 8:00 PM")
            else:
                print("   ❌ Hora incorrecta - esperaba 8:00 PM")
                return False
            
            # Test 3: Aplicar hora estándar a movimiento
            fecha_usuario = "2025-11-24"
            
            hora_mov_dia = aplicar_hora_estandar_movimiento(fecha_usuario, "dia")
            hora_mov_noche = aplicar_hora_estandar_movimiento(fecha_usuario, "noche")
            
            print(f"✅ Movimiento DÍA: {hora_mov_dia.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"✅ Movimiento NOCHE: {hora_mov_noche.strftime('%Y-%m-%d %H:%M:%S')}")
            
            # Verificar que mantiene la fecha del usuario pero con hora estándar
            if (hora_mov_dia.date() == fecha_test and hora_mov_dia.hour == 8 and
                hora_mov_noche.date() == fecha_test and hora_mov_noche.hour == 20):
                print("   ✓ Fechas y horas aplicadas correctamente")
            else:
                print("   ❌ Error en aplicación de horas")
                return False
            
            return True
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_movimientos_con_horas_estandar():
    """Simular movimientos para verificar que usan las horas correctas"""
    print("\n=== TEST: Movimientos con Horas Estándar ===")
    
    try:
        with app.app_context():
            # Verificar que tenemos explosivos para probar
            explosivo = Explosivo.query.first()
            if not explosivo:
                print("❌ No hay explosivos para probar")
                return False
            
            print(f"✅ Usando explosivo de prueba: {explosivo.codigo}")
            
            # Test de fechas para diferentes escenarios
            fechas_test = [
                ("2025-11-24", "dia", 8),  # Domingo día
                ("2025-11-24", "noche", 20),  # Domingo noche
                ("2025-11-25", "dia", 8),  # Lunes día
                ("2025-11-25", "noche", 20),  # Lunes noche
            ]
            
            for fecha_str, guardia, hora_esperada in fechas_test:
                hora_resultado = aplicar_hora_estandar_movimiento(fecha_str, guardia)
                
                if hora_resultado.hour == hora_esperada:
                    print(f"   ✓ {fecha_str} {guardia.upper()}: {hora_resultado.strftime('%H:%M')} ✅")
                else:
                    print(f"   ❌ {fecha_str} {guardia.upper()}: {hora_resultado.strftime('%H:%M')} (esperaba {hora_esperada:02d}:00)")
                    return False
            
            return True
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_consulta_movimientos_por_hora():
    """Verificar que se pueden consultar movimientos por hora específica"""
    print("\n=== TEST: Consultas por Hora de Turno ===")
    
    try:
        with app.app_context():
            # Consulta de ejemplo para movimientos de día (8AM)
            query_dia = text("""
                SELECT COUNT(*) as count_dia
                FROM salidas 
                WHERE DATEPART(hour, fecha_salida) = 8
                  AND fecha_salida >= DATEADD(day, -30, GETDATE())
            """)
            
            result = db.session.execute(query_dia).fetchone()
            movimientos_dia = result.count_dia if result else 0
            
            # Consulta de ejemplo para movimientos de noche (8PM)
            query_noche = text("""
                SELECT COUNT(*) as count_noche
                FROM salidas 
                WHERE DATEPART(hour, fecha_salida) = 20
                  AND fecha_salida >= DATEADD(day, -30, GETDATE())
            """)
            
            result = db.session.execute(query_noche).fetchone()
            movimientos_noche = result.count_noche if result else 0
            
            print(f"✅ Movimientos de DÍA (8AM) últimos 30 días: {movimientos_dia}")
            print(f"✅ Movimientos de NOCHE (8PM) últimos 30 días: {movimientos_noche}")
            
            # Si hay movimientos, verificar que tienen las horas correctas
            if movimientos_dia > 0 or movimientos_noche > 0:
                print("   ✓ Hay movimientos con horas estandarizadas")
            else:
                print("   ℹ️ Aún no hay movimientos con horas estandarizadas (normal en implementación nueva)")
            
            return True
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_beneficios_graficas():
    """Simular consulta para gráficas que se benefician de horas estándar"""
    print("\n=== TEST: Beneficios para Gráficas ===")
    
    try:
        with app.app_context():
            # Consulta de ejemplo para gráfica de turnos
            query_grafica = text("""
                SELECT 
                    CAST(fecha_salida AS DATE) as fecha,
                    CASE 
                        WHEN DATEPART(hour, fecha_salida) = 8 THEN 'DIA'
                        WHEN DATEPART(hour, fecha_salida) = 20 THEN 'NOCHE'
                        ELSE 'OTRO'
                    END as turno,
                    COUNT(*) as cantidad_movimientos,
                    SUM(cantidad) as total_explosivos
                FROM salidas 
                WHERE fecha_salida >= DATEADD(day, -7, GETDATE())
                GROUP BY CAST(fecha_salida AS DATE), 
                         CASE 
                             WHEN DATEPART(hour, fecha_salida) = 8 THEN 'DIA'
                             WHEN DATEPART(hour, fecha_salida) = 20 THEN 'NOCHE'
                             ELSE 'OTRO'
                         END
                ORDER BY fecha, turno
            """)
            
            resultados = db.session.execute(query_grafica).fetchall()
            
            print("   📊 Datos para gráficas (últimos 7 días):")
            print("      Fecha       | Turno | Movimientos | Total")
            print("      " + "-" * 45)
            
            for row in resultados:
                print(f"      {row.fecha} | {row.turno:5} | {row.cantidad_movimientos:11} | {row.total_explosivos}")
            
            # Verificar que no hay registros con 'OTRO' (horas no estándar)
            otros = [r for r in resultados if r.turno == 'OTRO']
            if not otros:
                print("   ✓ Todas las horas son estándar (8AM o 8PM)")
            else:
                print(f"   ⚠️ {len(otros)} registros con horas no estándar")
            
            print("\n   📈 Ventajas para gráficas:")
            print("      • Turnos claramente diferenciados en el tiempo")
            print("      • Consistencia en datos para análisis temporal") 
            print("      • Fácil agrupación por turno sin ambigüedad")
            
            return True
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    """Ejecutar todas las pruebas de horas estándar"""
    print("🕐 SISTEMA DE POLVORÍN - PRUEBAS HORAS ESTÁNDAR")
    print("=" * 60)
    print("📋 Verificando implementación: DÍA=8AM, NOCHE=8PM")
    
    resultados = []
    
    # Ejecutar todas las pruebas
    resultados.append(("Funciones Horas Estándar", test_horas_estandar()))
    resultados.append(("Movimientos con Horas", test_movimientos_con_horas_estandar()))
    resultados.append(("Consultas por Hora", test_consulta_movimientos_por_hora()))
    resultados.append(("Beneficios Gráficas", test_beneficios_graficas()))
    
    # Resumen de resultados
    print("\n" + "=" * 60)
    print("📊 RESUMEN DE PRUEBAS")
    
    exitosas = 0
    for nombre, resultado in resultados:
        estado = "✅ EXITOSA" if resultado else "❌ FALLIDA"
        print(f"{estado}: {nombre}")
        if resultado:
            exitosas += 1
    
    print(f"\n📈 RESULTADO FINAL: {exitosas}/{len(resultados)} pruebas exitosas")
    
    if exitosas == len(resultados):
        print("🎉 ¡HORAS ESTÁNDAR IMPLEMENTADAS CORRECTAMENTE!")
        print("\n📋 PRÓXIMOS PASOS:")
        print("   1. Los nuevos movimientos usarán las horas estándar")
        print("   2. Las gráficas mostrarán turnos claramente diferenciados")
        print("   3. Los análisis temporales serán más precisos")
        return 0
    else:
        print("⚠️ Algunas funciones requieren ajustes adicionales")
        return 1

if __name__ == "__main__":
    sys.exit(main())