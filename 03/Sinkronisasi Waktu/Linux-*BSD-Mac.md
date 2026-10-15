# Praktikum Sistem Terdistribusi - Sinkronisasi Waktu (Chrony)

Repositori ini berisi dokumentasi praktikum **Sinkronisasi Waktu** pada mata kuliah Sistem Terdistribusi. Praktikum dilakukan di macOS 13 (Ventura) dengan menggunakan **chrony**, sebuah implementasi *Network Time Protocol* (NTP). Skrip instalasi tersedia di berkas [`kode instalasi`](./kode%20instalasi).

## 1. Latar Belakang

Pada sistem terdistribusi, setiap komputer (node) memiliki jam fisik sendiri yang dikendalikan oleh osilator kristal. Osilator ini tidak pernah benar-benar presisi, sehingga jam di tiap mesin mengalami *clock drift*, yaitu kecepatan jam yang sedikit lebih cepat atau lebih lambat dari waktu yang sebenarnya. Akibatnya, dua mesin yang awalnya menunjukkan waktu sama akan semakin berbeda seiring berjalannya waktu. Selisih waktu antara dua jam pada satu saat disebut *clock skew*.

Perbedaan waktu ini menimbulkan masalah nyata, misalnya urutan kejadian (event ordering) yang salah pada log terdistribusi, kegagalan autentikasi berbasis token atau sertifikat yang bergantung pada waktu, konflik versi pada basis data terdistribusi, serta kesulitan saat melacak error lintas server. Karena itu diperlukan mekanisme sinkronisasi waktu agar seluruh node memiliki acuan waktu yang sama atau minimal selisih yang dapat diterima.

## 2. Dasar Teori

**NTP (Network Time Protocol)** adalah protokol yang menyinkronkan jam komputer melalui jaringan dengan merujuk pada server waktu yang tersusun secara hirarkis. Hirarki tersebut dinyatakan dengan **stratum**. Stratum 0 adalah sumber waktu referensi seperti jam atom atau GPS, stratum 1 adalah server yang terhubung langsung dengan stratum 0, stratum 2 mengambil waktu dari stratum 1, dan seterusnya. Semakin besar angka stratum, semakin jauh sebuah mesin dari sumber waktu primer. Pada hasil praktikum ini, komputer klien berada di stratum 3 karena mengambil waktu dari server berstratum 2.

Untuk menghitung selisih waktu, klien mengirim paket permintaan dan server membalas dengan cap waktu. Dari empat cap waktu tersebut (waktu kirim klien, waktu terima server, waktu kirim server, dan waktu terima klien), klien menghitung *offset* (selisih jam klien terhadap server) dan *delay* (waktu tempuh bolak-balik jaringan). Offset inilah yang digunakan untuk mengoreksi jam lokal.

**Chrony** terdiri dari dua komponen: `chronyd` sebagai daemon yang berjalan di latar belakang dan melakukan sinkronisasi, serta `chronyc` sebagai antarmuka baris perintah untuk memantau dan mengendalikan daemon. Dibandingkan `ntpd`, chrony dikenal lebih cepat mencapai sinkronisasi dan lebih baik pada koneksi yang tidak stabil. Chrony mengoreksi jam dengan dua cara. Pertama, *slew*, yaitu mempercepat atau memperlambat jam secara halus agar waktu tidak melompat. Kedua, *step*, yaitu melompatkan jam langsung ke waktu yang benar, dilakukan dengan perintah `makestep`.

## 3. Alat dan Lingkungan

Praktikum menggunakan komputer macOS 13 (Ventura) dengan arsitektur Intel (prefix Homebrew `/usr/local`), Homebrew sebagai pengelola paket, dan chrony versi 4.9. Karena macOS 13 sudah tidak didukung Homebrew, konfigurasi ini termasuk **Tier 3**. Konsekuensinya, Homebrew tidak menyediakan bottle (paket biner siap pakai) untuk sebagian besar paket sehingga harus dikompilasi dari kode sumber. Proses ini memakan waktu lama; pada praktikum ini total waktu build mencapai sekitar satu setengah jam, dengan kontribusi terbesar dari `libunistring` (29 menit), `gettext` (28 menit), dan `python@3.15` (36 menit).

## 4. Langkah Instalasi

Sebelum menginstal, proses Homebrew yang mungkin masih berjalan dihentikan dan file unduhan yang tidak lengkap dibersihkan agar tidak terjadi konflik. Perintah `pkill -f "brew"` menghentikan proses brew yang menggantung. Pada log terlihat pesan `no matches found` untuk penghapusan `*.incomplete`; ini hanya berarti tidak ada file sisa unduhan sehingga aman diabaikan.

Selanjutnya chrony diinstal dengan `brew install chrony`. Homebrew akan menampilkan daftar paket yang akan dipasang, yaitu chrony 4.9 beserta 11 dependensi (libunistring, json-c, gettext, libidn2, libtasn1, nettle, python@3.15, meson, p11-kit, texinfo, dan gnutls) dan satu pembaruan dependensi (sqlite 3.53.4 menjadi 3.54.0). Setelah selesai, kita dapat memastikan biner terpasang dengan memeriksa `chronyd` di `/usr/local/sbin` dan `chronyc` di `/usr/local/bin`.

```bash
brew install chrony
ls /usr/local/sbin/chronyd /usr/local/bin/chronyc
```

Skrip lengkap beserta persiapan direktori tersedia di berkas `kode instalasi`.

## 5. Menjalankan Daemon

Menjalankan `chronyd` memerlukan hak akses root karena daemon harus mengatur jam sistem.

```bash
sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf
```

Pada percobaan pertama muncul galat `Could not open /var/run/chrony/chronyd.pid : No such file or directory`. Artinya direktori untuk menyimpan file PID dan socket komunikasi belum ada. Akibatnya `chronyc` juga gagal dengan pesan `506 Cannot talk to daemon`, karena `chronyc` berkomunikasi dengan `chronyd` melalui socket yang berada di direktori tersebut. Solusinya adalah membuat direktori yang dibutuhkan:

```bash
sudo mkdir -p /var/run/chrony /usr/local/var/run /usr/local/var/lib/chrony
sudo chmod 755 /var/run/chrony
```

Setelah direktori tersedia, daemon dapat dijalankan kembali. Opsi `-n` menjalankan `chronyd` di latar depan (foreground) sehingga log langsung tampil di terminal, berguna untuk debugging. Pada sesi terminal berikutnya muncul pesan `Another chronyd may already be running (pid=95047)`. Ini menandakan daemon sudah aktif dari percobaan sebelumnya, sehingga tidak perlu dijalankan lagi.

Karena di `/var/run` macOS isinya dikosongkan saat reboot, direktori `/var/run/chrony` harus dibuat ulang setiap kali komputer dinyalakan ulang sebelum daemon dijalankan.

## 6. Verifikasi dan Pemantauan

Setelah daemon berjalan, sinkronisasi diperiksa dengan tiga perintah utama.

```bash
chronyc sources -v     # daftar server waktu dan statusnya
chronyc tracking       # status sinkronisasi jam lokal
sudo chronyc makestep  # paksa koreksi jam seketika
```

### 6.1 Hasil `chronyc sources -v`

Perintah ini menampilkan empat server waktu yang digunakan:

| Server | Stratum | Status | Offset |
|---|---|---|---|
| waktos2.unpak.ac.id | 2 | `^-` tidak digabung | +27 ms |
| time.citra.net.id | 2 | `^-` tidak digabung | -12 ms |
| 172-235-254-88 (Linode) | 2 | `^*` **terpilih (best)** | -436 µs |
| jkt-tmd.caliph.dev | 2 | `^-` tidak digabung | -779 ms |

Simbol `^` berarti sumber adalah server, sedangkan `*` menandai sumber terbaik yang sedang dipakai sebagai acuan. Simbol `-` berarti sumber dikenali namun tidak digabungkan dalam perhitungan. Kolom `Reach 37` (oktal) menunjukkan bahwa server telah dijawab beberapa kali berturut-turut, sedangkan `Poll 6` berarti interval permintaan 2^6 = 64 detik. Server `jkt-tmd.caliph.dev` memiliki offset -779 ms dengan ketidakpastian +/- 859 ms, sehingga wajar tidak dipilih. Chrony memilih server dengan estimasi galat paling kecil, yaitu +/- 42 ms pada server Linode.

### 6.2 Hasil `chronyc tracking` (sebelum makestep)

Sinkronisasi mengacu pada server Linode dengan stratum 3 untuk komputer lokal. Nilai penting yang tercatat adalah `System time: 0.013657703 seconds fast of NTP time`, artinya jam komputer lebih cepat sekitar 13,7 ms dari waktu NTP. `Last offset` sebesar +0,0201 detik adalah selisih pengukuran terakhir, `Root delay` 0,0808 detik adalah total delay jaringan menuju sumber primer, dan `Update interval` 64,4 detik adalah jeda antar pembaruan. Nilai `Frequency` 321,424 ppm dan `Skew` 836,632 ppm tampak besar, tetapi ini normal karena daemon baru berjalan dan baru memiliki sedikit sampel. Seiring bertambahnya sampel, estimasi frekuensi akan stabil dan skew akan turun drastis.

### 6.3 Hasil setelah `sudo chronyc makestep`

Perintah `makestep` mengembalikan respons `200 OK`, dan pengecekan `chronyc tracking` berikutnya menunjukkan `System time: 0.000000000 seconds slow of NTP time`. Artinya selisih waktu telah dikoreksi menjadi nol dan jam komputer sudah selaras dengan server NTP. Setelah itu chrony melanjutkan penyesuaian halus (slew) secara otomatis.

## 7. Analisis

Praktikum menunjukkan bahwa jam komputer lokal dapat menyimpang puluhan milidetik dari waktu referensi, dan bahwa chrony mampu mengoreksinya dengan cepat. Penggunaan beberapa server sekaligus meningkatkan ketahanan: jika satu server lambat atau tidak akurat (seperti `jkt-tmd.caliph.dev` dengan delay besar), chrony cukup memilih sumber yang paling terpercaya. Terlihat pula bahwa akurasi sinkronisasi dibatasi oleh kualitas jaringan; ketidakpastian +/- 42 ms pada server terpilih mencerminkan latensi internet, bukan kelemahan algoritma.

Hal yang dipelajari dari kendala selama praktikum antara lain: (1) pada macOS lama, instalasi lewat Homebrew lambat karena kompilasi dari sumber; (2) kegagalan `brew link` pada `python@3.15` dan `texinfo` terjadi karena sudah ada berkas dengan nama sama di `/usr/local/bin` (misalnya Python 3.13 dari python.org dan `info` bawaan lain). Kegagalan ini tidak memengaruhi chrony karena kedua paket hanya dependensi saat proses build; (3) `chronyd` membutuhkan direktori runtime yang harus dibuat manual di macOS; dan (4) komentar setelah tanda `#` pada baris perintah di zsh interaktif tidak diabaikan secara default, sehingga `grep` menganggap kata-kata komentar sebagai nama berkas. Untuk menghindarinya, jangan sertakan komentar pada baris perintah, atau aktifkan `setopt interactive_comments`.

## 8. Kesimpulan

Sinkronisasi waktu merupakan fondasi penting dalam sistem terdistribusi karena banyak mekanisme (pengurutan kejadian, autentikasi, replikasi, pencatatan log) bergantung pada kesamaan acuan waktu. Dengan chrony, jam komputer berhasil disinkronkan ke server NTP berstratum 2 dengan offset akhir 0 detik setelah `makestep`. Hasil ini membuktikan bahwa NTP yang diimplementasikan melalui chrony efektif menjaga konsistensi waktu antar node dalam jaringan.

## 9. Perintah Berguna

```bash
chronyc sources -v        # status sumber waktu
chronyc sourcestats       # statistik tiap sumber
chronyc tracking          # status sinkronisasi
sudo chronyc makestep     # koreksi langsung
sudo pkill chronyd        # hentikan daemon
```

## 10. Referensi

- Materi kuliah Sistem Terdistribusi, E-Learning UTDI: https://elearning.utdi.ac.id/mod/resource/view.php?id=78171
- Dokumentasi chrony: https://chrony-project.org/documentation.html
- Dukungan Homebrew: https://docs.brew.sh/Support-Tiers
