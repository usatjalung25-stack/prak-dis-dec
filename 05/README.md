<div align="center">

# Modul 5 — Fault Tolerance

**Praktikum Sistem Terdistribusi dan Terdesentralisasi**
Load Balancing Aplikasi · Failure Detection · Retry · Circuit Breaker

![Python](https://img.shields.io/badge/Python-3.12%20%7C%203.13-3776AB?logo=python&logoColor=white)
![BlackSheep](https://img.shields.io/badge/BlackSheep-2.6.x-1abc9c)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-Load%20Balancer-009639?logo=nginx&logoColor=white)

| Nama | NIM | Program Studi |
|------|-----|---------------|
| Usat Jalung | 255410017 | Informatika |

</div>

---

## Daftar Isi

1. [Gambaran Umum](#1-gambaran-umum)
2. [Struktur Folder](#2-struktur-folder)
3. [Persiapan dan Instalasi](#3-persiapan-dan-instalasi)
4. [Membuat Aplikasi Web (BlackSheep)](#4-membuat-aplikasi-web-blacksheep)
5. [Dockerfile dan docker-compose.yml](#5-dockerfile-dan-docker-composeyml)
6. [Menjalankan Docker Compose](#6-menjalankan-docker-compose)
7. [Failure Detection](#7-failure-detection)
8. [Solusi Error (Troubleshooting)](#8-solusi-error-troubleshooting)
9. [Ringkasan Perintah](#9-ringkasan-perintah)
10. [Perbedaan Repo dengan Modul](#10-perbedaan-repo-dengan-modul)

> **Cara membaca output di README ini**
> Output berlabel **📁 Hasil praktikum** diambil dari file log dan gambar yang ada di repo ini.
> Output berlabel **📘 Referensi modul** diambil dari contoh di modul PDF, dipakai untuk kondisi yang belum terekam di log repo (misalnya saat server aktif).

---

## 1. Gambaran Umum

**Fault tolerance** adalah kemampuan sistem untuk tetap bekerja walaupun sebagian komponennya gagal. Modul ini membahas tiga hal:

| Topik | Tujuan | Alat |
|-------|--------|------|
| **Load balancing** | Membagi request ke beberapa instance supaya tidak ada satu titik gagal | Nginx + Docker Compose |
| **Failure detection** | Mengetahui apakah sebuah komponen masih hidup | Heartbeat (socket TCP) |
| **Penanganan kegagalan** | Mencoba ulang dan melindungi sistem dari kegagalan berantai | Retry (`tenacity`) dan Circuit Breaker (`pybreaker`) |

### Arsitektur

```
                           ┌────────────────────────┐
                      ┌───►│  bs_app-1  (BlackSheep)│
 Browser ──► Nginx ───┤    └────────────────────────┘
 (port 80)   (proxy)  │    ┌────────────────────────┐
                      └───►│  bs_app-2  (BlackSheep)│
                           └────────────────────────┘
        Docker Compose membuat 2 instance dari service "bs_app"
```

Nginx menerima semua request di port 80, lalu meneruskannya ke salah satu instance `bs_app`. Jika satu instance mati, instance lain masih bisa melayani.

---

## 2. Struktur Folder

```
05/
├── README.md                  ← dokumen ini
├── image/                     ← tangkapan layar hasil uji
│   ├── 01-localhost:44777.png
│   └── 02-localhost:44777.png
├── sister-modul5-fault-tolerance   ← log terminal lengkap praktikum
├── Uji 2 kondisi                   ← log uji aplikasi aktif (port 44777)
└── modul5/
    ├── blacksheep_lb/         ← aplikasi BlackSheep (yang di-scale)
    │   ├── app/               ← kode aplikasi (main, controllers, views, static)
    │   ├── domain/
    │   ├── tests/
    │   ├── dev.py             ← menjalankan aplikasi untuk development
    │   ├── Dockerfile         ← image aplikasi
    │   ├── requirements.txt   ← daftar dependensi Python
    │   ├── settings.toml
    │   └── settings.dev.toml
    ├── nginx/
    │   ├── Dockerfile         ← image nginx
    │   └── nginx.conf         ← konfigurasi load balancer
    ├── docker-compose.yml     ← mengelola semua container
    ├── env.sh                 ← alias perintah (opsional)
    ├── heartbeat/
    │   └── check-server.py
    └── failure-detection/
        ├── check-retry.py
        └── check-circuit-breaker.py
```

---

## 3. Persiapan dan Instalasi

### 3.1 Kebutuhan

| Software | Fungsi |
|----------|--------|
| Python 3.12 atau lebih baru | Menjalankan aplikasi dan script uji |
| Docker + Docker Compose | Menjalankan container |
| Virtual environment (`venv` / `uv` / `micromamba`) | Memisahkan paket Python modul ini |

### 3.2 Install Docker

Pilih sesuai sistem operasi.

<details open>
<summary><b>macOS (yang dipakai pada praktikum ini)</b></summary>

Docker Desktop tidak bisa dipasang di macOS yang lebih lama dari Sonoma. Praktikum ini memakai macOS 13, jadi solusinya **Colima**, yaitu runtime Docker ringan tanpa Docker Desktop.

```bash
# 1. Install Colima, Docker CLI, dan Docker Compose
brew install colima docker docker-compose

# 2. Jalankan mesin Docker (2 CPU, 4 GB RAM)
colima start --cpu 2 --memory 4

# 3. Pastikan Docker aktif
docker info
docker run --rm hello-world
```

Cek versi:

```bash
python3 --version          # Python 3.13.9
docker --version           # Docker version 29.9.2
docker compose version     # Docker Compose version 5.6.1
```

Perintah berguna untuk Colima:

```bash
colima status      # lihat status
colima stop        # matikan mesin Docker
colima start       # nyalakan lagi
```
</details>

<details>
<summary><b>Linux (Arch / Artix)</b></summary>

```bash
sudo pacman -S docker docker-compose
```

Nyalakan service Docker sebelum dipakai:

```bash
# Sistem dengan dinit
sudo dinitctl start dockerd

# Sistem dengan systemd (kebanyakan distro Linux)
sudo systemctl start docker
```
</details>

<details>
<summary><b>Linux (Ubuntu / Debian)</b></summary>

```bash
sudo apt update
sudo apt install docker.io docker-compose-v2
sudo systemctl enable --now docker
```
</details>

<details>
<summary><b>Windows</b></summary>

Install **Docker Desktop**: <https://docs.docker.com/desktop/setup/install/windows-install/>
Setelah itu buka Docker Desktop dan tunggu sampai statusnya *running*.
</details>

### 3.3 Buat Virtual Environment

**Cara 1 — `venv` (dipakai di repo ini)**

```bash
mkdir -p ~/modul5 && cd ~/modul5
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install --upgrade pip
```

**Cara 2 — `uv` (dipakai di modul)**

```bash
mkdir workspace-05 && cd workspace-05
uv python list                   # lihat versi Python yang tersedia
uv python pin 3.14               # kunci versi Python
uv venv
source .venv/bin/activate
```

Prompt terminal akan berubah menjadi `(.venv)` jika environment aktif.

### 3.4 Install BlackSheep dan Paket Pendukung

```bash
pip install blacksheep blacksheep-cli requests tenacity pybreaker
```

| Paket | Fungsi |
|-------|--------|
| `blacksheep` | Framework web ASGI asynchronous |
| `blacksheep-cli` | Perintah `blacksheep create` untuk membuat proyek |
| `requests` | HTTP client untuk script uji |
| `tenacity` | Library retry |
| `pybreaker` | Library circuit breaker |

**📁 Hasil praktikum** (potongan akhir):

```text
Successfully installed Jinja2-3.1.6 arrow-1.4.0 binaryornot-0.6.0 blacksheep-2.6.4
blacksheep-cli-0.0.5 certifi-2026.10.23 ... pybreaker-1.4.1 ... requests-2.34.2 ... tenacity-9.2.1 ...
```

---

## 4. Membuat Aplikasi Web (BlackSheep)

### 4.1 Buat proyek dengan CLI

```bash
blacksheep create
```

Jawaban yang dipilih saat wizard muncul:

| Pertanyaan | Jawaban |
|------------|---------|
| Project name | `blacksheep_lb` |
| Project template | `mvc` |
| Use OpenAPI Documentation? | `Yes` |
| Library to read settings | `essentials-configuration` |
| App settings format | `TOML` |

**📁 Hasil praktikum:**

```text
✨ Project name: blacksheep_lb
🚀 Project template: mvc
📜 Use OpenAPI Documentation? Yes
🔧 Library to read settings essentials-configuration
🔩 App settings format TOML
────────────────────────────────────────────────────────────────────────────────
🏗️  Project created in blacksheep_lb
────────────────────────────────────────────────────────────────────────────────
-- What's next:
        cd blacksheep_lb
        pip install -r requirements.txt
        python dev.py
```

### 4.2 Install dependensi proyek

```bash
cd blacksheep_lb
pip install -r requirements.txt
```

Isi `requirements.txt`:

```text
blacksheep[full]>=2.3.0
Jinja2~=3.1.6
uvicorn~=0.34.0
uvloop; platform_system != "Windows"
essentials-configuration[full]
MarkupSafe==3.0.2
pydantic
```

> **Catatan:** `MarkupSafe==3.0.2` di-*pin* supaya cocok dengan template. Karena itu pip akan menurunkan versi dari 3.0.4 ke 3.0.2. Ini normal, bukan error.

**📁 Hasil praktikum:**

```text
Installing collected packages: websockets, uvloop, uvicorn, typing-extensions, PyJWT, pycparser,
MarkupSafe, defusedxml, annotated-types, typing-inspection, pydantic-core, cffi, pydantic, cryptography
  Attempting uninstall: MarkupSafe
    Found existing installation: MarkupSafe 3.0.4
    Uninstalling MarkupSafe-3.0.4:
      Successfully uninstalled MarkupSafe-3.0.4
Successfully installed MarkupSafe-3.0.2 PyJWT-2.15.1 ... pydantic-2.14.2 ... uvicorn-0.34.3 ...
```

### 4.3 Jalankan dan uji aplikasi

```bash
python dev.py
```

**📁 Hasil praktikum:**

```text
Running for local development ──────────────────────────────────────────────────
Visit http://localhost:44777/

INFO:     Started server process [13335]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://localhost:44777 (Press CTRL+C to quit)
INFO:     ::1:49624 - "GET / HTTP/1.1" 200 OK
INFO:     ::1:49624 - "GET /styles/public.css HTTP/1.1" 200 OK
INFO:     ::1:49626 - "GET /vendor/jquery/jquery.min.js HTTP/1.1" 200 OK
INFO:     ::1:49629 - "GET /images/blacksheep.png HTTP/1.1" 200 OK
...
```

Buka <http://localhost:44777> di browser:

![Halaman BlackSheep di localhost:44777](image/01-localhost%3A44777.png)

![Halaman BlackSheep di localhost:44777 (tampilan kedua)](image/02-localhost%3A44777.png)

Tekan `Ctrl+C` untuk menghentikan server:

```text
^CINFO:     Shutting down
INFO:     Waiting for application shutdown.
INFO:     Application shutdown complete.
INFO:     Finished server process [13335]
```

### 4.4 Penjelasan kode aplikasi

#### `dev.py` — menjalankan server untuk development

```python
if __name__ == "__main__":
    os.environ["APP_ENV"] = "dev"                 # mode development
    os.environ["APP_SHOW_ERROR_DETAILS"] = "1"    # tampilkan detail error
    port = int(os.environ.get("APP_PORT", 44777)) # port default 44777
    ...
    uvicorn.run("app.main:app", host="localhost", port=port, ...)
```

| Bagian | Penjelasan |
|--------|------------|
| `APP_ENV = "dev"` | Membuat aplikasi membaca `settings.dev.toml` di samping `settings.toml` |
| `APP_PORT` | Port bisa diganti lewat environment variable, default **44777** |
| `uvicorn.run("app.main:app", ...)` | Menjalankan objek `app` dari file `app/main.py` memakai server Uvicorn |
| `uvloop.install()` | Mempercepat event loop (hanya jika `uvloop` terpasang) |

> File ini **hanya untuk development**. Di dalam Docker, aplikasi dijalankan langsung oleh `uvicorn` di port **80**.

#### `app/main.py` — merakit aplikasi

```python
def configure_application(services, settings) -> Application:
    app = Application(services=services)
    app.middlewares.append(get_trailing_slash_middleware())
    app.serve_files("app/static")          # sajikan file CSS/JS/gambar
    configure_error_handlers(app)          # penanganan error
    configure_authentication(app, settings)
    configure_docs(app, settings)          # dokumentasi OpenAPI
    configure_templating(app, settings)    # template Jinja2
    return app

app = get_app()                            # objek ASGI yang dipanggil Uvicorn
```

#### `app/controllers/home.py` — routing

```python
class Home(Controller):
    @get()            # GET /
    def index(self):
        return self.view()   # render app/views/home/index.jinja

    @get(None)        # GET /example (nama diambil dari nama method)
    def example(self):
        return self.view()
```

#### `app/settings.py` — membaca konfigurasi

Konfigurasi dibaca berurutan dari `settings.toml`, lalu `settings.<env>.toml`, lalu environment variable berawalan `APP_`. Sumber yang lebih akhir menimpa yang sebelumnya.

---

## 5. Dockerfile dan docker-compose.yml

### 5.1 Peran tiap file

| Komponen | File | Tugas |
|----------|------|-------|
| Aplikasi | `blacksheep_lb/Dockerfile` | Membuat image aplikasi BlackSheep |
| Load balancer | `nginx/Dockerfile` + `nginx/nginx.conf` | Membuat image nginx yang membagi request |
| Orkestrasi | `docker-compose.yml` | Menjalankan app dan nginx bersama, serta men-scale app |
| Alias | `env.sh` | Singkatan perintah (opsional) |

### 5.2 `blacksheep_lb/Dockerfile`

```dockerfile
FROM python:3.12-slim
WORKDIR /home
COPY . /home
RUN python -m venv venv \
    && . venv/bin/activate \
    && pip install --upgrade pip \
    && pip install -r requirements.txt
ENV APP_ENV=prod BG_COLOR="#1abc9c" APP_ROUTE_PREFIX=""
EXPOSE 80
CMD ["sh", "-c", ". venv/bin/activate && uvicorn \"app.main:app\" --host 0.0.0.0 --port 80 --log-level info"]
```

| Baris | Penjelasan |
|-------|------------|
| `FROM python:3.12-slim` | Image dasar Python versi ringan |
| `WORKDIR /home` | Folder kerja di dalam container |
| `COPY . /home` | Menyalin seluruh isi proyek ke container |
| `RUN python -m venv venv && ... pip install` | Membuat virtual env lalu memasang dependensi |
| `ENV APP_ENV=prod ...` | Mode produksi, warna latar `#1abc9c` |
| `EXPOSE 80` | Menandakan aplikasi memakai port **80** (bukan 44777) |
| `CMD [...]` | Mengaktifkan venv lalu menjalankan `uvicorn` di `0.0.0.0:80` |

> **Penting:** `--host 0.0.0.0` wajib agar aplikasi bisa diakses dari container lain (nginx). Jika memakai `localhost`, nginx tidak bisa menjangkaunya.

### 5.3 `nginx/Dockerfile`

```dockerfile
FROM nginx

# Override the default nginx configuration file
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
```

Image nginx resmi dipakai, konfigurasi bawaan dihapus, lalu diganti dengan `nginx.conf` buatan sendiri.

### 5.4 `nginx/nginx.conf`

```nginx
events {
  worker_connections 4096;
}

http {
  # Definisi grup, lihat di docker-compose.yml
  upstream backend {
    server bs_app:80;
  }
  server {
    listen 80;
    location / {
      # sesuaikan dengan nama upstream di atas
      proxy_pass http://backend;
    }
  }
}
```

| Bagian | Penjelasan |
|--------|------------|
| `worker_connections 4096` | Maksimal koneksi simultan per worker |
| `upstream backend { server bs_app:80; }` | Grup server tujuan. `bs_app` adalah **nama service** di `docker-compose.yml`. DNS internal Docker mengubahnya menjadi alamat semua instance |
| `listen 80` | Nginx mendengarkan di port 80 |
| `proxy_pass http://backend` | Meneruskan request ke grup `backend` (nama harus sama dengan `upstream`) |

Dengan 2 instance, DNS Docker mengembalikan 2 alamat IP untuk `bs_app`, dan nginx membagi request di antara keduanya secara bergantian (*round robin*).

### 5.5 `docker-compose.yml`

```yaml
services:
  # aplikasi yang akan di-scale
  # ada pada direktori blacksheep_lb
  bs_app:
    build: ./blacksheep_lb

  # aktifkan nginx dengan menggunakan nginx/Dockerfile
  nginx:
    container_name: nginx
    build: ./nginx
    ports:
      - 80:80
    depends_on:
      - bs_app
```

| Bagian | Penjelasan |
|--------|------------|
| `bs_app.build` | Membangun image dari `blacksheep_lb/Dockerfile`. Tidak ada `container_name` dan `ports` supaya bisa di-scale |
| `nginx.container_name: nginx` | Nama container tetap `nginx` |
| `nginx.ports: 80:80` | Port 80 komputer → port 80 container. **Satu-satunya pintu masuk dari luar** |
| `depends_on: bs_app` | Nginx dijalankan setelah `bs_app` |

> **Kenapa `bs_app` tidak punya `ports`?** Jika dua instance sama-sama memakai port host yang sama, akan bentrok. Karena itu hanya nginx yang membuka port, dan akses ke `bs_app` lewat jaringan internal Docker.

### 5.6 `env.sh` — alias perintah (opsional, Linux/macOS)

```bash
alias dcu="docker compose up --build -d --scale bs_app=2"
alias dcd="docker compose down"
alias dps="docker ps --format '{{.Image}} {{.Names}}'"
alias dcln="docker logs nginx"
```

| Alias | Perintah asli | Fungsi |
|-------|---------------|--------|
| `dcu` | `docker compose up --build -d --scale bs_app=2` | Build, jalankan di background, buat **2 instance** `bs_app` |
| `dcd` | `docker compose down` | Matikan dan hapus semua container |
| `dps` | `docker ps --format ...` | Tampilkan nama image dan container yang berjalan |
| `dcln` | `docker logs nginx` | Lihat log nginx |

Aktifkan alias di terminal yang sedang dipakai:

```bash
source env.sh
```

> Di Linux, modul memakai `sudo docker-compose ...`. Di macOS dengan Colima, `sudo` tidak diperlukan dan perintahnya `docker compose` (tanpa tanda hubung).

---

## 6. Menjalankan Docker Compose

### 6.1 Pastikan Docker aktif

```bash
docker info > /dev/null 2>&1 && echo "Docker AKTIF" || echo "Docker MATI"
```

Jika **MATI**: lihat [Solusi Error](#8-solusi-error-troubleshooting).

### 6.2 Jalankan

Dari folder `modul5/` (yang berisi `docker-compose.yml`):

```bash
source env.sh
dcu
```

**📁 Hasil praktikum** (proses build berhasil, ringkas):

```text
Step 1/8 : FROM python:3.12-slim
3.12-slim: Pulling from library/python
...
Step 4/8 : RUN python -m venv venv && . venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt
...
Successfully installed Jinja2-3.1.6 MarkupSafe-3.0.2 ... blacksheep-2.6.4 ...
Step 6/8 : EXPOSE 80
Step 7/8 : CMD ["sh", "-c", ". venv/bin/activate && uvicorn \"app.main:app\" --host 0.0.0.0 --port 80 --log-level info"]
Successfully built b59ed27cdb57
Successfully tagged modul5-bs_app:latest
 ✔ Image modul5-bs_app Built                                              100.9s

Step 1/4 : FROM nginx
Step 3/4 : COPY nginx.conf /etc/nginx/nginx.conf
Successfully built 99a541f86cef
Successfully tagged modul5-nginx:latest

 ✔ Image modul5-bs_app       Built                                        100.9s
 ✔ Image modul5-nginx        Built                                          6.1s
 ✔ Network modul5_default    Created                                        0.2s
 ✔ Container modul5-bs_app-1 Created                                        0.3s
 ✔ Container modul5-bs_app-2 Created                                        0.3s
```

Pada run ini terjadi **error container name conflict** pada nginx:

```text
 ⠋ Container nginx           Creating                                       0.1s
 ✘ service:nginx:1           Error response from daemon: Conflict. The...   0.0s
Error response from daemon: Conflict. The container name "/nginx" is already in use by
container "0d3c692faf15...". You have to remove (or rename) that container to be able to reuse that name
```

**Penyebab:** sudah ada container lama bernama `nginx` (kemungkinan sisa percobaan sebelumnya; `docker info` di log menunjukkan sudah ada 15 container di mesin Docker). Karena `docker-compose.yml` memaksa `container_name: nginx`, Docker menolak membuat yang baru. Akibatnya nginx tidak berjalan dan `curl http://localhost/` mengembalikan kode `000` (tidak ada yang menjawab).

```text
(.venv) % for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost/; done
000
000
000
000
000
000
```

**Solusi:** hapus container lama, lalu jalankan ulang.

```bash
docker ps -a                        # cari container bernama "nginx"
docker rm -f nginx                  # hapus container lama
docker compose down --remove-orphans
dcu                                 # jalankan ulang
```

### 6.3 Verifikasi

**1. Cek container yang berjalan** (harus ada 2 instance `bs_app` dan 1 `nginx`):

```bash
dps
```

**📘 Referensi modul:**

```text
load-balancing-nginx nginx
load-balancing-bs_app load-balancing-bs_app-1
load-balancing-bs_app load-balancing-bs_app-2
```

> Di repo ini awalan nama adalah `modul5-` (mengikuti nama folder), jadi hasilnya `modul5-bs_app-1` dan `modul5-bs_app-2`.

**2. Buka di browser:** <http://localhost> (tanpa port berarti port **80**, bukan 44777 lagi).

**3. Kirim beberapa request lalu lihat log tiap instance:**

```bash
for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost/; done

docker logs modul5-bs_app-1 | grep "GET / "
echo "-----"
docker logs modul5-bs_app-2 | grep "GET / "
```

Jika load balancing berjalan, request muncul **di kedua instance**, dan semua `curl` mengembalikan `200`.

**📘 Referensi modul** (log `bs_app-1` dan `bs_app-2` menunjukkan request dibagi antar-instance):

```text
INFO:  172.18.0.4:39224 - "GET / HTTP/1.1" 200 OK     ← bs_app-1
INFO:  172.18.0.4:50056 - "GET / HTTP/1.1" 200 OK     ← bs_app-1
INFO:  172.18.0.4:48088 - "GET / HTTP/1.1" 200 OK     ← bs_app-2
```

### 6.4 Uji ketahanan (fault tolerance)

Matikan satu instance, lalu pastikan aplikasi **tetap bisa diakses**:

```bash
docker stop modul5-bs_app-1
for i in 1 2 3 4; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost/; done
docker start modul5-bs_app-1
```

Hasil yang diharapkan: `200` untuk semua request, karena `bs_app-2` masih hidup. Inilah inti *high availability*.

> Pada log praktikum, uji ini menghasilkan `000` (empat kali). Kemungkinan besar karena nginx belum berjalan akibat error conflict di atas, sehingga bukan hasil uji ketahanan yang sebenarnya. Ulangi uji ini setelah error diperbaiki.

### 6.5 Matikan semua container

```bash
dcd
```

**📁 Hasil praktikum:**

```text
[+] down 3/3
 ✔ Container modul5-bs_app-1 Removed                                       10.3s
 ✔ Container modul5-bs_app-2 Removed                                        0.1s
 ✔ Network modul5_default    Removed                                        0.2s
```

---

## 7. Failure Detection

*Failure detection* adalah proses menentukan apakah suatu komponen sudah gagal. Ada tiga teknik yang dipraktikkan, dari yang paling sederhana hingga yang paling lengkap.

| Teknik | Pertanyaan yang dijawab | File |
|--------|-------------------------|------|
| Heartbeat | "Apakah server masih hidup?" | `heartbeat/check-server.py` |
| Retry | "Kalau gagal, coba lagi berapa kali?" | `failure-detection/check-retry.py` |
| Circuit Breaker | "Kalau gagal terus, kapan berhenti mencoba?" | `failure-detection/check-circuit-breaker.py` |

### Persiapan uji dua kondisi

Setiap script diuji pada **dua kondisi**:

| Kondisi | Cara membuatnya |
|---------|-----------------|
| **A. Server mati** | Tidak ada aplikasi di port 44777 |
| **B. Server aktif** | Jalankan di terminal lain: `cd blacksheep_lb && python dev.py` |

**📁 Hasil praktikum** (kondisi B — server aktif, dari file `Uji 2 kondisi`):

```text
(.venv) % cd ~/modul5 && source .venv/bin/activate
(.venv) % cd blacksheep_lb && python dev.py
Running for local development ──────────────────────────────────────────────────
Visit http://localhost:44777/

INFO:     Started server process [14233]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://localhost:44777 (Press CTRL+C to quit)
INFO:     ::1:49788 - "GET / HTTP/1.1" 200 OK
```

---

### 7.1 Heartbeat

**Konsep:** protokol *heartbeat* memantau aktivitas komponen. Jika pemantau tidak menerima tanda hidup dalam waktu tertentu, komponen dianggap **gagal dan tidak responsif**.

#### Kode `heartbeat/check-server.py`

```python
import socket
import sys


def check_server(host: str, port: int, timeout: float = 3.0) -> bool:
    """Heartbeat sederhana: coba koneksi TCP ke host:port."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except (OSError, socket.timeout):
        return False


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Pemakaian: python check-server.py <host> <port>")
        sys.exit(2)

    host, port = sys.argv[1], int(sys.argv[2])
    if check_server(host, port):
        print("Server up")
    else:
        print("Server down")
        sys.exit(1)
```

#### Penjelasan

| Bagian | Penjelasan |
|--------|------------|
| `socket.create_connection((host, port), timeout=3.0)` | Mencoba membuka koneksi TCP ke server. Menunggu maksimal 3 detik |
| `return True` | Koneksi berhasil → server **hidup** |
| `except (OSError, socket.timeout)` | Koneksi ditolak atau kehabisan waktu → server **mati** |
| `sys.argv` | Host dan port diberikan dari baris perintah |
| `sys.exit(1)` / `sys.exit(2)` | Kode keluar: `0` = up, `1` = down, `2` = salah pemakaian |

Script ini mengecek **satu kali**. Agar menjadi heartbeat sungguhan, jalankan berulang:

```bash
while true; do python heartbeat/check-server.py localhost 44777; sleep 5; done
```

#### Cara menjalankan

```bash
python heartbeat/check-server.py localhost 44777
echo $?        # lihat kode keluar
```

#### Hasil dan perbedaan dua kondisi

| Kondisi | Output | Kode keluar | Arti |
|---------|--------|-------------|------|
| **A. Server mati** | `Server down` | `1` | Koneksi ditolak, port tidak ada yang mendengarkan |
| **B. Server aktif** | `Server up` | `0` | Koneksi TCP berhasil dibuat |

**📁 Hasil praktikum** (kondisi A):

```text
(.venv) % python heartbeat/check-server.py localhost 44777
Server down
(.venv) % python heartbeat/check-server.py localhost 44777
Server down
```

**📘 Referensi modul** (kondisi B):

```text
$ python check-server.py localhost 44777
Server up
$ python check-server.py localhost 80
Server down
```

---

### 7.2 Retry dengan `tenacity`

**Konsep:** selalu ada kemungkinan gagal saat terhubung ke komponen di luar aplikasi (jaringan putus, server sibuk, dan sebagainya). Banyak kegagalan bersifat sementara, sehingga **mencoba ulang** sering menyelesaikannya.

#### Kode `failure-detection/check-retry.py`

```python
import requests
from tenacity import (
    retry,
    stop_after_attempt,
    wait_fixed,
    retry_if_exception_type,
    RetryError,
)

URL = "http://localhost:44777"


@retry(
    stop=stop_after_attempt(5),                 # maksimal 5 percobaan
    wait=wait_fixed(2),                         # jeda 2 detik antar percobaan
    retry=retry_if_exception_type(requests.exceptions.RequestException),
)
def access_url(url: str) -> requests.Response:
    print(f"Attempting to access {url}...")
    response = requests.get(url, timeout=3)
    response.raise_for_status()
    return response


if __name__ == "__main__":
    try:
        access_url(URL)
        print(f"Successfully accessed {URL}")
    except RetryError as e:
        print(f"Failed to access URL after multiple retries: {e}")
```

#### Penjelasan

| Bagian | Penjelasan |
|--------|------------|
| `@retry(...)` | *Decorator* yang membungkus fungsi: jika fungsi gagal, otomatis dipanggil ulang |
| `stop_after_attempt(5)` | Berhenti setelah **5 percobaan** |
| `wait_fixed(2)` | Menunggu **2 detik** di antara percobaan |
| `retry_if_exception_type(RequestException)` | Hanya mengulang jika errornya terkait HTTP/koneksi. Error lain (misalnya bug kode) langsung dihentikan |
| `requests.get(url, timeout=3)` | Request dibatasi 3 detik agar tidak menggantung |
| `raise_for_status()` | Status `4xx`/`5xx` dianggap error supaya ikut di-retry |
| `except RetryError` | Setelah 5 kali gagal, `tenacity` melempar `RetryError` yang ditangkap di sini |

Alur kerjanya:

```
percobaan 1 ─gagal─► tunggu 2 dtk ─► percobaan 2 ─gagal─► ... ─► percobaan 5 ─gagal─► RetryError
        └──────────── sukses di percobaan mana pun ──► "Successfully accessed"
```

#### Hasil dan perbedaan dua kondisi

| Kondisi | Perilaku | Output akhir |
|---------|----------|--------------|
| **A. Server mati** | 5 kali mencoba, jeda 2 detik (total sekitar 8 detik), semua gagal | `Failed to access URL after multiple retries` |
| **B. Server aktif** | Berhasil pada percobaan pertama, tanpa jeda | `Successfully accessed http://localhost:44777` |

**📁 Hasil praktikum** (kondisi A — terlihat 5 kali `Attempting`):

```text
(.venv) % python failure-detection/check-retry.py
Attempting to access http://localhost:44777...
Attempting to access http://localhost:44777...
Attempting to access http://localhost:44777...
Attempting to access http://localhost:44777...
Attempting to access http://localhost:44777...
Failed to access URL after multiple retries: RetryError[<Future at 0x109641480 state=finished raised ConnectionError>]
```

**📘 Referensi modul** (kondisi B):

```text
$ python check-retry.py
Attempting to access http://localhost:44777...
Successfully accessed http://localhost:44777
```

---

### 7.3 Circuit Breaker

**Konsep:** pola desain yang dipakai di *microservices* untuk mencegah **kegagalan berantai**. Jika layanan sudah jelas gagal, memanggilnya terus-menerus hanya membuang waktu dan membebani sistem. Circuit breaker **memblokir sementara** panggilan ke layanan yang gagal.

Cara kerjanya seperti saklar listrik dengan tiga status:

```
                gagal ≥ ambang batas
     ┌────────┐ ─────────────────────► ┌────────┐
     │ CLOSED │                        │  OPEN  │  semua request langsung ditolak
     └────────┘ ◄───────────────────── └────────┘
          ▲        (uji berhasil)           │
          │                                 │ setelah reset_timeout
          │         ┌───────────┐           ▼
          └──────── │ HALF-OPEN │ ◄─────────┘
        uji berhasil└───────────┘
                          │ uji gagal
                          └──────► kembali ke OPEN
```

| Status | Perilaku |
|--------|----------|
| **Closed** | Normal. Request diizinkan dan kegagalan dihitung |
| **Open** | Ambang batas terlampaui. Request **langsung ditolak** tanpa menghubungi server, memberi waktu layanan untuk pulih |
| **Half-open** | Setelah waktu tunggu, beberapa request uji diizinkan. Jika berhasil → **closed**, jika gagal → kembali **open** |

#### Kode `failure-detection/check-circuit-breaker.py`

```python
import requests
import pybreaker
from tenacity import retry, stop_after_attempt, wait_fixed, retry_if_exception_type

URL = "http://localhost:44777"

# Closed -> Open setelah 3 kegagalan berturut-turut.
# Open selama 10 detik, lalu Half-Open untuk menguji pemulihan.
breaker = pybreaker.CircuitBreaker(fail_max=3, reset_timeout=10)


@retry(
    stop=stop_after_attempt(5),
    wait=wait_fixed(1),
    retry=retry_if_exception_type(requests.exceptions.RequestException),
    reraise=True,
)
@breaker
def access_url(url: str) -> requests.Response:
    print(f"Attempting to access {url}...")
    response = requests.get(url, timeout=3)
    response.raise_for_status()
    return response


if __name__ == "__main__":
    try:
        access_url(URL)
        print(f"Successfully accessed {URL}")
    except pybreaker.CircuitBreakerError:
        print("Circuit breaker OPEN: permintaan ditolak sementara, layanan diberi waktu pulih.")
    except requests.exceptions.RequestException as e:
        print(f"Failed to access {URL}: {e}")
    print(f"Status circuit breaker sekarang: {breaker.current_state}")
```

#### Penjelasan baris per baris

| Bagian | Penjelasan |
|--------|------------|
| `CircuitBreaker(fail_max=3, reset_timeout=10)` | Sirkuit **terbuka setelah 3 kegagalan berturut-turut**, dan tetap terbuka **10 detik** sebelum masuk half-open |
| `@breaker` | Membungkus fungsi: setiap panggilan dipantau, status sirkuit diperbarui |
| `@retry(...)` | Dipasang **di luar** `@breaker`, jadi setiap percobaan ulang melewati breaker lebih dulu |
| `reraise=True` | Error asli dilempar ulang (bukan dibungkus `RetryError`), sehingga bisa ditangkap sesuai jenisnya |
| `except pybreaker.CircuitBreakerError` | Dilempar saat sirkuit **open**. Bukan turunan `RequestException`, sehingga `retry` **berhenti** dan tidak mengulang lagi |
| `breaker.current_state` | Mencetak status akhir: `closed`, `open`, atau `half-open` |

**Alur saat server mati:**

1. Percobaan 1 → gagal (kegagalan ke-1)
2. Percobaan 2 → gagal (kegagalan ke-2)
3. Percobaan 3 → gagal (kegagalan ke-3) → ambang batas tercapai → sirkuit **OPEN** → `CircuitBreakerError`
4. `retry` tidak mengulang karena error bukan `RequestException` → program berhenti dengan pesan *Circuit breaker OPEN*

Perbedaan dengan `check-retry.py`: retry biasa tetap mencoba **5 kali**, sedangkan circuit breaker berhenti di percobaan **ke-3** dan menolak panggilan berikutnya selama 10 detik.

#### Hasil dan perbedaan dua kondisi

| Kondisi | Perilaku | Status akhir |
|---------|----------|--------------|
| **A. Server mati** | 3 kali mencoba, lalu sirkuit terbuka dan permintaan ditolak | `open` |
| **B. Server aktif** | Berhasil langsung, tidak ada kegagalan yang dihitung | `closed` |

**📁 Hasil praktikum** (kondisi A):

```text
(.venv) % python failure-detection/check-circuit-breaker.py
Attempting to access http://localhost:44777...
Attempting to access http://localhost:44777...
Attempting to access http://localhost:44777...
Circuit breaker OPEN: permintaan ditolak sementara, layanan diberi waktu pulih.
Status circuit breaker sekarang: open
```

**📘 Referensi modul** (kondisi B):

```text
$ python check-circuit-breaker.py
Attempting to access http://localhost:44777...
Successfully accessed http://localhost:44777
```

#### Perbandingan ketiga teknik

| | Heartbeat | Retry | Circuit Breaker |
|---|-----------|-------|-----------------|
| Tugas | Mendeteksi hidup/mati | Mengulang saat gagal | Berhenti mencoba saat gagal terus |
| Jumlah percobaan saat server mati | 1 | 5 | 3 |
| Menahan beban ke server yang rusak? | Tidak | Tidak | **Ya** |
| Output saat server mati | `Server down` | `Failed ... after multiple retries` | `Circuit breaker OPEN` |

---

## 8. Solusi Error (Troubleshooting)

Semua error di bawah ini **benar-benar muncul** pada log praktikum, kecuali yang ditandai *(umum)*.

### 8.1 Docker Desktop tidak bisa dipasang di macOS lama

```text
Error: docker-desktop: docker-desktop: This cask does not run on macOS versions older than Sonoma.
```

**Penyebab:** Docker Desktop mensyaratkan macOS Sonoma (14) atau lebih baru.
**Solusi:** pakai Colima.

```bash
brew install colima docker docker-compose
colima start --cpu 2 --memory 4
```

### 8.2 `Unable to find application named 'Docker'`

```text
% open -a Docker
Unable to find application named 'Docker'
```

**Penyebab:** aplikasi Docker Desktop memang tidak terpasang (lihat 8.1). Perintah `open -a Docker` tidak berlaku untuk Colima.
**Solusi:** nyalakan Docker lewat Colima, dan cek statusnya.

```bash
colima start
docker info > /dev/null 2>&1 && echo "Docker AKTIF" || echo "Docker MATI"
```

Alias praktis yang dipakai di log (tambahkan ke `~/.zshrc`):

```bash
alias docker-status='docker info >/dev/null 2>&1 && echo "Docker AKTIF" || echo "Docker MATI"'
```

### 8.3 Container name `/nginx` sudah dipakai

```text
Error response from daemon: Conflict. The container name "/nginx" is already in use by container "0d3c692faf15...".
You have to remove (or rename) that container to be able to reuse that name
```

**Penyebab:** ada container lama bernama `nginx` dan `docker-compose.yml` memaksa `container_name: nginx`.
**Solusi:**

```bash
docker ps -a                          # cari container "nginx" lama
docker rm -f nginx                    # hapus
docker compose down --remove-orphans  # bersihkan sisa compose
dcu                                   # jalankan lagi
```

### 8.4 `curl` mengembalikan `000`

```text
000
000
```

**Penyebab:** tidak ada server yang menjawab di port 80. Pada praktikum ini penyebabnya nginx gagal dibuat (8.3).
**Solusi:** pastikan nginx berjalan.

```bash
dps                       # harus muncul nginx dan 2 bs_app
docker logs nginx         # cek pesan error nginx
```

### 8.5 `Server down` / `ConnectionError` pada script uji

```text
Server down
...
Failed to access URL after multiple retries: RetryError[<Future ... raised ConnectionError>]
HTTPConnectionPool(host='localhost', port=44777): ... [Errno 111] Connection refused
```

**Penyebab:** aplikasi BlackSheep tidak berjalan di port 44777. Ini **perilaku yang diharapkan** untuk kondisi A, bukan bug.
**Solusi:** jika ingin kondisi B, jalankan aplikasinya di terminal lain.

```bash
cd blacksheep_lb
python dev.py
```

### 8.6 MarkupSafe diturunkan versinya

```text
Uninstalling MarkupSafe-3.0.4: Successfully uninstalled MarkupSafe-3.0.4
Successfully installed MarkupSafe-3.0.2
```

**Bukan error.** `requirements.txt` mengunci `MarkupSafe==3.0.2`, sehingga pip menyesuaikan.

### 8.7 `zsh: no such file or directory: /opt/homebrew/bin/brew`

```text
/Users/danel/.zshrc:27: no such file or directory: /opt/homebrew/bin/brew
```

**Penyebab:** `~/.zshrc` memanggil Homebrew versi Apple Silicon (`/opt/homebrew`), sedangkan komputer ini Intel (Homebrew ada di `/usr/local`).
**Solusi:** hapus atau perbaiki baris 27–29 di `~/.zshrc`. Untuk Intel Mac, pathnya `/usr/local/bin/brew`. Pesan ini hanya peringatan dan tidak menghalangi praktikum.

### 8.8 Peringatan `buildx Docker CLI plugin not found` *(umum)*

```text
WARN[0000] buildx Docker CLI plugin not found: falling back to the classic builder.
```

**Bukan error.** Docker memakai *classic builder* dan build tetap berhasil. Jika ingin menghilangkannya:

```bash
brew install docker-buildx
```

### 8.9 Port 80 sudah dipakai *(umum)*

```text
Bind for 0.0.0.0:80 failed: port is already allocated
```

**Solusi:** cari yang memakai port 80, atau ganti port host.

```bash
sudo lsof -i :80
```

Atau ubah `docker-compose.yml`:

```yaml
    ports:
      - 8080:80        # akses lewat http://localhost:8080
```

### 8.10 Docker daemon tidak berjalan *(umum)*

```text
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

| Sistem | Solusi |
|--------|--------|
| macOS (Colima) | `colima start` |
| Linux systemd | `sudo systemctl start docker` |
| Linux dinit | `sudo dinitctl start dockerd` |
| Windows | Buka Docker Desktop |

### 8.11 `ModuleNotFoundError: No module named 'tenacity'` / `'pybreaker'` *(umum)*

**Penyebab:** virtual environment belum aktif, atau paket belum dipasang.
**Solusi:**

```bash
source .venv/bin/activate
pip install requests tenacity pybreaker
```

### 8.12 `externally-managed-environment` saat `pip install` *(umum)*

**Penyebab:** pip dijalankan di luar virtual environment pada Python sistem yang dilindungi.
**Solusi:** aktifkan venv dulu (`source .venv/bin/activate`). Jangan memakai `--break-system-packages` di komputer pribadi kecuali terpaksa.

### 8.13 Nginx tetap mengarah ke container lama setelah restart *(umum)*

**Penyebab:** nginx menyimpan hasil DNS `bs_app` saat dijalankan. Jika container `bs_app` dibuat ulang dan alamat IP berubah, nginx bisa masih memakai alamat lama.
**Solusi:** restart nginx.

```bash
docker restart nginx
```

---

## 9. Ringkasan Perintah

### Alur lengkap dari nol

```bash
# 1. Siapkan Docker (macOS lama)
brew install colima docker docker-compose
colima start --cpu 2 --memory 4

# 2. Siapkan Python
mkdir -p ~/modul5 && cd ~/modul5
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install blacksheep blacksheep-cli requests tenacity pybreaker

# 3. Buat dan uji aplikasi
blacksheep create                  # isi: blacksheep_lb / mvc / Yes / essentials-configuration / TOML
cd blacksheep_lb
pip install -r requirements.txt
python dev.py                      # buka http://localhost:44777, hentikan dengan Ctrl+C
cd ..

# 4. Buat Dockerfile, nginx, docker-compose.yml, env.sh (isi: lihat bagian 5)

# 5. Jalankan load balancing
source env.sh
dcu
dps
open http://localhost

# 6. Uji failure detection (server mati lalu aktif)
python heartbeat/check-server.py localhost 44777
python failure-detection/check-retry.py
python failure-detection/check-circuit-breaker.py

# 7. Bersihkan
dcd
colima stop
```

### Perintah Docker yang sering dipakai

| Perintah | Fungsi |
|----------|--------|
| `docker ps` | Container yang sedang berjalan |
| `docker ps -a` | Semua container, termasuk yang berhenti |
| `docker logs <nama>` | Lihat log container |
| `docker stop <nama>` / `docker start <nama>` | Hentikan / jalankan container |
| `docker rm -f <nama>` | Hapus paksa container |
| `docker compose up --build -d --scale bs_app=2` | Build, jalankan, buat 2 instance |
| `docker compose down` | Matikan dan hapus semua |

---

## 10. Perbedaan Repo dengan Modul

Beberapa hal pada praktikum ini berbeda dari contoh di modul karena perbedaan lingkungan.

| Hal | Modul (Linux) | Repo ini (macOS) |
|-----|---------------|------------------|
| Sistem operasi | Artix Linux | macOS 13 (Intel) |
| Runtime Docker | `dockerd` (dinit/systemd) | Colima |
| Python | 3.14.4 | 3.13.9 (lokal) dan 3.12-slim (di container) |
| Env manager | `uv` | `venv` |
| `blacksheep_lb/Dockerfile` | Multi-stage (`server_builder`) dengan banyak paket build | Single-stage, lebih ringkas |
| Perintah compose | `sudo docker-compose` | `docker compose` (tanpa `sudo`) |
| Nama container | `load-balancing-bs_app-1` | `modul5-bs_app-1` |
| Pembuatan script `check-*.py` | Disebut di modul (tidak ada kodenya di PDF) | Dibuat langsung di terminal dengan `cat > file <<'EOF'` |

---

<div align="center">

**Usat Jalung · 255410017 · Informatika**
Praktikum Sistem Terdistribusi dan Terdesentralisasi — Universitas Teknologi Digital Indonesia

</div>
