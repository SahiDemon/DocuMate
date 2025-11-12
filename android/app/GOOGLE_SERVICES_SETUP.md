# Google Services Setup

## ⚠️ IMPORTANT: API Keys Security

**NEVER commit `google-services.json` to Git!** It contains sensitive API keys.

## Setup Instructions

1. **Get your `google-services.json` file:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to Project Settings → Your apps
   - Download `google-services.json` for Android

2. **Place the file:**
   ```
   android/app/google-services.json
   ```

3. **The file is already in `.gitignore`** - it won't be committed.

## Template

A template file (`google-services.json.template`) is provided as a reference.
Copy it to `google-services.json` and fill in your actual values.

## Security Notes

- ✅ `google-services.json` is in `.gitignore`
- ✅ Never share your API keys publicly
- ✅ If keys are exposed, regenerate them in Firebase Console
- ✅ Use environment variables for CI/CD pipelines

