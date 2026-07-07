"""
NBA Game Day API — the compliant workload.

This service is deliberately squeaky-clean so it passes every Polaris check
in this demo: resource requests/limits, liveness and readiness probes,
non-root user, read-only filesystem, no privilege escalation, pinned image tag,
and all capabilities dropped.
"""

import logging
import os

from flask import Flask, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("game-day-api")

VERSION = os.environ.get("APP_VERSION", "v1")

GAMES = [
    {
        "id": 1,
        "home": "Lakers",
        "away": "Celtics",
        "score": "112-108",
        "status": "Final",
        "arena": "Crypto.com Arena",
    },
    {
        "id": 2,
        "home": "Warriors",
        "away": "Nuggets",
        "score": "105-99",
        "status": "Final",
        "arena": "Chase Center",
    },
    {
        "id": 3,
        "home": "Bucks",
        "away": "Heat",
        "score": "98-95",
        "status": "Q4 2:30",
        "arena": "Fiserv Forum",
    },
    {
        "id": 4,
        "home": "Thunder",
        "away": "Mavericks",
        "score": "88-82",
        "status": "Q3 5:15",
        "arena": "Paycom Center",
    },
    {
        "id": 5,
        "home": "Knicks",
        "away": "76ers",
        "score": "0-0",
        "status": "Scheduled",
        "arena": "Madison Square Garden",
    },
]


@app.route("/")
def index():
    return jsonify(
        {
            "service": "game-day-api",
            "version": VERSION,
            "description": "NBA Game Day Scores — passed Polaris inspection",
            "endpoints": [
                "GET /games — all games",
                "GET /games/<id> — single game",
                "GET /live — live games only",
                "GET /health — health check",
            ],
        }
    )


@app.route("/games")
def games():
    return jsonify({"games": GAMES, "count": len(GAMES)})


@app.route("/games/<int:game_id>")
def game(game_id):
    match = next((g for g in GAMES if g["id"] == game_id), None)
    if not match:
        return jsonify({"error": "game not found"}), 404
    return jsonify(match)


@app.route("/live")
def live():
    live_games = [g for g in GAMES if g["status"] not in ("Final", "Scheduled")]
    return jsonify({"live_games": live_games, "count": len(live_games)})


@app.route("/health")
def health():
    return jsonify({"status": "ok", "version": VERSION})


if __name__ == "__main__":
    logger.info("game-day-api %s starting on :8080", VERSION)
    app.run(host="0.0.0.0", port=8080)
