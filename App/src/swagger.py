from flask import jsonify
from flask_swagger_ui import get_swaggerui_blueprint

SWAGGER_URL = '/swagger'
API_URL = '/openapi.json'

swaggerui_blueprint = get_swaggerui_blueprint(
    SWAGGER_URL,
    API_URL,
    config={'app_name': "People API"}
)

def openapi_spec():
    spec = {
        "openapi": "3.0.0",
        "info": {"title": "People API", "version": "1.0.0", "description": "API for managing people data"},
        "servers": [{"url": "/", "description": "API server"}],
        "paths": {
            "/api/people": {
                "get": {"summary": "Get all people"},
                "post": {"summary": "Create a new person"}
            },
            "/api/people/{id}": {
                "get": {"summary": "Get person by ID"},
                "delete": {"summary": "Delete person"}
            },
            "/health": {"get": {"summary": "Health check"}}
        },
        "components": {
            "schemas": {
                "Person": {
                    "type": "object",
                    "properties": {
                        "id": {"type": "integer"},
                        "first_name": {"type": "string"},
                        "last_name": {"type": "string"},
                        "created_at": {"type": "string", "format": "date-time"}
                    }
                },
                "NewPerson": {
                    "type": "object",
                    "required": ["first_name", "last_name"],
                    "properties": {
                        "first_name": {"type":"string"},
                        "last_name": {"type":"string"}
                    }
                }
            }
        }
    }
    return jsonify(spec)