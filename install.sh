#!/bin/bash
# install.sh - Installation des fichiers dahery4
echo ""
echo "╔════════════════════════════════════════╗"
echo "║     INSTALLATION FICHIERS DAHERY4     ║"
echo "║           par Juana-archer            ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Vérifier Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ Ce script doit être exécuté dans Termux!"
    exit 1
fi

echo "🔄 Début de l'installation..."
echo ""

# Mise à jour Termux
echo "📦 ÉTAPE 1: Mise à jour de Termux..."
pkg update -y && pkg upgrade -y
echo "✅ Termux mis à jour"
echo ""

# Dépendances système
echo "📦 ÉTAPE 2: Installation des dépendances..."
pkg install -y python git curl libsodium -y
export SODIUM_INSTALL=system
echo "✅ Dépendances installées"
echo ""

# Packages Python
echo "🐍 ÉTAPE 3: Installation packages Python..."
pip install --upgrade pip
pip install pynacl termcolor pycryptodome requests
pip install git+https://github.com/Juana-archer/install_tool.git
echo "✅ Packages Python installés"
echo ""

# Téléchargement des fichiers
echo "📥 ÉTAPE 4: Téléchargement des fichiers..."
GITHUB_USER="Juana-archer"
GITHUB_REPO="dahery4-files"  # CORRECT !
BASE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/master"

# Liste CORRECTE des fichiers
FILES_TO_DOWNLOAD=(
    "maj.py"
    "post.py"
    "r.py"
    "task.py"
    "task1.py"
)

# Dossier d'installation
INSTALL_DIR="$HOME/dahery4-tools"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Télécharger chaque fichier
for file in "${FILES_TO_DOWNLOAD[@]}"; do
    echo "⬇️  Téléchargement: $file"
    if curl -s -o "$file" "$BASE_URL/$file"; then
        chmod +x "$file"
        echo "   ✅ $file"
    else
        echo "   ❌ $file (erreur)"
    fi
done
echo ""

# Créer script de lancement
cat > launch.sh << 'LAUNCH'
#!/bin/bash
echo "🚀 Fichiers dahery4"
echo "=================="
echo ""
echo "📁 Fichiers disponibles:"
ls *.py 2>/dev/null | cat -n
echo ""
echo "💻 Usage: python3 [fichier].py"
echo "🔗 GitHub: https://github.com/Juana-archer/dahery4-files"
LAUNCH
chmod +x launch.sh

# Résumé
echo "✅ INSTALLATION TERMINÉE !"
echo ""
echo "📁 Dossier: $INSTALL_DIR"
echo "🚀 Pour lancer: cd $INSTALL_DIR && ./launch.sh"
echo "🔗 GitHub: https://github.com/Juana-archer/dahery4-files"
echo ""
echo "📞 Commandes utiles:"
echo "   python3 maj.py"
echo "   python3 task.py"
echo "   python3 post.py"
echo "   python3 r.py"
echo "   python3 task1.py"
