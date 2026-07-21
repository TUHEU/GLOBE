# GlobeTrotter Yaoundé — Site de téléchargement + App Web
Déployé sur : https://fahglobe.duckdns.org (VPS Ubuntu + Nginx + Let's Encrypt)

## Structure
```
website/
  index.html        <- la page d'accueil / téléchargement (ce site)
  app/               <- COLLE ICI le contenu de "flutter build web"
  downloads/         <- COLLE ICI l'APK et le zip Windows
```

## Sur le VPS, ce dossier vit dans :
```
/var/www/GLOBE/
```
Nginx sert `/` en statique depuis là, proxifie `/register`, `/login`, `/destinations`,
`/recommendations`, `/itineraries`, `/docs` etc. vers le backend FastAPI (port 4200).

## Préparer les fichiers (sur ton PC Windows)

### 1. App Web — attention au --base-href
```bash
flutter build web --release --base-href /app/
```
⚠️ Sans `--base-href /app/`, l'app affichera une page blanche une fois déployée
dans le sous-dossier /app/ (les chemins des assets seraient faux).

Envoie sur le VPS :
```bash
scp -r build\web\* root@TON_IP_VPS:/var/www/GLOBE/app/
```

### 2. APK Android
```bash
flutter build apk --release
```
Renomme `build\app\outputs\flutter-apk\app-release.apk`
en `globetrotter-yaounde.apk`, puis :
```bash
scp build\app\outputs\flutter-apk\globetrotter-yaounde.apk root@TON_IP_VPS:/var/www/GLOBE/downloads/
```

### 3. Windows Desktop
```bash
flutter build windows --release
```
Zippe TOUT le dossier `build\windows\x64\runner\Release\`
en `globetrotter-yaounde-windows.zip`, puis :
```bash
scp globetrotter-yaounde-windows.zip root@TON_IP_VPS:/var/www/GLOBE/downloads/
```

## Après chaque envoi, sur le VPS
```bash
chown -R www-data:www-data /var/www/GLOBE
chmod -R 755 /var/www/GLOBE
```

## Vérifications
```bash
curl -I https://fahglobe.duckdns.org/                                    # 200 -> vitrine OK
curl -I https://fahglobe.duckdns.org/app/                                # 200 -> app web OK
curl https://fahglobe.duckdns.org/destinations                           # JSON -> API OK
curl -I https://fahglobe.duckdns.org/downloads/globetrotter-yaounde.apk  # 200 -> APK dispo
curl -I https://fahglobe.duckdns.org/docs                                # 200 -> Swagger OK
```

## À personnaliser dans index.html
- Le lien du Google Form : cherche "REMPLACE #" dans la section communauté
- Le lien WhatsApp est déjà le tien

## Rappel Phase 1
Le backend tourne via systemd (service `fahglobe`, port interne 4200) et stocke
ses données en JSON (`data/*.json`) — pas de base de données. Utilise `update.sh`
pour mettre à jour le backend sans perdre de données (sauvegarde automatique).
