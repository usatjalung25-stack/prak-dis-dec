# Modul 6 — Distributed File System (HDFS)

**Praktikum Sistem Terdistribusi dan Terdesentralisasi**  
Program Studi Informatika — Universitas Teknologi Digital Indonesia

| Informasi | Detail |
| :--- | :--- |
| **Nama** | Usat Jalung |
| **Kelas** | IF1 |
| **Topik** | Instalasi Apache Hadoop 3.5.0 (pseudo-distributed) & Operasi Dasar HDFS |
| **Tanggal** | 06 November 2026 |
| **Penulis Modul** | Dr. Bambang Purnomosidi D. P. |
| **Sumber Materi** | Modul 6 - Praktikum Sistem Terdistribusi dan Terdesentralisasi, Prodi Informatika, UTDI |

---

## 📑 Daftar Isi
1. [Persyaratan Software](#-persyaratan-software)
2. [Unduh & Instalasi Apache Hadoop](#-unduh--instalasi-apache-hadoop)
3. [Instalasi pdsh & Konfigurasi SSH](#-instalasi-pdsh--konfigurasi-ssh)
4. [Konfigurasi Apache Hadoop](#-konfigurasi-apache-hadoop)
5. [Format NameNode & JAVA_HOME](#-format-namenode--java_home)
6. [Menjalankan Daemon HDFS](#-menjalankan-daemon-hdfs)
7. [Operasi File HDFS](#-operasi-file-hdfs)
8. [Tugas Praktikum](#-tugas-praktikum)
9. [Kesimpulan](#-kesimpulan)

---

## 📦 Persyaratan Software

Untuk mengerjakan materi pada petunjuk ini, beberapa distribusi software diperlukan:

| Software | Keterangan |
| :--- | :--- |
| **JDK** | Versi 17 dan/atau 21. Jika akan mengkompilasi Apache Hadoop, gunakan versi 17. JDK 17 untuk server, client boleh 17 atau 21. |
| **Apache Hadoop** | Versi 3.5.0 (rilis 2 April 2026). |
| **pdsh** | Parallel Distributed Shell. |
| **ssh / sshd** | Klien dan Server SSH. `sshd` harus telah dijalankan. |

> 💡 **Catatan:** Pada sistem Artix Linux + dinit sebagai init system, jalankan menggunakan `sudo dinitctl start sshd`. Jika menggunakan systemd: `sudo systemctl start ssh`.

---

## 📥 Unduh & Instalasi Apache Hadoop

### 1. Unduh Distribusi
Ambil distribusi Apache Hadoop di [https://hadoop.apache.org/releases.html](https://hadoop.apache.org/releases.html). Pilih **Binary download** untuk paket siap pakai.

![Halaman unduh Apache Hadoop](https://raw.githubusercontent.com/usatjalung25-stack/prak-dis-dec/2ee6aa575e7e5040d5f19b43675bd61e2c427787/06/image/01-Unduh%20Apache%20Hadoop.png)

### 2. Ekstraksi & Symbolic Link
