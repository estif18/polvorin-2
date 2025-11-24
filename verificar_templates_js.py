#!/usr/bin/env python3
"""
Script para verificar errores JavaScript en templates
Simula validaciones comunes que pueden causar errores de null reference
"""

import sys
import os
from pathlib import Path

def analizar_template_js(archivo_path):
    """Analizar un template HTML en busca de posibles errores JavaScript"""
    print(f"\n📁 Analizando: {archivo_path}")
    
    try:
        with open(archivo_path, 'r', encoding='utf-8') as f:
            contenido = f.read()
        
        # Patrones problemáticos comunes
        problemas = []
        lineas = contenido.split('\n')
        
        for num_linea, linea in enumerate(lineas, 1):
            # getElementById sin verificación
            if 'getElementById(' in linea and '.value' in linea and '?' not in linea:
                if 'const ' in linea or 'let ' in linea:
                    # Es una asignación, probablemente está bien
                    continue
                problemas.append({
                    'linea': num_linea,
                    'tipo': 'getElementById sin verificación',
                    'codigo': linea.strip(),
                    'severidad': 'MEDIA'
                })
            
            # querySelector sin verificación antes de acceder propiedades
            if 'querySelector(' in linea and ('.textContent' in linea or '.value' in linea):
                if '?' not in linea and 'const ' not in linea:
                    problemas.append({
                        'linea': num_linea,
                        'tipo': 'querySelector sin verificación',
                        'codigo': linea.strip(),
                        'severidad': 'ALTA'
                    })
            
            # forEach sin verificar elementos internos
            if 'forEach(' in linea:
                # Buscar las siguientes líneas para ver si hay acceso directo a propiedades
                for i in range(1, min(5, len(lineas) - num_linea)):
                    siguiente = lineas[num_linea + i - 1]
                    if '.value' in siguiente or '.textContent' in siguiente:
                        if '?' not in siguiente:
                            problemas.append({
                                'linea': num_linea + i,
                                'tipo': 'Acceso directo en forEach',
                                'codigo': siguiente.strip(),
                                'severidad': 'MEDIA'
                            })
                        break
        
        # Mostrar resultados
        if problemas:
            print(f"⚠️ Se encontraron {len(problemas)} posibles problemas:")
            
            for problema in problemas:
                emoji = "🔴" if problema['severidad'] == 'ALTA' else "🟡"
                print(f"  {emoji} Línea {problema['linea']}: {problema['tipo']}")
                print(f"     {problema['codigo']}")
        else:
            print("✅ No se encontraron problemas obvios")
        
        return len(problemas)
        
    except Exception as e:
        print(f"❌ Error leyendo archivo: {e}")
        return -1

def verificar_correccion_nueva_devolucion():
    """Verificar específicamente las correcciones en nueva_devolucion.html"""
    print("\n🔧 VERIFICANDO CORRECCIONES EN nueva_devolucion.html")
    
    archivo = Path("templates/nueva_devolucion.html")
    if not archivo.exists():
        print("❌ Archivo nueva_devolucion.html no encontrado")
        return False
    
    try:
        with open(archivo, 'r', encoding='utf-8') as f:
            contenido = f.read()
        
        # Verificar correcciones específicas
        correcciones_aplicadas = []
        
        # 1. Verificar uso de optional chaining (?.)
        if "getElementById('fecha_devolucion')?.value" in contenido:
            correcciones_aplicadas.append("✅ Optional chaining en fecha_devolucion")
        else:
            print("❌ Falta optional chaining en fecha_devolucion")
        
        # 2. Verificar verificación de cantidadInput
        if "cantidadInput && cantidadInput.value" in contenido:
            correcciones_aplicadas.append("✅ Verificación de cantidadInput")
        else:
            print("❌ Falta verificación de cantidadInput")
        
        # 3. Verificar verificación de observacionesEl
        if "const observacionesEl = document.getElementById('observaciones')" in contenido:
            correcciones_aplicadas.append("✅ Variable observacionesEl correcta")
        else:
            print("❌ Falta variable observacionesEl")
        
        # 4. Verificar verificación de elementos del DOM
        if "nombreEl ? nombreEl.textContent" in contenido:
            correcciones_aplicadas.append("✅ Verificación de nombreEl")
        else:
            print("❌ Falta verificación de nombreEl")
        
        print(f"\n📊 Correcciones aplicadas: {len(correcciones_aplicadas)}/4")
        for correccion in correcciones_aplicadas:
            print(f"   {correccion}")
        
        return len(correcciones_aplicadas) >= 3
        
    except Exception as e:
        print(f"❌ Error verificando correcciones: {e}")
        return False

def main():
    """Ejecutar análisis de templates"""
    print("🔍 ANALIZADOR DE ERRORES JAVASCRIPT EN TEMPLATES")
    print("=" * 60)
    
    # Cambiar al directorio del proyecto
    if not os.path.exists("templates"):
        print("❌ Directorio templates no encontrado. Ejecutar desde raíz del proyecto.")
        return 1
    
    # Analizar templates principales
    templates_criticos = [
        "templates/nueva_devolucion.html",
        "templates/nueva_salida.html", 
        "templates/nuevo_ingreso.html"
    ]
    
    total_problemas = 0
    
    for template in templates_criticos:
        if os.path.exists(template):
            problemas = analizar_template_js(template)
            if problemas > 0:
                total_problemas += problemas
        else:
            print(f"⚠️ Template {template} no encontrado")
    
    # Verificar correcciones específicas
    correcciones_ok = verificar_correccion_nueva_devolucion()
    
    # Resumen final
    print("\n" + "=" * 60)
    print("📊 RESUMEN DEL ANÁLISIS")
    print(f"Total de problemas potenciales: {total_problemas}")
    
    if correcciones_ok:
        print("✅ Correcciones aplicadas correctamente")
    else:
        print("❌ Algunas correcciones necesitan revisión")
    
    if total_problemas == 0 and correcciones_ok:
        print("🎉 ¡Templates sin problemas de referencia null!")
        return 0
    else:
        print("⚠️ Se recomienda revisar los problemas encontrados")
        return 1

if __name__ == "__main__":
    sys.exit(main())