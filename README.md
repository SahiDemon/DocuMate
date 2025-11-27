# DocuMate 📄

> Your ultimate solution for managing and organizing important documents with smart OCR and beautiful dark UI.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-blue.svg" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-3.0+-blue.svg" alt="Dart Version">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

## 🎯 About DocuMate

DocuMate is your ultimate solution for managing and organizing important documents. Whether it's your insurance card, driver's license, or regional office paperwork, DocuMate provides a secure and convenient way to keep all your crucial documents in one place.

### ✨ Key Features

#### 🎨 User Experience
- **Adaptive Theme System** - Seamlessly switch between Dark, Light, and AMOLED Black themes
- **Material Design 3** - Modern, fluid UI with smooth animations and transitions
- **Responsive Design** - Optimized for all screen sizes from phones to tablets
- **Intuitive Navigation** - Clean, organized interface with quick access to all features

#### 🔒 Security & Privacy
- **End-to-End Encryption** - Military-grade AES-256 encryption for all documents
- **Encrypted Google Drive Backup** - Your documents are encrypted locally before uploading to your own Google Drive
- **Biometric Authentication** - Fingerprint and face unlock support
- **No Third-Party Servers** - Documents never touch our servers, complete data ownership
- **Open Source** - Full transparency with publicly auditable code

#### 📸 Smart Document Management
- **Advanced OCR Scanning** - Powered by Google ML Kit for accurate text extraction
- **Auto-Categorization** - AI-powered document type detection
- **Smart Expiry Reminders** - Customizable notifications before documents expire
- **Full-Text Search** - Find any document or text within documents instantly
- **Document Versioning** - Track changes and maintain document history

#### ☁️ Cloud Integration
- **Your Google Drive, Your Rules** - Use your own Google Drive storage
- **Client-Side Encryption** - Documents encrypted on device before upload
- **Sync Across Devices** - Access encrypted documents on multiple devices
- **Zero-Knowledge Architecture** - We can't access your data, only you can
- **Offline-First Design** - Full functionality without internet connection

#### 📊 Organization & Insights
- **Smart Categories** - ID, Insurance, Bills, Medical, Legal, and custom categories
- **Dashboard Analytics** - Visual insights into document status and expiry
- **Bulk Operations** - Import, export, and manage multiple documents at once
- **Custom Tags & Labels** - Organize documents your way
- **Quick Share** - Securely share documents with encrypted links

## 📱 Screenshots

_Coming soon - Screenshots of the beautiful dark UI_

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / Xcode for running on devices

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/SahiDemon/DocuMate.git
   cd documate
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Download Roboto fonts**
   - Download from [Google Fonts](https://fonts.google.com/specimen/Roboto)
   - Add to `assets/fonts/`:
     - Roboto-Regular.ttf
     - Roboto-Medium.ttf
     - Roboto-Bold.ttf

4. **Generate Hive adapters**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── main.dart                      # App entry point
├── theme/
│   └── app_theme.dart            # Dark theme configuration
├── models/
│   ├── document_model.dart       # Document data model
│   └── document_category.dart    # Category enums & types
├── screens/
│   ├── welcome_screen.dart       # Onboarding screen
│   └── home_screen.dart          # Main dashboard
├── services/                      # Business logic
├── widgets/                       # Reusable widgets
└── utils/                         # Helper functions
```

## 🎨 Design Philosophy

DocuMate's UI is inspired by:
- **My Diary Component** from fitness apps for organized, card-based layouts
- **Relax View** for smooth onboarding animations
- **Dark Theme** with deep blacks and vibrant accent colors for better visibility


## 🌐 Live Demo

Check out the live landing page: [DocuMate Website](https://sahidemon.github.io/DocuMate/)

## 🔐 Security & Privacy First

DocuMate is built with security and transparency at its core:

### 🛡️ What Makes DocuMate Secure?

1. **Complete Transparency** - 100% open-source code, auditable by anyone
2. **Your Data, Your Control** - Documents stored on YOUR Google Drive, not our servers
3. **Client-Side Encryption** - All encryption happens on your device before upload
4. **Zero-Knowledge Architecture** - We literally cannot access your documents, even if we wanted to
5. **No Analytics/Tracking** - We don't collect usage data, crash reports, or any telemetry
6. **Biometric Protection** - Lock your documents behind fingerprint or face recognition
7. **Open Encryption Standards** - AES-256, the same encryption used by governments and banks

### 🔒 How Encryption Works

```
1. You scan/add a document → 
2. Document encrypted with AES-256 using your device-specific key → 
3. Encrypted file uploaded to YOUR Google Drive → 
4. Even Google can't read your documents → 
5. Only your device with the decryption key can open them
```

### 🌟 Why Use Your Own Google Drive?

- **Free Storage** - Use your existing 15GB Google Drive storage
- **No Subscription** - No monthly fees, no premium plans
- **Data Ownership** - You control where your data lives
- **Easy Migration** - Download encrypted files anytime, anywhere
- **Redundancy** - Google's infrastructure ensures your data never disappears

## 📚 Document Categories

1. **ID & Identity** - Driver's License, Passport, ID Cards
2. **Insurance** - Health, Car, Home insurance
3. **Bills & Utilities** - Electricity, Water, Gas bills
4. **Medical & Health** - Prescriptions, Medical reports
5. **Legal Documents** - Contracts, Agreements
6. **Other Documents** - Miscellaneous files

## 🔧 Technologies Used

### Core Framework
- **Flutter 3.0+** - Cross-platform UI framework with Material Design 3
- **Dart 3.0+** - Modern, type-safe programming language

### Storage & Security
- **Hive** - Fast, lightweight local NoSQL database
- **flutter_secure_storage** - Secure storage for encryption keys
- **encrypt** - AES-256 encryption for documents
- **crypto** - Cryptographic operations

### Cloud Integration
- **googleapis** - Official Google Drive API client
- **google_sign_in** - OAuth2 authentication for Google services
- **firebase_auth** - Secure user authentication

### Document Processing
- **Google ML Kit** - Advanced OCR text recognition
- **edge_detection** - Smart document edge detection and cropping
- **opencv_dart** - Image processing and enhancement
- **camera & image_picker** - Document capture from camera/gallery

### User Experience
- **flutter_local_notifications** - Customizable expiry reminders
- **local_auth** - Biometric authentication support
- **intl** - Internationalization and date formatting
- **provider/riverpod** - State management

## 📋 Implementation Status

### ✅ Completed
- [x] Project structure and architecture
- [x] Adaptive theme system (Dark/Light/AMOLED)
- [x] Material Design 3 implementation
- [x] Welcome/onboarding flow with animations
- [x] Home dashboard UI with analytics
- [x] Data models and categories
- [x] Dependency setup
- [x] Landing page with modern design
- [x] Responsive mobile-optimized UI
- [x] Smooth animations and transitions
- [x] Professional documentation site
- [x] Local Hive database integration
- [x] Document CRUD operations
- [x] End-to-end AES-256 encryption
- [x] Google Drive integration with OAuth2
- [x] Client-side encryption before cloud upload
- [x] Camera integration with edge detection
- [x] OCR implementation with ML Kit
- [x] Biometric authentication
- [x] Advanced reminder system
- [x] Full-text search with indexing
- [x] Multi-device sync with encrypted data
- [x] Document versioning and history
- [x] Custom categories and tags
- [x] Bulk import/export operations
- [x] Backup and restore functionality

### 📅 Planned


## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**SahiDemon**
- GitHub: [@SahiDemon](https://github.com/SahiDemon)

## 🙏 Acknowledgments

- Icons from Material Design
- Fonts from Google Fonts
- Design mockups from Google Stitch
- OCR powered by Google ML Kit

## 🤝 Our Privacy Commitment

We believe privacy is a fundamental right:

- ✅ **No user tracking** - We don't know who uses DocuMate
- ✅ **No data collection** - We can't see your documents
- ✅ **No cloud servers** - Your encrypted files go directly to YOUR Google Drive
- ✅ **No monetization** - Free forever, no ads, no premium tiers
- ✅ **Open source** - Every line of code is public and auditable

## 📞 Support

If you have any questions or need help, please open an issue on GitHub.

For security vulnerabilities, please email privately before public disclosure.

---

<p align="center">Made with ❤️ and Flutter</p>
<p align="center">DocuMate - Your documents, organized beautifully. 📄✨</p>

