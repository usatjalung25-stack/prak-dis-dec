# 📘 Modul 5: Fault Tolerance (Toleransi Kegagalan)

## 📋 Daftar Isi
1. [Pendahuluan](#1-pendahuluan)
2. [Struktur Proyek](#2-struktur-proyek)
3. [Persyaratan & Instalasi](#3-persyaratan--instalasi)
4. [Penjelasan Kode & Implementasi](#4-penjelasan-kode--implementasi)
5. [Cara Menjalankan Proyek](#5-cara-menjalankan-proyek)
6. [Output & Bukti Eksekusi](#6-output--bukti-eksekusi)
7. [Solusi Masalah (Troubleshooting)](#7-solusi-masalah-troubleshooting)

---

## 1. Pendahuluan
Modul ini membahas implementasi **Fault Tolerance** (Toleransi Kegagalan) pada sistem terdistribusi. Tujuan utamanya adalah memastikan sistem tetap dapat beroperasi atau pulih dengan cepat ketika terjadi kegagalan pada salah satu komponen. Teknik yang diimplementasikan dalam modul ini meliputi:
- **Load Balancing**: Mendistribusikan beban lalu lintas ke beberapa instance aplikasi.
- **Heartbeat**: Memantau ketersediaan server secara berkala.
- **Retry Pattern**: Mencoba ulang permintaan yang gagal sementara (transient failure).
- **Circuit Breaker**: Mencegah permintaan berulang ke layanan yang sedang *down* agar layanan tersebut punya waktu untuk pulih.

---

## 2. Struktur Proyek
