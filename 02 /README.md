# Menggunakan uv untuk Mengelola Environment dan Paket Python

Panduan praktis (bukan panduan lengkap) untuk membuat *workspace* proyek dengan versi Python tertentu dan paket khusus menggunakan [uv](https://docs.astral.sh/uv/).

- **Sistem operasi**: macOS (x86_64)
- **uv**: 0.13.0
- **Python**: 3.12.15 (CPython)
- **Last update**: 10 Oktober 2026

## Daftar Isi

- [Instalasi](#instalasi)
- [Update](#update)
- [Membuat Workspace](#membuat-workspace)
- [Membuat Environment](#membuat-environment)
- [Mengelola Paket](#mengelola-paket)
- [Menyimpan Daftar Paket](#menyimpan-daftar-paket)
- [Troubleshooting](#troubleshooting)

## Instalasi

Petunjuk lengkap: <https://docs.astral.sh/uv/getting-started/installation/>. Berikut contoh di macOS/Linux:

```bash
$ curl -LsSf https://astral.sh/uv/install.sh | sh
downloading uv 0.13.0 x86_64-apple-darwin
skipping sha256 checksum verification (it requires the 'sha256sum' command)
installing to /Users/danel/.local/bin
  uv
  uvx
everything's installed!
```

Pastikan `$PATH` berisi lokasi uv diinstal (`~/.local/bin`). Cek dengan:

```bash
$ uv --version
```

## Update

```bash
$ uv self update
```

## Membuat Workspace

Buat direktori yang akan menjadi workspace proyek:

```bash
$ mkdir workspace-01
$ cd workspace-01
```

Lihat daftar versi Python yang tersedia:

```bash
$ uv python list
cpython-3.15.0-macos-x86_64-none                  <download available>
cpython-3.14.8-macos-x86_64-none                  <download available>
cpython-3.14.4-macos-x86_64-none                  /Users/danel/.local/bin/python3.14 -> ...
cpython-3.13.9-macos-x86_64-none                  /usr/local/bin/python3.13 -> ...
cpython-3.12.15-macos-x86_64-none                 /Users/danel/.local/share/uv/python/cpython-3.12-macos-x86_64-none/bin/python3.12
cpython-3.11.17-macos-x86_64-none                 <download available>
...
```

Pin versi Python untuk workspace ini. Cara paling sederhana adalah memakai nomor versi:

```bash
$ uv python pin 3.12
Updated `.python-version` from `/home/bpdp/.local/bin/python3.14` -> `3.12`
```

> **Catatan**: `uv python pin` juga bisa menerima path executable (kolom kanan pada `uv python list`). Jika versi belum terpasang, uv akan mengunduhnya otomatis (hanya sekali).

File `.python-version` akan dibuat di direktori tersebut.

## Membuat Environment

```bash
$ uv venv
Using CPython 3.12.15
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
```

Aktifkan environment:

```bash
$ source .venv/bin/activate
(workspace-01) $ which python
/Users/danel/workspace-01/.venv/bin/python
```

Prefix `(workspace-01)` menandakan environment yang sedang aktif. Untuk keluar, gunakan:

```bash
(workspace-01) $ deactivate
```

## Mengelola Paket

Gunakan `uv pip`. Perintahnya kompatibel dengan `pip`, tetapi hanya berlaku untuk workspace ini.

```bash
(workspace-01) $ uv pip install pandas
Resolved 4 packages in 627ms
Prepared 4 packages in 2.92s
Installed 4 packages in 192ms
 + numpy==2.5.3
 + pandas==3.0.6
 + python-dateutil==2.9.0.post0
 + six==1.17.0
```

Lihat paket yang terpasang:

```bash
(workspace-01) $ uv pip list
Package         Version
--------------- -----------
numpy           2.5.3
pandas          3.0.6
python-dateutil 2.9.0.post0
six             1.17.0
```

## Menyimpan Daftar Paket

Simpan ke `requirements.txt` agar environment bisa direproduksi:

```bash
(workspace-01) $ uv pip freeze > requirements.txt
```

Pasang ulang di mesin lain:

```bash
$ uv pip install -r requirements.txt
```

## Troubleshooting

**`source: no such file or directory: /Users/danel/.local/bin/env`**

File `env` tidak selalu dibuat oleh installer. Tambahkan PATH secara manual ke `~/.zshrc`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**`mkdir: workspace-01: File exists`**

Direktori sudah ada, jadi cukup lanjutkan dengan `cd workspace-01`.

## Struktur Akhir Workspace

```
workspace-01/
├── .python-version
├── .venv/
└── requirements.txt
```

> Tambahkan `.venv/` ke `.gitignore` agar tidak ikut ter-commit.

## Referensi

- Dokumentasi uv: <https://docs.astral.sh/uv/>
- Panduan asli oleh Dr. Bambang Purnomosidi D. P. ([PT Neo Akselerasi Indonesia](https://neo-x.id))
