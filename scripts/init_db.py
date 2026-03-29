import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / 'alarms.db'

DEFAULT_ALARMS = [
    ('Кабінет', '+380676739457', '721801', '7218*10', 0),
    ('Гараж', '+380676739457', '721801', '721800', 1),
    ('Село', '+380676739457', '721801', '721800', 2),
    ('Квартира', '+380676739457', '721801', '721800', 3),
    ('Бабуся Леся', '+380676739457', '721801', '721800', 4),
    ('Кладовка кабінет', '+380676739457', '7218*29', '7218*20', 5),
]


def initialize_database() -> None:
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute(
            '''
            CREATE TABLE IF NOT EXISTS users (
                username TEXT PRIMARY KEY,
                password TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            '''
        )

        conn.execute(
            '''
            CREATE TABLE IF NOT EXISTS auth_tokens (
                token TEXT PRIMARY KEY,
                username TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(username) REFERENCES users(username)
            )
            '''
        )

        conn.execute(
            '''
            CREATE TABLE IF NOT EXISTS alarms (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                phone TEXT NOT NULL,
                arm TEXT NOT NULL,
                disarm TEXT NOT NULL,
                sort_order INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            '''
        )

        count = conn.execute('SELECT COUNT(*) FROM alarms').fetchone()[0]
        if count == 0:
            conn.executemany(
                '''
                INSERT INTO alarms(title, phone, arm, disarm, sort_order)
                VALUES (?, ?, ?, ?, ?)
                ''',
                DEFAULT_ALARMS,
            )

        conn.commit()
    finally:
        conn.close()


if __name__ == '__main__':
    initialize_database()
    print(f'Database initialized at: {DB_PATH}')
