# Panduan Instalasi dan Konfigurasi Chrony di macOS (Homebrew)

Dokumen ini menjelaskan langkah-langkah instalasi, konfigurasi, dan pemecahan masalah (*troubleshooting*) untuk menjalankan NTP daemon **Chrony** di macOS menggunakan Homebrew.

---

## ⚠️ Peringatan & Prasyarat

Sebelum memulai, perhatikan beberapa hal berdasarkan lingkungan sistem:
1. **Versi macOS**: Dokumentasi ini berdasarkan macOS 13 (Ventura). Homebrew mengklasifikasikannya sebagai *Tier 3 Support*, sehingga beberapa dependensi akan dikompilasi dari sumber (*build from source*).
2. **Command Line Tools**: Pastikan sudah diperbarui. Jika muncul peringatan, jalankan:
   ```bash
   sudo rm -rf /Library/Developer/CommandLineTools
   sudo xcode-select --install
   ```
3. **Untrusted Tap**: Jika muncul peringatan `jostasik/tap`, Anda bisa mengabaikannya atau mempercayainya dengan: `brew trust jostasik/tap`.

---

## 📦 Langkah 1: Instalasi

1. Bersihkan proses atau cache Homebrew yang mungkin menggantung (opsional):
   ```bash
   pkill -f "brew"
   rm -f ~/Library/Caches/Homebrew/downloads/*.incomplete
   ```

2. Jalankan instalasi Chrony:
   ```bash
   brew install chrony
   ```
   > **Catatan:** Anda mungkin melihat peringatan `The brew link step did not complete successfully` pada dependensi seperti `python@3.15` atau `texinfo` karena konflik file dengan instalasi Python/Texinfo lain di sistem. **Abaikan saja**, karena formula `chrony` itu sendiri akan tetap terinstal dengan sukses.

---

## ⚙️ Langkah 2: Konfigurasi Direktori Sistem

Secara default, macOS tidak memiliki direktori yang dibutuhkan Chrony untuk menyimpan file PID. Jika Anda langsung menjalankannya, akan muncul error:  
`Could not open /var/run/chrony/chronyd.pid : No such file or directory`

**Solusi:** Buat direktori dan atur izin aksesnya:
```bash
sudo mkdir -p /var/run/chrony /usr/local/var/run /usr/local/var/lib/chrony
sudo chmod 755 /var/run/chrony
```

---

## 🚀 Langkah 3: Menjalankan Chrony Daemon

Jalankan daemon Chrony dengan hak akses administrator (`sudo`):
```bash
sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf
```
*(Tambahkan flag `-n` jika ingin menjalankannya di foreground untuk debugging: `sudo /usr/local/sbin/chronyd -n -f /usr/local/etc/chrony.conf`)*

---

## ✅ Langkah 4: Verifikasi Sinkronisasi Waktu

Gunakan `chronyc` (Chrony client) untuk memastikan waktu sudah tersinkronisasi.

### 1. Periksa Daftar Sumber Waktu (NTP Servers)
Jalankan perintah:
```bash
chronyc sources -v
```
**Contoh Output Sukses:**
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
> **Indikator Sukses:** Tanda `^*` di kolom `MS` (baris ke-3 pada contoh di atas) menandakan server tersebut adalah sumber waktu terbaik yang sedang aktif digunakan.

### 2. Paksa Sinkronisasi Langkah Waktu (Opsional)
Jika waktu sistem sangat melenceng, paksa penyesuaian segera:
```bash
sudo chronyc makestep
```
**Contoh Output:**
```text
200 OK
```

### 3. Periksa Status Pelacakan Waktu (Tracking)
Jalankan perintah:
```bash
chronyc tracking
```
**Contoh Output Sukses:**
```text
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
> **Indikator Sukses:** Baris `System time` menunjukkan `0.000000000 seconds` (atau nilai yang sangat mendekati nol), yang berarti waktu sistem Anda sudah sinkron sempurna dengan server NTP.

---

## 🔧 Troubleshooting (Pemecahan Masalah)

| Masalah / Error | Penyebab | Solusi |
| :--- | :--- | :--- |
| `506 Cannot talk to daemon` | Daemon `chronyd` tidak berjalan. | Pastikan sudah dijalankan dengan `sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf`. |
| `Could not open /var/run/chrony/chronyd.pid : No such file or directory` | Direktori PID belum dibuat. | Jalankan: `sudo mkdir -p /var/run/chrony` dan `sudo chmod 755 /var/run/chrony`. |
| `Another chronyd may already be running (pid=XXXX)` | Ada instance `chronyd` lain yang aktif. | Hentikan dulu dengan `sudo pkill -f chronyd`, lalu jalankan ulang. |
| Peringatan `brew link` gagal pada dependensi | Konflik file biner (misal: `python3`) dengan instalasi lain. | Aman untuk diabaikan selama `chrony` itu sendiri berhasil terinstal (`🍺`). |

---

## 💡 Tips Tambahan: Menjalankan Otomatis saat Startup
Karena macOS tidak menjalankan service Homebrew secara otomatis, Anda perlu membuat file *LaunchDaemon* agar `chronyd` berjalan setiap kali Mac dinyalakan.

1. Buat file `/Library/LaunchDaemons/org.tuxfamily.chrony.plist`
2. Isi dengan konfigurasi yang menunjuk ke `/usr/local/sbin/chronyd`
3. Muat dengan: `sudo launchctl load /Library/LaunchDaemons/org.tuxfamily.chrony.plist`

*(File konfigurasi utama Chrony dapat diedit di `/usr/local/etc/chrony.conf`)*
