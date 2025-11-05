import logging
from flask import Blueprint, request, jsonify
from psycopg2.extras import RealDictCursor
from .db import get_db_connection

logger = logging.getLogger(__name__)
api_bp = Blueprint('api', __name__, url_prefix='/api')

@api_bp.route('/people', methods=['GET', 'POST'])
def people():
    try:
        if request.method == 'POST':
            data = request.get_json(silent=True)
            if not data:
                return jsonify({"error": "Missing request body"}), 400
            first_name = (data.get('first_name') or '').strip()
            last_name = (data.get('last_name') or '').strip()
            if not first_name or not last_name:
                return jsonify({"error": "First name and last name are required"}), 400

            conn = get_db_connection()
            try:
                cur = conn.cursor(cursor_factory=RealDictCursor)
                cur.execute(
                    "INSERT INTO people (first_name, last_name) VALUES (%s, %s) RETURNING *",
                    (first_name, last_name)
                )
                person = cur.fetchone()
                conn.commit()
                cur.close()
                return jsonify(dict(person)), 201
            finally:
                conn.close()

        else:  # GET
            conn = get_db_connection()
            try:
                cur = conn.cursor(cursor_factory=RealDictCursor)
                cur.execute("SELECT * FROM people ORDER BY id")
                people_list = cur.fetchall()
                cur.close()
                return jsonify([dict(p) for p in people_list]), 200
            finally:
                conn.close()

    except Exception as e:
        logger.exception("Error in /api/people")
        return jsonify({"error": str(e)}), 500

@api_bp.route('/people/<int:person_id>', methods=['GET', 'DELETE'])
def person_by_id(person_id):
    try:
        conn = get_db_connection()
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            if request.method == 'GET':
                cur.execute("SELECT * FROM people WHERE id = %s", (person_id,))
                person = cur.fetchone()
                cur.close()
                if person:
                    return jsonify(dict(person)), 200
                return jsonify({"error": "Person not found"}), 404

            else:  # DELETE
                cur.execute("DELETE FROM people WHERE id = %s RETURNING *", (person_id,))
                person = cur.fetchone()
                conn.commit()
                cur.close()
                if person:
                    logger.info(f"Deleted person with ID: {person_id}")
                    return jsonify({"message": "Person was deleted", "data": dict(person)}), 200
                return jsonify({"error": "Person not found"}), 404
        finally:
            conn.close()

    except Exception as e:
        logger.exception(f"Error in /api/people/{person_id}")
        return jsonify({"error": str(e)}), 500