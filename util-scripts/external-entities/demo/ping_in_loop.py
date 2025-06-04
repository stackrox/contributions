from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import threading
import socket
import time

# Shared set of targets
targets_lock = threading.Lock()
targets = set()
ping_interval = 2  # seconds between pings

def ping_target(ip, port):
    try:
        with socket.create_connection((ip, port), timeout=2):
            print(f"Success: {ip}:{port}")
    except Exception as e:
        print(f"Failed: {ip}:{port} - {e}")

def ping_loop():
    while True:
        with targets_lock:
            current_targets = list(targets)
        for ip, port in current_targets:
            ping_target(ip, port)
        time.sleep(ping_interval)

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        query = parse_qs(parsed_path.query)

        if parsed_path.path == "/action=open":
            ip = query.get("ip", [None])[0]
            port = query.get("port", [None])[0]
            print("ip= ", ip, " port= ", port)

            if ip and port:
                try:
                    port = int(port)
                    with targets_lock:
                        targets.clear()  # Reset all current targets
                        targets.add((ip, port))
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(f"Pinging {ip}:{port}...".encode())
                except ValueError:
                    self.send_response(400)
                    self.end_headers()
                    self.wfile.write(b"Invalid port value.")
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Missing ip or port parameter.")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        return  # Disable default logging

def run_server(port=8181):
    server = HTTPServer(('127.0.0.1', port), RequestHandler)
    print(f"Server started on port {port}")
    server.serve_forever()

if __name__ == "__main__":
    threading.Thread(target=ping_loop, daemon=True).start()
    run_server()

