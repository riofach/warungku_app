# 🏪 WarungKu App

> Aplikasi Kasir Digital untuk UMKM Warung/Toko Kelontong

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 Deskripsi

**WarungKu App** adalah aplikasi mobile Flutter untuk pemilik warung/toko kelontong yang memungkinkan:

- 🛒 **Point of Sale (POS)** - Transaksi kasir cepat dengan QRIS & Tunai
- 📦 **Manajemen Inventori** - Kelola barang, kategori, dan stok
- 📊 **Dashboard Analytics** - Monitor omset, profit, dan performa bisnis
- 📋 **Kelola Pesanan** - Terima dan proses pesanan dari website
- 📈 **Laporan & Export** - Generate laporan PDF

## 🏗️ Arsitektur

```
lib/
├── core/                    # Shared components
│   ├── constants/           # App & Supabase constants
│   ├── theme/               # Colors, spacing, typography
│   ├── widgets/             # Reusable widgets
│   ├── services/            # Supabase service
│   ├── router/              # GoRouter configuration
│   └── utils/               # Formatters, validators
│
└── features/                # Feature modules
    ├── auth/                # Authentication
    │   ├── data/            # Models, repositories, providers
    │   └── presentation/    # Screens, widgets
    ├── dashboard/           # Dashboard & analytics
    ├── pos/                 # Point of sale
    ├── inventory/           # Item & category management
    ├── orders/              # Order management
    ├── reports/             # Reports & export
    └── settings/            # App settings
```

## 🛠️ Tech Stack

| Technology   | Version | Purpose                           |
| ------------ | ------- | --------------------------------- |
| Flutter      | 3.x     | UI Framework                      |
| Dart         | 3.x     | Programming Language              |
| Supabase     | Latest  | Backend (Auth, Database, Storage) |
| Riverpod     | 3.x     | State Management                  |
| GoRouter     | 17.x    | Navigation                        |
| Google Fonts | 7.x     | Typography (Inter)                |

## 📦 Dependencies

```yaml
dependencies:
  supabase_flutter: ^2.12.0 # Supabase SDK
  flutter_riverpod: ^3.2.0 # State management
  go_router: ^17.0.1 # Navigation
  google_fonts: ^7.0.2 # Inter font
  intl: ^0.20.2 # Localization & formatting
  flutter_dotenv: ^6.0.0 # Environment variables
  image_picker: ^1.2.1 # Image upload
  pdf: ^3.11.3 # PDF generation
  printing: ^5.14.2 # PDF printing/sharing
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / VS Code
- Supabase account

### Installation

1. **Clone repository**

   ```bash
   git clone https://github.com/riofach/warungku_app.git
   cd warungku_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Setup environment variables**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` dengan kredensial Supabase Anda:

   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

## 📱 Screenshots

| Login                                | Dashboard                                    | POS                              |
| ------------------------------------ | -------------------------------------------- | -------------------------------- |
| ![Login](docs/screenshots/login.png) | ![Dashboard](docs/screenshots/dashboard.png) | ![POS](docs/screenshots/pos.png) |

## 🎨 Design System

### Colors

| Token     | Hex       | Usage                      |
| --------- | --------- | -------------------------- |
| Primary   | `#2563EB` | Buttons, links, accents    |
| Secondary | `#10B981` | Success, profit indicators |
| Error     | `#EF4444` | Error states, warnings     |
| Warning   | `#F59E0B` | Low stock alerts           |

### Typography

- **Font Family**: Inter (Google Fonts)
- **Sizes**: 12sp - 32sp
- **Weights**: 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)

## 📁 Project Structure

```
warungku_app/
├── lib/                     # Source code
├── assets/
│   └── images/              # Image assets
├── android/                 # Android native code
├── ios/                     # iOS native code (if needed)
├── test/                    # Unit & widget tests
├── .env.example             # Environment template
├── pubspec.yaml             # Dependencies
└── README.md                # This file
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🔐 Environment Variables

| Variable            | Description            | Required |
| ------------------- | ---------------------- | -------- |
| `SUPABASE_URL`      | Supabase project URL   | ✅       |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | ✅       |

## 📄 Related Projects

- [WarungKu Web](../warungku_web) - Customer-facing website (Laravel)
- [Supabase](https://supabase.com) - Backend as a Service

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨💻 Author

**Fachrio Raditya** - Skripsi Project

---

<p align="center">
  Made with ❤️ using Flutter & Supabase
</p>
