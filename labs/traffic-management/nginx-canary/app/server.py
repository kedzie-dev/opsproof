import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


version = os.environ.get("VERSION", "v1")
fail_every = int(os.environ.get("FAIL_EVERY", "0"))
requests = 0


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        global requests
        if self.path == "/health":
            self.send_response(200)
            self.end_headers()
            return
        if self.path != "/orders/42":
            self.send_error(404)
            return

        requests += 1
        if fail_every and requests % fail_every == 0:
            self.send_error(503, "simulated v2 failure")
            return

        body = json.dumps({"order_id": 42, "served_by": version}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        print(f"{version} {self.address_string()} {format % args}", flush=True)


ThreadingHTTPServer(("", 8080), Handler).serve_forever()
