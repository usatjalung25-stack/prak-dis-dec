# Modul 2 - Komunikasi Antar Proses pada Sistem Terdistribusi

Praktikum Sistem Terdistribusi dan Terdesentralisasi
Universitas Teknologi Digital Indonesia - Prodi Informatika

| | |
|---|---|
| **Nama** | USAT JALUNG |
| **NIM** | 255410017 |
| **Sistem Operasi** | MOS |

---

## Tugas 1 - Menampilkan proses yang ada pada komputer

Saya membuka **Task Manager** dengan menekan `Ctrl + Shift + Esc`, lalu masuk ke tab **Processes**. Di sana terlihat semua proses yang sedang berjalan di komputer saya. Proses dikelompokkan menjadi *Apps* (aplikasi yang saya buka) dan *Background processes* (proses latar belakang milik sistem operasi dan layanan lain). Setiap proses menampilkan penggunaan CPU, Memory, Disk, dan Network.

![Daftar proses pada Task Manager](images/task%20manager-01.png)

*Gambar 1. Daftar proses yang berjalan pada komputer saya (Task Manager).*

---

## Tugas 2 - Menjalankan aplikasi dan melihat proses yang dimunculkan

Saya menjalankan aplikasi **Google Chrome**, lalu melihat Task Manager lagi. Walaupun saya hanya membuka satu aplikasi, ternyata muncul **banyak proses** dengan nama yang sama. Saat grup aplikasi saya buka (expand), terlihat proses-proses terpisah untuk jendela utama, tab, dan *extension*. Artinya satu aplikasi bisa terdiri dari beberapa proses yang berjalan bersamaan dan saling berkomunikasi.

![Aplikasi dijalankan dan proses yang muncul](images/task%20manager-02.png)

*Gambar 2. Proses yang dimunculkan setelah saya menjalankan aplikasi.*

---

## Tugas 3 - Mematikan proses tanpa menutup aplikasi

Saya mencari cara untuk mematikan proses milik aplikasi tanpa menekan tombol close / exit pada jendela aplikasinya. Caranya: di Task Manager saya klik kanan pada proses aplikasi, lalu pilih **End task**. Dengan cara ini proses dihentikan paksa oleh sistem operasi, bukan ditutup oleh aplikasinya sendiri.

![Mematikan proses melalui Task Manager](images/task%20manager-03.png)

*Gambar 3. Saya mematikan proses aplikasi dengan End task.*

Selain lewat Task Manager, proses juga bisa dimatikan dengan perintah di Command Prompt:

```bat
tasklist                          :: melihat daftar proses
taskkill /IM chrome.exe /F        :: mematikan proses berdasarkan nama
taskkill /PID <PID> /F            :: mematikan proses berdasarkan PID
```

Setelah proses dimatikan, saya membuka aplikasi lagi (*restart*). Sistem operasi membuat proses baru dengan PID yang berbeda dari sebelumnya.

![Hasil setelah proses dimatikan dan dijalankan ulang](images/task%20manager-04.png)

*Gambar 4. Kondisi proses setelah dimatikan dan dijalankan kembali.*

---

## Tugas 4 - Penjelasan semua yang saya kerjakan

1. **Menampilkan proses.** Saya membuka Task Manager dan melihat tab *Processes* untuk mengetahui proses apa saja yang berjalan beserta penggunaan sumber dayanya (Gambar 1).
2. **Menjalankan aplikasi.** Saya membuka Google Chrome dan mengamati proses yang muncul. Satu aplikasi ternyata menghasilkan banyak proses (Gambar 2).
3. **Mematikan proses.** Saya mematikan proses aplikasi memakai *End task* di Task Manager, bukan dengan menutup jendela aplikasi. Perintah `taskkill` bisa dipakai untuk hal yang sama (Gambar 3).
4. **Menjalankan ulang.** Saya membuka aplikasi lagi dan melihat bahwa proses baru dibuat oleh sistem operasi (Gambar 4).

### Kesimpulan

Proses adalah hasil eksekusi program yang dikelola oleh sistem operasi, terdiri dari *executable code*, data, *resources*, dan informasi *state* (stack dan heap). Pada satu node, semua proses berada dalam kendali sistem operasi sehingga pembuatan, pemantauan, dan penghentian proses bisa dilakukan dengan mudah dan transparan bagi pengguna. Dari praktikum ini saya memahami bahwa satu aplikasi dapat terdiri dari banyak proses, dan proses dapat dihentikan langsung dari sistem operasi tanpa melalui aplikasinya.
