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
