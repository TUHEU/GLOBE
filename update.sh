#!/usr/bin/env bash
# ============================================================
# update.sh — Met à jour le SITE (vitrine + téléchargements)
# GlobeTrotter Yaoundé — servi par Nginx sur le VPS
#
# Usage :
#   ./update.sh              -> met à jour depuis le dépôt git (si présent)
#   ./update.sh /chemin/dir  -> met à jour depuis un dossier (scp manuel)
#
# NE TOUCHE JAMAIS à app/ ni downloads/ — ces dossiers contiennent
# les gros fichiers binaires (build Flutter Web, APK, zip Windows)
# qui ne sont pas censés être écrasés à chaque mise à jour du texte
# de la page d'accueil.
# ============================================================
set -euo pipefail

# ---------- Configuration (ajuste si besoin) ----------
SITE_DIR="/var/www/GLOBE"
BACKUP_DIR="/var/www/GLOBE_backups"
KEEP_BACKUPS=10
HEALTH_URL="https://fahglobe.duckdns.org/"
NGINX_SERVICE="nginx"

# Dossiers/fichiers à NE JAMAIS écraser lors d'une mise à jour du site
PROTECTED=("app" "downloads")

# ---------- Couleurs ----------
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

[ -d "$SITE_DIR" ] || fail "Dossier introuvable : $SITE_DIR"
cd "$SITE_DIR"
echo "=== Mise à jour du site GlobeTrotter Yaoundé — $(date '+%Y-%m-%d %H:%M:%S') ==="

# ---------- 1. Sauvegarde des fichiers du site (hors app/ et downloads/) ----------
mkdir -p "$BACKUP_DIR"
STAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_PATH="$BACKUP_DIR/site_$STAMP.tar.gz"

EXCLUDES=()
for d in "${PROTECTED[@]}"; do
  EXCLUDES+=(--exclude="./$d")
done

tar -czf "$BACKUP_PATH" "${EXCLUDES[@]}" -C "$SITE_DIR" .
info "Site sauvegardé → $BACKUP_PATH"

# Ne garder que les KEEP_BACKUPS sauvegardes les plus récentes
ls -1t "$BACKUP_DIR"/site_*.tar.gz 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm --

# ---------- 2. Récupérer les nouveaux fichiers ----------
SOURCE_DIR="${1:-}"

if [ -n "$SOURCE_DIR" ]; then
  # ----- Mode "dossier fourni en argument" (après un scp manuel) -----
  [ -d "$SOURCE_DIR" ] || fail "Dossier source introuvable : $SOURCE_DIR"
  info "Copie depuis $SOURCE_DIR (app/ et downloads/ ignorés)..."

  RSYNC_EXCLUDES=()
  for d in "${PROTECTED[@]}"; do
    RSYNC_EXCLUDES+=(--exclude="$d")
  done

  rsync -av --delete "${RSYNC_EXCLUDES[@]}" "$SOURCE_DIR"/ "$SITE_DIR"/

elif [ -d "$SITE_DIR/.git" ]; then
  # ----- Mode git (si le site est versionné) -----
  info "Dépôt git détecté — récupération des changements..."
  git pull
else
  warn "Pas de dépôt git et aucun dossier source fourni."
  warn "Usage : ./update.sh /chemin/vers/nouveau/site"
  warn "        (envoie d'abord les nouveaux fichiers avec scp, puis relance)"
  fail "Rien à mettre à jour."
fi

# ---------- 3. Permissions ----------
info "Permissions..."
chown -R www-data:www-data "$SITE_DIR"
chmod -R 755 "$SITE_DIR"

# ---------- 4. Vérifier la config Nginx puis recharger ----------
info "Vérification de la config Nginx..."
nginx -t || fail "Config Nginx invalide ! Le site n'a pas été rechargé."

info "Rechargement de Nginx..."
systemctl reload "$NGINX_SERVICE"

# ---------- 5. Vérification de santé ----------
sleep 1
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
  info "Site accessible ($HEALTH_URL → 200)"
else
  warn "Le site répond avec le code $HTTP_CODE (attendu: 200)"
  warn "Vérifie : curl -I $HEALTH_URL"
fi

# Rappels sur les dossiers protégés (juste informatif)
echo ""
if [ -d "$SITE_DIR/app/assets" ] || [ -f "$SITE_DIR/app/index.html" ]; then
  info "app/ (build Flutter Web) présent — inchangé par cette mise à jour"
else
  warn "app/ semble vide — pense à y déposer 'flutter build web --release --base-href /app/'"
fi

if [ -n "$(ls -A "$SITE_DIR/downloads" 2>/dev/null | grep -v LISEZMOI)" ]; then
  info "downloads/ (APK / Windows) présent — inchangé par cette mise à jour"
else
  warn "downloads/ semble vide — pense à y déposer l'APK et le zip Windows"
fi

echo ""
echo "=== Mise à jour du site terminée ✅ ==="
echo "Sauvegarde disponible : $BACKUP_PATH"
