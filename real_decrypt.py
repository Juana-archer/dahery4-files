#!/usr/bin/env python3
# real_decrypt.py - Déchiffrement COMPLET et CORRECT

import re
import zlib
import marshal
import sys
import os

def extract_real_code():
    """Extrait et exécute le vrai code déchiffré"""
    
    print("🔓 DÉCHIFFREMENT RÉEL DU CODE")
    print("=" * 50)
    
    # 1. Lire task.py directement
    with open('task.py', 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    print("📦 Analyse du fichier original...")
    
    # 2. Chercher TOUTES les variables (méthode robuste)
    variables = {}
    
    # Nettoyer le contenu
    clean_content = content.replace('\n', ' ').replace('\t', ' ')
    
    # Pattern pour trouver var='value'
    pattern = r"(\w+)\s*=\s*['\"]([^'\"]+)['\"]"
    matches = re.findall(pattern, clean_content)
    
    for var_name, var_value in matches:
        variables[var_name] = var_value
    
    print(f"✅ {len(variables)} variables extraites")
    
    # 3. Chercher LES VRAIES variables de déchiffrement
    # Regarder le code original pour comprendre la logique
    lines = content.split('\n')
    for line in lines:
        if 'bytes.fromhex' in line and 'payload_data' in line:
            print(f"📝 Ligne de déchiffrement: {line.strip()}")
    
    # 4. Essayer de trouver payload_data et config_salt
    payload_data = None
    config_salt = None
    
    for key, value in variables.items():
        if 'payload' in key.lower() and len(value) > 100:
            payload_data = value
            print(f"🎯 Payload trouvée: {key} = {value[:50]}...")
        if 'salt' in key.lower():
            config_salt = value
            print(f"🎯 Salt trouvée: {key} = {value}")
    
    if not payload_data or not config_salt:
        print("❌ Variables essentielles non trouvées")
        
        # Afficher les variables longues (potentiellement la payload)
        print("\n🔍 Variables longues (>100 chars):")
        for key, value in variables.items():
            if len(value) > 100:
                print(f"  {key}: {value[:80]}...")
        return None
    
    print(f"\n🔓 Déchiffrement avec:")
    print(f"  Payload: {len(payload_data)//2} bytes hex")
    print(f"  Salt: {len(config_salt)//2} bytes hex")
    
    # 5. DÉCHIFFREMENT
    try:
        # Convertir hex -> bytes
        salt_bytes = bytes.fromhex(config_salt)
        payload_bytes = bytes.fromhex(payload_data)
        
        # XOR déchiffrement
        print("\n🧮 Déchiffrement XOR...")
        decrypted = bytearray()
        for i, byte in enumerate(payload_bytes):
            decrypted.append(byte ^ salt_bytes[i % len(salt_bytes)])
        
        # Zlib decompression
        print("🗜️  Décompression zlib...")
        try:
            decompressed = zlib.decompress(bytes(decrypted))
            print(f"✅ Décompressé: {len(decompressed)} bytes")
            data = decompressed
        except zlib.error:
            print("⚠️  Pas de zlib, utilisation directe")
            data = bytes(decrypted)
        
        # Marshal load
        print("📦 Chargement marshal...")
        code_obj = marshal.loads(data)
        print("🎉 VRAI code objet chargé!")
        
        return code_obj, variables
        
    except Exception as e:
        print(f"❌ Erreur déchiffrement: {e}")
        import traceback
        traceback.print_exc()
        return None, None

def save_real_source(code_obj, output_file="real_decrypted.py"):
    """Sauvegarde le VRAI code source"""
    
    print(f"\n💾 Sauvegarde du vrai code: {output_file}")
    
    # Méthode 1: Essayer uncompyle6/decompyle3
    source_code = None
    
    try:
        # Essayer decompyle3 d'abord
        import decompyle3
        import io
        
        print("  Décompilation avec decompyle3...")
        output = io.StringIO()
        
        # Méthode alternative
        from decompyle3 import decompile
        try:
            decompile(sys.version_info[:2], code_obj, out=output)
            source_code = output.getvalue()
            print("  ✅ Décompilation réussie!")
        except Exception as e:
            print(f"  ❌ decompyle3 échoué: {e}")
            raise
            
    except ImportError:
        print("  ❌ decompyle3 non installé")
    
    except Exception:
        # Méthode 2: Utiliser le bytecode
        import dis
        import io
        
        print("  Récupération du bytecode...")
        output = io.StringIO()
        dis.dis(code_obj, file=output)
        source_code = f"# BYTECODE DU VRAI PROGRAMME\n"
        source_code += "# Python {sys.version}\n"
        source_code += "# Exécutez avec: python -c \"import marshal; exec(marshal.load(open('code.bin','rb')))\"\n"
        source_code += "'''\n" + output.getvalue() + "\n'''"
    
    if source_code:
        # Sauvegarder
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("#!/usr/bin/env python3\n")
            f.write('"""\n')
            f.write('VRAI CODE DÉCHIFFRÉ\n')
            f.write('Original: task.py (obfusqué)\n')
            f.write('Déchiffré le: ' + __import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S') + '\n')
            f.write('"""\n\n')
            f.write("#" * 60 + "\n")
            f.write("# IMPORTANT: Ceci est le VRAI code déchiffré\n")
            f.write("#" * 60 + "\n\n")
            f.write(source_code)
        
        print(f"✅ Fichier sauvegardé: {output_file}")
        
        # Afficher un aperçu
        print("\n📄 Aperçu (30 premières lignes):")
        print("-" * 40)
        lines = source_code.split('\n')
        for i in range(min(30, len(lines))):
            print(lines[i])
        
        return output_file
    
    return None

def execute_real_code(code_obj):
    """Exécute le VRAI code déchiffré"""
    
    print("\n" + "="*50)
    print("🚀 EXÉCUTION DU VRAI CODE DÉCHIFFRÉ")
    print("="*50)
    
    try:
        exec(code_obj)
    except Exception as e:
        print(f"❌ Erreur d'exécution: {e}")
        import traceback
        traceback.print_exc()

def extract_and_save_raw():
    """Méthode ALTERNATIVE: Extraire le code brut sans analyse"""
    
    print("\n🔧 MÉTHODE ALTERNATIVE: Extraction brute")
    
    with open('task.py', 'r') as f:
        data = f.read()
    
    # Chercher la payload HEX complète
    import re
    
    # Pattern amélioré
    hex_pattern = r"'([a-f0-9]{5000,})'"  # Très longue chaîne hex
    matches = re.findall(hex_pattern, data)
    
    if not matches:
        print("❌ Aucune longue chaîne hex trouvée")
        return
    
    payload_hex = matches[0]
    print(f"✅ Payload brute: {len(payload_hex)//2} bytes")
    
    # Chercher le salt
    salt_pattern = r"config_salt\s*=\s*'([a-f0-9]+)'"
    salt_match = re.search(salt_pattern, data)
    
    if salt_match:
        salt_hex = salt_match.group(1)
        print(f"✅ Salt: {len(salt_hex)//2} bytes")
        
        # Déchiffrement
        salt = bytes.fromhex(salt_hex)
        payload = bytes.fromhex(payload_hex)
        
        # XOR
        decrypted = bytearray()
        for i, b in enumerate(payload):
            decrypted.append(b ^ salt[i % len(salt)])
        
        # Sauvegarder brut
        with open('raw_decrypted.bin', 'wb') as f:
            f.write(bytes(decrypted))
        
        print("✅ Données brutes sauvegardées: raw_decrypted.bin")
        
        # Essayer marshal
        try:
            import marshal
            code = marshal.loads(bytes(decrypted))
            
            # Sauvegarder objet
            with open('real_code.bin', 'wb') as f:
                marshal.dump(code, f)
            
            print("✅ Objet code réel: real_code.bin")
            
            # Exécuter
            print("\n🎮 Exécuter ce code? (o/n)")
            if input().strip().lower() == 'o':
                exec(code)
                
        except Exception as e:
            print(f"⚠️  Marshal échoué: {e}")
            
            # Essayer zlib d'abord
            try:
                import zlib
                decomp = zlib.decompress(bytes(decrypted))
                
                # Puis marshal
                code = marshal.loads(decomp)
                
                with open('real_code.bin', 'wb') as f:
                    marshal.dump(code, f)
                
                print("✅ Code avec zlib: real_code.bin")
                
                # Exécuter
                print("\n🎮 Exécuter? (o/n)")
                if input().strip().lower() == 'o':
                    exec(code)
                    
            except Exception as e2:
                print(f"❌ Échec complet: {e2}")

def main():
    """Fonction principale"""
    
    print("🔓 DÉCHIFFREMENT COMPLET - VERSION FINALE")
    print("=" * 60)
    
    # Vérifier fichier
    if not os.path.exists('task.py'):
        print("❌ task.py non trouvé")
        return
    
    # Option 1: Méthode intelligente
    print("\n1️⃣ MÉTHODE INTELLIGENTE")
    result = extract_real_code()
    
    if result and result[0]:
        code_obj, variables = result
        
        # Sauvegarder
        saved = save_real_source(code_obj, "real_final_code.py")
        
        if saved:
            print(f"\n✅ VRAI code sauvegardé dans: {saved}")
            print(f"   Taille: {os.path.getsize(saved)} bytes")
        
        # Exécuter
        print("\n🎮 Exécuter le VRAI code? (o/n)")
        if input().strip().lower() == 'o':
            execute_real_code(code_obj)
    
    else:
        print("\n❌ Méthode intelligente échouée, tentative méthode brute...")
        
        # Option 2: Méthode brute
        print("\n2️⃣ MÉTHODE BRUTE")
        extract_and_save_raw()

if __name__ == "__main__":
    main()
