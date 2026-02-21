import threading
import time
from flask import Flask, request
import socket

app = Flask(__name__)

# Set of active targets (tuple of IP and port)
targets = set()
targets_lock = threading.Lock()

def connect_to_target(ip, port, timeout=1):
    """Connect to target via TCP socket"""
    try:
        with socket.create_connection((ip, int(port)), timeout=timeout):
            print(f"[✓] Created connection {ip}:{port}")
    except Exception as e:
        print(f"[✗] Failed to connect {ip}:{port} - {e}")

def connector():
    """Background thread to continuously connect to targets"""
    while True:
        with targets_lock:
            current_targets = list(targets)
        for ip, port in current_targets:
            connect_to_target(ip, port)
        time.sleep(2)

@app.route('/')
def handle_request():
    action = request.args.get('action')
    ip = request.args.get('ip')
    port = request.args.get('port')

    if not all([action, ip, port]):
        return "Missing required parameters: action, ip, port", 400

    target = (ip, int(port))

    with targets_lock:
        if action == 'open':
            targets.add(target)
            return f"Opened {ip}:{port}", 200
        elif action == 'close':
            targets.discard(target)
            return f"Closed {ip}:{port}", 200
        else:
            return f"Invalid action '{action}'", 400

if __name__ == '__main__':
    threading.Thread(target=connector, daemon=True).start()
    # Start the Flask server
    app.run(host='127.0.0.1', port=8181)

