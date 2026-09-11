import json
import os
import threading
import urllib.error
import urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


role = os.environ.get("ROLE", "order")
payment_delay_ms = int(os.environ.get("PAYMENT_DELAY_MS", "0"))
payment_fail_every = int(os.environ.get("PAYMENT_FAIL_EVERY", "0"))
payment_requests = 0
payment_lock = threading.Lock()


def send_json(handler, status, body):
    encoded = json.dumps(body).encode()
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", str(len(encoded)))
    handler.end_headers()
    handler.wfile.write(encoded)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            send_json(self, 200, {"role": role, "ready": True})
            return
        if role == "payment" and self.path == "/payment-status":
            self.payment_status()
            return
        if role == "order" and self.path == "/orders/42":
            self.order_status()
            return
        self.send_error(404)

    def payment_status(self):
        global payment_requests
        with payment_lock:
            payment_requests += 1
            request_number = payment_requests
        if payment_delay_ms:
            threading.Event().wait(payment_delay_ms / 1000)
        if payment_fail_every and request_number % payment_fail_every == 0:
            send_json(self, 503, {"payment": "unavailable", "request_number": request_number})
            return
        send_json(self, 200, {"payment": "approved", "request_number": request_number})

    def order_status(self):
        upstream = os.environ.get("UPSTREAM_URL", "http://127.0.0.1:10000/payment-status")
        try:
            with urllib.request.urlopen(upstream, timeout=1) as response:
                payment = json.load(response)
            send_json(self, 200, {"order_id": 42, "payment": payment, "via": "envoy-sidecar"})
        except urllib.error.HTTPError as error:
            send_json(self, error.code, {"order_id": 42, "payment_error": error.code, "via": "envoy-sidecar"})
        except (urllib.error.URLError, TimeoutError) as error:
            send_json(self, 503, {"order_id": 42, "payment_error": str(error), "via": "envoy-sidecar"})

    def log_message(self, format, *args):
        print(f"{role} {self.address_string()} {format % args}", flush=True)


def run_client():
    target = os.environ.get("ORDER_URL", "http://order-api:8080/orders/42")
    count = int(os.environ.get("REQUESTS", "20"))
    concurrency = int(os.environ.get("CONCURRENCY", "10"))

    def request_once(_):
        try:
            with urllib.request.urlopen(target, timeout=2) as response:
                return response.status
        except urllib.error.HTTPError as error:
            return error.code
        except (urllib.error.URLError, TimeoutError):
            return "network_error"

    with ThreadPoolExecutor(max_workers=concurrency) as executor:
        result = Counter(executor.map(request_once, range(count)))
    print(json.dumps({"requests": count, "concurrency": concurrency, "status_counts": result}, sort_keys=True), flush=True)


if role == "client":
    run_client()
else:
    ThreadingHTTPServer(("", 8080), Handler).serve_forever()
