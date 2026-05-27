import webview
import os
import sys

def resource(rel):
    if getattr(sys, 'frozen', False):
        base = sys._MEIPASS
    else:
        base = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(base, rel)

if __name__ == '__main__':
    window = webview.create_window(
        title='AvikQuest',
        url=f'file://{resource("app.html")}',
        width=1200,
        height=820,
        min_size=(960, 660),
        background_color='#08080f',
        text_select=False,
    )
    webview.start(gui='cocoa')
