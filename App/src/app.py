from flask import Flask, jsonify
import logging
import os

app = Flask(__name__)

# logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# register modules (local imports to avoid cyclic imports)
from .handlers import api_bp  # noqa: E402
from .swagger import swaggerui_blueprint, openapi_spec  # noqa: E402
from .db import init_db, get_db_connection  # noqa: E402

# register blueprints
app.register_blueprint(swaggerui_blueprint, url_prefix='/swagger')
app.register_blueprint(api_bp)

# openapi.json
app.add_url_rule('/openapi.json', 'openapi_spec', openapi_spec)

@app.before_first_request
def startup():
    """Initialize DB before handling the first request (avoids init at import)."""
    try:
        init_db()
    except Exception as e:
        logger.error(f"Init DB failed on startup: {e}")

@app.route('/')
def home():
    """Home page with links"""
    return """
    <html>
        <head>
            <title>People API</title>
            <style> body { font-family: Arial, sans-serif; margin: 50px; } h1 { color: #0078d4; } a { display: block; margin: 10px 0; } </style>
        </head>
        <body>
            <h1>People API</h1>
            <a href="/swagger">API Documentation (Swagger UI)</a>
            <a href="/api/people">People list</a>
            <a href="/health">Health</a>
        </body>
    </html>
    """

@app.route('/health')
def health():
    """Health check"""
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)