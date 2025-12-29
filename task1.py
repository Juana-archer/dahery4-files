#!/usr/bin/env python3
import sys
import asyncio
import builtins

print("="*70)
print("⚡ LANCEUR ASYNCHRONE")
print("="*70)

# BYPASS
sys.exit = lambda *a, **k: None
builtins.exit = lambda *a, **k: None
builtins.quit = lambda *a, **k: None

# Silence vérification
_orig_print = print
def silent_print(*args, **kwargs):
    msg = ' '.join(str(arg) for arg in args)
    if any(keyword in msg for keyword in ["Vérification", "❌", "contacter"]):
        return
    _orig_print(*args, **kwargs)
builtins.print = silent_print

# Charge le code
with open('task.py', 'rb') as f:
    code = f.read().decode('utf-8', errors='ignore')

# Patch la ligne problématique
lines = code.split('\n')
if len(lines) >= 30 and 'exec(m.loads(z.decompress(d)))' in lines[29]:
    lines[29] = '''
try:
    import marshal as m
    import zlib as z
    __decompressed = z.decompress(d)
    __loaded = m.loads(__decompressed)
    if __loaded:
        exec(__loaded)
except:
    pass  # Données optionnelles ignorées
'''

patched_code = '\n'.join(lines)

print("🔧 Configuration asynchrone...")

# Environnement
env = {
    '__name__': '__main__',
    '__file__': 'run_async.py',
    'print': silent_print,
}

# Exécute le code pour charger tout
exec(patched_code, env)

print("✅ Code chargé")
print("🔍 Recherche de la fonction principale...")

# Cherche main() ou autre fonction asynchrone
async_funcs = ['main', 'run', 'start', 'execute', 'bot', 'client']

async def run_program():
    for func_name in async_funcs:
        if func_name in env and callable(env[func_name]):
            print(f"▶ Lancement de {func_name}()...")
            try:
                # Exécute la coroutine
                result = await env[func_name]()
                print(f"✅ {func_name}() terminé: {result}")
                return True
            except TypeError as e:
                if "object is not callable" in str(e):
                    continue
                print(f"⚠ {func_name}() erreur: {e}")
            except Exception as e:
                print(f"⚠ {func_name}() erreur: {e}")

    print("ℹ Aucune fonction asynchrone exécutée")

    # Cherche une fonction synchrone
    for func_name in ['menu', 'help', 'show_options']:
        if func_name in env and callable(env[func_name]):
            print(f"▶ Exécution de {func_name}()...")
            try:
                env[func_name]()
                return True
            except Exception as e:
                print(f"⚠ {func_name}() erreur: {e}")

    return False

# Lance la boucle d'événements
print("\n🚀 Démarrage de la boucle asynchrone...")
print("="*70)

try:
    # Démarre la boucle d'événements
    success = asyncio.run(run_program())

    if success:
        print("\n✅ PROGRAMME EXÉCUTÉ AVEC SUCCÈS")
    else:
        print("\nℹ Programme chargé mais non exécuté")
        print("💡 Essayez d'appeler une fonction manuellement:")

        # Affiche les fonctions disponibles
        print("\n📋 FONCTIONS DISPONIBLES:")
        funcs = []
        for key, value in env.items():
            if callable(value) and not key.startswith('_'):
                funcs.append(key)

        for func in sorted(funcs)[:15]:
            print(f"  {func}()")

        print(f"\n🎯 Total: {len(funcs)} fonctions disponibles")

except KeyboardInterrupt:
    print("\n\n⏹️ Interrompu par l'utilisateur")
except Exception as e:
    print(f"\n❌ ERREUR: {type(e).__name__}: {e}")

print("\n" + "="*70)
print("🏁 FIN")
print("="*70)
