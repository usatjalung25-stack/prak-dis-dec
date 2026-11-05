# Modul 6 — Distributed File System (HDFS)

**Praktikum Sistem Terdistribusi dan Terdesentralisasi**
Prodi Informatika — Universitas Teknologi Digital Indonesia

| | |
|---|---|
| **Nama** | Usat Jalung |
| **Kelas** | IF1 |
| **Topik** | Instalasi Apache Hadoop 3.5.0 (pseudo-distributed) dan operasi dasar HDFS |

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
8. [Selesai: Operasi File HDFS](#8-selesai-operasi-file-hdfs)
9. [Tugas](#9-tugas)
10. [Kesimpulan](#10-kesimpulan)

---

## Gambaran Arsitektur

```
 Client (hdfs dfs ...)
        │
        ▼
 ┌────────────────┐   metadata   ┌──────────────────────┐
 │   NameNode     │◄────────────►│ Secondary NameNode   │
 │ localhost:9000 │              │ (checkpoint)         │
 └───────┬────────┘              └──────────────────────┘
         │ perintah blok
         ▼
 ┌────────────────┐
 │   DataNode     │  ← menyimpan blok data (replikasi = 1)
 └────────────────┘
```

**NameNode** mengelola metadata dan struktur direktori, **DataNode** menyimpan blok data, dan **Secondary NameNode** membantu checkpoint metadata. Pada praktikum ini semuanya berjalan di satu mesin (`localhost`).

---

## 0. Persyaratan Software

| Software | Keterangan |
|---|---|
| JDK | Versi 17 dan/atau 21. JDK 17 untuk server, client boleh JDK 17 atau 21 |
| Apache Hadoop | Versi 3.5.0 (rilis 2 April 2026) |
| pdsh | Parallel Distributed Shell, dipakai skrip Hadoop untuk menjalankan perintah di banyak node |
| ssh | Klien SSH |
| sshd | Server SSH, harus berjalan |

```bash
# Artix Linux + dinit
sudo dinitctl start sshd

# Distro dengan systemd
sudo systemctl start ssh
```

**Penjelasan:** Hadoop memakai SSH untuk menjalankan daemon (NameNode, DataNode, dst.), sehingga `sshd` wajib aktif walaupun semuanya berjalan di `localhost`.

---

## 1. Unduh Apache Hadoop

Distribusi diambil dari <https://hadoop.apache.org/releases.html>.

![Halaman unduh Apache Hadoop](img/01-download-hadoop.png)

**Penjelasan gambar:** Tabel rilis menampilkan versi **3.5.0** (2026 Apr 2) sebagai versi terbaru. Kolom *Binary download* dipilih karena yang dibutuhkan paket siap pakai, bukan source code. File `hadoop-3.5.0.tar.gz` disimpan di `~/master/data-engineering/apache-hadoop/`.

---

## 2. Instalasi Apache Hadoop

### 2.1 Ekstraksi dan symbolic link

```bash
cd ~/software/storage/
tar -xvf ~/master/data-engineering/apache-hadoop/hadoop-3.5.0.tar.gz
ln -s hadoop-3.5.0 hadoop
```

| Perintah | Fungsi |
|---|---|
| `cd ~/software/storage/` | Pindah ke direktori tujuan instalasi |
| `tar -xvf ...` | Mengekstrak arsip (`x` ekstrak, `v` tampilkan proses, `f` file) |
| `ln -s hadoop-3.5.0 hadoop` | Membuat *symlink* `hadoop` → `hadoop-3.5.0` agar versi mudah diganti tanpa mengubah konfigurasi |

![Hasil ln -s](img/02-symlink-hadoop.png)

**Penjelasan output:** Baris `lrwxrwxrwx ... hadoop -> hadoop-3.5.0` menunjukkan `hadoop` adalah *symbolic link* (diawali `l`) yang menunjuk ke direktori asli `hadoop-3.5.0` (diawali `d`).

> **Catatan:** Lokasi instalasi disebut **`$HADOOP_HOME`** = `$HOME/software/storage/hadoop`.

### 2.2 Environment variable PATH

File `~/env/bash/storage/hadoop.sh`:

```bash
export PATH="$HOME/software/storage/hadoop/bin:$HOME/software/storage/hadoop/sbin:$PATH"
```

![Isi file hadoop.sh](img/03-env-hadoop-sh.png)

**Penjelasan:** `bin` berisi perintah klien (`hadoop`, `hdfs`, `yarn`), `sbin` berisi skrip administrasi (`start-dfs.sh`, `stop-dfs.sh`). Keduanya ditambahkan ke `PATH` agar bisa dipanggil dari direktori mana pun.

```bash
source ~/env/bash/storage/hadoop.sh
```

### 2.3 Verifikasi instalasi

```bash
hadoop
```

![Output perintah hadoop](img/04-hadoop-usage.png)

**Penjelasan output:**

- Sebelum `source`: `bash: hadoop: command not found` karena `PATH` belum diatur.
- Setelah `source`: muncul *usage* berisi daftar *OPTIONS* dan *SUBCOMMAND* (`fs`, `classpath`, `distcp`, `version`, dll.).
- Artinya Hadoop sudah terpasang dan dapat dijalankan.

---

## 3. Instalasi pdsh dan Konfigurasi SSH

### 3.1 Instalasi pdsh

Pada Artix Linux, `pdsh` dikompilasi dari AUR dengan **trizen**.

```bash
trizen -Ss pdsh
trizen -S pdsh
```

![Pencarian pdsh dengan trizen](img/05-trizen-search-pdsh.png)

**Penjelasan:** `trizen -Ss pdsh` menampilkan `aur/pdsh 2.36-1` dan `aur/pdsh-genders` (dengan dukungan *Genders Database*). Dipilih `pdsh` biasa.

![Proses build PKGBUILD pdsh](img/06-trizen-install-pdsh.png)

**Penjelasan:** `trizen -S pdsh` mengambil `PKGBUILD` dan menampilkan *diff* versi 2.35 → **2.36**. Opsi `./configure --without-rsh --with-ssh` berarti pdsh memakai **SSH** (bukan RSH) sebagai mekanisme akses remote.

![Instalasi pdsh selesai](img/07-pdsh-installed.png)

**Penjelasan:** Setelah `==> Finished making: pdsh 2.36-1`, `pacman` memasang paket (ukuran 0.48 MiB) tanpa error.

### 3.2 Verifikasi pdsh

```bash
pdsh -q -w localhost
```

![Output pdsh -q](img/08-pdsh-query.png)

| Field | Nilai | Arti |
|---|---|---|
| `Rcmd type` | `ssh` | pdsh memakai SSH (sudah benar) |
| `Remote username` | user lokal | Akun untuk login ke node |
| `Fanout` | `32` | Maksimum koneksi paralel |
| `Target nodes` | `localhost` | Node tujuan |

Jika `Rcmd type` bukan `ssh`:

```bash
export PDSH_RCMD_TYPE=ssh
```

### 3.3 SSH ke localhost tanpa password

```bash
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
```

| Perintah | Fungsi |
|---|---|
| `ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa` | Membuat pasangan kunci RSA tanpa passphrase |
| `cat ... >> authorized_keys` | Mendaftarkan kunci publik agar boleh login |
| `chmod 0600 ...` | Mengunci izin file (SSH menolak jika izin terlalu longgar) |

![Pembuatan kunci SSH dan tes ssh localhost](img/09-ssh-keygen-localhost.png)

**Penjelasan output:**

- `ssh-keygen` menghasilkan kunci **RSA 3072** beserta *fingerprint* dan *randomart image*.
- `ssh localhost` pertama meminta konfirmasi *host authenticity*; dijawab `yes` sehingga `localhost` masuk ke `known_hosts`.
- Setelah `logout`, `ssh localhost` kedua langsung masuk **tanpa password**, syarat agar `start-dfs.sh` berjalan otomatis.

---

## 4. Konfigurasi Apache Hadoop

Semua file berada di `$HADOOP_HOME/etc/hadoop/`.

### 4.1 `hdfs-site.xml`

```xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
```

**Penjelasan:** `dfs.replication = 1` karena hanya ada satu DataNode. Nilai bawaan (3) tidak bisa terpenuhi di satu mesin.

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

- `fs.defaultFS` menentukan alamat NameNode, sehingga `hdfs dfs` otomatis terhubung ke `hdfs://localhost:9000`.
- `hadoop.proxyuser.<user>.groups/hosts` mengizinkan user tersebut bertindak sebagai *proxy user*. Ganti `yourusername` dengan nama user Linux.

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

**Penjelasan:** MapReduce dijalankan di atas **YARN**, dan `classpath` menunjuk ke pustaka MapReduce.

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

| Properti | Arti |
|---|---|
| `aux-services = mapreduce_shuffle` | Layanan *shuffle* untuk MapReduce |
| `env-whitelist` | Variabel lingkungan yang diteruskan ke container |
| `resource.memory-mb = 4096` | Total memori NodeManager (4 GB) |
| `minimum-allocation-mb = 2048` | Alokasi memori minimum per container (2 GB) |
| `vmem-pmem-ratio = 2.1` | Batas memori virtual terhadap memori fisik |

![Konfigurasi XML di editor](img/10-konfigurasi-xml.png)

---

## 5. Format NameNode

> ⚠️ Proses ini **dilakukan sekali saja**. Jika diulang, file yang sudah diproses di HDFS akan terhapus.

```bash
java -version
hdfs namenode -format
```

![Output java -version dan format NameNode](img/11-namenode-format-1.png)

**Penjelasan output:**

- `java -version` menunjukkan **OpenJDK 17.0.18 (LTS)**, sesuai persyaratan.
- `hdfs namenode -format` memulai NameNode dengan `version = 3.5.0` dan `args = [-format]`.
- `logs does not exist. Creating.` hanya peringatan karena direktori log baru dibuat.

![Akhir proses format NameNode](img/12-namenode-format-2.png)

**Penjelasan output:**

- `Storage directory /tmp/hadoop-<user>/dfs/name has been successfully formatted` → format **berhasil**.
- `Saving image file ... fsimage` → metadata awal tersimpan.
- `SHUTDOWN_MSG: Shutting down NameNode` normal; proses format memang berhenti setelah selesai.

---

## 6. Atur Konfigurasi JAVA_HOME

Edit `$HADOOP_HOME/etc/hadoop/hadoop-env.sh`:

```bash
export JAVA_HOME=/home/<user>/.sdkman/candidates/java/current
```

![Edit hadoop-env.sh](img/13-java-home.png)

**Penjelasan:** `JAVA_HOME` adalah satu-satunya variabel yang wajib bagi Hadoop (baris ke-54 pada gambar). JDK di sini dikelola dengan **SDKMAN**, sehingga path menunjuk ke `.sdkman/candidates/java/current`. Sesuaikan dengan lokasi JDK masing-masing.

---

## 7. Jalankan Daemon HDFS

```bash
start-dfs.sh
```

![Output start-dfs.sh](img/14-start-dfs.png)

| Pesan | Arti |
|---|---|
| `Starting namenodes on [localhost]` | NameNode aktif |
| `Starting datanodes` | DataNode aktif |
| `Starting secondary namenodes [<hostname>]` | Secondary NameNode aktif |

Pemantauan lewat web UI: **<http://localhost:9870>**.

![Web UI HDFS](img/15-web-ui-overview.png)

**Penjelasan tampilan:**

- `Overview 'localhost:9000' (active)` → NameNode aktif di port 9000.
- `Version: 3.5.0` sesuai versi yang dipasang.
- `Safemode is off` → HDFS siap menerima operasi baca/tulis.
- `1 files and directories, 0 blocks` → masih kosong (hanya root).
- `Configured Capacity` → kapasitas disk yang dapat dipakai HDFS.

---

## 8. Selesai: Operasi File HDFS

Daftar lengkap perintah: [FileSystemShell](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/FileSystemShell.html).

```bash
hdfs dfs -ls /
hdfs dfs -mkdir -p /user/<nama-user>
hdfs dfs -ls /
hdfs dfs -ls /user
```

![Contoh operasi file HDFS](img/16-hdfs-dfs-contoh.png)

| Perintah | Hasil |
|---|---|
| `hdfs dfs -ls /` (pertama) | Kosong |
| `hdfs dfs -mkdir -p /user/<nama-user>` | Membuat direktori beserta induknya (`-p`) |
| `hdfs dfs -ls /` (kedua) | `Found 1 items` → muncul `/user` |
| `hdfs dfs -ls /user` | Muncul `/user/<nama-user>` |

Kolom `drwxr-xr-x - <user> supergroup` menunjukkan izin, pemilik, dan grup direktori di HDFS.

### Menghentikan HDFS

```bash
stop-dfs.sh
```

![Output stop-dfs.sh](img/17-stop-dfs.png)

**Penjelasan:** NameNode, DataNode, dan Secondary NameNode dihentikan berurutan.

---

## 9. Tugas

1. Membuat direktori `/user/<nama-user>/datasets` di HDFS.
2. Mencari 3 file `.csv` di Internet, lalu menyalinnya ke direktori tersebut.

### 9.1 Membuat direktori `datasets`

```bash
hdfs dfs -mkdir -p /user/<nama-user>/datasets
hdfs dfs -ls /user/<nama-user>
```

![Membuat direktori datasets](img/18-tugas-mkdir-datasets.png)

**Penjelasan:** `-p` membuat seluruh path sekaligus; `-ls` memastikan direktori `datasets` sudah ada.

### 9.2 Mengunduh 3 file CSV

| No | Nama file | Sumber |
|---|---|---|
| 1 | `<file-1>.csv` | `<URL sumber>` |
| 2 | `<file-2>.csv` | `<URL sumber>` |
| 3 | `<file-3>.csv` | `<URL sumber>` |

```bash
wget -P ~/datasets <URL-file-1> <URL-file-2> <URL-file-3>
ls -lh ~/datasets
```

![File CSV di komputer lokal](img/19-tugas-csv-lokal.png)

### 9.3 Menyalin CSV ke HDFS

```bash
hdfs dfs -put ~/datasets/*.csv /user/<nama-user>/datasets/
hdfs dfs -ls -h /user/<nama-user>/datasets
```

![Hasil copy CSV ke HDFS](img/20-tugas-put-csv.png)

**Penjelasan:** `-put` menyalin file dari sistem file lokal ke HDFS; `-ls -h` menampilkan ukuran yang mudah dibaca. Ketiga file `.csv` harus tampil di direktori `datasets`.

### 9.4 (Opsional) Verifikasi isi

```bash
hdfs dfs -cat /user/<nama-user>/datasets/<file-1>.csv | head
```

![Browse file system di web UI](img/21-tugas-browse-fs.png)

---

## 10. Kesimpulan

- Apache Hadoop 3.5.0 berhasil dipasang dan dikonfigurasi dalam mode *pseudo-distributed*.
- `pdsh` dan SSH tanpa password diperlukan agar `start-dfs.sh` dapat menjalankan daemon.
- NameNode, DataNode, dan Secondary NameNode berjalan dan dapat dipantau lewat web UI.
- Operasi dasar HDFS (`-mkdir`, `-ls`, `-put`) berhasil, termasuk menyimpan 3 file CSV di `/user/<nama-user>/datasets`.

---

## Struktur Folder

```
06/
├── README.md
├── modul-06.pdf
└── img/
    ├── 01-download-hadoop.png
    ├── ...
    └── 21-tugas-browse-fs.png
```
