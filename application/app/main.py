from flask import Flask, jsonify
import string
from random import randint

# the all-important app variable:
app = Flask(__name__)

@app.route("/")
def hello():
  return "Hello world! Try /api to request a sample json payload"

@app.route("/api")
def api():
  letters = string.ascii_letters
  keys = list(range(0,len(letters)))
  values = [letters[randint(0, len(letters))-1] for letter in letters]
  response = dict(zip(keys,values))

  return jsonify(response)

if __name__ == "__main__":
  app.run(host='0.0.0.0', debug=True, port=8080)
