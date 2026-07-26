#!/usr/bin/env bash
# ============================================================
# restore.sh — Restaure une sauvegarde du site (hors app/ downloads/)
# Usage :
#   ./restore.sh              -> liste les sauvegardes disponibles
#   ./restore.sh <fichier>    -> restaure la sauvegarde choisie
# ============================================================
set -euo pipefail

SITE_DIR="/var/www/GLOBE"
BACKUP_DIR="/var/www/GLOBE_backups"
NGINX_SERVICE="nginx"

if [ -z "${1:-}" ]; then
  echo "Sauvegardes disponibles dans $BACKUP_DIR :"
  echo ""
  ls -1t "$BACKUP_DIR"/site_*.tar.gz 2>/dev/null || echo "(aucune sauvegarde trouvée)"
  echo ""
  echo "Usage : ./restore.sh $BACKUP_DIR/site_XXXXXXXX_XXXXXX.tar.gz"
  exit 0
fi

BACKUP_FILE="$1"
[ -f "$BACKUP_FILE" ] || { echo "[ERREUR] Fichier introuvable : $BACKUP_FILE"; exit 1; }

echo "⚠️  Ceci va restaurer les fichiers du site (app/ et downloads/ ne sont pas touchés)."
read -p "Continuer ? (o/N) " CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
  echo "Annulé."
  exit 0
fi

# Sauvegarde de sécurité de l'état actuel avant restauration
SAFETY=$(date '+%Y%m%d_%H%M%S')
tar -czf "$BACKUP_DIR/site_before_restore_$SAFETY.tar.gz" \
  --exclude="./app" --exclude="./downloads" -C "$SITE_DIR" .
echo "[OK] État actuel sauvegardé (site_before_restore_$SAFETY.tar.gz)"

tar -xzf "$BACKUP_FILE" -C "$SITE_DIR"
echo "[OK] Site restauré depuis $BACKUP_FILE"

chown -R www-data:www-data "$SITE_DIR"
chmod -R 755 "$SITE_DIR"

nginx -t && systemctl reload "$NGINX_SERVICE"
echo "[OK] Nginx rechargé"
