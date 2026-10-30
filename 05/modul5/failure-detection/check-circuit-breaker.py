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
