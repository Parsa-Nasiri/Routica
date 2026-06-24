# App Icon Setup Instructions - Android Only

## Step 1: Add Your Icon
Place your app icon file here with the name `icon.png`

**Requirements:**
- Format: PNG
- Size: 1024x1024 pixels (square)
- Background: Transparent or solid color
- Recommended: High-quality, clear icon that represents your app

## Step 2: Generate Icons
After placing your icon file, run these commands:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for:
- ✅ Android (all densities including adaptive icons)

## Step 3: Verify
After generation, you can verify the icons were created by checking:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Android Adaptive Icon: `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png` and `ic_launcher_background.png`

## Notes
- The icon will use your app's theme color (#0C1421) for the adaptive icon background
- Android adaptive icons will be generated automatically
- Only Android icons are generated (iOS, Web, Windows, macOS are disabled)

