import sys
sys.path.append(r'c:\Users\estif\Desktop\CODIGO-REGISTRO-POLVORIN')

try:
    from app import db, app
    
    with app.app_context():
        connection = db.engine.raw_connection()
        cursor = connection.cursor()
        
        print('🔍 Buscando valores válidos para el campo estado...')
        
        # Ver algunos valores existentes de estado en la tabla salidas
        cursor.execute("SELECT DISTINCT estado FROM salidas WHERE estado IS NOT NULL")
        
        estados = cursor.fetchall()
        print('\nValores de estado existentes:')
        for estado in estados:
            print(f'  - "{estado[0]}"')
        
        # También revisar la tabla ingresos para comparar
        cursor.execute("SELECT DISTINCT estado FROM ingresos WHERE estado IS NOT NULL")
        
        estados_ing = cursor.fetchall()
        print('\nValores de estado en ingresos (para comparar):')
        for estado in estados_ing:
            print(f'  - "{estado[0]}"')
            
        cursor.close()
        connection.close()
        
except Exception as e:
    print(f'❌ Error: {str(e)}')