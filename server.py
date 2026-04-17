#!/usr/bin/env python3
# server.py — receives JSON POSTs and stores them to data.txt
# THIS SCRIPT IS FOR EDUCATIONAL PURPOSES ONLY! DO NOT RUN ON PRODUCTION OR SENSITIVE ENVIRONMENTS

import os
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

SEPARATOR = "=" * 60

DATA_FILE = os.path.join(os.path.dirname(__file__), "data.txt")
PORT = 8080


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        timestamp = datetime.now(timezone.utc).isoformat()
        ip = self.client_address[0]
        entry = (
            f"{SEPARATOR}\n"
            f"timestamp: {timestamp}\n"
            f"ip: {ip}\n"
            f"{SEPARATOR}\n"
            f"{body.decode('utf-8', errors='replace')}\n"
        )
        with open(DATA_FILE, "a") as f:
            f.write(entry)
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if self.path == "/data.txt" and os.path.exists(DATA_FILE):
            with open(DATA_FILE, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} - {fmt % args}")


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"Serving on 0.0.0.0:{PORT}")
    server.serve_forever()
