#!/usr/bin/env python3
# decrypt_to_source.py - Transforme task.py en code lisible

import re
import zlib
import marshal
import sys
import os
import tempfile
import subprocess

def decrypt_task_to_source(input_file="task.py", output_file="task_decrypted.py"):
    """
    Déchiffre COMPLÈTEMENT task.py en code source lisible
    """
    
    print(f"🔓 DÉCHIFFREMENT DE {input_file}")
    print("=" * 60)
    
    # 1. LIRE le fichier
    with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    print(f"📦 Taille: {len(content)} caractères")
    
    # 2. TROUVER les variables de chiffrement
    # Méthode ROBUSTE qui marche avec n'importe quel format
    lines = content.split('\n')
    
    # Chercher payload_data (même sur plusieurs lignes)
    payload_hex = None
    salt_hex = None
    
    current_line = ""
    for line in lines:
        if 'payload_data' in line:
            current_line = line
            # Si la ligne est incomplète (quotes non fermées)
            while current_line.count("'") % 2 == 1:
                idx = lines.index(line) + 1
                if idx < len(lines):
                    current_line += lines[idx]
                    line = lines[idx]
                else:
                    break
            
            # Extraire la valeur hex
            hex_match = re.search(r"'([a-f0-9]{100,})'", current_line)
            if hex_match:
                payload_hex = hex_match.group(1)
                print(f"✅ Payload trouvée: {len(payload_hex)//2} bytes")
            break
    
    # Chercher config_salt
    for line in lines:
        if 'config_salt' in line:
            salt_match = re.search(r"'([a-f0-9]+)'", line)
            if salt_match:
                salt_hex = salt_match.group(1)
                print(f"✅ Salt trouvé: {len(salt_hex)//2} bytes")
            break
    
    if not payload_hex or not salt_hex:
        print("❌ Variables non trouvées!")
        return None
    
    # 3. DÉCHIFFRER
    print("\n🔓 Déchiffrement en cours...")
    
    salt = bytes.fromhex(salt_hex)
    payload = bytes.fromhex(payload_hex)
    
    # XOR
    decrypted = bytearray()
    for i, byte in enumerate(payload):
        decrypted.append(byte ^ salt[i % len(salt)])
    
    # Zlib + Marshal
    try:
        decompressed = zlib.decompress(bytes(decrypted))
        code_obj = marshal.loads(decompressed)
        print(f"✅ Décompressé: {len(decompressed)} bytes")
    except zlib.error:
        code_obj = marshal.loads(bytes(decrypted))
        print(f"✅ Chargement direct: {len(decrypted)} bytes")
    
    print("🎯 Code Python chargé en mémoire")
    
    # 4. CONVERTIR en code source (DÉCOMPILATION)
    print("\n🔧 Conversion en code source lisible...")
    
    # OPTION A: Sauvegarder en .pyc et décompiler
    source_code = decompile_to_source(code_obj)
    
    if not source_code:
        print("❌ Décompilation échouée, utilisation du bytecode")
        source_code = get_bytecode_as_source(code_obj)
    
    # 5. SAUVEGARDER le code source
    print(f"\n💾 Sauvegarde: {output_file}")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("#!/usr/bin/env python3\n")
        f.write('"""\n')
        f.write('CODE PYTHON DÉCHIFFRÉ EN CLAIR\n')
        f.write(f'Original: {input_file} (chiffré)\n')
        f.write(f'Déchiffré le: {__import__("datetime").datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
        f.write('"""\n\n')
        
        # Ajouter les infos de déchiffrement
        f.write("#" * 60 + "\n")
        f.write("# INFORMATIONS DE DÉCHIFFREMENT\n")
        f.write("#" * 60 + "\n")
        f.write(f"# config_salt = '{salt_hex}'\n")
        f.write(f"# payload_data = '{payload_hex[:100]}...'  # {len(payload_hex)//2} bytes\n")
        f.write("# Méthode: XOR → zlib → marshal\n")
        f.write("#" * 60 + "\n\n")
        
        # Le code source
        f.write(source_code)
    
    # Compter les lignes
    with open(output_file, 'r') as f:
        line_count = len(f.readlines())
    
    print(f"✅ Fichier créé: {output_file}")
    print(f"📄 {line_count} lignes de code")
    
    # 6. VÉRIFIER la syntaxe
    print("\n🔍 Vérification syntaxique...")
    try:
        with open(output_file, 'r') as f:
            test_code = f.read()
        compile(test_code, output_file, 'exec')
        print("✅ Syntaxe Python VALIDE")
    except SyntaxError as e:
        print(f"⚠️  Problème syntaxique: {e}")
        print("Le fichier contient peut-être du bytecode")
    
    return output_file

def decompile_to_source(code_obj):
    """Essaye de décompiler l'objet code en source"""
    
    # Méthode 1: uncompyle6 (si disponible)
    try:
        import uncompyle6
        import io
        
        print("  Essai avec uncompyle6...")
        output = io.StringIO()
        
        # Essayer différentes versions
        for version in ['3.9', '3.8', '3.7', '3.10', '3.11']:
            try:
                output = io.StringIO()
                uncompyle6.deparse_code2str(code_obj, out=output, version=version)
                source = output.getvalue()
                print(f"    ✅ Version Python {version}")
                return source
            except:
                continue
                
    except ImportError:
        print("  ❌ uncompyle6 non installé")
    
    # Méthode 2: decompyle3 (si disponible)
    try:
        from decompyle3.semantics.pysource import code_deparse
        import io
        
        print("  Essai avec decompyle3...")
        output = io.StringIO()
        
        # Essayer différentes versions
        for version in [(3, 9), (3, 8), (3, 7), (3, 10)]:
            try:
                output = io.StringIO()
                code_deparse(code_obj, out=output, version=version)
                source = output.getvalue()
                print(f"    ✅ Python {version[0]}.{version[1]}")
                return source
            except:
                continue
                
    except ImportError:
        print("  ❌ decompyle3 non disponible")
    
    # Méthode 3: pycdc (outil externe)
    try:
        print("  Essai avec pycdc...")
        
        # Créer un fichier .pyc temporaire
        import tempfile
        tmp_file = tempfile.NamedTemporaryFile(suffix='.pyc', delete=False)
        
        # Écrire un header .pyc valide
        import struct
        import time
        magic = 3394  # Python 3.8 magic number
        tmp_file.write(struct.pack('<H', magic))
        tmp_file.write(struct.pack('<I', int(time.time())))
        tmp_file.write(struct.pack('<I', 0))
        marshal.dump(code_obj, tmp_file)
        tmp_file.close()
        
        # Essayer pycdc
        try:
            result = subprocess.run(
                ['pycdc', tmp_file.name],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                os.unlink(tmp_file.name)
                return result.stdout
        except FileNotFoundError:
            print("    ❌ pycdc non installé")
        
        os.unlink(tmp_file.name)
        
    except Exception as e:
        print(f"  ❌ pycdc erreur: {e}")
    
    return None

def get_bytecode_as_source(code_obj):
    """Retourne le bytecode formaté comme source"""
    
    import dis
    import io
    
    output = io.StringIO()
    dis.dis(code_obj, file=output)
    bytecode = output.getvalue()
    
    source = f'''# ==================== BYTECODE ====================
# Le décompilateur a échoué, voici le bytecode
# Pour le décompiler, installez:
#   pip install uncompyle6
#   pip install decompyle3
# Ou utilisez: python -m py_compile votre_fichier.py

"""
{bytecode}
"""

# ==================== EXÉCUTION DIRECTE ====================
# Pour exécuter ce code malgré tout:
import marshal
code_obj = marshal.loads({repr(marshal.dumps(code_obj))})
exec(code_obj)
'''
    
    return source

def main():
    """Fonction principale"""
    
    print("🔓 DÉCHIFFREUR PYTHON → CODE CLAIR")
    print("=" * 60)
    
    # Vérifier le fichier
    input_file = "task.py"
    if not os.path.exists(input_file):
        print(f"❌ {input_file} non trouvé")
        print("Placez ce script dans le même dossier que task.py")
        return
    
    # Déchiffrer
    output_file = decrypt_task_to_source(input_file, "task_EN_CLAIR.py")
    
    if output_file:
        print(f"\n{'='*60}")
        print("🎉 DÉCHIFFREMENT RÉUSSI !")
        print(f"{'='*60}")
        
        # Afficher un aperçu
        print("\n👁️  APERÇU DU CODE DÉCHIFFRÉ:")
        print("-" * 40)
        
        try:
            with open(output_file, 'r') as f:
                for i in range(25):  # 25 premières lignes
                    line = f.readline()
                    if not line:
                        break
                    print(f"{i+1:3}: {line.rstrip()}")
            
            print("...")
            
        except Exception as e:
            print(f"❌ Erreur lecture: {e}")
        
        # Instructions
        print(f"\n📋 INSTRUCTIONS:")
        print(f"1. Voir le code complet: cat {output_file}")
        print(f"2. Éditer: nano {output_file}")
        print(f"3. Exécuter: python {output_file}")
        print(f"\n📊 Taille: {os.path.getsize(output_file)} bytes")
        
        # Vérifier si c'est vraiment du code source
        with open(output_file, 'r') as f:
            content = f.read()
            if "LOAD_CONST" in content or "CALL_FUNCTION" in content:
                print("⚠️  ATTENTION: Le fichier contient du BYTECODE, pas du code source")
                print("   Installez un décompilateur: pip install uncompyle6")
    
    else:
        print("\n❌ Échec du déchiffrement")

if __name__ == "__main__":
    main()
