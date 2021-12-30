from flask import Flask

# Flask
app = Flask(__name__)

@app.route('/test')

def index():
    return 'Hello Flask'

app.run()       # 服务器跑起来

# print(__name__)     # 当前这个文件