# Contributing to WarungKu App

Terima kasih telah tertarik untuk berkontribusi ke WarungKu App! 🎉

## 📋 Code of Conduct

Proyek ini mengikuti [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/). Dengan berpartisipasi, Anda diharapkan untuk mematuhi kode etik ini.

## 🚀 Getting Started

1. Fork repository ini
2. Clone fork Anda: `git clone https://github.com/riofach/warungku_app.git`
3. Buat branch baru: `git checkout -b feature/your-feature-name`
4. Lakukan perubahan
5. Commit dengan pesan yang jelas: `git commit -m "feat: add new feature"`
6. Push ke branch Anda: `git push origin feature/your-feature-name`
7. Buat Pull Request

## 📝 Commit Message Convention

Kami menggunakan [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- `feat`: Fitur baru
- `fix`: Bug fix
- `docs`: Perubahan dokumentasi
- `style`: Formatting, missing semicolons, etc (tidak mengubah logic)
- `refactor`: Refactoring kode
- `test`: Menambah atau memperbaiki test
- `chore`: Maintenance tasks

### Contoh

```
feat(pos): add QRIS payment support
fix(cart): fix quantity calculation bug
docs: update README with new screenshots
```

## 🧪 Testing

Pastikan semua test pass sebelum membuat PR:

```bash
flutter test
flutter analyze
```

## 📏 Code Style

- Gunakan `flutter format` untuk formatting
- Ikuti [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Pastikan tidak ada warning dari `flutter analyze`

## 📂 Folder Structure

Ikuti struktur folder yang sudah ada:

```
lib/
├── core/           # Shared code
└── features/       # Feature modules
    └── feature_name/
        ├── data/          # Models, repositories, providers
        └── presentation/  # Screens, widgets
```

## 🤝 Pull Request Guidelines

1. Update README.md jika diperlukan
2. Pastikan semua test pass
3. Pastikan tidak ada breaking changes tanpa diskusi terlebih dahulu
4. Gunakan deskripsi yang jelas pada PR

## 💬 Need Help?

Jika ada pertanyaan, silakan buat issue baru dengan label `question`.

Terima kasih! 🙏
