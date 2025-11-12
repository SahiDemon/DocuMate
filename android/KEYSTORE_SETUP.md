# Creating a Production Keystore for DocuMate

## Why You Need This
To publish your app on Google Play Store, you need to sign it with your own keystore. This identifies you as the developer and ensures nobody else can update your app.

## ⚠️ IMPORTANT
- **Keep your keystore file SAFE!**
- **Never share it publicly**
- **Never commit it to Git**
- **If you lose it, you cannot update your app on Play Store**

---

## Option 1: Using Android Studio (Easiest)

1. Open this project in Android Studio
2. Go to menu: **Build → Generate Signed Bundle / APK**
3. Select **APK** and click **Next**
4. Click **Create new...**
5. Fill in the form:
   - **Key store path:** Browse and save as `documate-release-key.jks` in `android/app/` folder
   - **Password:** Choose a strong password (remember it!)
   - **Alias:** `documate`
   - **Validity:** 25 years (default)
   - **Certificate info:** Fill with your details
6. Click **OK**
7. The keystore will be created!

---

## Option 2: Using keytool (Command Line)

### Requirements:
- Java Development Kit (JDK) installed
- Or Android Studio installed

### Find keytool:
**Windows:**
```
C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe
```

**Mac:**
```
/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool
```

### Run this command:
```bash
keytool -genkey -v -keystore documate-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias documate
```

### You'll be asked for:
1. **Keystore password** - Create a strong password
2. **Key password** - Use the same password for simplicity
3. **Your name**
4. **Organization unit** - e.g., "Development"
5. **Organization** - e.g., "Your Company"
6. **City**
7. **State**
8. **Country code** - e.g., "US"

---

## Option 3: Using Our PowerShell Script (Windows)

1. Make sure Java or Android Studio is installed
2. Open PowerShell in the `android` folder
3. Run:
   ```powershell
   .\generate-keystore.ps1
   ```

**Default values used:**
- Password: `documate123` (⚠️ Change this for production!)
- Alias: `documate`

---

## After Creating the Keystore

### 1. Move the keystore file:
Place `documate-release-key.jks` in the `android/app/` directory

### 2. Update `android/key.properties`:
```properties
storePassword=YOUR_PASSWORD_HERE
keyPassword=YOUR_PASSWORD_HERE
keyAlias=documate
storeFile=documate-release-key.jks
```

### 3. Add to `.gitignore`:
Make sure these are in your `.gitignore`:
```
*.jks
*.keystore
key.properties
```

### 4. Build the signed APK:
```bash
flutter build apk --release
```

---

## Verify Your Setup

After building, check the signing info:
```bash
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

You should see your certificate details!

---

## Backup Your Keystore

1. Copy `documate-release-key.jks` to a safe location
2. Store it in:
   - A secure cloud storage (encrypted)
   - An external drive
   - A password manager
3. Save your passwords securely
4. Keep `key.properties` backup (but not in Git!)

---

## Troubleshooting

### "keytool: command not found"
- Install Java JDK or Android Studio
- Add Java to your PATH

### "Keystore was tampered with"
- You entered the wrong password
- The keystore file is corrupted

### "Build fails with signing error"
- Check `key.properties` exists in `android/` folder
- Verify the `storeFile` path is correct (should be `documate-release-key.jks` not a full path)
- Ensure passwords are correct

---

## For Play Store

When uploading to Play Store, Google recommends using **App Bundle** format:

```bash
flutter build appbundle --release
```

This creates `app-release.aab` which is optimized for the Play Store.

---

Need help? Check the main `PRODUCTION_BUILD_GUIDE.md` file!

