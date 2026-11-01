#!/usr/bin/env bash
# setup-modul5.sh: membuat semua file buatan sendiri untuk Modul 5.
# Jalankan SETELAH `blacksheep create` (folder ~/modul5/blacksheep_lb sudah ada).
set -euo pipefail
cd ~/modul5
mkdir -p nginx heartbeat failure-detection

# ---- 1. Dockerfile aplikasi
cat > blacksheep_lb/Dockerfile <<'EOF'
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
EOF

# ---- 2. Nginx (load balancer)
cat > nginx/Dockerfile <<'EOF'
FROM nginx

# Override the default nginx configuration file
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
EOF

cat > nginx/nginx.conf <<'EOF'
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
EOF

# ---- 3. Docker Compose dan alias
cat > docker-compose.yml <<'EOF'
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
EOF

cat > env.sh <<'EOF'
alias dcu="docker compose up --build -d --scale bs_app=2"
alias dcd="docker compose down"
alias dps="docker ps --format '{{.Image}} {{.Names}}'"
alias dcln="docker logs nginx"
EOF

# ---- 4. Heartbeat
cat > heartbeat/check-server.py <<'EOF'
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
EOF

# ---- 5. Retry
cat > failure-detection/check-retry.py <<'EOF'
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
EOF

# ---- 6. Circuit breaker
cat > failure-detection/check-circuit-breaker.py <<'EOF'
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
EOF

# ---- 7. Tambahan: retry dengan penanganan error + server palsu (status 500)
cat > failure-detection/check-retry-handling.py <<'EOF'
import logging
import sys

import requests
from tenacity import (
    before_sleep_log,
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_fixed,
)

URL = "http://localhost:44777"

# Format log: waktu, tingkat (INFO/WARNING/ERROR), pesan
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("retry")


@retry(
    stop=stop_after_attempt(5),                      # maksimal 5 percobaan
    wait=wait_fixed(2),                              # jeda 2 detik antar percobaan
    retry=retry_if_exception_type(requests.exceptions.RequestException),
    before_sleep=before_sleep_log(log, logging.WARNING),  # catat tiap kegagalan
    reraise=True,                                    # lempar error ASLI, bukan RetryError
)
def access_url(url: str) -> requests.Response:
    log.info("Attempting to access %s ...", url)
    response = requests.get(url, timeout=3)
    response.raise_for_status()                      # 4xx/5xx dianggap error
    return response


def main() -> int:
    """Kembalikan kode keluar: 0 = sukses, 1 = gagal setelah retry, 2 = error tak terduga."""
    try:
        access_url(URL)
    except requests.exceptions.ConnectionError:
        log.error("Server tidak dapat dihubungi (mati atau port salah).")
        log.error("Nyalakan dulu server: cd blacksheep_lb && python dev.py")
        return 1
    except requests.exceptions.Timeout:
        log.error("Server tidak menjawab dalam batas waktu 3 detik.")
        return 1
    except requests.exceptions.HTTPError as exc:
        status = exc.response.status_code if exc.response is not None else "?"
        log.error("Server menjawab tetapi dengan status error: %s", status)
        return 1
    except Exception:
        # Bukan masalah jaringan (misalnya bug di kode): jangan di-retry, tampilkan detailnya
        log.exception("Error tak terduga")
        return 2

    log.info("Successfully accessed %s", URL)
    return 0


if __name__ == "__main__":
    sys.exit(main())
EOF

cat > failure-detection/fake-server-500.py <<'EOF'
"""Server palsu untuk uji: selalu menjawab status 500 di port 44777.

Dipakai untuk melihat bagaimana check-retry-handling.py bereaksi saat server
HIDUP tetapi menjawab dengan error (bukan mati).
"""
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(500)
        self.end_headers()
        self.wfile.write(b"Internal Server Error")

    def log_message(self, *args):  # matikan log bawaan agar terminal bersih
        pass


if __name__ == "__main__":
    print("Server palsu (selalu 500) berjalan di http://localhost:44777  (Ctrl+C untuk berhenti)")
    HTTPServer(("localhost", 44777), Handler).serve_forever()
EOF

echo "Selesai. 10 file dibuat di ~/modul5"
