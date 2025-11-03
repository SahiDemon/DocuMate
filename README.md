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

- 📸 **Smart OCR Scanning** - Automatically extract text and information from documents
- 🔔 **Expiry Reminders** - Get notified before your documents expire
- 🎨 **Beautiful Dark UI** - Elegant dark theme inspired by modern design principles
- 📁 **Organized Categories** - Manage documents by type (ID, Insurance, Bills, Medical, Legal)
- 🔒 **Secure Storage** - Encrypted local storage keeps your documents safe
- 🚀 **Fast & Offline** - Works completely offline, no internet required
- 🔍 **Quick Search** - Find any document instantly with full-text search
- 📊 **Smart Insights** - See document counts, expiring items, and more at a glance

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

### Color Palette

- **Primary Dark**: `#0A0E27` - Deep blue-black background
- **Card Dark**: `#252B48` - Elevated card surfaces
- **Accent Blue**: `#4A90E2` - Identity documents
- **Accent Purple**: `#7B68EE` - Insurance documents
- **Accent Green**: `#5DBD9D` - Bills & utilities
- **Accent Orange**: `#FF8C42` - Legal documents
- **Accent Red**: `#E74C3C` - Medical documents

## 📚 Document Categories

1. **ID & Identity** - Driver's License, Passport, ID Cards
2. **Insurance** - Health, Car, Home insurance
3. **Bills & Utilities** - Electricity, Water, Gas bills
4. **Medical & Health** - Prescriptions, Medical reports
5. **Legal Documents** - Contracts, Agreements
6. **Other Documents** - Miscellaneous files

## 🔧 Technologies Used

- **Flutter** - Cross-platform UI framework
- **Hive** - Fast, lightweight local database
- **Google ML Kit** - OCR text recognition
- **flutter_local_notifications** - Expiry reminders
- **camera & image_picker** - Document capture
- **intl** - Date formatting

## 📋 Implementation Status

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for detailed roadmap.

### ✅ Completed
- [x] Project structure and architecture
- [x] Dark theme system
- [x] Welcome/onboarding flow
- [x] Home dashboard UI
- [x] Data models and categories
- [x] Dependency setup

### 🚧 In Progress
- [ ] Camera integration
- [ ] OCR implementation
- [ ] Database operations
- [ ] Reminder system

### 📅 Planned
- [ ] Search functionality
- [ ] Settings screen
- [ ] Export/Import data
- [ ] Cloud backup

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

- UI inspiration from [Best Flutter UI Templates](https://github.com/mitesh77/Best-Flutter-UI-Templates)
- Icons from Material Design
- Fonts from Google Fonts

## 📞 Support

If you have any questions or need help, please open an issue on GitHub.

---

<p align="center">Made with ❤️ and Flutter</p>
<p align="center">DocuMate - Your documents, organized beautifully. 📄✨</p>

