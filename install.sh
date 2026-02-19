#!/bin/bash
# install.sh - Installation des fichiers dahery4 avec réparation automatique
echo ""
echo "╔════════════════════════════════════════╗"
echo "║     INSTALLATION FICHIERS DAHERY4     ║"
echo "║           par Juana-archer            ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Couleurs
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
PURPLE='\033[0;95m'
CYAN='\033[0;96m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[ℹ️]${NC} $1"; }
print_success() { echo -e "${GREEN}[✅]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠️]${NC} $1"; }
print_error() { echo -e "${RED}[❌]${NC} $1"; }
print_title() { echo -e "${PURPLE}═══════════════════════════════════════════════${NC}"; }
print_step() { echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# Fonction de réparation système
repair_system() {
    print_info "Vérification du système..."
    
    if [ ! -d "/data/data/com.termux" ]; then
        print_error "Ce script doit être exécuté dans Termux!"
        exit 1
    fi
    
    # Nettoyer les locks
    rm -f /data/data/com.termux/files/usr/var/lib/dpkg/lock* 2>/dev/null || true
    rm -f /data/data/com.termux/files/usr/var/lib/dpkg/lock-frontend* 2>/dev/null || true
    
    # Réparer packages
    yes "" | pkg upgrade -y --fix-broken 2>/dev/null || true
    dpkg --configure -a 2>/dev/null || true
    
    print_success "Système vérifié"
    echo ""
}

# Fonction de nettoyage des fichiers indésirables
cleanup_unwanted_files() {
    print_info "Nettoyage des fichiers indésirables..."
    
    # Liste des fichiers à supprimer
    UNWANTED_FILES=(
        "task1.py"
        "main.py"
    )
    
    local deleted_count=0
    
    for file in "${UNWANTED_FILES[@]}"; do
        if [ -f "$file" ]; then
            # Créer un backup avant suppression (au cas où)
            backup_file "$file"
            rm -f "$file"
            print_warning "Fichier supprimé: $file"
            deleted_count=$((deleted_count + 1))
        fi
    done
    
    if [ $deleted_count -eq 0 ]; then
        print_success "Aucun fichier indésirable trouvé"
    else
        print_info "$deleted_count fichier(s) indésirable(s) supprimé(s)"
    fi
    echo ""
}

# Fonction de backup
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup_name="$file.backup_$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_name"
        print_info "Backup créé: $backup_name"
    fi
}

# Fonction d'installation avec gestion d'erreur
run_install() {
    local description="$1"
    local command="$2"
    local critical="${3:-false}"
    
    print_info "$description"
    
    if eval "$command" 2>/dev/null; then
        print_success "✓"
        return 0
    else
        if [ "$critical" = "true" ]; then
            print_error "❌ ÉCHEC CRITIQUE"
            exit 1
        else
            print_warning "⚠️ Échec (continuation...)"
            return 1
        fi
    fi
    echo ""
}

# DÉBUT DE L'INSTALLATION
repair_system

# NETTOYAGE INITIAL DES FICHIERS INDÉSIRABLES
print_title
print_info "🧹 NETTOYAGE PRÉALABLE"
print_title
echo ""
cleanup_unwanted_files

print_info "Début de l'installation..."
echo ""

# ────────────────────────────────────────────────────────────
# ÉTAPE 1: Mise à jour de Termux
# ────────────────────────────────────────────────────────────
print_title
print_info "📦 ÉTAPE 1: Mise à jour de Termux"
print_title
echo ""

run_install "Mise à jour des dépôts" "pkg update -y" "false"
run_install "Mise à jour des packages" "pkg upgrade -y" "false"
print_success "Termux à jour"
echo ""

# ────────────────────────────────────────────────────────────
# ÉTAPE 2: Installation des dépendances système
# ────────────────────────────────────────────────────────────
print_title
print_info "🔧 ÉTAPE 2: Installation des dépendances système"
print_title
echo ""

# Installation de Git (obligatoire)
print_info "Vérification de Git..."
if ! command -v git >/dev/null 2>&1; then
    run_install "Installation de Git" "pkg install -y git" "true"
else
    print_success "Git déjà installé"
fi
echo ""

# Installation de mpv (lecteur multimédia)
print_info "Installation de mpv..."
if ! command -v mpv >/dev/null 2>&1; then
    run_install "Installation de mpv" "pkg install -y mpv" "false"
else
    print_success "mpv déjà installé"
fi
echo ""

# Packages système essentiels
SYSTEM_PKGS=(
    "python"
    "python-pip"
    "curl"
    "wget"
    "libsodium"
    "clang"
    "libxml2"
    "libxslt"
    "libjpeg-turbo"
    "libpng"
    "openssl"
    "binutils"
)

for pkg in "${SYSTEM_PKGS[@]}"; do
    if ! pkg list-installed 2>/dev/null | grep -q "^$pkg"; then
        run_install "Installation de $pkg" "pkg install -y $pkg" "false"
    else
        print_success "$pkg déjà installé"
    fi
done

export SODIUM_INSTALL=system
print_success "Dépendances système installées"
echo ""

# ────────────────────────────────────────────────────────────
# ÉTAPE 3: Configuration Python et pip
# ────────────────────────────────────────────────────────────
print_title
print_info "🐍 ÉTAPE 3: Configuration de Python"
print_title
echo ""

# Mise à jour de pip et outils de base
run_install "Mise à jour de pip" "python3 -m pip install --upgrade pip" "false"
run_install "Installation de wheel" "python3 -m pip install wheel" "false"
run_install "Installation de setuptools" "python3 -m pip install setuptools --upgrade" "false"
print_success "Python configuré"
echo ""

# ────────────────────────────────────────────────────────────
# ÉTAPE 4: Installation des dépendances Python de BASE
# ────────────────────────────────────────────────────────────
print_title
print_info "📚 ÉTAPE 4: Installation des dépendances Python"
print_title
echo ""

# Packages Python essentiels
PYTHON_BASE=(
    "pynacl"
    "termcolor"
    "pycryptodome"
    "requests"
    "colorama"
    "tqdm"
    "python-dotenv"
)

for package in "${PYTHON_BASE[@]}"; do
    run_install "Installation de $package" "python3 -m pip install $package" "false"
done

print_success "Dépendances Python de base installées"
echo ""

# ────────────────────────────────────────────────────────────
# ÉTAPE 5: Installation des dépendances avancées (GROQ, HTTP, etc)
# ────────────────────────────────────────────────────────────
print_title
print_info "🚀 ÉTAPE 5: Installation des dépendances avancées"
print_title
echo ""

# Nouvelles dépendances (selon votre liste)
ADVANCED_PKGS=(
    "groq"
    "httpx<=0.28.1"
    "httpx-sse"
    "pydantic<2"
    "pillow<=11.3.0"
    "pytesseract"
    "selenium<=4.15.0"
    "undetected-chromedriver"
    "webdriver-manager"
    "beautifulsoup4"
    "mechanize"
    "lxml"
    "cssselect"
    "fake-useragent"
    "cloudscraper"
    "capsolver"
    "twocaptcha-python"
    "2captcha-python"
    "aiohttp"
    "aiofiles"
    "asyncio"
    "nest-asyncio"
    "pyppeteer"
    "playwright"
    "telethon"
)

for package in "${ADVANCED_PKGS[@]}"; do
    run_install "Installation de $package" "python3 -m pip install '$package'" "false"
done

print_success "Dépendances avancées installées"
echo ""

# ────────────────────────────────────────────────────────────
# ÉTAPE 6: Installation de insta-pip-dahe (UNIQUE module GitHub)
# ────────────────────────────────────────────────────────────
print_title
print_info "🛠️  ÉTAPE 6: Installation du module personnalisé"
print_title
echo ""

print_info "Installation de insta-pip-dahe depuis GitHub..."
if command -v git >/dev/null 2>&1; then
    if python3 -m pip install "git+https://github.com/Juana-archer/insta-pip-dahe.git" 2>/dev/null; then
        print_success "insta-pip-dahe ✓"
    else
        print_warning "insta-pip-dahe non installé (tentative alternative)"
        # Tentative avec --no-deps
        python3 -m pip install "git+https://github.com/Juana-archer/insta-pip-dahe.git" --no-deps 2>/dev/null && \
            print_success "insta-pip-dahe ✓ (--no-deps)" || \
            print_warning "insta-pip-dahe toujours échoué"
    fi
else
    print_error "Git non disponible - insta-pip-dahe ne peut pas être installé"
fi
echo ""

# ────────────────────────────────────────────────────────────
# ÉTAPE 7: Téléchargement des fichiers (DEUX DÉPÔTS DISTINCTS)
# ────────────────────────────────────────────────────────────
print_title
print_info "📥 ÉTAPE 7: Téléchargement des fichiers"
print_title
echo ""

GITHUB_USER="Juana-archer"
success_count=0
total_files=5  # maj.py, post.py, r.py, task.py, n

# ============================================================
# SOURCE 1: dahery4-files POUR maj.py, post.py, r.py
# ============================================================
REPO_MAIN="dahery4-files"
BASE_URL_MAIN="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_MAIN/master"

# Fichiers depuis dahery4-files
FILES_MAIN=(
    "maj.py"
    "post.py"
    "r.py"
)

print_step
print_info "📁 Dépôt 1/2: $REPO_MAIN"
print_step
echo ""

for file in "${FILES_MAIN[@]}"; do
    print_info "Téléchargement: $file"
    
    # Backup si existe
    [ -f "$file" ] && backup_file "$file"
    
    # Tentative master d'abord
    if curl -s -L -o "$file" "$BASE_URL_MAIN/$file" 2>/dev/null; then
        chmod +x "$file" 2>/dev/null || true
        print_success "$file ✓ (master)"
        success_count=$((success_count + 1))
    else
        # Tentative main
        ALT_URL="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_MAIN/main/$file"
        if curl -s -L -o "$file" "$ALT_URL" 2>/dev/null; then
            chmod +x "$file" 2>/dev/null || true
            print_success "$file ✓ (main)"
            success_count=$((success_count + 1))
        else
            print_error "$file ✗ - Échec"
        fi
    fi
done

# ============================================================
# SOURCE 2: mise_vaovao POUR task.py ET n
# ============================================================
REPO_MISE="mise_vaovao"
BRANCH="main"
BASE_URL_MISE="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_MISE/$BRANCH"

# Fichiers depuis mise_vaovao
FILES_MISE=(
    "task.py"
    "n"
)

echo ""
print_step
print_info "📁 Dépôt 2/2: $REPO_MISE (branche: $BRANCH)"
print_step
echo ""

for file in "${FILES_MISE[@]}"; do
    print_info "Téléchargement: $file"
    
    # Backup si existe
    [ -f "$file" ] && backup_file "$file"
    
    FILE_URL="$BASE_URL_MISE/$file"
    if curl -s -L -o "$file" "$FILE_URL" 2>/dev/null; then
        chmod +x "$file" 2>/dev/null || true
        print_success "$file ✓"
        success_count=$((success_count + 1))
    else
        print_error "$file ✗ - Échec"
    fi
done
echo ""

# ────────────────────────────────────────────────────────────
# ÉTAPE 8: NETTOYAGE POST-TÉLÉCHARGEMENT
# ────────────────────────────────────────────────────────────
print_title
print_info "🧹 NETTOYAGE FINAL"
print_title
echo ""
cleanup_unwanted_files

# ────────────────────────────────────────────────────────────
# ÉTAPE 9: Création des utilitaires
# ────────────────────────────────────────────────────────────
print_title
print_info "⚙️  ÉTAPE 9: Configuration et utilitaires"
print_title
echo ""

# Script de lancement amélioré
cat > launch.sh << 'LAUNCH'
#!/usr/bin/env bash
clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║           🔥 DAHERY4 - TASK MANAGER LAUNCHER 🔥            ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "📁 FICHIERS INSTALLÉS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for file in maj.py post.py r.py task.py n; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        lines=$(wc -l < "$file" 2>/dev/null || echo "0")
        printf "  • %-15s (%s, %s lignes)\n" "$file" "$size" "$lines"
    fi
done

# Vérifier qu'il n'y a pas de fichiers indésirables
echo ""
echo "🧹 VÉRIFICATION DES FICHIERS INDÉSIRABLES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for unwanted in task1.py main.py; do
    if [ -f "$unwanted" ]; then
        echo "  ⚠️  $unwanted présent (devrait être supprimé)"
    else
        echo "  ✅ $unwanted absent"
    fi
done

echo ""
echo "🚀 COMMANDES DISPONIBLES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  python3 maj.py      → Mise à jour"
echo "  python3 post.py     → Publication"
echo "  python3 r.py        → Récupération"
echo "  python3 task.py     → Tâche principale"
echo "  ./n                 → Exécuter le script n"
echo "  mpv [fichier]       → Lire un fichier multimédia"
echo ""
echo "📦 DÉPENDANCES: $(pip3 list 2>/dev/null | wc -l) packages installés"
echo ""
echo "🔗 DÉPÔTS SOURCES:"
echo "  • https://github.com/Juana-archer/dahery4-files"
echo "  • https://github.com/Juana-archer/mise_vaovao"
echo ""
LAUNCH

chmod +x launch.sh
print_success "launch.sh créé"

# Script de vérification complet
cat > check_installation.py << 'CHECK'
#!/usr/bin/env python3
import sys
import importlib
from pathlib import Path

# Liste des packages à vérifier
PACKAGES = [
    "pynacl", "termcolor", "Crypto", "requests", "colorama",
    "groq", "httpx", "pydantic", "PIL", "selenium",
    "bs4", "mechanize", "telethon", "dotenv", "tqdm",
    "aiohttp", "asyncio", "cloudscraper", "twocaptcha"
]

# Fichiers à vérifier
FILES = ["maj.py", "post.py", "r.py", "task.py", "n"]

# Fichiers indésirables à signaler
UNWANTED_FILES = ["task1.py", "main.py"]

def check_color(text, status, is_ok=True):
    if is_ok:
        return f"\033[92m✅ {text:<25} {status}\033[0m"
    else:
        return f"\033[91m❌ {text:<25} {status}\033[0m"

print("\033[95m" + "=" * 60 + "\033[0m")
print("\033[1;96m🔍 VÉRIFICATION COMPLÈTE DE L'INSTALLATION DAHERY4\033[0m")
print("\033[95m" + "=" * 60 + "\033[0m")
print()

# Vérification des packages
print("\033[1;93m📦 PACKAGES PYTHON:\033[0m")
print("-" * 60)

for package in PACKAGES:
    try:
        if package == "bs4":
            module = "bs4"
        elif package == "Crypto":
            module = "Crypto"
        elif package == "PIL":
            module = "PIL"
        else:
            module = package
            
        importlib.import_module(module)
        
        # Tentative d'obtenir la version
        try:
            version = importlib.metadata.version(module)
        except:
            version = "✓"
            
        print(check_color(package, version, True))
    except ImportError:
        print(check_color(package, "NON INSTALLÉ", False))

print()
print("\033[1;93m📁 FICHIERS:\033[0m")
print("-" * 60)

for file in FILES:
    if Path(file).exists():
        size = Path(file).stat().st_size
        lines = len(open(file).readlines())
        print(check_color(file, f"{size} octets, {lines} lignes", True))
    else:
        print(check_color(file, "ABSENT", False))

print()
print("\033[1;93m🧹 VÉRIFICATION FICHIERS INDÉSIRABLES:\033[0m")
print("-" * 60)

unwanted_found = False
for file in UNWANTED_FILES:
    if Path(file).exists():
        print(check_color(file, "PRÉSENT (devrait être supprimé)", False))
        unwanted_found = True
    else:
        print(check_color(file, "absent", True))

print()
print("\033[95m" + "=" * 60 + "\033[0m")

# Résumé
success_packages = 0
for package in PACKAGES:
    try:
        if package == "bs4":
            import bs4
        elif package == "Crypto":
            from Crypto import Cipher
        else:
            importlib.import_module(package)
        success_packages += 1
    except:
        pass

success_files = sum(1 for f in FILES if Path(f).exists())

print(f"\n📊 RÉSUMÉ: {success_packages}/{len(PACKAGES)} packages, {success_files}/{len(FILES)} fichiers")
if unwanted_found:
    print("\033[93m⚠️  Des fichiers indésirables sont présents\033[0m")
print("\033[92m✅ Installation terminée !\033[0m" if success_files == len(FILES) else "\033[93m⚠️ Installation partielle\033[0m")
print()
CHECK

chmod +x check_installation.py
print_success "check_installation.py créé"

# Vérification de l'installation de mpv
echo ""
print_info "🔊 Vérification de mpv..."
if command -v mpv >/dev/null 2>&1; then
    print_success "mpv est installé et prêt à l'emploi"
    mpv_version=$(mpv --version | head -n1)
    echo "   Version: $mpv_version"
else
    print_warning "mpv n'est pas installé correctement"
fi
echo ""

# Nettoyage des fichiers temporaires
echo ""
print_info "🧹 Nettoyage des fichiers temporaires..."
rm -f user_id.txt 2>/dev/null || true
rm -f session.txt 2>/dev/null || true
rm -f cookies.pkl 2>/dev/null || true
rm -f *.log 2>/dev/null || true
print_success "Nettoyage effectué"
echo ""

# ────────────────────────────────────────────────────────────
# RÉSUMÉ FINAL
# ────────────────────────────────────────────────────────────
print_title
print_info "🎯 RÉSUMÉ DE L'INSTALLATION"
print_title
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║           ✅ INSTALLATION TERMINÉE AVEC SUCCÈS             ║"
echo "║                                                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  📦 SYSTÈME:                                                ║"
echo "║    • Termux mis à jour                                      ║"
echo "║    • Git et dépendances système                            ║"
echo "║    • Python + pip configurés                               ║"
echo "║    • mpv installé (lecteur multimédia)                     ║"
echo "║                                                              ║"
echo "║  📚 PACKAGES INSTALLÉS:                                     ║"
echo "║    • Base: pynacl, termcolor, pycryptodome, requests       ║"
echo "║    • Avancé: groq, httpx, pydantic v1, selenium            ║"
echo "║    • Web: beautifulsoup4, mechanize, cloudscraper          ║"
echo "║    • Image: pillow, pytesseract                            ║"
echo "║    • Captcha: 2captcha, twocaptcha, capsolver              ║"
echo "║    • Async: aiohttp, asyncio, playwright                   ║"
echo "║                                                              ║"
echo "║  🛠️  MODULE PERSO:                                          ║"
echo "║    • insta-pip-dahe (GitHub)                               ║"
echo "║                                                              ║"
echo "║  📁 FICHIERS: $success_count/$total_files téléchargés        ║"
echo "║    • Depuis dahery4-files: maj.py, post.py, r.py           ║"
echo "║    • Depuis mise_vaovao: task.py, n                        ║"
echo "║                                                              ║"
echo "║  🧹 NETTOYAGE:                                              ║"
echo "║    • Suppression automatique: task1.py, main.py            ║"
echo "║    • Fichiers temporaires nettoyés                         ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

print_success "🎉 INSTALLATION RÉUSSIE !"
echo ""

print_info "🚀 COMMANDES RAPIDES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  python3 task.py      → Lancer le programme principal"
echo "  ./n                  → Exécuter le script n"
echo "  ./launch.sh          → Afficher le launcher"
echo "  python3 check_installation.py → Vérifier l'installation"
echo "  mpv [fichier]        → Lire un fichier multimédia"
echo ""

print_info "📊 STATUT:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 Packages installés: $(pip3 list 2>/dev/null | wc -l)"
echo "  📁 Fichiers présents: $success_count/$total_files"
echo ""

if [ $success_count -eq $total_files ]; then
    print_success "Tous les fichiers sont présents !"
else
    print_warning "$((total_files - success_count)) fichier(s) manquant(s)"
fi
echo ""

print_info "🔧 DÉPANNAGE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  • Réinstaller: rm -f *.py n && ./install.sh"
echo "  • Réparer pip: pkg install python-pip --reinstall"
echo "  • Vérifier mpv: mpv --version"
echo "  • Voir les logs: tail -20 ~/.cache/pip/log/*"
echo ""

echo -e "${GREEN}✨ Script terminé. Bonne utilisation !${NC}"
echo ""
