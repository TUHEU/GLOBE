# Installer la nouvelle icône de l'app

Les images sont déjà prêtes dans `assets/icon/` :
- `app_icon.png` — icône carrée 1024×1024 (iOS, Web, Windows, icône Android classique)
- `app_icon_foreground.png` — version avec marge pour l'icône adaptative Android (fond vert uni derrière)

## 1. Ajoute la dépendance dans `pubspec.yaml`

Sous `dev_dependencies:` :
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.3
```

Puis, à la racine du fichier (même niveau que `flutter:`), ajoute :
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#0F5A2E"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"
    background_color: "#0F5A2E"
    theme_color: "#0F5A2E"
  windows:
    generate: true
    image_path: "assets/icon/app_icon.png"
    icon_size: 256
```

## 2. Génère les icônes

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

Ça régénère automatiquement toutes les tailles nécessaires pour Android
(`android/app/src/main/res/mipmap-*`), iOS, Web (`web/icons/`) et Windows
(`windows/runner/resources/app_icon.ico`).

## 3. Rebuild pour voir la nouvelle icône

```bash
flutter clean
flutter build apk --release
flutter build web --release --base-href /app/
flutter build windows --release
```

⚠️ La nouvelle icône n'apparaît PAS avec `flutter run` en mode debug sur un
appareil qui a déjà l'ancienne app installée — désinstalle l'ancienne version
du téléphone/émulateur avant de réinstaller le nouvel APK, sinon Android garde
l'icône en cache.
