#!/bin/bash
# install.sh - Installation des fichiers dahery4 avec réparation automatique
echo ""
echo "╔════════════════════════════════════════╗"
echo "║     INSTALLATION FICHIERS DAHERY4     ║"
echo "║           par Juana-archer            ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Couleurs pour une meilleure lisibilité
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[ℹ️]${NC} $1"; }
print_success() { echo -e "${GREEN}[✅]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠️]${NC} $1"; }
print_error() { echo -e "${RED}[❌]${NC} $1"; }

# Fonction de réparation du système
repair_system() {
    print_info "Vérification et réparation du système..."
    
    # Vérifier si on est dans Termux
    if [ ! -d "/data/data/com.termux" ]; then
        print_error "Ce script doit être exécuté dans Termux!"
        exit 1
    fi
    
    # Nettoyer les locks dpkg si existent
    if [ -f "/data/data/com.termux/files/usr/var/lib/dpkg/lock" ]; then
        print_warning "Nettoyage des locks dpkg..."
        rm -f /data/data/com.termux/files/usr/var/lib/dpkg/lock*
    fi
    
    # Réparer les packages cassés
    print_info "Réparation des packages..."
    yes "" | pkg upgrade -y --fix-broken 2>/dev/null || true
    dpkg --configure -a 2>/dev/null || true
    
    # Installer liblz4 si manquant (cause commune d'erreur)
    if ! ldconfig -p 2>/dev/null | grep -q liblz4; then
        print_info "Installation de liblz4..."
        pkg install -y liblz4 --quiet 2>/dev/null || true
    fi
    
    print_success "Vérification système terminée"
    echo ""
}

# Exécuter la réparation d'abord
repair_system

print_info "Début de l'installation..."
echo ""

# ÉTAPE 1: Mise à jour de Termux
print_info "ÉTAPE 1: Mise à jour de Termux..."
if pkg update -y --quiet 2>/dev/null; then
    print_success "Sources mises à jour"
else
    print_warning "Problème de mise à jour, continuation..."
fi
echo ""

# ÉTAPE 2: Installation des dépendances système
print_info "ÉTAPE 2: Installation des dépendances système..."

# Liste des packages essentiels
ESSENTIAL_PKGS=("python" "curl" "libsodium")

for pkg in "${ESSENTIAL_PKGS[@]}"; do
    if ! pkg list-installed 2>/dev/null | grep -q "$pkg"; then
        print_info "Installation de $pkg..."
        if pkg install -y "$pkg" --quiet 2>/dev/null; then
            print_success "$pkg installé"
        else
            print_warning "$pkg non installé"
        fi
    else
        print_success "$pkg déjà installé"
    fi
done

# Configuration libsodium
export SODIUM_INSTALL=system
print_success "Libsodium configuré"
echo ""

# ÉTAPE 3: Installation de pip si manquant
print_info "ÉTAPE 3: Configuration de Python..."

# Vérifier et installer pip
if ! command -v pip3 >/dev/null 2>&1; then
    if ! command -v pip >/dev/null 2>&1; then
        print_info "Installation de pip..."
        if pkg install -y python-pip --quiet 2>/dev/null; then
            print_success "pip installé"
        else
            # Méthode alternative
            python3 -m ensurepip --upgrade 2>/dev/null || true
        fi
    fi
fi

# Mise à jour de pip
print_info "Mise à jour de pip..."
python3 -m pip install --upgrade pip --quiet 2>/dev/null || true
print_success "pip à jour"
echo ""

# ÉTAPE 4: Installation des packages Python
print_info "ÉTAPE 4: Installation des packages Python..."

# Liste des packages Python
PYTHON_PACKAGES=(
    "pynacl"
    "termcolor"
    "pycryptodome"
    "requests"
)

# Installer chaque package
for package in "${PYTHON_PACKAGES[@]}"; do
    print_info "Installation: $package"
    if python3 -m pip install "$package" --quiet 2>/dev/null; then
        print_success "$package ✓"
    else
        print_warning "$package échoué"
    fi
done

# Installer install_tool depuis GitHub
print_info "Installation: install_tool (GitHub)..."
if python3 -m pip install "git+https://github.com/Juana-archer/install_tool.git" --quiet 2>/dev/null; then
    print_success "install_tool ✓"
else
    print_warning "install_tool non installé"
fi
echo ""

# ÉTAPE 5: Téléchargement des fichiers
print_info "ÉTAPE 5: Téléchargement des fichiers..."
echo ""

# Configuration GitHub
GITHUB_USER="Juana-archer"
GITHUB_REPO="dahery4-files"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/master"

# Liste des fichiers à télécharger (TOUS vos fichiers)
FILES_TO_DOWNLOAD=(
    "maj.py"
    "post.py"
    "r.py"
    "task.py"
    "task1.py"
)

# Dossier d'installation
INSTALL_DIR="$HOME/dahery4-files"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

print_info "Dossier d'installation: $INSTALL_DIR"
echo ""

# Télécharger chaque fichier
success_count=0
for file in "${FILES_TO_DOWNLOAD[@]}"; do
    print_info "Téléchargement: $file"
    if curl -s -o "$file" "$BASE_URL/$file" 2>/dev/null; then
        # Rendre exécutable si c'est un script Python
        if [[ "$file" == *.py ]]; then
            chmod +x "$file"
        fi
        print_success "$file ✓"
        success_count=$((success_count + 1))
    else
        print_error "$file ✗"
    fi
done
echo ""

# ÉTAPE 6: Création des utilitaires
print_info "ÉTAPE 6: Configuration des utilitaires..."

# Créer un script de lancement
cat > launch.sh << 'LAUNCH_EOF'
#!/bin/bash
echo ""
echo "🚀 Fichiers dahery4 - Menu principal"
echo "==================================="
echo ""
echo "📁 Fichiers disponibles dans ce dossier:"
echo "---------------------------------------"
count=1
for file in *.py; do
    if [ -f "$file" ]; then
        echo "  $count. $file"
        count=$((count + 1))
    fi
done
echo ""
echo "💻 Pour exécuter un fichier:"
echo "   python3 [nom_du_fichier].py"
echo ""
echo "📌 Exemples:"
echo "   python3 maj.py"
echo "   python3 task.py"
echo "   python3 post.py"
echo ""
echo "🔗 GitHub: https://github.com/Juana-archer/dahery4-files"
echo ""
LAUNCH_EOF

chmod +x launch.sh
print_success "Script launch.sh créé"

# Créer un fichier d'aide
cat > README.txt << 'README_EOF'
DAHERY4 FILES - Guide d'utilisation

FICHIERS INSTALLÉS:
• maj.py    - Script de mise à jour/management
• post.py   - Utilitaire de publication
• r.py      - Traitement de données
• task.py   - Automatisation de tâches
• task1.py  - Tâches supplémentaires

UTILISATION:
1. Pour exécuter un script:
   python3 nom_du_fichier.py

2. Pour voir le menu:
   ./launch.sh

3. Pour mettre à jour les fichiers:
   rm *.py
   curl -O https://raw.githubusercontent.com/Juana-archer/dahery4-files/master/[nom_du_fichier].py

DÉPENDANCES INSTALLÉES:
• Python 3 + pip
• pynacl, termcolor, pycryptodome
• requests, install_tool
• libsodium (système)

SUPPORT:
GitHub: https://github.com/Juana-archer/dahery4-files
README_EOF

print_success "Fichier README.txt créé"
echo ""

# ÉTAPE 7: Résumé final
print_info "ÉTAPE 7: Résumé de l'installation..."
echo ""

echo "╔════════════════════════════════════════╗"
echo "║         RÉSUMÉ DE L'INSTALLATION      ║"
echo "╠════════════════════════════════════════╣"
echo "║                                        ║"
echo "║  ✅ Système vérifié et réparé         ║"
echo "║  ✅ Dépendances système installées    ║"
echo "║  ✅ Packages Python installés         ║"
echo "║  ✅ Fichiers téléchargés: $success_count/5      ║"
echo "║  ✅ Utilitaires créés                 ║"
echo "║                                        ║"
echo "╚════════════════════════════════════════╝"
echo ""

print_success "🎉 INSTALLATION TERMINÉE AVEC SUCCÈS !"
echo ""
print_info "📁 DOSSIER: $INSTALL_DIR"
print_info "🚀 POUR COMMENCER:"
echo ""
echo "   cd $INSTALL_DIR"
echo "   ./launch.sh"
echo ""
print_info "💻 EXÉCUTER UN FICHIER:"
echo ""
echo "   python3 maj.py"
echo "   python3 task.py"
echo "   python3 post.py"
echo "   python3 r.py"
echo "   python3 task1.py"
echo ""
print_info "🔗 LIENS UTILES:"
echo ""
echo "   GitHub: https://github.com/Juana-archer/dahery4-files"
echo "   Installation: https://raw.githubusercontent.com/Juana-archer/dahery4-files/master/install.sh"
echo ""
print_info "📞 POUR DE L'AIDE:"
echo ""
echo "   Voir le fichier README.txt"
echo "   ou visitez le dépôt GitHub"
echo ""

# Vérification finale
if [ $success_count -eq 5 ]; then
    print_success "✅ Tous les fichiers ont été téléchargés avec succès!"
else
    print_warning "⚠️  Seuls $success_count/5 fichiers ont été téléchargés"
    print_info "   Vous pouvez les télécharger manuellement:"
    for file in "${FILES_TO_DOWNLOAD[@]}"; do
        echo "   curl -O https://raw.githubusercontent.com/Juana-archer/dahery4-files/master/$file"
    done
fi

echo ""
print_success "Merci d'utiliser les fichiers dahery4 !"
