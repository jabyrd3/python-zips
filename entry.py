from flask import Flask, render_template
import json

app = Flask(__name__)
f = open('/zips/zips.json')
zips = json.load(f)

@app.route("/<zip>")
def render(zip):
    for i in zips['data']:
        if i['zip'] == zip:
            data = i
            return render_template("root.html", data=data)

@app.route("/zips")
def get_zips():
    return zips

@app.route("/zips/<zip>")
def get_zip(zip):
    for i in zips['data']:
        if i['zip'] == zip:
            data = i
    return data
if __name__ == "__main__":
   app.run(host="0.0.0.0", port=5000)
