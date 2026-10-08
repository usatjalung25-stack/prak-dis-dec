```markdown
# Praktikum Minggu 01 - Pengenalan Sistem Terdistribusi dan Terdesentralisasi
## Git dan GitHub

**Mata Kuliah:** Praktikum Sistem Terdistribusi dan Terdesentralisasi  
**Topik:** Git dan GitHub  
**Nama:** usatjalung25  
**Email:** usat.jalung25@students.utdi.ac.id  
**Tanggal:** Oktober 2026  
**Sistem Operasi:** macOS 13  
**Git Version:** 2.39.2 (Apple Git-143)

---

## 📚 TUJUAN PRAKTIKUM

Praktikum ini bertujuan untuk:
1. Memahami fungsi dasar Git dan GitHub.
2. Melakukan instalasi Git pada komputer (macOS) menggunakan Homebrew.
3. Melakukan konfigurasi identitas pengguna Git.
4. Membuat dan mengelola repository.
5. Menghubungkan repository lokal dengan GitHub.
6. Melakukan commit dan mengunggah perubahan ke repository.
7. Memahami dasar kolaborasi menggunakan Git dan GitHub.
8. Melakukan instalasi software pendukung (FFmpeg dan Firefox).

---

## 📚 DASAR TEORI

Materi yang dipelajari dalam praktikum meliputi:

### 1. Instalasi Git
Pada tahap ini dilakukan instalasi Git pada komputer. Git digunakan untuk mengelola perubahan pada file dan project secara terstruktur. Pada macOS, Git dapat diinstal menggunakan Homebrew sebagai package manager.

### 2. Konfigurasi Git
Setelah Git berhasil diinstal, dilakukan konfigurasi nama pengguna dan email. Konfigurasi ini digunakan untuk mengidentifikasi pengguna ketika melakukan commit.

### 3. Pengelolaan Repository
Tahap ini membahas pembuatan dan pengelolaan repository. Repository dapat digunakan untuk menyimpan source code, dokumentasi, dan file project lainnya.

### 4. Repository pada Account Sendiri
Materi ini membahas cara mengelola repository yang berada pada akun GitHub pribadi, mulai dari membuat repository sampai melakukan sinkronisasi dengan repository lokal.

### 5. Repository pada Organisasi
Materi ini membahas penggunaan repository yang berada dalam organisasi. Repository organisasi dapat digunakan ketika beberapa pengguna bekerja dalam satu kelompok atau project.

### 6. Kolaborasi
Tahap terakhir membahas penggunaan Git dan GitHub untuk bekerja secara bersama-sama dalam sebuah project. Setiap anggota dapat melakukan perubahan pada project dan mengelola perubahan tersebut menggunakan Git.

---

## ⏩ PEMBAHASAN PRAKTIKUM

### PRAKTIK 1: INSTALASI HOMEBREW DAN GIT

#### 1.1 Instalasi Homebrew (Package Manager untuk macOS)
Homebrew adalah package manager untuk macOS yang memudahkan instalasi berbagai software termasuk Git.
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 1.2 Instalasi FFmpeg dan Firefox menggunakan Homebrew
```bash
brew install ffmpeg firefox
```

**Output dan Pembahasan:**
```text
==> Downloading Homebrew API data
✔︎ JSON API packages.ventura.jws.json                           Downloaded   15.0MB/ 15.0MB
Warning: You are using macOS 13.
We (and Apple) do not provide support for this old version.

Homebrew no longer builds bottles for this configuration.
Consider MacPorts, which provides binary packages for this macOS version:
  https://www.macports.org
```
**Pembahasan:**  
Sistem menggunakan macOS 13 yang sudah tidak didukung penuh oleh Homebrew. Homebrew menyarankan untuk menggunakan MacPorts sebagai alternatif.

```text
Warning: The following taps are not trusted:
  jostasik/tap

Homebrew is currently ignoring formulae, casks and commands
from these taps because tap trust is required.
```
**Pembahasan:**  
Terdapat warning tentang tap yang tidak trusted (`jostasik/tap`). Homebrew mengabaikan formulae, casks, dan commands dari tap ini karena memerlukan trust.

**Solusi:**
```bash
# Untap jika tidak diperlukan
brew untap jostasik/tap

# Atau trust jika diperlukan
brew trust jostasik/tap
```

**Daftar Dependencies yang akan diinstal:**
```text
==> Would install 1 formula:
ffmpeg 9.0.2
==> Would install 21 dependencies for ffmpeg:
openssl@3, readline, sqlite, xz, lz4, zstd, expat, python@3.14, 
meson, nasm, dav1d, mpg123, lame, libvmaf, libvpx, opus, sdl3, 
sdl2-compat, svt-av1, x264, x265
==> Would upgrade 1 dependency for ffmpeg:
cmake
```
**Pembahasan:**  
FFmpeg memerlukan 21 dependencies untuk berfungsi dengan baik. Dependencies ini termasuk library untuk encoding/decoding video dan audio.

#### 1.3 Konfirmasi Instalasi
```text
==> Do you want to proceed with the installation? [y/n]
y
```
**Pembahasan:**  
User mengkonfirmasi dengan mengetik `y` untuk melanjutkan instalasi.

#### 1.4 Proses Download dan Verifikasi
**Output:**
```text
==> Fetching downloads for: ffmpeg and firefox
✔︎ API Source ffmpeg.rb                                         Verified      3.7KB/  3.7KB
✔︎ API Source openssl@3.rb                                      Verified      7.2KB/  7.2KB
✔︎ Formula readline (8.3.6)                                     Verified      3.4MB/  3.4MB
✔︎ Formula sqlite (3.53.4)                                      Verified      3.3MB/  3.3MB
✔︎ Formula python@3.14 (3.14.8)                                 Verified     31.5MB/ 31.5MB
✔︎ Formula openssl@3 (3.6.5)                                    Verified     55.1MB/ 55.1MB
✔︎ Cask firefox (157.0)                                         Downloaded  161.8MB/161.8MB
```
**Pembahasan:**  
Homebrew mendownload dan memverifikasi semua dependencies. Total ada puluhan package yang didownload termasuk Firefox versi 157.0.

#### 1.5 Error yang Muncul dan Solusi
```text
Error: ffmpeg: A `brew install ffmpeg firefox` process has already locked /usr/local/Cellar/pkgconf.
Please wait for it to finish or terminate it to continue.

Error: firefox: It seems there is already an App at '/Applications/Firefox.app'.
```
**Pembahasan:**  
- Error pertama menunjukkan ada proses instalasi yang sedang berjalan dan mengunci `/usr/local/Cellar/pkgconf`.
- Error kedua menunjukkan Firefox sudah terinstal di `/Applications/Firefox.app`.

**Solusi:**
```bash
# Install firefox sebagai cask
brew install --cask firefox
```

#### 1.6 Instalasi Firefox sebagai Cask
```bash
brew install --cask firefox
```
**Output:**
```text
==> Fetching downloads for: firefox
✔︎ Cask firefox (157.0)                                         Downloaded  161.8MB/161.8MB
==> Installing Cask firefox
==> Purging files for version 157.0 of Cask firefox

This is a Tier 3 configuration:
  https://docs.brew.sh/Support-Tiers#tier-3
You can report issues with Tier 3 configurations to Homebrew/* repositories!
```
**Pembahasan:**  
Firefox berhasil didownload dan diinstal sebagai cask (aplikasi GUI). Warning Tier 3 menunjukkan bahwa konfigurasi macOS 13 ini tidak didukung penuh.

---

### PRAKTIK 2: MENGECEK LOKASI INSTALASI

#### 2.1 Mencari Lokasi FFmpeg
```bash
find $(brew --cellar)/ffmpeg
```
**Output:**
```text
/opt/homebrew/Cellar/ffmpeg/8.1.1/bin/ffmpeg
/opt/homebrew/Cellar/ffmpeg/8.1.1/share/man/man1/ffmpeg.1
find: /usr/local/Cellar/ffmpeg: No such file or directory
```
**Pembahasan:**  
FFmpeg terinstal di `/opt/homebrew/Cellar/ffmpeg/8.1.1/`. Terdapat binary executable dan file dokumentasi manual.

#### 2.2 Melihat Isi Direktori Homebrew
```bash
ls -l $(brew --prefix)/bin
```
**Output:**
```text
total 1768
lrwxr-xr-x  1 danel  admin      35 Oct  5 11:48 bomtool -> ../Cellar/pkgconf/3.0.7/bin/bomtool
lrwxr-xr-x  1 danel  admin      20 Oct 28  2025 brew -> ../Homebrew/bin/brew
lrwxr-xr-x  1 danel  admin      32 Jul 10 00:19 ninja -> ../Cellar/ninja/1.13.2/bin/ninja
lrwxr-xr-x  1 danel  admin      38 Oct  5 11:48 pkg-config -> ../Cellar/pkgconf/3.0.7/bin/pkg-config
lrwxr-xr-x  1 danel  admin      35 Oct  5 11:48 pkgconf -> ../Cellar/pkgconf/3.0.7/bin/pkgconf
```
**Pembahasan:**  
Homebrew membuat symbolic links (symlinks) di `/opt/homebrew/bin/` yang mengarah ke lokasi instalasi sebenarnya di Cellar. Ini memungkinkan perintah dipanggil dari mana saja.

#### 2.3 Mencari Lokasi Firefox
```bash
find $(brew --caskroom)/firefox
```
**Output:**
```text
/opt/homebrew/Caskroom/firefox/151.0.3/Firefox.app
find: /usr/local/Caskroom/firefox: No such file or directory
```
**Pembahasan:**  
Firefox sebagai cask terinstal di `/opt/homebrew/Caskroom/firefox/151.0.3/Firefox.app`.

#### 2.4 Mengecek Aplikasi di /Applications
```bash
ls /Applications
```
**Output:**
```text
Firefox.app
Antigravity IDE.app	Google Drive.app	WhatsApp.app
CapCut.app		Safari.app		XAMPP
Claude.app		Utilities		wpsoffice.app
Firefox.app		Visual Studio Code.app	zoom.us.app
```
**Pembahasan:**  
Firefox terlihat di folder Applications dan siap digunakan. Homebrew membuat symlink ke folder Applications untuk memudahkan akses.

---

### PRAKTIK 3: KONFIGURASI GIT

#### 3.1 Mengecek Versi Git
```bash
git --version
```
**Output:**
```text
git version 2.39.2 (Apple Git-143)
```
**Pembahasan:**  
Git versi 2.39.2 sudah terinstal. Ini adalah versi yang disediakan oleh Apple (Apple Git-143).

#### 3.2 Konfigurasi Username Git
```bash
git config --global user.name "usatjalung25"
```
**Pembahasan:**  
Mengatur nama pengguna yang akan tercatat pada setiap commit. Username ini akan muncul di GitHub sebagai author.

#### 3.3 Konfigurasi Email Git
```bash
git config --global user.email usat.jalung25@students.utdi.ac.id
```
**Pembahasan:**  
Email dikonfigurasi untuk mengidentifikasi pemilik commit. Email ini harus sesuai dengan yang terdaftar di GitHub.

#### 3.4 Melihat File Konfigurasi Git
```bash
cat ~/.gitconfig
```
**Output:**
```ini
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
[user]
	name = usatjalung25
	email = usat.jalung25@students.utdi.ac.id
[http]
	lowSpeedLimit = 1000
	postBuffer = 157286400
[init]
	defaultBranch = main
```
**Pembahasan:**  
File `.gitconfig` berisi:
- **Git LFS filter**: Untuk menangani file besar.
- **User identity**: Name dan email.
- **HTTP settings**: Optimasi untuk upload (`lowSpeedLimit` dan `postBuffer`).
- **Default branch**: Diatur ke `main` (bukan `master`).

#### 3.5 Melihat Semua Konfigurasi Git
```bash
git config --list
```
**Output:**
```text
credential.helper=osxkeychain
init.defaultbranch=main
filter.lfs.clean=git-lfs clean -- %f
filter.lfs.smudge=git-lfs smudge -- %f
filter.lfs.process=git-lfs filter-process
filter.lfs.required=true
user.name=usatjalung25
user.email=usat.jalung25@students.utdi.ac.id
http.lowspeedlimit=1000
http.postbuffer=157286400
init.defaultbranch=main
```
**Pembahasan:**  
Semua konfigurasi ditampilkan dalam format `key=value`. Konfigurasi penting:
- **credential.helper=osxkeychain**: Menggunakan keychain macOS untuk menyimpan credential.
- **init.defaultbranch=main**: Branch default adalah `main`.
- **http.postbuffer=157286400**: Buffer size 150MB untuk upload file besar.

---

### PRAKTIK 4: DOKUMENTASI FILE REPOSITORY

Berdasarkan screenshot GitHub yang ditampilkan, berikut adalah file-file yang telah di-commit:

| No | Nama File | Last Commit Message | Waktu |
|----|-----------|---------------------|-------|
| 1 | 07-git --version.png | Rename Jepretan Layar 2026-10-08 pukul 07.13.32.png | 1 hour ago |
| 2 | 01-Homebrew.png | Rename Homebrew01.png | 1 hour ago |
| 3 | 01-Homebrew_kode.png | Rename Homebrew_kode03.png | 1 hour ago |
| 4 | 02-Homebrew.png | Rename Homebrew02.png | 1 hour ago |
| 5 | 03-brew install ffmpeg firefox | Rename Jepretan Layar 2026-10-08 pukul 07.10.24.png | 1 hour ago |
| 6 | 04-brew reinstall firefox.png | Rename 04-ls Applications \| grep "Firefox.app.png | 1 hour ago |
| 7 | 05-ls Applications.png | Rename Jepretan Layar 2026-10-08 pukul 07.12.56.png | 1 hour ago |
| 8 | 06-brew install --cask firefox.png | Rename Jepretan Layar 2026-10-08 pukul 07.13.24.png | 1 hour ago |
| 9 | 08-Konfigurasi Username.png | Rename 07-Konfigurasi Username.png | 1 minute ago |
| 10 | 09-Membuat Konfigurasi Email.png | Rename 08-Membuat Konfigurasi Email.png | 1 minute ago |
| 11 | 10-Melihat Konfigurasi-1.png | Rename 09-Melihat Konfigurasi-1.png | now |
| 12 | 10-Melihat Konfigurasi-2.png | Rename 09-Melihat Konfigurasi-2.png | now |

**Pembahasan:**  
- File-file ini merupakan dokumentasi screenshot dari setiap langkah praktikum.
- Penamaan dengan nomor urut (01, 02, 03, dst) memudahkan pengurutan.
- File-file di-rename dari nama default screenshot ("Jepretan Layar") menjadi nama yang lebih deskriptif.
- Semua file berhasil di-commit ke repository GitHub.

---

## 📝 KESIMPULAN

Praktikum Git dan GitHub memberikan pemahaman dasar mengenai pengelolaan project menggunakan version control. Kesimpulan yang dapat diambil:

1. **Instalasi Git di macOS** dapat dilakukan menggunakan Homebrew. Git versi 2.39.2 (Apple Git-143) berhasil terinstal.
2. **Homebrew** memudahkan instalasi software di macOS, termasuk Git, FFmpeg, dan Firefox. Namun, macOS 13 yang digunakan sudah tidak didukung penuh (Tier 3 configuration).
3. **Konfigurasi Git** sangat penting untuk mengidentifikasi author setiap commit. Konfigurasi yang dilakukan meliputi: Username (`usatjalung25`), Email (`usat.jalung25@students.utdi.ac.id`), Default branch (`main`), Git LFS untuk file besar, dan HTTP buffer untuk upload file besar (150MB).
4. **Git LFS** (Large File Storage) sudah terkonfigurasi untuk menangani file-file besar dalam repository.
5. **Credential helper** menggunakan `osxkeychain` untuk menyimpan credential GitHub secara aman di macOS.
6. **Repository management** meliputi pembuatan, konfigurasi, dan sinkronisasi antara repository lokal dan remote.
7. **Dokumentasi** setiap langkah praktikum penting untuk referensi dan pembelajaran di masa mendatang. File screenshot berhasil di-commit dengan penamaan yang terstruktur.
8. **Warning dan Error** yang muncul selama instalasi dapat diatasi dengan memahami pesan error dan mencari solusi yang tepat (seperti `install --cask` untuk aplikasi GUI).
9. **Symbolic links** yang dibuat Homebrew di `/opt/homebrew/bin/` memungkinkan perintah dipanggil dari mana saja di terminal.
10. **Tier 3 Configuration** menunjukkan bahwa macOS 13 sudah tidak mendapat dukungan penuh dari Homebrew, sehingga disarankan untuk upgrade ke versi macOS yang lebih baru.

---

## 🗒️ REFERENSI

1. **Git Documentation** - https://git-scm.com/doc
2. **GitHub Guides** - https://guides.github.com
3. **Homebrew Documentation** - https://docs.brew.sh
4. **Homebrew Tap Trust** - https://docs.brew.sh/Tap-Trust
5. **Homebrew Support Tiers** - https://docs.brew.sh/Support-Tiers#tier-3
6. **MacPorts** - https://www.macports.org
7. **Materi praktikum mengacu pada dokumentasi Git dan GitHub serta materi petunjuk penggunaan Git dan GitHub dari repository NEO-X-School**  
   https://github.com/NEO-X-School/notes/tree/main/petunjuk-git-github
8. **Git Configuration** - https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration
9. **Git LFS** - https://git-lfs.com

---

**Disusun oleh:**  
**Nama:** usatjalung25  
**Email:** usat.jalung25@students.utdi.ac.id  
**Tanggal:** Oktober 2026  
**Sistem Operasi:** macOS 13  
**Git Version:** 2.39.2 (Apple Git-143)  
**Homebrew Location:** /opt/homebrew

---
**© 2026 - Praktikum Sistem Terdistribusi dan Terdesentralisasi**
```
