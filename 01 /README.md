# 📘 Praktikum Sistem Terdistribusi — Minggu 01

**Instalasi & Konfigurasi Git, GitHub, serta Software Pendukung (FFmpeg & Firefox) pada macOS**

![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)
![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=for-the-badge&logo=homebrew&logoColor=black)
![macOS](https://img.shields.io/badge/macOS_13-000000?style=for-the-badge&logo=apple&logoColor=white)

---

## 👤 Identitas

| Keterangan | Detail |
|------------|--------|
| **Nama GitHub** | `usatjalung25` |
| **Email** | usat.jalung25@students.utdi.ac.id |
| **Mata Kuliah** | Sistem Terdistribusi |
| **Pertemuan** | Minggu 01 |

---

## 📑 Daftar Isi

- [Tujuan Praktikum](#-tujuan-praktikum)
- [Alat dan Bahan](#️-alat-dan-bahan)
- [Langkah-Langkah Praktikum](#-langkah-langkah-praktikum)
- [Hasil dan Analisis](#-hasil-dan-analisis)
- [Kesimpulan](#-kesimpulan)

---

## 🎯 Tujuan Praktikum

1. Memahami konsep *Version Control System* (VCS) menggunakan Git.
2. Menginstal dan mengonfigurasi Git di macOS menggunakan Homebrew.
3. Membuat repository lokal dan menghubungkannya dengan GitHub (remote).
4. Memahami alur kerja kolaborasi: membuat **branch** baru, **pull request (PR)**, **code review**, dan **merge** ke branch utama (`main`/`master`) tanpa merusak kode yang sudah ada.
5. Menginstal software pendukung, yaitu **FFmpeg** (tool command-line untuk memproses file multimedia) dan **Firefox** (browser web), untuk mendukung lingkungan pengembangan sistem terdistribusi.

---

## 🛠️ Alat dan Bahan

1. Komputer/Laptop dengan sistem operasi **macOS 13**
2. Koneksi internet
3. Terminal (bawaan macOS) atau iTerm2
4. Akun GitHub aktif
5. Homebrew (package manager untuk macOS)

---

## 💻 Langkah-Langkah Praktikum

### Langkah 1: Instalasi Git menggunakan Homebrew

1. Buka **Terminal** pada macOS.
2. Pastikan Homebrew sudah terinstal, lalu instal Git:
   ```bash
   brew install git
   ```
3. Verifikasi hasil instalasi dengan memeriksa versi Git:
   ```bash
   git --version
   ```

### Langkah 2: Konfigurasi Identitas Git

1. Atur nama pengguna global:
   ```bash
   git config --global user.name "usatjalung25"
   ```
2. Atur alamat email global (sesuaikan dengan email GitHub):
   ```bash
   git config --global user.email "usat.jalung25@students.utdi.ac.id"
   ```
3. Pastikan konfigurasi sudah benar:
   ```bash
   git config --list
   ```

### Langkah 3: Membuat Repository Lokal

1. Buat direktori baru untuk project praktikum:
   ```bash
   mkdir praktikum-siter-minggu01
   cd praktikum-siter-minggu01
   ```
2. Inisialisasi direktori tersebut menjadi repository Git:
   ```bash
   git init
   ```

### Langkah 4: Menghubungkan ke GitHub (Akun Pribadi & Organisasi)

1. Buat repository baru di akun GitHub dengan nama `praktikum-siter-minggu01`.
2. Hubungkan repository lokal ke GitHub remote:
   ```bash
   git remote add origin https://github.com/usatjalung25/praktikum-siter-minggu01.git
   ```

### Langkah 5: Commit dan Push Pertama

1. Buat file baru, misalnya `README.md`:
   ```bash
   echo "# Praktikum Sistem Terdistribusi" > README.md
   ```
2. Tambahkan file ke staging area:
   ```bash
   git add README.md
   ```
3. Simpan perubahan dengan commit:
   ```bash
   git commit -m "Initial commit: Tambah README"
   ```
4. Ubah nama branch utama menjadi `main` (jika belum):
   ```bash
   git branch -M main
   ```
5. Unggah (push) perubahan ke GitHub:
   ```bash
   git push -u origin main
   ```

### Langkah 6: Instalasi Software Pendukung

1. Instal **FFmpeg** via Homebrew:
   ```bash
   brew install ffmpeg
   ```
2. Instal **Firefox** via Homebrew Cask:
   ```bash
   brew install --cask firefox
   ```

---

## 📊 Hasil dan Analisis

> 📸 *Tambahkan screenshot Terminal/GitHub Anda di bagian ini, contoh:*
> `![Hasil git --version](images/git-version.png)`

**Analisis Konfigurasi**
Konfigurasi nama dan email penting agar setiap riwayat commit tercatat dengan jelas siapa penulisnya.

**Analisis Sinkronisasi**
Perintah `git push` berhasil mengirimkan berkas lokal ke server GitHub. Hal ini membuktikan konsep dasar sistem terdistribusi, yaitu kode disimpan di server remote dan dapat diakses dari berbagai tempat.

---

## 🔚 Kesimpulan

Dari praktikum Minggu 01 ini, dapat disimpulkan bahwa:

1. Git bertindak sebagai *Version Control System* (VCS) lokal untuk melacak perubahan file, sedangkan GitHub adalah platform *hosting* berbasis cloud yang memfasilitasi kolaborasi dan distribusi kode.
2. Penggunaan Homebrew di macOS sangat memudahkan manajemen paket aplikasi seperti Git, FFmpeg, dan Firefox melalui command-line.
3. Alur kerja dasar Git (`add` → `commit` → `push`) merupakan fondasi utama sebelum melangkah ke arsitektur sistem terdistribusi yang lebih kompleks pada pertemuan berikutnya.

---

<p align="center">Dibuat oleh <b>usatjalung25</b> · Praktikum Sistem Terdistribusi</p>
