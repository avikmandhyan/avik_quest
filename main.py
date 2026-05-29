import webview
import os
import sys
import json
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler

SAVE_FILE = os.path.expanduser('~/.avikquest_save.json')

def get_base():
    if getattr(sys, 'frozen', False):
        return sys._MEIPASS
    return os.path.dirname(os.path.abspath(__file__))

class API:
    def save(self, data):
        try:
            with open(SAVE_FILE, 'w') as f:
                json.dump(data, f)
            return True
        except Exception as e:
            print(f'Save error: {e}')
            return False

    def load(self):
        try:
            if os.path.exists(SAVE_FILE):
                with open(SAVE_FILE, 'r') as f:
                    return json.load(f)
        except Exception as e:
            print(f'Load error: {e}')
        return None

def start_server(base_dir, port=39871):
    """Serve the app over localhost so localStorage works."""
    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=base_dir, **kwargs)
        def log_message(self, *args):
            pass  # suppress access logs
    server = HTTPServer(('127.0.0.1', port), Handler)
    t = threading.Thread(target=server.serve_forever, daemon=True)
    t.start()
    return server

if __name__ == '__main__':
    base = get_base()
    port = 39871
    start_server(base, port)

    api = API()
    window = webview.create_window(
        title='AvikQuest — Life RPG',
        url=f'http://127.0.0.1:{port}/app.html',
        width=1100,
        height=780,
        min_size=(900, 650),
        background_color='#0f0f13',
        js_api=api,
    )
    webview.start(gui='cocoa')
