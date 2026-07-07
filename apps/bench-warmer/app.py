"""
Bench Warmer — the rogue workload.

Used as the base image for every `k8s/bad-pods/*.yaml` manifest. Each variant
of the manifest tries to violate a different Polaris check (runs as root,
uses :latest, missing probes, no resources, etc.) so the demo can show the
dashboard flagging violations and the webhook rejecting them.

The app itself is trivial — it just prints bench-warming commentary on a loop
and exposes a /health endpoint, so when one of the rogue manifests *does* get
deployed (before the webhook is active) you can still see it running.
"""

import logging
import os
import random
import threading
import time

from flask import Flask, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("bench-warmer")

LINES = [
    "Coach, put me in! I've been stretching for three quarters.",
    "I'm basically a professional towel waver at this point.",
    "My jersey is still factory-fresh. Zero sweat detected.",
    "Someone tell the scoreboard I exist.",
    "I warmed this bench so well, it has a five-star Yelp rating.",
    "If sitting were an Olympic sport, I'd be a gold medalist.",
]


def complain_forever():
    while True:
        logger.info("BENCH WARMER: %s", random.choice(LINES))
        time.sleep(5)


@app.route("/")
def index():
    return jsonify(
        {
            "service": "bench-warmer",
            "version": os.environ.get("APP_VERSION", "v1"),
            "description": "Riding the pine. Used to demonstrate Polaris violations.",
        }
    )


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    threading.Thread(target=complain_forever, daemon=True).start()
    logger.info("bench-warmer starting on :8080")
    app.run(host="0.0.0.0", port=8080)
