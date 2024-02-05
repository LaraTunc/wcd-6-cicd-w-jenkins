import os
from flask import Flask
app = Flask(__name__)

@app.route("/")
def main():
    return "Success! Welcome My App!"


@app.route('/hello')
def courses():
    return 'HELLO WORLD!'

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
