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
