# Sinkronisasi Waktu dengan Chrony ke NTP Server

Dokumen ini menjelaskan cara memasang **Chrony** (<https://chrony-project.org/>), menggunakan perintah Chrony untuk sinkronisasi waktu ke NTP server, menjelaskan proses sinkronisasinya, dan mengatasi error yang umum muncul.

Panduan ini disusun dari pengalaman praktik di **macOS 13 (Ventura)** dengan Homebrew, dan dilengkapi jalur **Linux (Debian/Ubuntu)** sebagai pembanding, karena perintah `apt` dan `systemctl` hanya ada di Linux.

---

## Daftar Isi

1. [Pengantar](#1-pengantar)
2. [Instalasi Chrony](#2-instalasi-chrony)
3. [Konfigurasi](#3-konfigurasi)
4. [Menjalankan dan Sinkronisasi ke NTP Server](#4-menjalankan-dan-sinkronisasi-ke-ntp-server)
5. [Verifikasi dengan Perintah Chrony](#5-verifikasi-dengan-perintah-chrony)
6. [Pembahasan: Bagaimana Proses Sinkronisasi Bekerja](#6-pembahasan-bagaimana-proses-sinkronisasi-bekerja)
7. [Mengatasi Error (Troubleshooting)](#7-mengatasi-error-troubleshooting)
8. [Ringkasan Perintah](#8-ringkasan-perintah)

---

## 1. Pengantar

Chrony adalah implementasi NTP (Network Time Protocol) yang terdiri dari dua program:

| Komponen | Fungsi |
|----------|--------|
| `chronyd` | Daemon yang berjalan di latar belakang, berkomunikasi dengan NTP server dan menyetel jam sistem |
| `chronyc` | Program command-line untuk memantau dan mengendalikan `chronyd` |

Chrony dirancang agar cepat konvergen, akurat, dan tetap bekerja baik pada koneksi yang tidak stabil atau mesin yang sering tidur/mati.

---

## 2. Instalasi Chrony

### 2.1 Linux (Debian / Ubuntu)

```bash
sudo apt update
sudo apt install chrony -y
```

Cek layanan:

```bash
sudo systemctl enable --now chrony
sudo systemctl status chrony
```

### 2.2 macOS (Homebrew)

> **Penting:** `apt` **tidak ada** di macOS. Menjalankan `sudo apt install chrony` di macOS akan memunculkan pesan aneh seperti *"Unable to locate a Java Runtime that supports apt"*, karena macOS mencoba mencari program Java bernama `apt`. Gunakan Homebrew.

```bash
# 1. Pastikan Homebrew terpasang
brew --version

# 2. Pasang Chrony
brew install chrony
```

Hasil pengecekan versi Homebrew pada praktik:

![Cek versi Homebrew dengan perintah brew --version](images/01-brew-version.png)

Saat muncul pertanyaan `Do you want to proceed with the installation? [y/n]`, ketik `y` lalu Enter dan **tunggu sampai selesai**. Jangan menutup terminal atau menjalankan `brew install` kedua kali.

Pada macOS 13 ke bawah, Homebrew tidak lagi menyediakan *bottle* (paket biner siap pakai), sehingga Chrony dan dependensinya **dikompilasi dari source**. Proses ini bisa memakan waktu cukup lama dan membutuhkan **Xcode Command Line Tools**:

```bash
xcode-select --install
```

Jika Homebrew gagal atau terlalu lambat, alternatifnya adalah MacPorts (<https://www.macports.org>):

```bash
sudo port install chrony
```

Verifikasi hasil instalasi:

```bash
ls $(brew --prefix)/sbin/chronyd
ls $(brew --prefix)/bin/chronyc
chronyd --version
```

---

## 3. Konfigurasi

Lokasi file konfigurasi **berbeda** di tiap sistem:

| Sistem | Lokasi `chrony.conf` |
|--------|----------------------|
| Debian / Ubuntu | `/etc/chrony/chrony.conf` |
| macOS Intel (Homebrew) | `/usr/local/etc/chrony.conf` |
| macOS Apple Silicon (Homebrew) | `/opt/homebrew/etc/chrony.conf` |

> Perintah `sudo nano /etc/chrony/chrony.conf` di macOS hanya membuat file baru di jalur Linux yang **tidak dipakai** oleh Chrony versi Homebrew. Gunakan `$(brew --prefix)/etc/chrony.conf`.

### 3.1 Konfigurasi minimal (Indonesia)

Gunakan pool NTP Indonesia agar latensi rendah:

**Linux:** edit `/etc/chrony/chrony.conf`, ganti baris `pool ...` bawaan dengan:

```conf
pool id.pool.ntp.org iburst
makestep 1.0 3
rtcsync
```

**macOS:**

```bash
mkdir -p $(brew --prefix)/var/lib/chrony

cat > $(brew --prefix)/etc/chrony.conf << EOF
pool id.pool.ntp.org iburst
makestep 1.0 3
driftfile $(brew --prefix)/var/lib/chrony/chrony.drift
EOF
```

### 3.2 Arti setiap direktif

| Direktif | Arti |
|----------|------|
| `pool id.pool.ntp.org iburst` | Memakai kumpulan server NTP Indonesia. `iburst` mengirim beberapa paket cepat di awal agar sinkronisasi pertama lebih singkat |
| `makestep 1.0 3` | Jika selisih waktu lebih dari 1 detik, jam boleh **dilompatkan** langsung, tetapi hanya pada 3 pembaruan pertama |
| `rtcsync` | (Linux) menyinkronkan jam hardware/RTC secara berkala |
| `driftfile` | Menyimpan laju penyimpangan jam agar akurasi cepat pulih setelah restart |

---

## 4. Menjalankan dan Sinkronisasi ke NTP Server

### 4.1 Linux

```bash
sudo systemctl restart chrony
```

### 4.2 macOS

macOS tidak memakai `systemctl` (itu milik systemd/Linux), jadi `chronyd` dijalankan langsung:

```bash
sudo $(brew --prefix)/sbin/chronyd -f $(brew --prefix)/etc/chrony.conf
```

Untuk menghentikannya:

```bash
sudo pkill chronyd
```

### 4.3 Memaksa sinkronisasi segera

Setelah `chronyd` berjalan, jam dapat dipaksa langsung cocok dengan server tanpa menunggu penyesuaian bertahap:

```bash
sudo chronyc makestep
```

Output yang diharapkan: `200 OK`.

### 4.4 Alternatif cepat tanpa Chrony (macOS)

Jika Chrony belum terpasang, macOS punya `sntp` bawaan untuk sinkronisasi satu kali:

```bash
sudo sntp -sS id.pool.ntp.org
```

Contoh hasil dari praktik:

```
+0.451559 +/- 0.081563 id.pool.ntp.org 103.105.57.11
```

Tangkapan layar hasil praktik (baris terakhir adalah output `sntp`):

![Hasil sinkronisasi waktu dengan sntp ke id.pool.ntp.org](images/03-chronyd-not-found-sntp.png)

Artinya, jam lokal tertinggal sekitar **0,45 detik** dari server `103.105.57.11` (toleransi galat ±0,08 detik), dan nilai itu sudah dikoreksi pada jam sistem (opsi `-S` = *step*). `sntp` hanya sinkronisasi **sekali**, sedangkan Chrony menjaga sinkronisasi **terus-menerus**.

---

## 5. Verifikasi dengan Perintah Chrony

```bash
chronyc sources -v     # daftar server NTP dan statusnya
chronyc sourcestats    # statistik kualitas tiap sumber
chronyc tracking       # status sinkronisasi jam sistem saat ini
```

### 5.1 Membaca `chronyc sources -v`

Contoh:

```
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* 103.105.57.11                 2   6   377    34   +120us[ +150us] +/- 12ms
^+ 202.65.114.202                2   6   377    35    -80us[  -50us] +/- 15ms
```

| Kolom / Simbol | Arti |
|----------------|------|
| `^` | Sumber adalah server NTP |
| `*` | Server yang **sedang dipakai** sebagai acuan utama |
| `+` | Server cadangan yang dianggap baik dan digabungkan |
| `-` / `?` / `x` | Server dikecualikan / tidak terjangkau / dianggap salah |
| `Stratum` | Jarak dari sumber waktu referensi (semakin kecil semakin dekat) |
| `Poll` | Interval polling, dalam pangkat 2 detik (6 = 64 detik) |
| `Reach` | Riwayat 8 percobaan terakhir dalam oktal; `377` artinya semua berhasil |
| `LastRx` | Detik sejak sampel terakhir diterima |

### 5.2 Membaca `chronyc tracking`

Contoh:

```
Reference ID    : 6769390B (103.105.57.11)
Stratum         : 3
System time     : 0.000012345 seconds fast of NTP time
Last offset     : +0.000008123 seconds
RMS offset      : 0.000021000 seconds
Frequency       : 12.345 ppm slow
Leap status     : Normal
```

Yang perlu diperhatikan: `System time` (selisih jam saat ini terhadap NTP, idealnya di bawah beberapa milidetik), `Leap status` bernilai `Normal`, dan `Reference ID` bukan `00000000` (jika 0, berarti belum tersinkron).

---

## 6. Pembahasan: Bagaimana Proses Sinkronisasi Bekerja

Sinkronisasi waktu dimulai ketika `chronyd` membaca file konfigurasi dan menemukan direktif `pool id.pool.ntp.org iburst`. Nama `id.pool.ntp.org` di-resolve melalui DNS menjadi beberapa alamat IP server NTP di Indonesia, dan `chronyd` memilih beberapa di antaranya sebagai sumber. Karena opsi `iburst` aktif, Chrony mengirim sekelompok paket permintaan secara cepat pada awal koneksi, sehingga ia punya cukup sampel untuk menilai kualitas setiap server tanpa menunggu menit-menitan. Setelah itu, interval polling dinaikkan secara bertahap, misalnya dari 64 detik hingga ribuan detik, selama sumber terbukti stabil.

Setiap kali berkomunikasi, `chronyd` mencatat empat cap waktu: waktu klien mengirim permintaan (T1), waktu server menerimanya (T2), waktu server membalas (T3), dan waktu klien menerima balasan (T4). Dari keempatnya, Chrony menghitung dua besaran utama. **Offset** adalah perkiraan selisih antara jam lokal dan jam server, dihitung sebagai `((T2 − T1) + (T3 − T4)) / 2`. **Delay** adalah total waktu perjalanan pulang-pergi jaringan, dihitung sebagai `(T4 − T1) − (T3 − T2)`. Rumus ini mengasumsikan jalur jaringan simetris, sehingga delay yang kecil dan stabil menghasilkan estimasi offset yang lebih dapat dipercaya. Itulah sebabnya server yang dekat secara jaringan, seperti pool Indonesia, biasanya memberi hasil lebih baik.

Dari kumpulan sampel tersebut, Chrony menjalankan algoritma seleksi untuk membuang server yang menyimpang (disebut *falseticker*) dan menggabungkan server yang konsisten (*truechimer*). Server yang terpilih sebagai acuan utama ditandai `*` pada `chronyc sources`, sedangkan server cadangan ditandai `+`. Dengan memakai beberapa sumber sekaligus, jam sistem tidak bergantung pada satu server yang mungkin salah atau terganggu.

Setelah estimasi offset diperoleh, Chrony harus mengoreksi jam sistem, dan ada dua cara. Cara pertama adalah **slew**, yaitu mempercepat atau memperlambat laju jam sedikit demi sedikit sampai selisihnya hilang. Cara ini aman karena waktu tidak pernah melompat atau mundur, sehingga aplikasi seperti database, log, dan sertifikat tidak terganggu. Cara kedua adalah **step**, yaitu langsung melompatkan jam ke nilai yang benar. Direktif `makestep 1.0 3` mengatur bahwa lompatan hanya diizinkan bila selisih lebih dari 1 detik dan hanya pada 3 pembaruan pertama setelah `chronyd` dijalankan; setelah itu Chrony hanya memakai slew. Perintah manual `chronyc makestep` memaksa lompatan itu segera. Pada contoh praktik, `sntp -sS` menemukan offset +0,45 detik dan langsung melakukan step, sedangkan Chrony dalam kondisi yang sama akan melakukan step jika selisihnya melebihi ambang, atau slew jika masih di bawah ambang.

Terakhir, Chrony terus mengukur seberapa cepat atau lambat jam hardware berjalan dibanding waktu sebenarnya, yang disebut **frekuensi drift** dan dinyatakan dalam ppm (bagian per sejuta). Nilai ini disimpan di `driftfile`, sehingga setelah komputer di-restart Chrony langsung memakai kompensasi yang sudah diketahui dan tidak perlu belajar dari nol. Kombinasi pemilihan sumber, koreksi bertahap, dan kompensasi drift inilah yang membuat Chrony mampu menjaga selisih waktu pada kisaran milidetik, bahkan mikrodetik pada jaringan yang baik.

> **Catatan macOS:** macOS sudah memiliki layanan sinkronisasi waktu bawaan (`timed`, aktif jika *Set time and date automatically* dinyalakan di System Settings). Menjalankan `chronyd` bersamaan dengan `timed` dapat membuat dua layanan menyetel jam secara bersamaan. Untuk pengujian ini hal itu tidak masalah, tetapi untuk penggunaan jangka panjang sebaiknya pilih salah satu.

---

## 7. Mengatasi Error (Troubleshooting)

Bagian ini memuat error yang benar-benar muncul pada praktik, lalu error umum lainnya.

### 7.1 `Unable to locate a Java Runtime that supports apt`

**Penyebab:** Perintah `apt` tidak ada di macOS, jadi macOS mengira itu program Java.
**Solusi:** Di macOS pakai `brew install chrony`. `apt` hanya untuk Debian/Ubuntu.

### 7.2 `sudo: systemctl: command not found`

**Penyebab:** `systemctl` adalah bagian dari systemd (Linux), tidak tersedia di macOS.
**Solusi (macOS):** jalankan daemon langsung:

```bash
sudo $(brew --prefix)/sbin/chronyd -f $(brew --prefix)/etc/chrony.conf
```

### 7.3 `zsh: command not found: chronyc` / `chronyd: command not found`

**Penyebab:** Chrony belum terpasang (instalasi gagal atau belum selesai), atau lokasinya tidak ada di `PATH`.
**Solusi:**

```bash
# Cek apakah sudah terpasang
brew list chrony
ls $(brew --prefix)/sbin/chronyd $(brew --prefix)/bin/chronyc

# Jika terpasang tapi tidak ditemukan, tambahkan ke PATH
echo 'export PATH="$(brew --prefix)/bin:$(brew --prefix)/sbin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Jika belum terpasang, ulangi instalasi (lihat 7.4)
brew install chrony
```

### 7.4 `Error: chrony: A 'brew install chrony' process has already locked /usr/local/Cellar/chrony`

![Error brew install chrony: proses lain telah mengunci Cellar chrony](images/02-brew-install-error.png)

**Penyebab:** Ada proses `brew install chrony` lain yang masih berjalan (misalnya di tab terminal lain, atau sesi sebelumnya yang masih menunggu jawaban `[y/n]`).
**Solusi:**

```bash
# 1. Lihat proses brew yang masih berjalan
ps aux | grep -i "[b]rew"

# 2. Hentikan proses tersebut (ganti PID sesuai hasil di atas)
kill <PID>
# atau hentikan semua proses brew
pkill -f brew

# 3. Bersihkan sisa lock bila perlu
rm -f ~/Library/Caches/Homebrew/downloads/*.incomplete
brew cleanup

# 4. Ulangi instalasi
brew install chrony
```

Jika menunggu di prompt `[y/n]`, ketik `y`. Jangan menjalankan `brew install` kedua sebelum yang pertama selesai.

### 7.5 `sudo: /usr/local/sbin/chronyd: command not found`

![Error chronyd dan chronyc command not found pada terminal macOS](images/03-chronyd-not-found-sntp.png)

**Penyebab:** Akibat error 7.4, Chrony belum benar-benar terpasang, sehingga file `chronyd` belum ada.
**Solusi:** Selesaikan instalasi terlebih dahulu (7.4), lalu cek `ls $(brew --prefix)/sbin/chronyd`.

### 7.6 Peringatan Homebrew di macOS 13 (Tier 3)

```
Warning: You are using macOS 13.
Homebrew no longer builds bottles for this configuration.
```

**Arti:** Paket tidak tersedia dalam bentuk biner, jadi dikompilasi dari source: lebih lama dan bisa gagal pada dependensi tertentu.
**Solusi:**

- Pastikan Xcode Command Line Tools terpasang: `xcode-select --install`
- Bersabar, kompilasi `python@3.15`, `gnutls`, dan `gettext` bisa lama
- Jika tetap gagal, perbarui macOS, atau pakai MacPorts: `sudo port install chrony`
- Sebagai solusi sementara, pakai `sudo sntp -sS id.pool.ntp.org`

### 7.7 Peringatan `The following taps are not trusted: jostasik/tap`

**Arti:** Ada tap Homebrew pihak ketiga yang belum dipercaya sehingga diabaikan. Ini **bukan** penyebab kegagalan instalasi Chrony.
**Solusi:** Jika tap itu tidak dipakai, hapus: `brew untap jostasik/tap`. Jika diperlukan, percayai dengan `brew trust jostasik/tap`.

### 7.8 `zsh: number expected`

**Penyebab:** Komentar yang diketik di baris perintah (`# /opt/homebrew ... atau /usr/local ...`) ikut ditafsirkan zsh karena komentar interaktif tidak aktif.
**Solusi:** Jangan salin teks setelah tanda `#`, atau aktifkan: `setopt interactive_comments`.

### 7.9 `506 Cannot talk to daemon` (`chronyc`)

**Penyebab:** `chronyd` tidak berjalan.
**Solusi:**

```bash
# Linux
sudo systemctl start chrony

# macOS
sudo $(brew --prefix)/sbin/chronyd -f $(brew --prefix)/etc/chrony.conf
```

### 7.10 `chronyc sources` kosong atau `Reach` bernilai `0`

**Penyebab:** Tidak ada koneksi ke server NTP: DNS gagal, firewall memblokir UDP port 123, atau konfigurasi salah.
**Solusi:**

```bash
# Tes DNS
nslookup id.pool.ntp.org

# Tes server secara langsung
sudo sntp -d id.pool.ntp.org

# Periksa isi konfigurasi
cat $(brew --prefix)/etc/chrony.conf    # macOS
cat /etc/chrony/chrony.conf             # Linux
```

Pastikan firewall atau jaringan kampus/kantor mengizinkan **UDP 123 keluar**. Jika `id.pool.ntp.org` bermasalah, coba pool lain seperti `pool 2.asia.pool.ntp.org iburst` atau `server time.google.com iburst`.

### 7.11 `Reference ID: 00000000` atau `Leap status: Not synchronised`

**Penyebab:** Belum ada sumber yang terpilih, biasanya karena `chronyd` baru dijalankan.
**Solusi:** Tunggu 1–2 menit lalu cek lagi `chronyc tracking`. Jika tetap gagal, periksa langkah 7.10. Anda bisa memaksa dengan `sudo chronyc makestep` setelah sumber muncul.

### 7.12 Jam tetap melenceng jauh

**Penyebab:** Selisih besar tetapi `makestep` hanya berlaku pada pembaruan awal.
**Solusi:**

```bash
sudo chronyc makestep
```

Atau restart `chronyd` agar ambang `makestep` berlaku lagi.

### 7.13 Error saat mengedit konfigurasi (`Permission denied`)

**Solusi:** Gunakan `sudo` saat mengedit file di folder sistem, atau pastikan direktori tujuan ada (`mkdir -p`).

---

## 8. Ringkasan Perintah

| Tujuan | Linux | macOS |
|--------|-------|-------|
| Pasang | `sudo apt install chrony` | `brew install chrony` |
| Konfigurasi | `/etc/chrony/chrony.conf` | `$(brew --prefix)/etc/chrony.conf` |
| Jalankan | `sudo systemctl restart chrony` | `sudo $(brew --prefix)/sbin/chronyd -f $(brew --prefix)/etc/chrony.conf` |
| Lihat sumber | `chronyc sources -v` | `chronyc sources -v` |
| Lihat status | `chronyc tracking` | `chronyc tracking` |
| Paksa sinkron | `sudo chronyc makestep` | `sudo chronyc makestep` |
| Sinkron sekali (alternatif) | `sudo chronyd -q 'pool id.pool.ntp.org iburst'` | `sudo sntp -sS id.pool.ntp.org` |
| Hentikan | `sudo systemctl stop chrony` | `sudo pkill chronyd` |

---

## Referensi

- Chrony: <https://chrony-project.org/>
- Dokumentasi Chrony: <https://chrony-project.org/documentation.html>
- NTP Pool Project: <https://www.pool.ntp.org/>
- Homebrew Support Tiers: <https://docs.brew.sh/Support-Tiers>
