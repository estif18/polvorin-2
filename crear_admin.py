#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para crear usuario administrador
Sistema de Registro de Polvorín v4.0
"""

from app import app, db, Usuario

def crear_admin():
    """Crear usuario administrador por defecto"""
    try:
        with app.app_context():
            # Verificar si ya existe un admin
            admin_existente = Usuario.query.filter_by(username='admin').first()
            
            if admin_existente:
                print("❌ El usuario 'admin' ya existe.")
                print(f"   Rol actual: {admin_existente.rol}")
                return False
            
            # Crear nuevo usuario admin
            admin = Usuario(
                username='admin',
                password='admin123',  # Cambiar en producción
                rol='administrador'
            )
            
            db.session.add(admin)
            db.session.commit()
            
            print("✅ Usuario administrador creado exitosamente!")
            print("   Usuario: admin")
            print("   Contraseña: admin123")
            print("   ⚠️  IMPORTANTE: Cambiar la contraseña en producción")
            
            return True
            
    except Exception as e:
        print(f"❌ Error creando usuario administrador: {e}")
        return False

if __name__ == '__main__':
    print("🚀 Creando usuario administrador...")
    crear_admin()