#!/usr/bin/env python3
# decrypt_auto_fixed.py - Lit et déchiffre automatiquement task.py (Python 3.12 compatible)

import re
import zlib
import marshal
import sys
import os
import io
from datetime import datetime

def decrypt_task_py(filename="task.py"):
    """Déchiffre automatiquement task.py"""
    
    print(f"🔍 Lecture de {filename}...")
    
    # 1. Lire le fichier
    try:
        with open(filename, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"❌ Fichier {filename} non trouvé")
        return None, None
    except Exception as e:
        print(f"❌ Erreur lecture fichier: {e}")
        return None, None
    
    # 2. Extraire toutes les variables
    print("📦 Extraction des variables...")
    
    vars_dict = {}
    # Nettoyer le contenu pour l'analyse
    lines = content.replace(';', '\n').split('\n')
    
    for line in lines:
        line = line.strip()
        if line and '=' in line and not line.startswith('#'):
            # Supprimer les commentaires
            line = line.split('#')[0].strip()
            if '=' in line:
                parts = line.split('=', 1)
                if len(parts) == 2:
                    var_name = parts[0].strip()
                    var_value = parts[1].strip()
                    
                    # Nettoyer les quotes
                    if (var_value.startswith("'") and var_value.endswith("'")) or \
                       (var_value.startswith('"') and var_value.endswith('"')):
                        var_value = var_value[1:-1]
                    
                    vars_dict[var_name] = var_value
    
    print(f"✅ {len(vars_dict)} variables trouvées")
    
    # 3. Chercher les variables essentielles
    essential_vars = ['payload_data', 'config_salt']
    missing = [v for v in essential_vars if v not in vars_dict]
    
    if missing:
        print(f"❌ Variables manquantes: {missing}")
        
        # Chercher par pattern
        for var_name, var_value in vars_dict.items():
            if 'payload' in var_name.lower():
                print(f"  Variable similaire trouvée: {var_name}")
                vars_dict['payload_data'] = var_value
                if 'payload_data' in missing:
                    missing.remove('payload_data')
            
            if 'salt' in var_name.lower():
                print(f"  Variable similaire trouvée: {var_name}")
                vars_dict['config_salt'] = var_value
                if 'config_salt' in missing:
                    missing.remove('config_salt')
        
        if missing:
            print(f"❌ Toujours manquantes: {missing}")
            return None, None
    
    print("✅ Variables essentielles trouvées")
    
    # 4. Déchiffrement
    print("\n🔓 Déchiffrement en cours...")
    
    try:
        # Convertir hex en bytes
        salt_bytes = bytes.fromhex(vars_dict['config_salt'])
        payload_bytes = bytes.fromhex(vars_dict['payload_data'])
        
        print(f"  Salt: {len(salt_bytes)} bytes")
        print(f"  Payload: {len(payload_bytes)} bytes")
        
        # XOR décryption
        print("  Déchiffrement XOR...")
        decrypted = bytearray()
        for i, byte in enumerate(payload_bytes):
            decrypted.append(byte ^ salt_bytes[i % len(salt_bytes)])
        
        decrypted_bytes = bytes(decrypted)
        print(f"  Après XOR: {len(decrypted_bytes)} bytes")
        
        # 5. Zlib decompression
        print("  Décompression zlib...")
        try:
            decompressed = zlib.decompress(decrypted_bytes)
            print(f"  Après zlib: {len(decompressed)} bytes")
            data_to_load = decompressed
        except zlib.error as e:
            print(f"  ❌ Zlib échoué: {e}")
            print("  Tentative de chargement direct...")
            data_to_load = decrypted_bytes
        
        # 6. Marshal loading
        print("  Chargement marshal...")
        code_obj = marshal.loads(data_to_load)
        print("  ✅ Code objet chargé avec succès!")
        
        return code_obj, vars_dict
        
    except Exception as e:
        print(f"❌ Erreur lors du déchiffrement: {e}")
        import traceback
        traceback.print_exc()
        return None, None

def save_decrypted_code(code_obj, vars_dict, output_file="task_decrypted.py"):
    """Sauvegarde le code déchiffré avec decompyle3"""
    
    print(f"\n💾 Sauvegarde dans {output_file}...")
    
    try:
        # Essayer de décompiler avec decompyle3
        source_code = ""
        try:
            import decompyle3
            print("  Décompilation avec decompyle3...")
            
            output = io.StringIO()
            # Utiliser decompyle3 pour décompiler
            from decompyle3.semantics.pysource import code_deparse
            import uncompyle6.version as uv
            
            # Méthode alternative avec decompyle3
            try:
                # Essayer la méthode standard
                from decompyle3 import decompile
                output = io.StringIO()
                decompile(uv.version, code_obj, out=output)
                source_code = output.getvalue()
            except:
                # Méthode de secours
                import dis
                output = io.StringIO()
                dis.dis(code_obj, file=output)
                source_code = f"# Bytecode (Python {sys.version_info.major}.{sys.version_info.minor})\n"
                source_code += "# Utilisez 'python -m dis code_object.bin' pour analyser\n"
                source_code += "'''\n" + output.getvalue() + "\n'''"
                
        except ImportError:
            print("  ❌ decompyle3 non installé, utilisation du bytecode")
            import dis
            output = io.StringIO()
            dis.dis(code_obj, file=output)
            source_code = f"# Bytecode (installez: pip install decompyle3)\n"
            source_code += "# Python version: {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}\n"
            source_code += "'''\n" + output.getvalue() + "\n'''"
        
        # Écrire le fichier de sortie
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("#!/usr/bin/env python3\n")
            f.write('"""\n')
            f.write('Fichier déchiffré automatiquement\n')
            f.write(f'Original: task.py\n')
            f.write(f'Déchiffré le: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
            f.write(f'Python version: {sys.version}\n')
            f.write('"""\n\n')
            
            f.write("#" * 60 + "\n")
            f.write("# VARIABLES ORIGINALES\n")
            f.write("#" * 60 + "\n\n")
            
            # Écrire les variables (limiter aux plus importantes)
            important_vars = ['config_salt', 'payload_data', 'stream5500', 'token7191', 
                             'hash7775', 'key8747', 'm', 'z', 'b', 'd']
            
            for var_name in important_vars:
                if var_name in vars_dict:
                    f.write(f"{var_name} = '{vars_dict[var_name]}'\n")
            
            # Écrire quelques autres variables
            count = 0
            for var_name, var_value in vars_dict.items():
                if var_name not in important_vars and len(var_value) < 50:
                    f.write(f"{var_name} = '{var_value}'\n")
                    count += 1
                    if count > 20:  # Limiter à 20 variables supplémentaires
                        break
            
            f.write("\n" + "#" * 60 + "\n")
            f.write("# CODE DÉCHIFFRÉ\n")
            f.write("#" * 60 + "\n\n")
            f.write(source_code)
        
        print(f"✅ Fichier sauvegardé: {output_file}")
        print(f"📄 Taille: {os.path.getsize(output_file)} bytes")
        
        # Sauvegarder aussi l'objet code brut
        with open('code_object.bin', 'wb') as f:
            marshal.dump(code_obj, f)
        print("✅ Objet code brut sauvegardé: code_object.bin")
        
        return output_file
        
    except Exception as e:
        print(f"❌ Erreur sauvegarde: {e}")
        import traceback
        traceback.print_exc()
        
        # Sauvegarde d'urgence de l'objet code
        try:
            with open('code_object_emergency.bin', 'wb') as f:
                marshal.dump(code_obj, f)
            print("✅ Objet code sauvegardé (urgence): code_object_emergency.bin")
        except:
            pass
        
        return None

def execute_code(code_obj):
    """Exécute le code déchiffré"""
    
    print("\n" + "="*50)
    print("🎮 EXÉCUTION DU CODE DÉCHIFFRÉ")
    print("="*50)
    
    try:
        exec(code_obj)
    except Exception as e:
        print(f"❌ Erreur d'exécution: {e}")
        import traceback
        traceback.print_exc()

def view_bytecode(code_obj):
    """Affiche le bytecode du code déchiffré"""
    
    print("\n" + "="*50)
    print("📄 BYTECODE DU CODE DÉCHIFFRÉ")
    print("="*50)
    
    try:
        import dis
        dis.dis(code_obj)
    except Exception as e:
        print(f"❌ Erreur affichage bytecode: {e}")

def main():
    """Fonction principale"""
    
    print("🔓 DÉCHIFFREUR AUTOMATIQUE POUR task.py (Python 3.12+ compatible)")
    print("=" * 60)
    print(f"Python version: {sys.version}")
    print("=" * 60)
    
    # Vérifier si le fichier existe
    if not os.path.exists("task.py"):
        print("❌ Fichier task.py non trouvé")
        print("   Placez ce script dans le même dossier que task.py")
        return
    
    # 1. Déchiffrer
    result = decrypt_task_py()
    if not result or result[0] is None:
        print("\n❌ Échec du déchiffrement")
        return
    
    code_obj, vars_dict = result
    
    # 2. Afficher info bytecode
    view_bytecode(code_obj)
    
    # 3. Sauvegarder
    saved_file = save_decrypted_code(code_obj, vars_dict, "task_decrypted_fixed.py")
    
    if saved_file:
        print(f"\n📋 Fichiers créés:")
        print(f"   • {saved_file} - Code déchiffré")
        print(f"   • code_object.bin - Objet code brut")
        
        print(f"\n📋 Commandes utiles:")
        print(f"   cat {saved_file} | head -100")
        print(f"   nano {saved_file}")
        print(f"   python -m dis code_object.bin")
    
    # 4. Demander l'exécution
    print("\n" + "-" * 60)
    choice = input("Voulez-vous exécuter le code déchiffré? (o/n): ").strip().lower()
    
    if choice == 'o':
        execute_code(code_obj)
    else:
        print("\n✅ Déchiffrement terminé!")
        print("👋 Au revoir!")

if __name__ == "__main__":
    main()
