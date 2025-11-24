#!/usr/bin/env python3
"""
Script de pruebas para verificar correcciones en el sistema
Ejecuta pruebas de funcionalidad después de las correcciones
"""

import sys
import os

# Agregar el directorio del proyecto al path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import *

def test_vista_stock_actual():
    """Probar la vista v_stock_actual"""
    print("=== TEST: Vista v_stock_actual ===")
    
    try:
        with app.app_context():
            # Test 1: Verificar que la vista existe
            result = db.session.execute(text("""
                SELECT COUNT(*) as count
                FROM INFORMATION_SCHEMA.VIEWS 
                WHERE TABLE_NAME = 'v_stock_actual'
            """)).fetchone()
            
            if result and result.count > 0:
                print("✅ Vista v_stock_actual existe")
            else:
                print("❌ Vista v_stock_actual NO existe")
                return False
            
            # Test 2: Verificar datos de la vista
            result = db.session.execute(text("SELECT COUNT(*) as count FROM v_stock_actual")).fetchone()
            if result and result.count > 0:
                print(f"✅ Vista tiene {result.count} registros")
            else:
                print("❌ Vista está vacía")
                return False
            
            # Test 3: Verificar algunos stocks específicos
            result = db.session.execute(text("""
                SELECT TOP 3 codigo, descripcion, stock_actual 
                FROM v_stock_actual 
                ORDER BY codigo
            """)).fetchall()
            
            for row in result:
                print(f"   {row.codigo} | {row.descripcion[:30]} | Stock: {row.stock_actual}")
            
            return True
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_funciones_stock():
    """Probar las funciones de stock corregidas"""
    print("\n=== TEST: Funciones de Stock ===")
    
    try:
        with app.app_context():
            # Test 1: usar_vista_stock_powerbi()
            vista_disponible = usar_vista_stock_powerbi()
            print(f"✅ usar_vista_stock_powerbi(): {vista_disponible}")
            
            # Test 2: obtener_stock_via_vista()
            explosivo_test = Explosivo.query.first()
            if explosivo_test:
                stock = obtener_stock_via_vista(explosivo_test.id)
                print(f"✅ obtener_stock_via_vista({explosivo_test.codigo}): {stock}")
            
            # Test 3: calcular_stock_explosivo()
            if explosivo_test:
                stock = calcular_stock_explosivo(explosivo_test.id)
                print(f"✅ calcular_stock_explosivo({explosivo_test.codigo}): {stock}")
            
            # Test 4: obtener_stock_todos_explosivos_optimizado()
            stocks = obtener_stock_todos_explosivos_optimizado()
            print(f"✅ obtener_stock_todos_explosivos_optimizado(): {len(stocks)} explosivos")
            
            return True
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_consistencia_datos():
    """Verificar consistencia entre vista y stock_diario"""
    print("\n=== TEST: Consistencia de Datos ===")
    
    try:
        with app.app_context():
            # Verificar que no hay inconsistencias
            result = db.session.execute(text("""
                SELECT COUNT(*) as inconsistencias
                FROM v_stock_actual v
                INNER JOIN stock_diario sd ON v.id = sd.explosivo_id
                WHERE sd.fecha = CAST(GETDATE() AS DATE)
                  AND sd.guardia = CASE 
                      WHEN DATEPART(HOUR, GETDATE()) BETWEEN 6 AND 17 THEN 'dia'
                      ELSE 'noche'
                  END
                  AND ABS(v.stock_actual - sd.stock_final) > 0
            """)).fetchone()
            
            inconsistencias = result.inconsistencias if result else 0
            
            if inconsistencias == 0:
                print("✅ No hay inconsistencias entre vista y stock_diario")
            else:
                print(f"❌ {inconsistencias} inconsistencias encontradas")
                return False
            
            # Verificar algunos registros específicos
            result = db.session.execute(text("""
                SELECT TOP 3
                    v.codigo,
                    v.stock_actual as vista,
                    sd.stock_final as diario
                FROM v_stock_actual v
                INNER JOIN stock_diario sd ON v.id = sd.explosivo_id
                WHERE sd.fecha = CAST(GETDATE() AS DATE)
                  AND v.codigo LIKE '030%'
                ORDER BY v.codigo
            """)).fetchall()
            
            for row in result:
                consistente = "✅" if row.vista == row.diario else "❌"
                print(f"   {consistente} {row.codigo} | Vista: {row.vista} | Diario: {row.diario}")
            
            return True
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_apis_criticas():
    """Probar APIs críticas"""
    print("\n=== TEST: APIs Críticas ===")
    
    try:
        with app.app_context():
            # Simular request context para las APIs
            with app.test_request_context():
                # Simular sesión de usuario
                from flask import session
                session['user_id'] = 1  # Asumir usuario admin
                
                # Test API stock masivo
                try:
                    stocks = obtener_stock_todos_explosivos_optimizado()
                    print(f"✅ API stock masivo: {len(stocks)} explosivos")
                except Exception as e:
                    print(f"❌ Error API stock masivo: {e}")
                
                # Test API stock individual
                explosivo_test = Explosivo.query.first()
                if explosivo_test:
                    try:
                        stock = calcular_stock_explosivo(explosivo_test.id)
                        print(f"✅ API stock individual: {explosivo_test.codigo} = {stock}")
                    except Exception as e:
                        print(f"❌ Error API stock individual: {e}")
            
            return True
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    """Ejecutar todas las pruebas"""
    print("🧨 SISTEMA DE POLVORÍN - PRUEBAS POST-CORRECCIÓN")
    print("=" * 60)
    
    resultados = []
    
    # Ejecutar todas las pruebas
    resultados.append(("Vista v_stock_actual", test_vista_stock_actual()))
    resultados.append(("Funciones de Stock", test_funciones_stock()))
    resultados.append(("Consistencia de Datos", test_consistencia_datos()))
    resultados.append(("APIs Críticas", test_apis_criticas()))
    
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
        print("🎉 ¡TODAS LAS CORRECCIONES FUNCIONAN CORRECTAMENTE!")
        return 0
    else:
        print("⚠️ Algunas correcciones requieren atención adicional")
        return 1

if __name__ == "__main__":
    sys.exit(main())