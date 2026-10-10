# Konfigurasi Git

[← Kembali](README.md)

Bagian ini merupakan bagian dari seri tulisan tentang [Git](https://git-scm.com/). Kunjungi [README.md](README.md) untuk melihat gambaran umum seluruh materi.

## Daftar Isi

- [Mengapa Git Perlu Dikonfigurasi?](#mengapa-git-perlu-dikonfigurasi)
- [Tingkatan Konfigurasi](#tingkatan-konfigurasi)
- [Langkah 1: Pastikan Git Sudah Terpasang](#langkah-1-pastikan-git-sudah-terpasang)
- [Langkah 2: Atur Username dan Email](#langkah-2-atur-username-dan-email)
- [Langkah 3: Verifikasi Konfigurasi](#langkah-3-verifikasi-konfigurasi)
- [Langkah 4: Konfigurasi Tambahan yang Direkomendasikan](#langkah-4-konfigurasi-tambahan-yang-direkomendasikan)
- [Konfigurasi Berbeda per Repo](#konfigurasi-berbeda-per-repo)
- [Mengubah, Menghapus, dan Mengedit Konfigurasi](#mengubah-menghapus-dan-mengedit-konfigurasi)
- [Mengatasi Error](#mengatasi-error)
- [Ringkasan Perintah](#ringkasan-perintah)

---

## Mengapa Git Perlu Dikonfigurasi?

Setiap kali Anda membuat *commit*, Git mencatat siapa yang melakukan perubahan tersebut. Identitas itu diambil dari konfigurasi `user.name` dan `user.email`. Jika belum diatur, Git akan menolak membuat commit atau menebak identitas dari nama komputer Anda, dan hasilnya biasanya tidak sesuai.

Karena itu, konfigurasi minimal yang harus dilakukan adalah **username** dan **email**.

---

## Tingkatan Konfigurasi

Git punya tiga tingkatan konfigurasi. Tingkat yang lebih spesifik akan menimpa tingkat yang lebih umum.

| Tingkat | Opsi | Cakupan | Lokasi file |
|---|---|---|---|
| System | `--system` | Semua user di komputer | Linux/macOS: `/etc/gitconfig`<br>Windows: `C:\Program Files\Git\etc\gitconfig` |
| Global | `--global` | Semua repo milik user saat ini | Linux/macOS: `~/.gitconfig` atau `~/.config/git/config`<br>Windows: `C:\Users\NamaUser\.gitconfig` |
| Local | `--local` (bawaan) | Hanya satu repo | `.git/config` di dalam repo |

**Urutan prioritas: local > global > system.** Jika sebuah repo punya email sendiri, email itu dipakai di repo tersebut dan mengabaikan email global.

> [!NOTE]
> Pada Windows lama (XP), lokasinya `C:\Documents and Settings\NamaUser`. Pada Windows modern, gunakan `C:\Users\NamaUser`.

---

## Langkah 1: Pastikan Git Sudah Terpasang

```
$ git --version
git version 2.43.0
```

Jika muncul `command not found` atau `'git' is not recognized`, lihat [Mengatasi Error](#mengatasi-error).

---

## Langkah 2: Atur Username dan Email

```
$ git config --global user.name "Nama Lengkap di GitHub"
$ git config --global user.email "email@domain.tld"
```

Hal yang perlu diperhatikan:

- Isi `user.name` dengan **nama lengkap yang sama persis dengan yang tertulis di profil GitHub** Anda (*Settings → Public profile → Name*), bukan nama panggilan atau nama komputer. Contoh: `"Budi Santoso"`.
- Isi `user.email` dengan email yang **sama dengan yang terdaftar di akun GitHub** Anda.
- Gunakan tanda kutip jika nama mengandung spasi.
- Langkah ini cukup dilakukan **sekali saja**, kecuali jika Anda ingin mengganti identitas.
- Agar commit terhubung ke akun GitHub (avatar tampil dan terhitung di grafik kontribusi), gunakan email yang **terdaftar di akun GitHub** Anda.

> [!TIP]
> Jika tidak ingin menampilkan email asli, GitHub menyediakan email privat di *Settings → Emails* dengan format `ID+username@users.noreply.github.com`.

---

## Langkah 3: Verifikasi Konfigurasi

### Melihat satu nilai

```
$ git config user.name
Nama Lengkap di GitHub
$ git config user.email
email@domain.tld
```

### Melihat isi file konfigurasi global (Linux/macOS)

```
$ cat ~/.gitconfig
[user]
        name = Nama Lengkap di GitHub
        email = email@domain.tld
[init]
        defaultBranch = main
```

### Melihat seluruh konfigurasi yang aktif

```
$ git config --list
```

Hasilnya bergantung pada lokasi Anda berada:

| Lokasi | Yang ditampilkan |
|---|---|
| Di luar repo Git | Konfigurasi system dan global |
| Di dalam repo Git | Konfigurasi system, global, dan local (`.git/config`) |

Contoh di luar repo:

```
$ git config --list
user.name=Nama Lengkap di GitHub
user.email=email@domain.tld
init.defaultbranch=main
```

Contoh di dalam repo:

```
$ git config --list
user.name=Nama Lengkap di GitHub
user.email=email@domain.tld
init.defaultbranch=main
core.repositoryformatversion=0
core.filemode=true
core.bare=false
core.logallrefupdates=true
remote.origin.url=https://github.com/username/repo
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
branch.main.remote=origin
branch.main.merge=refs/heads/main
```

### Melihat asal setiap nilai

Berguna untuk *debugging*, karena menunjukkan nilai berasal dari file global atau local.

```
$ git config --list --show-origin
file:/home/user/.gitconfig      user.name=Nama Lengkap di GitHub
file:/home/user/.gitconfig      user.email=email@domain.tld
file:.git/config                core.bare=false
```

---

## Langkah 4: Konfigurasi Tambahan yang Direkomendasikan

### Nama branch awal

Git lama memakai `master` untuk repo baru. Agar sesuai dengan GitHub, gunakan `main`:

```
$ git config --global init.defaultBranch main
```

### Editor teks bawaan

Dipakai saat menulis pesan commit panjang atau saat *rebase*:

```
$ git config --global core.editor "nano"
$ git config --global core.editor "code --wait"   # VS Code
```

### Perilaku `git pull`

Git versi baru menampilkan peringatan jika strategi pull belum ditentukan. Pilih salah satu:

```
$ git config --global pull.rebase false   # merge (perilaku klasik)
$ git config --global pull.rebase true    # rebase
```

### Akhiran baris (line ending)

Penting jika bekerja lintas sistem operasi:

```
$ git config --global core.autocrlf true     # Windows
$ git config --global core.autocrlf input    # Linux/macOS
```

### Alias

Mempersingkat perintah yang sering dipakai:

```
$ git config --global alias.st status
$ git config --global alias.co checkout
$ git config --global alias.lg "log --oneline --graph --decorate"
```

Setelah itu, `git st` sama dengan `git status`.

### Penyimpanan kredensial

Agar tidak perlu mengetik ulang password/token:

| Helper | Perintah | Keterangan |
|---|---|---|
| `cache` | `git config --global credential.helper cache` | Linux, disimpan sementara di memori |
| `store` | `git config --global credential.helper store` | Disimpan permanen sebagai teks biasa (kurang aman) |
| `manager` | `git config --global credential.helper manager` | Windows, memakai Git Credential Manager |

---

## Konfigurasi Berbeda per Repo

Misalnya Anda memakai email kantor untuk proyek kantor dan email pribadi untuk proyek lain. Jalankan perintah **di dalam repo** tanpa `--global`:

```
$ cd proyek-kantor
$ git config user.name "Nama Lengkap di GitHub"
$ git config user.email "nama@kantor.co.id"
```

Nilai ini disimpan di `.git/config` dan hanya berlaku di repo tersebut.

---

## Mengubah, Menghapus, dan Mengedit Konfigurasi

| Tujuan | Perintah |
|---|---|
| Mengubah nilai | `git config --global user.email "emailbaru@domain.tld"` |
| Menghapus satu nilai | `git config --global --unset user.email` |
| Mengedit lewat editor | `git config --global --edit` |

---

## Mengatasi Error

Daftar singkat:

| No | Pesan error | Lompat ke |
|---|---|---|
| 1 | `Author identity unknown` | [Lihat](#1-author-identity-unknown) |
| 2 | `git: command not found` | [Lihat](#2-git-command-not-found) |
| 3 | `--local can only be used inside a git repository` | [Lihat](#3---local-can-only-be-used-inside-a-git-repository) |
| 4 | `could not lock config file ... File exists` | [Lihat](#4-could-not-lock-config-file--file-exists) |
| 5 | `could not lock config file: Permission denied` | [Lihat](#5-could-not-lock-config-file-permission-denied) |
| 6 | `bad config line` | [Lihat](#6-bad-config-line) |
| 7 | Nama/email salah di commit lama | [Lihat](#7-nama-atau-email-salah-pada-commit-yang-sudah-dibuat) |
| 8 | Commit tidak muncul di grafik GitHub | [Lihat](#8-commit-tidak-muncul-di-grafik-kontribusi-github) |
| 9 | Konfigurasi tidak sesuai harapan | [Lihat](#9-konfigurasi-yang-dipakai-tidak-sesuai-harapan) |
| 10 | `LF will be replaced by CRLF` | [Lihat](#10-lf-will-be-replaced-by-crlf) |
| 11 | `Authentication failed` saat push | [Lihat](#11-authentication-failed-saat-push) |
| 12 | Editor tidak terbuka | [Lihat](#12-editor-tidak-terbuka-atau-langsung-menutup) |

### 1. Author identity unknown

```
Author identity unknown
*** Please tell me who you are.
fatal: unable to auto-detect email address
```

- **Penyebab:** `user.name` dan `user.email` belum diatur.
- **Solusi:**

  ```
  $ git config --global user.name "Nama Lengkap di GitHub"
  $ git config --global user.email "email@domain.tld"
  ```

### 2. git: command not found

Muncul juga sebagai `'git' is not recognized` di Windows.

- **Penyebab:** Git belum terpasang atau belum masuk ke `PATH`.
- **Solusi:**

  | Sistem | Perintah |
  |---|---|
  | Debian/Ubuntu | `sudo apt install git` |
  | Fedora | `sudo dnf install git` |
  | macOS | `brew install git` |
  | Windows | Unduh dari [git-scm.com](https://git-scm.com/), pilih opsi *Git from the command line* saat instalasi, lalu tutup dan buka kembali terminal |

### 3. --local can only be used inside a git repository

```
fatal: --local can only be used inside a git repository
```

- **Penyebab:** perintah `git config` tingkat local dijalankan di luar repo.
- **Solusi:** pindah ke direktori repo (`cd nama-repo`), atau gunakan `--global` jika memang ingin konfigurasi untuk semua repo.

### 4. could not lock config file ... File exists

- **Penyebab:** ada file `.lock` sisa dari proses Git yang terhenti, misalnya `~/.gitconfig.lock`.
- **Solusi:** pastikan tidak ada proses Git lain yang berjalan, lalu hapus file lock:

  ```
  $ rm ~/.gitconfig.lock
  ```

  Untuk repo, file lock berada di `.git/config.lock`.

### 5. could not lock config file: Permission denied

- **Penyebab:** tidak ada izin menulis ke file konfigurasi, biasanya karena memakai `--system` tanpa hak administrator, atau `.gitconfig` dimiliki root.
- **Solusi:**
  - Gunakan `--global` alih-alih `--system`.
  - Jika file dimiliki root, perbaiki kepemilikannya:

    ```
    $ sudo chown $USER ~/.gitconfig
    ```

### 6. bad config line

```
fatal: bad config line N in file ...
```

- **Penyebab:** kesalahan sintaks di file konfigurasi, misalnya kurung siku tidak lengkap atau baris tidak valid, biasanya akibat pengeditan manual.
- **Solusi:** buka file yang disebut pada pesan error dan perbaiki baris ke-N:

  ```
  $ git config --global --edit
  ```

### 7. Nama atau email salah pada commit yang sudah dibuat

Mengubah konfigurasi **tidak** mengubah commit lama. Perbaikannya tergantung kasus:

**Commit terakhir saja:**

```
$ git commit --amend --reset-author --no-edit
```

**Beberapa commit terakhir** (misalnya 3 commit):

```
$ git rebase -i HEAD~3 --exec "git commit --amend --reset-author --no-edit"
```

> [!WARNING]
> Jika commit sudah di-*push*, mengubahnya berarti menulis ulang riwayat dan membutuhkan `git push --force-with-lease`. Lakukan hanya jika repo tidak dipakai bersama orang lain, atau sudah dikoordinasikan dengan tim.

### 8. Commit tidak muncul di grafik kontribusi GitHub

- **Penyebab:** email pada commit tidak terdaftar di akun GitHub Anda.
- **Solusi:**
  - Tambahkan email tersebut di *GitHub → Settings → Emails*, atau ganti `user.email` dengan email yang sudah terdaftar (termasuk email noreply).
  - Periksa bahwa `git config user.email` di repo itu menghasilkan nilai yang diharapkan, karena konfigurasi local bisa menimpa global.

### 9. Konfigurasi yang dipakai tidak sesuai harapan

- **Solusi:** periksa sumber nilainya:

  ```
  $ git config --show-origin user.email
  file:.git/config        nama@kantor.co.id
  ```

  Jika berasal dari `.git/config`, itu konfigurasi local yang menimpa global. Hapus dengan perintah berikut (tanpa `--global`) jika tidak diinginkan:

  ```
  $ git config --unset user.email
  ```

### 10. LF will be replaced by CRLF

```
warning: LF will be replaced by CRLF
```

- **Penyebab:** perbedaan akhiran baris antara Windows dan Linux/macOS. Ini peringatan, bukan error fatal.
- **Solusi:** atur `core.autocrlf` sesuai sistem operasi Anda (lihat [Langkah 4](#akhiran-baris-line-ending)).

### 11. Authentication failed saat push

Muncul juga sebagai `Support for password authentication was removed`.

- **Penyebab:** GitHub tidak lagi menerima password akun untuk operasi Git lewat HTTPS.
- **Solusi:** gunakan *Personal Access Token* sebagai pengganti password, atau gunakan SSH. Pastikan juga `credential.helper` sudah diatur agar token tersimpan.

### 12. Editor tidak terbuka atau langsung menutup

- **Penyebab:** `core.editor` menunjuk ke program yang tidak ada, atau editor GUI dipakai tanpa opsi tunggu.
- **Solusi:**

  ```
  $ git config --global core.editor "nano"
  ```

  Untuk VS Code, jangan lupa tambahkan `--wait`.

---

## Ringkasan Perintah

| Tujuan | Perintah |
|---|---|
| Atur nama | `git config --global user.name "Nama"` |
| Atur email | `git config --global user.email "email@domain.tld"` |
| Lihat satu nilai | `git config user.name` |
| Lihat semua konfigurasi | `git config --list` |
| Lihat asal konfigurasi | `git config --list --show-origin` |
| Edit file konfigurasi | `git config --global --edit` |
| Hapus nilai | `git config --global --unset user.email` |
| Atur nama branch awal | `git config --global init.defaultBranch main` |

Dengan konfigurasi ini, Git siap dipakai. Lanjutkan ke materi berikutnya pada [README.md](README.md).
