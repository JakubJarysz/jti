import os
import logging
import psycopg2

logger = logging.getLogger(__name__)

def get_db_connection():
    """
    Create a connection to PostgreSQL using a password.
    """
    db_host = os.environ.get('DB_HOST', 'localhost')
    db_name = os.environ.get('DB_NAME', 'mydb')
    db_user = os.environ.get('DB_USER', 'postgres')
    db_port = os.environ.get('DB_PORT', '5432')
    pwd = os.environ.get('DB_PASSWORD', 'password')
    
    logger.info("Connecting to database using password")
    return psycopg2.connect(
        host=db_host,
        database=db_name,
        user=db_user,
        password=pwd,
        port=db_port
    )

def init_db():
    """Ensure the 'people' table exists."""
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS people (
                id SERIAL PRIMARY KEY,
                first_name VARCHAR(100) NOT NULL,
                last_name VARCHAR(100) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        cur.close()
        logger.info("Table 'people' exists or was created.")
    except Exception as e:
        logger.error(f"DB initialization error: {e}")
        raise
    finally:
        if conn:
            conn.close()