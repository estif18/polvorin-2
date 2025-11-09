"""
INGRESO HIPOTÉTICO - STOCK INICIAL
==================================

Agregar 1000 unidades de cada explosivo como stock inicial
para tener datos de prueba en el sistema
"""

import pyodbc
from datetime import datetime

SQLSERVER_CONFIG = {
    'server': 'pallca.database.windows.net',
    'database': 'pallca',
    'username': 'pract_seg_pal@santa-luisa.pe@pallca',
    'password': 'pallca/berlin/2025',
    'driver': '{ODBC Driver 17 for SQL Server}'
}

def get_connection():
    connection_string = (
        f"DRIVER={SQLSERVER_CONFIG['driver']};"
        f"SERVER={SQLSERVER_CONFIG['server']};"
        f"DATABASE={SQLSERVER_CONFIG['database']};"
        f"UID={SQLSERVER_CONFIG['username']};"
        f"PWD={SQLSERVER_CONFIG['password']}"
    )
    return pyodbc.connect(connection_string)

def obtener_todos_los_explosivos():
    """Obtener todos los explosivos de la base de datos"""
    
    print("🔍 OBTENIENDO LISTA DE EXPLOSIVOS")
    print("=" * 32)
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT id, codigo, descripcion, unidad
            FROM explosivos
            ORDER BY codigo
        """)
        
        explosivos = cursor.fetchall()
        
        print(f"📊 Total explosivos encontrados: {len(explosivos)}")
        print(f"\n📋 LISTA DE EXPLOSIVOS:")
        
        for i, explosivo in enumerate(explosivos, 1):
            exp_id, codigo, descripcion, unidad = explosivo
            desc_corta = descripcion[:50] + "..." if len(descripcion) > 50 else descripcion
            print(f"  {i:2d}. {codigo} - {desc_corta} ({unidad})")
        
        return explosivos
        
    except Exception as e:
        print(f"❌ Error obteniendo explosivos: {e}")
        return []
    finally:
        conn.close()

def crear_ingresos_masivos(explosivos):
    """Crear ingresos de 1000 unidades para cada explosivo"""
    
    print(f"\n➕ CREANDO INGRESOS MASIVOS")
    print("=" * 26)
    print(f"🎯 Objetivo: 1000 unidades por explosivo")
    print(f"📅 Fecha: 31 de octubre 2025, guardia día")
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        fecha_ingreso = datetime(2025, 10, 31, 10, 0, 0)  # 31 oct 2025, 10:00 AM
        ingresos_creados = []
        errores = []
        
        print(f"\n🚀 PROCESANDO INGRESOS...")
        
        for i, explosivo in enumerate(explosivos, 1):
            exp_id, codigo, descripcion, unidad = explosivo
            
            try:
                print(f"  📦 {i:2d}/{len(explosivos)}: {codigo} - 1000 {unidad}")
                
                # Insertar ingreso
                cursor.execute("""
                    INSERT INTO ingresos (
                        explosivo_id, 
                        cantidad, 
                        fecha_ingreso, 
                        numero_vale, 
                        recibido_por, 
                        guardia, 
                        observaciones
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (
                    exp_id,
                    1000,  # 1000 unidades
                    fecha_ingreso,
                    'VALE-INICIAL-001',  # Vale hipotético
                    'SISTEMA ADMINISTRADOR',  # Recibido por
                    'DIA',  # Guardia día
                    f'STOCK INICIAL HIPOTÉTICO - 1000 {unidad} de {descripcion[:30]}'
                ))
                
                ingresos_creados.append({
                    'codigo': codigo,
                    'descripcion': descripcion,
                    'cantidad': 1000,
                    'unidad': unidad
                })
                
            except Exception as e:
                error_msg = f"Error en {codigo}: {str(e)}"
                errores.append(error_msg)
                print(f"    ❌ {error_msg}")
        
        # Confirmar transacción
        if ingresos_creados:
            conn.commit()
            print(f"\n🏆 ¡INGRESOS CREADOS EXITOSAMENTE!")
            print(f"  ✅ Explosivos procesados: {len(ingresos_creados)}")
            print(f"  📊 Total unidades agregadas: {len(ingresos_creados) * 1000:,}")
            
            if errores:
                print(f"  ⚠️  Errores encontrados: {len(errores)}")
                for error in errores:
                    print(f"    • {error}")
            
            return True
        else:
            conn.rollback()
            print(f"\n❌ No se crearon ingresos")
            return False
        
    except Exception as e:
        conn.rollback()
        print(f"\n❌ Error general creando ingresos: {e}")
        return False
    finally:
        conn.close()

def verificar_ingresos_creados():
    """Verificar que los ingresos se crearon correctamente"""
    
    print(f"\n✅ VERIFICANDO INGRESOS CREADOS")
    print("=" * 29)
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        # Contar ingresos del día 31 octubre
        cursor.execute("""
            SELECT COUNT(*) as total_ingresos, SUM(cantidad) as total_unidades
            FROM ingresos
            WHERE CAST(fecha_ingreso AS DATE) = '2025-10-31'
            AND guardia = 'DIA'
        """)
        
        resultado = cursor.fetchone()
        total_ingresos, total_unidades = resultado
        
        print(f"📊 RESUMEN DE INGRESOS DÍA 31/10/2025:")
        print(f"  • Total registros: {total_ingresos}")
        print(f"  • Total unidades: {total_unidades:,}")
        
        # Mostrar algunos ejemplos
        cursor.execute("""
            SELECT TOP 5 e.codigo, i.cantidad, e.unidad, e.descripcion
            FROM ingresos i
            JOIN explosivos e ON i.explosivo_id = e.id
            WHERE CAST(i.fecha_ingreso AS DATE) = '2025-10-31'
            AND i.guardia = 'DIA'
            ORDER BY e.codigo
        """)
        
        ejemplos = cursor.fetchall()
        
        print(f"\n📋 EJEMPLOS DE INGRESOS CREADOS:")
        for ejemplo in ejemplos:
            codigo, cantidad, unidad, descripcion = ejemplo
            desc_corta = descripcion[:40] + "..." if len(descripcion) > 40 else descripcion
            print(f"  • {codigo}: {cantidad:,} {unidad} - {desc_corta}")
        
        if len(ejemplos) == 5:
            print(f"  ... y {total_ingresos - 5} más")
        
        return total_ingresos > 0
        
    except Exception as e:
        print(f"❌ Error verificando ingresos: {e}")
        return False
    finally:
        conn.close()

def mostrar_stock_actual_muestra():
    """Mostrar una muestra del stock actual después de los ingresos"""
    
    print(f"\n📊 MUESTRA DE STOCK ACTUAL")
    print("=" * 24)
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        # Obtener muestra de stock actual usando la vista si existe
        cursor.execute("""
            SELECT TOP 10 
                e.codigo, 
                e.descripcion, 
                e.unidad,
                COALESCE(SUM(i.cantidad), 0) as total_ingresos,
                COALESCE(SUM(s.cantidad), 0) as total_salidas,
                COALESCE(SUM(d.cantidad_devuelta), 0) as total_devoluciones,
                (COALESCE(SUM(i.cantidad), 0) - COALESCE(SUM(s.cantidad), 0) + COALESCE(SUM(d.cantidad_devuelta), 0)) as stock_calculado
            FROM explosivos e
            LEFT JOIN ingresos i ON e.id = i.explosivo_id
            LEFT JOIN salidas s ON e.id = s.explosivo_id
            LEFT JOIN devoluciones d ON e.id = d.explosivo_id
            GROUP BY e.id, e.codigo, e.descripcion, e.unidad
            ORDER BY e.codigo
        """)
        
        stocks = cursor.fetchall()
        
        print(f"🎯 STOCK CALCULADO (primeros 10 items):")
        print(f"{'CÓDIGO':<12} {'STOCK':>8} {'UNIDAD':<6} {'DESCRIPCIÓN'}")
        print(f"{'-'*12} {'-'*8} {'-'*6} {'-'*30}")
        
        for stock in stocks:
            codigo, descripcion, unidad, ingresos, salidas, devoluciones, stock_calc = stock
            desc_corta = descripcion[:30] + "..." if len(descripcion) > 30 else descripcion
            print(f"{codigo:<12} {stock_calc:>8,.0f} {unidad:<6} {desc_corta}")
        
        print(f"\n💡 NOTA: Stock = Ingresos - Salidas + Devoluciones")
        
        return True
        
    except Exception as e:
        print(f"❌ Error calculando stock: {e}")
        return False
    finally:
        conn.close()

if __name__ == "__main__":
    print("📦 INGRESO MASIVO - STOCK INICIAL HIPOTÉTICO")
    print("=" * 42)
    print("🎯 Objetivo: Crear 1000 unidades de cada explosivo")
    print("📅 Fecha: 31 de octubre 2025")
    print("🏷️  Vale: VALE-INICIAL-001")
    
    # Paso 1: Obtener todos los explosivos
    explosivos = obtener_todos_los_explosivos()
    
    if explosivos:
        # Paso 2: Crear los ingresos masivos
        if crear_ingresos_masivos(explosivos):
            # Paso 3: Verificar que se crearon correctamente
            if verificar_ingresos_creados():
                # Paso 4: Mostrar muestra del stock resultante
                mostrar_stock_actual_muestra()
                
                print(f"\n🌟 PROCESO COMPLETADO EXITOSAMENTE")
                print(f"   📦 Stock inicial creado para todos los explosivos")
                print(f"   🎯 1000 unidades por explosivo")
                print(f"   ✅ Sistema listo para operaciones")
            else:
                print(f"\n⚠️  Verificación falló")
        else:
            print(f"\n❌ Error creando ingresos")
    else:
        print(f"\n❌ No se encontraron explosivos en la base de datos")