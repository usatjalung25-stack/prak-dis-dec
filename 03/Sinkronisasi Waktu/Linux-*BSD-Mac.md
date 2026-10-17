# Praktikum Sistem Terdistribusi: Sinkronisasi Waktu dengan Chrony
**Mata Kuliah:** Praktikum Sistem Terdistribusi dan Terdesentralisasi                     
**Prodi:** Informatika — Universitas Teknologi Digital Indonesia                  

Dokumentasi praktikum **Sinkronisasi Waktu** menggunakan **chrony** (implementasi NTP) di **macOS 13 Ventura**.
Skrip perintah lengkap ada di berkas [`kode instalasi`](./kode%20instalasi).

## Daftar Isi

1. [Pengantar](#1-pengantar)
2. [Lingkungan Praktikum](#2-lingkungan-praktikum)
3. [Langkah Praktikum (Kode + Output)](#3-langkah-praktikum-kode--output)
4. [Masalah yang Muncul dan Cara Mengatasinya](#4-masalah-yang-muncul-dan-cara-mengatasinya)
5. [Pembahasan Hasil](#5-pembahasan-hasil)
6. [Kesimpulan](#6-kesimpulan)
7. [Perintah Cepat](#7-perintah-cepat)
8. [Referensi](#8-referensi)

---

## 1. Pengantar

### Mengapa waktu perlu disinkronkan?

Setiap komputer punya jam sendiri. Jam ini tidak pernah 100% akurat, ada yang sedikit lebih cepat dan ada yang lebih lambat. Penyimpangan ini disebut **clock drift**, dan selisih waktu antar dua komputer disebut **clock skew**.

Pada sistem terdistribusi, selisih waktu bisa menyebabkan:

- urutan kejadian di log salah,
- autentikasi (token, sertifikat) gagal karena waktu tidak cocok,
- konflik data pada basis data terdistribusi,
- sulit melacak error antar server.

Karena itu semua komputer perlu memakai acuan waktu yang sama.

### Istilah penting

| Istilah | Arti singkat |
|---|---|
| **NTP** | *Network Time Protocol*, protokol untuk menyamakan waktu lewat jaringan |
| **Chrony** | Program NTP, terdiri dari `chronyd` (daemon) dan `chronyc` (alat kontrol) |
| **Stratum** | Tingkat jarak dari sumber waktu asli. Stratum 0 = jam atom/GPS, makin besar angkanya makin jauh |
| **Offset** | Selisih jam komputer kita terhadap server waktu |
| **Delay** | Lama waktu tempuh paket bolak-balik ke server |
| **Slew** | Koreksi pelan-pelan (jam dipercepat/diperlambat sedikit), waktu tidak melompat |
| **Step** (`makestep`) | Koreksi langsung, jam dilompatkan ke waktu yang benar |
| **ppm** | *parts per million*, satuan untuk laju penyimpangan jam |

### Cara kerja singkat

1. Komputer kita (klien) mengirim permintaan waktu ke beberapa server NTP.
2. Server membalas dengan cap waktu.
3. Chrony menghitung offset dan delay dari cap waktu tersebut.
4. Chrony memilih server terbaik, lalu mengoreksi jam lokal.

---

## 2. Lingkungan Praktikum

| Komponen | Keterangan |
|---|---|
| Sistem operasi | macOS 13 (Ventura), arsitektur Intel |
| Pengelola paket | Homebrew (prefix `/usr/local`) |
| Aplikasi | chrony 4.9 |
| Status dukungan | **Tier 3** (Homebrew tidak lagi menyediakan bottle untuk macOS 13) |

Karena Tier 3, hampir semua paket **dikompilasi dari kode sumber**, sehingga instalasi memakan waktu sangat lama (sekitar 1,5 jam pada praktikum ini).

---

## 3. Langkah Praktikum (Kode + Output)

### Langkah 1: Hentikan proses brew yang menggantung

Tujuannya agar tidak bentrok dengan instalasi baru.

```bash
pkill -f "brew"
```

Perintah ini tidak menampilkan output kalau berhasil.

### Langkah 2: Bersihkan sisa unduhan

```bash
rm -f ~/Library/Caches/Homebrew/downloads/*.incomplete
```

Output:

```text
zsh: no matches found: /Users/danel/Library/Caches/Homebrew/downloads/*.incomplete
```

Artinya tidak ada file sisa unduhan. Ini **bukan masalah**, lanjut saja ke langkah berikutnya (lihat [Masalah 2](#masalah-2-no-matches-found-saat-rm)).

### Langkah 3: Instal chrony

```bash
brew install chrony
```

Output awal (daftar yang akan dipasang):

```text
==> Would install 1 formula:
chrony 4.9
==> Would install 11 dependencies for chrony:
libunistring  1.4.2
json-c        0.19
gettext       1.0
libidn2       2.3.8
libtasn1      4.21.0
nettle        4.0
python@3.15   3.15.0
meson         1.12.1
p11-kit       0.26.5
texinfo       7.3_1
gnutls        3.8.13_2
==> Would upgrade 1 dependency for chrony:
sqlite 3.53.4 -> 3.54.0
```

Output saat proses build (ringkas):

```text
🍺  /usr/local/Cellar/libunistring/1.4.2: 59 files, 5.9MB, built in 29 minutes
🍺  /usr/local/Cellar/json-c/0.19: 34 files, 361.8KB, built in 49 seconds
🍺  /usr/local/Cellar/gettext/1.0: 2,499 files, 34.8MB, built in 28 minutes
🍺  /usr/local/Cellar/libidn2/2.3.8: 80 files, 919.6KB
🍺  /usr/local/Cellar/libtasn1/4.21.0: 64 files, 664.4KB, built in 14 minutes
🍺  /usr/local/Cellar/nettle/4.0: 93 files, 2.8MB, built in 5 minutes
🍺  /usr/local/Cellar/sqlite/3.54.0: 13 files, 5.4MB, built in 1 minute 50 seconds
🍺  /usr/local/Cellar/python@3.15/3.15.0: 10,510 files, 259.2MB, built in 36 minutes
🍺  /usr/local/Cellar/meson/1.12.1: 269 files, 4.4MB
🍺  /usr/local/Cellar/p11-kit/0.26.5: 31 files, 4.5MB, built in 5 minutes
🍺  /usr/local/Cellar/texinfo/7.3_1: 530 files, 11.2MB, built in 7 minutes
🍺  /usr/local/Cellar/gnutls/3.8.13_2: 1,289 files, 10.9MB, built in 7 minutes
==> Installing chrony
🍺  /usr/local/Cellar/chrony/4.9: 11 files, 821.5KB, built in 22 seconds
```

Selama proses ini muncul beberapa **warning** dan **error `brew link`**. Semuanya dijelaskan di bagian [Masalah dan Solusi](#4-masalah-yang-muncul-dan-cara-mengatasinya). Yang penting, baris terakhir `chrony/4.9 ... built in 22 seconds` menandakan **chrony berhasil terpasang**.

### Langkah 4: Pastikan program terpasang

```bash
ls /usr/local/sbin/chronyd /usr/local/bin/chronyc
```

Output:

```text
/usr/local/bin/chronyc	/usr/local/sbin/chronyd
```

Kedua file ada, berarti instalasi berhasil.

### Langkah 5: Percobaan pertama menjalankan chronyd (GAGAL)

```bash
sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf
```

Output:

```text
Password:
Could not open /var/run/chrony/chronyd.pid : No such file or directory
```

Lalu dicek dengan `chronyc`:

```bash
sleep 10
chronyc sources -v
chronyc tracking
sudo chronyc makestep
```

Semuanya gagal dengan output yang sama:

```text
506 Cannot talk to daemon
```

Penyebab dan solusinya ada di [Masalah 5 dan 6](#masalah-5-could-not-open-varrunchronychronydpid).

### Langkah 6: Buat direktori yang dibutuhkan (SOLUSI)

```bash
sudo mkdir -p /var/run/chrony /usr/local/var/run /usr/local/var/lib/chrony
sudo chmod 755 /var/run/chrony
```

Tidak ada output kalau berhasil. Setelah itu daemon dijalankan ulang:

```bash
sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf
```

Jika daemon sudah aktif dari percobaan sebelumnya, akan muncul:

```text
Another chronyd may already be running (pid=95047), check /var/run/chrony/chronyd.pid
```

Pesan ini artinya **daemon sudah jalan**, jadi langsung lanjut ke verifikasi.

### Langkah 7: Lihat daftar sumber waktu

```bash
sleep 10
chronyc sources -v
```

Output:

```text
  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current best, '+' = combined, '-' = not combined,
| /             'x' = may be in error, '~' = too variable, '?' = unusable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^- waktos2.unpak.ac.id           2   6    37    35    +27ms[  +27ms] +/-  565ms
^- time.citra.net.id             2   6    37    35    -12ms[  -12ms] +/-   41ms
^* 172-235-254-88.ip.linode>     2   6    37    36   -436us[  +20ms] +/-   42ms
^- jkt-tmd.caliph.dev            2   6    37    35   -779ms[ -779ms] +/-  859ms
```

### Langkah 8: Cek status sinkronisasi (sebelum makestep)

```bash
chronyc tracking
```

Output:

```text
Reference ID    : ACEBFE58 (172-235-254-88.ip.linodeusercontent.com)
Stratum         : 3
Ref time (UTC)  : Thu Oct 15 12:45:05 2026
System time     : 0.013657703 seconds fast of NTP time
Last offset     : +0.020098928 seconds
RMS offset      : 0.020098928 seconds
Frequency       : 321.424 ppm fast
Residual freq   : +0.000 ppm
Skew            : 836.632 ppm
Root delay      : 0.080809571 seconds
Root dispersion : 0.036665339 seconds
Update interval : 64.4 seconds
Leap status     : Normal
```

### Langkah 9: Paksa koreksi waktu, lalu cek ulang

```bash
sudo chronyc makestep
chronyc tracking
```

Output:

```text
200 OK
Reference ID    : ACEBFE58 (172-235-254-88.ip.linodeusercontent.com)
Stratum         : 3
Ref time (UTC)  : Thu Oct 15 12:45:05 2026
System time     : 0.000000000 seconds slow of NTP time
Last offset     : +0.020098928 seconds
RMS offset      : 0.020098928 seconds
Frequency       : 321.424 ppm fast
Residual freq   : +0.000 ppm
Skew            : 836.632 ppm
Root delay      : 0.080809571 seconds
Root dispersion : 0.036732569 seconds
Update interval : 64.4 seconds
Leap status     : Normal
```

Perhatikan baris `System time`: sebelum `makestep` jam **lebih cepat 0,0137 detik**, sesudahnya **0,000000000 detik**. Jam sudah sinkron.

---

## 4. Masalah yang Muncul dan Cara Mengatasinya

Ringkasan semua masalah dalam praktikum ini:

| No | Pesan / Gejala | Serius? | Solusi singkat |
|---|---|---|---|
| 1 | `grep: #: No such file or directory` | Tidak | Jangan tulis komentar `#` di baris perintah zsh |
| 2 | `zsh: no matches found: ...*.incomplete` | Tidak | Abaikan, atau pakai `2>/dev/null` |
| 3 | Warning macOS 13, Tier 3, Command Line Tools | Tidak | Abaikan (opsional update CLT) |
| 4 | Warning `jostasik/tap` not trusted | Tidak | Abaikan, atau `brew untap jostasik/tap` |
| 5 | `Could not open /var/run/chrony/chronyd.pid` | **Ya** | Buat direktori dengan `mkdir -p` |
| 6 | `506 Cannot talk to daemon` | **Ya** | Pastikan daemon jalan, buat direktori, start ulang |
| 7 | `brew link step did not complete` (python, texinfo) | Tidak | Abaikan, jangan pakai `--overwrite` |
| 8 | `Another chronyd may already be running` | Tidak | Daemon sudah aktif, lanjut verifikasi |
| 9 | `Skew` dan `Frequency` tampak besar | Tidak | Normal di awal, tunggu beberapa menit |

### Masalah 1: `grep: #: No such file or directory`

**Gejala:**

```text
danel@1111QD-rs ~ % ps aux | grep -i "[b]rew"        # lihat proses brew yang masih jalan
grep: #: No such file or directory
grep: lihat: No such file or directory
grep: proses: No such file or directory
...
```

**Penyebab:** zsh interaktif secara bawaan **tidak mengabaikan komentar** `#` di baris perintah. Akibatnya kata-kata komentar dikirim ke `grep` sebagai nama file.

**Solusi (pilih salah satu):**

```bash
# a) Hapus komentar dari baris perintah
ps aux | grep -i "[b]rew"

# b) Atau aktifkan komentar di zsh interaktif
setopt interactive_comments
```

### Masalah 2: `no matches found` saat `rm`

**Gejala:**

```text
zsh: no matches found: /Users/danel/Library/Caches/Homebrew/downloads/*.incomplete
```

**Penyebab:** tidak ada file berakhiran `.incomplete`. zsh menganggap pola `*` yang tidak cocok sebagai error.

**Solusi:** abaikan saja karena memang tidak ada yang perlu dihapus. Kalau ingin pesan ini hilang:

```bash
setopt nonomatch
rm -f ~/Library/Caches/Homebrew/downloads/*.incomplete
```

### Masalah 3: Warning macOS 13 / Tier 3 / Command Line Tools

**Gejala:**

```text
Warning: You are using macOS 13.
We (and Apple) do not provide support for this old version.
Homebrew no longer builds bottles for this configuration.
...
Warning: A newer Command Line Tools release is available.
```

**Penyebab:** macOS 13 sudah terlalu lama sehingga Homebrew tidak lagi menyediakan paket jadi (bottle). Paket harus dikompilasi sendiri, dan inilah yang membuat instalasi lama.

**Solusi:** hanya peringatan, instalasi tetap jalan. Pilihan lain (opsional):

- Update Command Line Tools lewat *System Settings > Software Update*.
- Gunakan **MacPorts** yang masih menyediakan paket biner untuk macOS 13.
- Upgrade macOS bila perangkat mendukung.

### Masalah 4: Warning tap `jostasik/tap` tidak dipercaya

**Gejala:**

```text
Warning: The following taps are not trusted:
  jostasik/tap
Homebrew is currently ignoring formulae, casks and commands
from these taps because tap trust is required.
```

**Penyebab:** ada repositori tambahan (tap) di Homebrew yang belum dipercaya.

**Solusi:** tidak berpengaruh ke chrony, jadi boleh diabaikan. Pilihan lain:

```bash
brew untap jostasik/tap        # hapus tap jika tidak dipakai
brew trust jostasik/tap        # atau percayai jika memang dibutuhkan
```

### Masalah 5: `Could not open /var/run/chrony/chronyd.pid`

**Gejala:**

```text
Could not open /var/run/chrony/chronyd.pid : No such file or directory
```

**Penyebab:** `chronyd` perlu menulis file PID dan socket di `/var/run/chrony`, tetapi direktori itu belum ada. Di macOS, isi `/var/run` juga dikosongkan setiap restart.

**Solusi:**

```bash
sudo mkdir -p /var/run/chrony /usr/local/var/run /usr/local/var/lib/chrony
sudo chmod 755 /var/run/chrony
sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf
```

### Masalah 6: `506 Cannot talk to daemon`

**Gejala:**

```text
506 Cannot talk to daemon
```

**Penyebab:** `chronyc` (alat kontrol) tidak bisa menghubungi `chronyd` karena daemon belum berjalan atau gagal start (biasanya akibat Masalah 5).

**Solusi, ikuti urutan ini:**

```bash
# 1. Cek apakah chronyd berjalan
ps aux | grep [c]hronyd

# 2. Jika tidak ada, buat direktori lalu start daemon
sudo mkdir -p /var/run/chrony /usr/local/var/run /usr/local/var/lib/chrony
sudo chmod 755 /var/run/chrony
sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf

# 3. Tunggu lalu uji
sleep 10
chronyc tracking
```

> **Tips:** jika memakai `sudo /usr/local/sbin/chronyd -n ...` (mode foreground), terminal akan "terkunci" karena daemon berjalan di depan. Buka tab terminal baru untuk menjalankan `chronyc`, atau tekan `Ctrl+C` untuk menghentikannya.

### Masalah 7: `brew link step did not complete successfully`

**Gejala (python@3.15):**

```text
Error: The `brew link` step did not complete successfully
The formula built, but is not symlinked into /usr/local
Could not symlink bin/idle3
Target /usr/local/bin/idle3
already exists. You may want to remove it:
  rm '/usr/local/bin/idle3'
```

**Gejala (texinfo):** pesan serupa untuk `bin/info`.

**Penyebab:** di `/usr/local/bin` sudah ada file dengan nama sama, misalnya `python3` milik Python 3.13 dari python.org dan `info` bawaan sistem. Homebrew menolak menimpanya.

**Solusi:** **tidak perlu diperbaiki.** Python dan texinfo hanya dibutuhkan saat proses *build*, bukan untuk menjalankan chrony. Yang penting `brew install chrony` berakhir dengan `chrony/4.9 ... built`.

> **Jangan** menjalankan `brew link --overwrite python@3.15` kecuali paham risikonya. Perintah itu akan menimpa `python3` dan `pip3` Python 3.13 yang sedang dipakai, dan bisa merusak proyek lain.

### Masalah 8: `Another chronyd may already be running`

**Gejala:**

```text
Another chronyd may already be running (pid=95047), check /var/run/chrony/chronyd.pid
```

**Penyebab:** daemon sudah aktif dari percobaan sebelumnya, jadi tidak boleh dijalankan dua kali.

**Solusi:** lanjut ke verifikasi (`chronyc sources -v`). Jika ingin memulai ulang bersih:

```bash
sudo pkill chronyd
sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf
```

### Masalah 9: `Skew` dan `Frequency` terlihat sangat besar

**Gejala:**

```text
Frequency       : 321.424 ppm fast
Skew            : 836.632 ppm
```

**Penyebab:** daemon baru berjalan sehingga baru punya sedikit sampel pengukuran. Estimasinya masih kasar.

**Solusi:** tidak perlu apa-apa. Biarkan chrony berjalan beberapa menit sampai jam, lalu cek lagi dengan `chronyc tracking`. Nilai skew akan turun dan frekuensi menjadi stabil.

---

## 5. Pembahasan Hasil

### 5.1 Membaca hasil `chronyc sources`

| Server | Stratum | Simbol | Offset | Estimasi galat | Keterangan |
|---|---|---|---|---|---|
| waktos2.unpak.ac.id | 2 | `^-` | +27 ms | ±565 ms | Galat terlalu besar |
| time.citra.net.id | 2 | `^-` | -12 ms | ±41 ms | Cukup baik, tidak dipilih |
| 172-235-254-88 (Linode) | 2 | `^*` | -436 µs | ±42 ms | **Dipilih sebagai sumber terbaik** |
| jkt-tmd.caliph.dev | 2 | `^-` | -779 ms | ±859 ms | Offset dan galat sangat besar |

Cara membaca simbolnya:

- `^` berarti sumbernya berupa **server**.
- `*` berarti **sumber terbaik** yang sedang dipakai.
- `-` berarti sumber dikenal tetapi **tidak digabung** dalam perhitungan.
- `Reach 37` (oktal) berarti server sudah menjawab beberapa kali berturut-turut, jadi koneksinya sehat.
- `Poll 6` berarti jeda permintaan 2^6 = **64 detik**.

Chrony memilih server dengan estimasi galat paling kecil, bukan sekadar yang offset-nya paling kecil. Server `jkt-tmd.caliph.dev` jelas ditinggalkan karena offset -779 ms dan galatnya mencapai ±859 ms.

### 5.2 Membaca hasil `chronyc tracking`

| Baris | Nilai | Artinya |
|---|---|---|
| Reference ID | ACEBFE58 (Linode) | Server acuan yang sedang dipakai |
| Stratum | 3 | Komputer kita satu tingkat di bawah server stratum 2 |
| System time | 0,0137 detik *fast* | Jam komputer lebih cepat sekitar **13,7 ms** dari waktu NTP |
| Last offset | +0,0201 detik | Selisih pada pengukuran terakhir |
| Root delay | 0,0808 detik | Total delay jaringan sampai sumber utama |
| Update interval | 64,4 detik | Jeda antar pembaruan |
| Frequency / Skew | 321 ppm / 836 ppm | Masih kasar karena sampel sedikit (lihat Masalah 9) |
| Leap status | Normal | Tidak ada penyesuaian leap second |

### 5.3 Efek `makestep`

| Kondisi | System time |
|---|---|
| Sebelum `makestep` | 0,013657703 detik **lebih cepat** |
| Sesudah `makestep` | 0,000000000 detik |

Perintah `makestep` melakukan koreksi langsung (step), sehingga selisih 13,7 ms hilang seketika. Setelah itu chrony melanjutkan koreksi halus (slew) secara otomatis.

### 5.4 Pelajaran dari praktikum

1. **Akurasi dibatasi jaringan.** Galat ±42 ms pada server terpilih berasal dari latensi internet, bukan kelemahan chrony.
2. **Banyak server lebih tangguh.** Jika satu server buruk (seperti `jkt-tmd.caliph.dev`), chrony otomatis memilih yang lain.
3. **macOS lama = instalasi lambat.** Tier 3 membuat semua paket dikompilasi sendiri.
4. **Pesan error tidak selalu fatal.** Error `brew link` dan warning tap tidak memengaruhi hasil. Yang fatal hanya galat pada `chronyd`.
5. **macOS menghapus `/var/run` saat restart.** Buat ulang direktori chrony setiap reboot sebelum menjalankan daemon.

---

## 6. Kesimpulan

Sinkronisasi waktu penting pada sistem terdistribusi agar urutan kejadian, autentikasi, dan replikasi data berjalan benar. Dengan chrony, jam komputer berhasil disinkronkan ke server NTP berstratum 2 (server terpilih: Linode, galat ±42 ms). Selisih awal **13,7 ms** berhasil dikoreksi menjadi **0 detik** setelah `makestep`. Kendala selama praktikum, mulai dari direktori runtime yang belum ada hingga error `brew link`, semuanya dapat diatasi dengan langkah yang sudah didokumentasikan di atas.

---

## 7. Perintah Cepat

```bash
# Start daemon (buat direktori dulu setelah reboot)
sudo mkdir -p /var/run/chrony /usr/local/var/run /usr/local/var/lib/chrony
sudo chmod 755 /var/run/chrony
sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf

# Cek daemon
ps aux | grep [c]hronyd

# Monitoring
chronyc sources -v        # daftar server waktu
chronyc sourcestats       # statistik tiap sumber
chronyc tracking          # status sinkronisasi

# Koreksi langsung
sudo chronyc makestep

# Hentikan daemon
sudo pkill chronyd
```

---

## 8. Referensi

- Materi kuliah Sistem Terdistribusi, E-Learning UTDI: https://elearning.utdi.ac.id/mod/resource/view.php?id=78171
- Dokumentasi chrony: https://chrony-project.org/documentation.html
- Tingkat dukungan Homebrew: https://docs.brew.sh/Support-Tiers
