# Modul 6 — Distributed File System (HDFS)

**Praktikum Sistem Terdistribusi dan Terdesentralisasi**
Program Studi Informatika — Universitas Teknologi Digital Indonesia

| Keterangan | Isi |
|---|---|
| Nama | Usat Jalung |
| Kelas | IF1 |
| Modul | 6 — Distributed File System (HDFS) |
| Perangkat lunak | Apache Hadoop 3.5.0, JDK 17, pdsh, OpenSSH |
| Penulis modul | Dr. Bambang Purnomosidi D. P. |

---

## Daftar Isi

0. [Persyaratan Software](#0-persyaratan-software)
1. [Unduh Apache Hadoop](#1-unduh-apache-hadoop)
2. [Instalasi Apache Hadoop](#2-instalasi-apache-hadoop)
3. [Instalasi pdsh dan Konfigurasi SSH](#3-instalasi-pdsh-dan-konfigurasi-ssh)
4. [Konfigurasi Apache Hadoop](#4-konfigurasi-apache-hadoop)
5. [Format NameNode](#5-format-namenode)
6. [Atur Konfigurasi JAVA_HOME](#6-atur-konfigurasi-java_home)
7. [Jalankan Daemon HDFS](#7-jalankan-daemon-hdfs)
8. [Selesai: Operasi File di HDFS](#8-selesai-operasi-file-di-hdfs)
9. [Tugas](#9-tugas)
10. [Kesimpulan](#10-kesimpulan)

---

## Gambaran Umum

**HDFS (Hadoop Distributed File System)** adalah sistem berkas terdistribusi milik Apache Hadoop. Berkas dipecah menjadi blok-blok, lalu disimpan pada beberapa node. Ada tiga komponen utama yang dijalankan pada praktikum ini:

| Komponen | Fungsi |
|---|---|
| **NameNode** | Menyimpan metadata (struktur direktori dan lokasi blok) |
| **DataNode** | Menyimpan blok data yang sebenarnya |
| **Secondary NameNode** | Membantu NameNode membuat checkpoint metadata |

Praktikum ini memakai mode **pseudo-distributed**, yaitu semua daemon berjalan di satu mesin (`localhost`).

---

## 0. Persyaratan Software

Software yang diperlukan:

- **JDK versi 17 dan/atau 21.** JDK 17 dipakai untuk server, sedangkan client dapat memakai JDK 17 atau 21.
- **Apache Hadoop 3.5.0** (rilis 2 April 2026).
- **pdsh** (*Parallel Distributed Shell*).
- **ssh** dan **sshd** yang sudah berjalan.

Perintah untuk menjalankan `sshd`:

```bash
# Jika memakai systemd
sudo systemctl start ssh

# Jika memakai dinit (Artix Linux)
sudo dinitctl start sshd
```

**Penjelasan:** Hadoop memakai SSH untuk menjalankan daemon pada setiap node, sehingga layanan `sshd` wajib aktif sebelum HDFS dijalankan. Perintah `systemctl start ssh` mengaktifkan layanan tersebut pada distro berbasis systemd.

Pemeriksaan versi Java:

```bash
java -version
```

📷 **Gambar 0 — Versi Java**

![Gambar 0 - Versi Java](images/00-java-version.png)

**Penjelasan output:** Output menampilkan versi JDK yang terpasang. Versi `17.x` menunjukkan syarat JDK sudah terpenuhi.

---

## 1. Unduh Apache Hadoop

Distribusi Apache Hadoop diambil dari halaman resmi: <https://hadoop.apache.org/releases.html>

Pilih versi **3.5.0** pada kolom *Binary download* (`binary` untuk arsitektur x86_64, `binary-aarch64` untuk ARM).

📷 **Gambar 1 — Halaman unduhan Apache Hadoop**

![Gambar 1 - Halaman unduhan Hadoop](images/01-unduh-hadoop.png)

**Penjelasan:** Tabel pada halaman tersebut memuat versi, tanggal rilis, tautan *source*, dan tautan *binary*. File yang diunduh berbentuk `hadoop-3.5.0.tar.gz`. Tautan *checksum signature* dapat dipakai untuk memverifikasi keaslian file.

---

## 2. Instalasi Apache Hadoop

### 2.1 Ekstraksi file

```bash
cd ~/software/storage/
tar -xvf ~/master/data-engineering/apache-hadoop/hadoop-3.5.0.tar.gz
ln -s hadoop-3.5.0 hadoop
```

**Penjelasan kode:**

| Perintah | Fungsi |
|---|---|
| `cd ~/software/storage/` | Pindah ke direktori tujuan instalasi |
| `tar -xvf ...` | Mengekstrak arsip (`x` ekstrak, `v` tampilkan proses, `f` file arsip) |
| `ln -s hadoop-3.5.0 hadoop` | Membuat *symbolic link* `hadoop` yang menunjuk ke `hadoop-3.5.0`, sehingga jika berganti versi cukup mengubah link-nya |

📷 **Gambar 2 — Hasil ekstraksi dan symbolic link**

![Gambar 2 - Hasil ekstraksi](images/02-ekstraksi-hadoop.png)

**Penjelasan output:** Pada hasil `ls -l` terlihat `hadoop -> hadoop-3.5.0`, yang berarti *symbolic link* berhasil dibuat. Lokasi ini selanjutnya disebut `$HADOOP_HOME`, yaitu `$HOME/software/storage/hadoop`.

### 2.2 Konfigurasi variabel lingkungan PATH

Isi file `~/env/bash/storage/hadoop.sh`:

```bash
export PATH="$HOME/software/storage/hadoop/bin:$HOME/software/storage/hadoop/sbin:$PATH"
```

📷 **Gambar 3 — Isi file hadoop.sh**

![Gambar 3 - Isi file hadoop.sh](images/03-env-hadoop-sh.png)

**Penjelasan:** Baris `export PATH=...` menambahkan direktori `bin` dan `sbin` milik Hadoop ke `PATH`. Dengan begitu perintah `hadoop`, `hdfs`, `start-dfs.sh`, dan `stop-dfs.sh` dapat dijalankan dari direktori mana pun.

Aktifkan konfigurasi pada setiap terminal baru:

```bash
source ~/env/bash/storage/hadoop.sh
```

### 2.3 Verifikasi instalasi

```bash
hadoop
```

📷 **Gambar 4 — Output perintah `hadoop`**

![Gambar 4 - Output perintah hadoop](images/04-hadoop-command.png)

**Penjelasan output:**

- Sebelum `source`, terminal menampilkan `bash: hadoop: command not found`, karena `PATH` belum memuat direktori Hadoop.
- Setelah `source`, perintah `hadoop` menampilkan *usage* beserta daftar subcommand (misalnya `fs`, `classpath`, `distcp`, `version`). Ini menandakan Hadoop terpasang dengan benar.

---

## 3. Instalasi pdsh dan Konfigurasi SSH

### 3.1 Instalasi pdsh

Sebagian besar distro Linux menyediakan paket `pdsh`. Pada Artix Linux, `pdsh` dikompilasi dari AUR memakai `trizen`.

```bash
trizen -Ss pdsh     # mencari paket
trizen -S pdsh      # memasang paket
```

Untuk distro lain, sesuaikan dengan manajer paket yang dipakai, misalnya:

```bash
sudo apt install pdsh     # Debian/Ubuntu
```

📷 **Gambar 5 — Pencarian paket pdsh**

![Gambar 5 - Pencarian pdsh](images/05-trizen-cari-pdsh.png)

**Penjelasan output:** `trizen -Ss pdsh` menampilkan paket `pdsh 2.36-1` dari AUR beserta varian `pdsh-genders`.

📷 **Gambar 6 — Proses build dan instalasi pdsh**

![Gambar 6 - Build pdsh](images/06-trizen-build-pdsh.png)

![Gambar 7 - Instalasi pdsh selesai](images/07-trizen-install-pdsh.png)

**Penjelasan output:** Terlihat berkas `PKGBUILD` diperbarui ke versi 2.36, kemudian paket dibuat (`Creating package "pdsh"`) dan dipasang oleh `pacman` (`installing pdsh`). Ukuran terpasang sekitar 0,48 MiB.

### 3.2 Pemeriksaan pdsh

```bash
pdsh -q -w localhost
```

📷 **Gambar 8 — Output `pdsh -q -w localhost`**

![Gambar 8 - Output pdsh](images/08-pdsh-query.png)

**Penjelasan kode:** Opsi `-q` menampilkan konfigurasi tanpa menjalankan perintah, sedangkan `-w localhost` menentukan target node.

**Penjelasan output:** Bagian yang penting adalah `Rcmd type: ssh`, yang berarti `pdsh` memakai SSH, dan `Target nodes: localhost`.

Jika `Rcmd type` bukan `ssh`, atur variabel lingkungan:

```bash
export PDSH_RCMD_TYPE=ssh
```

### 3.3 Konfigurasi SSH tanpa password

```bash
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
```

**Penjelasan kode:**

| Perintah | Fungsi |
|---|---|
| `ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa` | Membuat pasangan kunci RSA tanpa *passphrase* |
| `cat ...id_rsa.pub >> ...authorized_keys` | Mendaftarkan kunci publik sebagai kunci yang diizinkan login |
| `chmod 0600 ~/.ssh/authorized_keys` | Membatasi hak akses file agar hanya pemilik yang dapat membaca dan menulis |

Uji koneksi:

```bash
ssh localhost
```

📷 **Gambar 9 — Pembuatan kunci dan uji `ssh localhost`**

![Gambar 9 - Konfigurasi SSH](images/09-ssh-keygen-localhost.png)

**Penjelasan output:**

- `ssh-keygen` menampilkan lokasi kunci privat/publik, *fingerprint*, dan gambar *randomart*.
- Pada koneksi pertama muncul pertanyaan *"Are you sure you want to continue connecting"*. Jawab `yes`, maka `localhost` ditambahkan ke daftar *known hosts*.
- Pada koneksi berikutnya login langsung berhasil tanpa password. Hal ini diperlukan karena skrip `start-dfs.sh` memakai SSH untuk menjalankan daemon. Ketik `exit` untuk keluar (muncul `logout`).

---

## 4. Konfigurasi Apache Hadoop

Seluruh file konfigurasi berada di `$HADOOP_HOME/etc/hadoop/`.

### 4.1 `hdfs-site.xml`

```xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
```

**Penjelasan:** `dfs.replication` menentukan jumlah salinan setiap blok data. Karena hanya ada satu DataNode, nilainya `1`.

### 4.2 `core-site.xml`

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.proxyuser.yourusername.groups</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.yourusername.hosts</name>
        <value>*</value>
    </property>
</configuration>
```

**Penjelasan:**

- `fs.defaultFS` adalah alamat *filesystem* bawaan, yaitu NameNode pada `localhost` port `9000`.
- Dua properti `hadoop.proxyuser.*` mengizinkan pengguna tertentu bertindak sebagai *proxy user*. Ganti `yourusername` dengan nama pengguna Linux masing-masing.

### 4.3 `mapred-site.xml`

```xml
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_CLASSPATH:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
```

**Penjelasan:** `mapreduce.framework.name=yarn` menjadikan YARN sebagai pengelola eksekusi MapReduce. `mapreduce.application.classpath` menentukan lokasi pustaka MapReduce.

### 4.4 `yarn-site.xml`

```xml
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>4096</value>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>2048</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-pmem-ratio</name>
        <value>2.1</value>
    </property>
</configuration>
```

**Penjelasan:**

| Properti | Fungsi |
|---|---|
| `yarn.nodemanager.aux-services` | Mengaktifkan layanan *shuffle* untuk MapReduce |
| `yarn.nodemanager.env-whitelist` | Daftar variabel lingkungan yang diteruskan ke container |
| `yarn.nodemanager.resource.memory-mb` | Total memori (4096 MB) yang boleh dipakai NodeManager |
| `yarn.scheduler.minimum-allocation-mb` | Alokasi memori minimum per container (2048 MB) |
| `yarn.nodemanager.vmem-pmem-ratio` | Rasio memori virtual terhadap memori fisik (2,1) |

📷 **Gambar 10 — Bukti konfigurasi (opsional)**

![Gambar 10 - File konfigurasi](images/10-konfigurasi-xml.png)

---

## 5. Format NameNode

> ⚠️ **Perhatian:** Proses ini dilakukan **sekali saja**. Jika diulang, berbagai file yang sudah diproses di HDFS akan terhapus.

```bash
java -version
hdfs namenode -format
```

📷 **Gambar 11 — Output `hdfs namenode -format` (bagian awal)**

![Gambar 11 - Format NameNode awal](images/11-format-namenode-1.png)

📷 **Gambar 12 — Output `hdfs namenode -format` (bagian akhir)**

![Gambar 12 - Format NameNode akhir](images/12-format-namenode-2.png)

**Penjelasan kode:** `hdfs namenode -format` menginisialisasi *filesystem* HDFS yang baru, yaitu membuat direktori penyimpanan metadata NameNode dan berkas `fsimage` awal.

**Penjelasan output:**

- `STARTUP_MSG: version = 3.5.0` menunjukkan versi Hadoop yang dipakai.
- Pesan `Storage directory /tmp/hadoop-<user>/dfs/name has been successfully formatted` menandakan format berhasil.
- Muncul pula `Saving image file ... fsimage`, yaitu penyimpanan citra metadata awal dengan `txid=0`.
- Pesan `SHUTDOWN_MSG: Shutting down NameNode` di akhir adalah normal, karena proses format memang berhenti setelah selesai.

---

## 6. Atur Konfigurasi JAVA_HOME

Edit file `$HADOOP_HOME/etc/hadoop/hadoop-env.sh`, lalu isi `JAVA_HOME` sesuai lokasi JDK pada komputer:

```bash
export JAVA_HOME=/home/<nama-user>/.sdkman/candidates/java/current
```

📷 **Gambar 13 — Pengisian JAVA_HOME pada hadoop-env.sh**

![Gambar 13 - JAVA_HOME](images/13-java-home.png)

**Penjelasan:** Menurut komentar pada file tersebut, `JAVA_HOME` adalah satu-satunya variabel lingkungan yang wajib diatur. Jika kosong, daemon Hadoop gagal dijalankan karena tidak menemukan Java. Path di atas hanya contoh dan harus disesuaikan, dan lokasinya dapat dicari dengan `dirname $(dirname $(readlink -f $(which java)))`.

---

## 7. Jalankan Daemon HDFS

```bash
start-dfs.sh
```

📷 **Gambar 14 — Menjalankan `start-dfs.sh`**

![Gambar 14 - start-dfs.sh](images/14-start-dfs.png)

**Penjelasan output:** Tiga baris output menunjukkan tiga daemon dijalankan:

1. `Starting namenodes on [localhost]` — NameNode aktif.
2. `Starting datanodes` — DataNode aktif.
3. `Starting secondary namenodes [<hostname>]` — Secondary NameNode aktif.

Pemeriksaan proses Java yang berjalan (opsional):

```bash
jps
```

### Pemantauan melalui Web UI

Buka peramban ke alamat: **<http://localhost:9870>**

📷 **Gambar 15 — Web UI NameNode (Overview dan Summary)**

![Gambar 15 - Web UI HDFS](images/15-web-ui-hdfs.png)

**Penjelasan tampilan:**

| Bagian | Makna |
|---|---|
| `Overview 'localhost:9000' (active)` | NameNode berjalan dan berstatus aktif |
| `Version 3.5.0` | Versi Hadoop yang berjalan |
| `Cluster ID` / `Block Pool ID` | Identitas klaster dan kumpulan blok |
| `Safemode is off` | HDFS siap menerima operasi baca dan tulis |
| `Security is off` | Mode keamanan (Kerberos) tidak aktif |
| `Configured Capacity` | Total kapasitas penyimpanan yang tersedia untuk HDFS |
| `DFS Used` | Kapasitas yang sudah terpakai (masih mendekati 0 karena belum ada data) |

---

## 8. Selesai: Operasi File di HDFS

Jika sampai tahap ini berhasil, Hadoop dan HDFS siap digunakan. Daftar lengkap perintah HDFS dapat dilihat di dokumentasi resmi: <https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/FileSystemShell.html>

```bash
hdfs dfs -ls /
hdfs dfs -mkdir -p /user/<nama-user>
hdfs dfs -ls /
hdfs dfs -ls /user
```

**Penjelasan kode:**

| Perintah | Fungsi |
|---|---|
| `hdfs dfs -ls /` | Menampilkan isi direktori root HDFS |
| `hdfs dfs -mkdir -p /user/<nama-user>` | Membuat direktori beserta direktori induknya (`-p`) |
| `hdfs dfs -ls /user` | Menampilkan isi direktori `/user` |

📷 **Gambar 16 — Operasi dasar HDFS**

![Gambar 16 - Operasi dasar HDFS](images/16-hdfs-dfs-ls-mkdir.png)

**Penjelasan output:**

- `hdfs dfs -ls /` pertama tidak menampilkan apa pun karena HDFS masih kosong.
- Setelah `mkdir`, muncul `Found 1 items` dengan baris `drwxr-xr-x - <user> supergroup 0 ... /user`.
- Pada baris tersebut, `d` berarti direktori, `rwxr-xr-x` adalah hak akses, `<user>` adalah pemilik, `supergroup` adalah grup, dan `0` adalah ukuran (direktori tidak punya ukuran).

### Menghentikan HDFS

```bash
stop-dfs.sh
```

📷 **Gambar 17 — Menjalankan `stop-dfs.sh`**

![Gambar 17 - stop-dfs.sh](images/17-stop-dfs.png)

**Penjelasan output:** Ketiga daemon (NameNode, DataNode, dan Secondary NameNode) dihentikan satu per satu.

---

## 9. Tugas

**Soal:**

1. Buat direktori `/user/<nama-user>/datasets` di HDFS.
2. Cari 3 file `.csv` di Internet, lalu salin ketiganya ke direktori yang baru dibuat pada tugas 1.

### 9.1 Membuat direktori datasets

```bash
hdfs dfs -mkdir -p /user/<nama-user>/datasets
hdfs dfs -ls /user/<nama-user>
```

📷 **Gambar 18 — Direktori datasets berhasil dibuat**

![Gambar 18 - Direktori datasets](images/18-tugas-mkdir-datasets.png)

**Penjelasan output:** Pada hasil `-ls` muncul entri `/user/<nama-user>/datasets` bertipe direktori (`d`), sehingga tugas 1 selesai.

### 9.2 Mengunduh 3 file CSV

Tiga file CSV diunduh ke direktori lokal, misalnya `~/datasets/`:

```bash
mkdir -p ~/datasets
cd ~/datasets
# unduh melalui peramban atau memakai wget/curl, contoh:
# wget -O <nama-file>.csv "<URL-file-csv>"
ls -lh ~/datasets
```

| No | Nama file | Sumber | Keterangan isi |
|---|---|---|---|
| 1 | `<file-1>.csv` | `<URL sumber>` | `<deskripsi singkat>` |
| 2 | `<file-2>.csv` | `<URL sumber>` | `<deskripsi singkat>` |
| 3 | `<file-3>.csv` | `<URL sumber>` | `<deskripsi singkat>` |

📷 **Gambar 19 — Tiga file CSV pada direktori lokal**

![Gambar 19 - File CSV lokal](images/19-tugas-csv-lokal.png)

**Penjelasan:** `ls -lh` menampilkan tiga file CSV beserta ukurannya dalam format yang mudah dibaca (`-h`).

### 9.3 Menyalin file CSV ke HDFS

```bash
hdfs dfs -put ~/datasets/*.csv /user/<nama-user>/datasets/
hdfs dfs -ls /user/<nama-user>/datasets
```

📷 **Gambar 20 — Hasil penyalinan file ke HDFS**

![Gambar 20 - File CSV di HDFS](images/20-tugas-put-csv.png)

**Penjelasan kode:**

| Perintah | Fungsi |
|---|---|
| `hdfs dfs -put <sumber> <tujuan>` | Menyalin file dari sistem berkas lokal ke HDFS |
| `*.csv` | Pola yang mencocokkan semua file berekstensi `.csv` |

**Penjelasan output:** `-ls` menampilkan `Found 3 items`, yaitu tiga file CSV beserta ukuran, pemilik, dan hak aksesnya. Karena `dfs.replication` bernilai 1, setiap blok hanya memiliki satu salinan.

Pemeriksaan isi file (opsional):

```bash
hdfs dfs -cat /user/<nama-user>/datasets/<file-1>.csv | head
```

### 9.4 Verifikasi melalui Web UI

Buka **Utilities → Browse the file system** pada <http://localhost:9870>, lalu masuk ke `/user/<nama-user>/datasets`.

📷 **Gambar 21 — Tampilan file pada Web UI**

![Gambar 21 - Browse file system](images/21-tugas-web-ui.png)

**Penjelasan:** Ketiga file tampil dengan kolom *Permission*, *Owner*, *Size*, dan *Replication* bernilai `1`, sehingga data terbukti tersimpan di HDFS.

---

## 10. Kesimpulan

1. Apache Hadoop 3.5.0 berhasil dipasang dan dikonfigurasi dalam mode *pseudo-distributed*.
2. `pdsh` dan SSH tanpa password diperlukan agar skrip `start-dfs.sh` dapat menjalankan daemon.
3. Konfigurasi utama berada pada `core-site.xml` (alamat NameNode) dan `hdfs-site.xml` (jumlah replikasi).
4. Format NameNode hanya dilakukan sekali karena dapat menghapus data HDFS.
5. Daemon NameNode, DataNode, dan Secondary NameNode berhasil berjalan dan dipantau melalui Web UI pada port 9870.
6. Tugas selesai: direktori `/user/<nama-user>/datasets` dibuat, dan tiga file CSV berhasil disalin ke dalamnya.

---

## Struktur Folder Repository

```text
06/
├── README.md
└── images/
    ├── 00-java-version.png
    ├── 01-unduh-hadoop.png
    ├── ...
    └── 21-tugas-web-ui.png
```

> **Catatan:** Ganti `<nama-user>` dengan nama pengguna yang dipakai (misalnya hasil dari `whoami`), dan sesuaikan nama file gambar dengan yang ada di folder `images/`.
