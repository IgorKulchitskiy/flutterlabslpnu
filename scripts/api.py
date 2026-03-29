import json
import os
import secrets
import sqlite3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse

from init_db import DB_PATH, initialize_database


LOG_PATH = os.path.join(os.path.dirname(__file__), 'api.log')


def _log(message: str) -> None:
    print(message, flush=True)
    try:
        with open(LOG_PATH, 'a', encoding='utf-8') as log_file:
            log_file.write(message + '\n')
    except Exception:
        pass


def _log_request_start(handler: BaseHTTPRequestHandler) -> None:
    _log(f'[REQ] {handler.command} {handler.path}')


def _json_response(handler: BaseHTTPRequestHandler, status: int, payload) -> None:
    body = json.dumps(payload).encode('utf-8')
    handler.send_response(status)
    handler.send_header('Content-Type', 'application/json; charset=utf-8')
    handler.send_header('Content-Length', str(len(body)))
    handler.send_header('Access-Control-Allow-Origin', '*')
    handler.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    handler.send_header(
        'Access-Control-Allow-Methods',
        'GET, POST, PATCH, DELETE, OPTIONS',
    )
    handler.end_headers()
    handler.wfile.write(body)
    _log(f'[{status}] {handler.command} {handler.path}')


def _read_json(handler: BaseHTTPRequestHandler) -> dict:
    try:
        length = int(handler.headers.get('Content-Length', '0'))
        raw = handler.rfile.read(length) if length > 0 else b''
        if not raw:
            return {}
        data = json.loads(raw.decode('utf-8'))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def _extract_bearer_token(handler: BaseHTTPRequestHandler) -> str | None:
    header = handler.headers.get('Authorization', '').strip()
    if not header.lower().startswith('bearer '):
        return None

    token = header[7:].strip()
    return token if token else None


def _authorized_username(handler: BaseHTTPRequestHandler) -> str | None:
    token = _extract_bearer_token(handler)
    if token is None:
        return None

    conn = _get_conn()
    try:
        row = conn.execute(
            'SELECT username FROM auth_tokens WHERE token = ?',
            (token,),
        ).fetchone()
    finally:
        conn.close()

    if row is None:
        return None

    return row['username']


class ApiHandler(BaseHTTPRequestHandler):
    def log_message(self, format: str, *args) -> None:
        _log(f'[HTTP] {self.address_string()} - {format % args}')

    def do_OPTIONS(self) -> None:
        _log_request_start(self)
        _json_response(self, 200, {'ok': True})

    def do_GET(self) -> None:
        _log_request_start(self)
        path = urlparse(self.path).path

        if path == '/health':
            _json_response(self, 200, {'status': 'ok'})
            return

        if path == '/api/alarms':
            if _authorized_username(self) is None:
                _json_response(self, 401, {'message': 'unauthorized'})
                return

            conn = _get_conn()
            try:
                rows = conn.execute(
                    '''
                    SELECT id, title, phone, arm, disarm
                    FROM alarms
                    ORDER BY sort_order ASC, id ASC
                    '''
                ).fetchall()
            finally:
                conn.close()

            alarms = [
                {
                    'id': row['id'],
                    'title': row['title'],
                    'phone': row['phone'],
                    'arm': row['arm'],
                    'disarm': row['disarm'],
                }
                for row in rows
            ]

            _json_response(self, 200, alarms)
            return

        if path.startswith('/api/users/'):
            auth_username = _authorized_username(self)
            if auth_username is None:
                _json_response(self, 401, {'message': 'unauthorized'})
                return

            username = unquote(path.replace('/api/users/', '', 1)).strip()
            if not username:
                _json_response(self, 400, {'message': 'username is required'})
                return

            if auth_username != username:
                _json_response(self, 403, {'message': 'forbidden'})
                return

            conn = _get_conn()
            try:
                row = conn.execute(
                    'SELECT username, password FROM users WHERE username = ?',
                    (username,),
                ).fetchone()
            finally:
                conn.close()

            if row is None:
                _json_response(self, 404, {'message': 'user not found'})
                return

            _json_response(
                self,
                200,
                {'username': row['username'], 'password': row['password']},
            )
            return

        _json_response(self, 404, {'message': 'not found'})

    def do_POST(self) -> None:
        _log_request_start(self)
        path = urlparse(self.path).path
        payload = _read_json(self)

        if path == '/api/register':
            username = str(payload.get('username', '')).strip()
            password = str(payload.get('password', '')).strip()

            if not username or not password:
                _json_response(
                    self,
                    400,
                    {'message': 'username and password are required'},
                )
                return

            conn = _get_conn()
            try:
                existing = conn.execute(
                    'SELECT username FROM users WHERE username = ?',
                    (username,),
                ).fetchone()
                if existing is not None:
                    _json_response(self, 409, {'message': 'user already exists'})
                    return

                conn.execute(
                    'INSERT INTO users(username, password) VALUES (?, ?)',
                    (username, password),
                )
                conn.commit()
            finally:
                conn.close()

            token = secrets.token_hex(32)

            conn = _get_conn()
            try:
                conn.execute(
                    'INSERT INTO auth_tokens(token, username) VALUES (?, ?)',
                    (token, username),
                )
                conn.commit()
            finally:
                conn.close()

            _json_response(
                self,
                201,
                {'username': username, 'password': password, 'token': token},
            )
            return

        if path == '/api/login':
            username = str(payload.get('username', '')).strip()
            password = str(payload.get('password', '')).strip()

            if not username or not password:
                _json_response(
                    self,
                    400,
                    {'message': 'username and password are required'},
                )
                return

            conn = _get_conn()
            try:
                row = conn.execute(
                    'SELECT username, password FROM users WHERE username = ?',
                    (username,),
                ).fetchone()
            finally:
                conn.close()

            if row is None or row['password'] != password:
                _json_response(self, 401, {'message': 'invalid credentials'})
                return

            token = secrets.token_hex(32)

            conn = _get_conn()
            try:
                conn.execute(
                    'DELETE FROM auth_tokens WHERE username = ?',
                    (username,),
                )
                conn.execute(
                    'INSERT INTO auth_tokens(token, username) VALUES (?, ?)',
                    (token, username),
                )
                conn.commit()
            finally:
                conn.close()

            _json_response(
                self,
                200,
                {
                    'username': row['username'],
                    'password': row['password'],
                    'token': token,
                },
            )
            return

        if path == '/api/alarms':
            if _authorized_username(self) is None:
                _json_response(self, 401, {'message': 'unauthorized'})
                return

            title = str(payload.get('title', '')).strip()
            phone = str(payload.get('phone', '')).strip()
            arm = str(payload.get('arm', '')).strip()
            disarm = str(payload.get('disarm', '')).strip()

            if not title or not phone or not arm or not disarm:
                _json_response(
                    self,
                    400,
                    {'message': 'title, phone, arm and disarm are required'},
                )
                return

            conn = _get_conn()
            try:
                next_order = conn.execute(
                    'SELECT COALESCE(MAX(sort_order), -1) + 1 FROM alarms'
                ).fetchone()[0]

                cursor = conn.execute(
                    '''
                    INSERT INTO alarms(title, phone, arm, disarm, sort_order)
                    VALUES (?, ?, ?, ?, ?)
                    ''',
                    (title, phone, arm, disarm, next_order),
                )
                conn.commit()
                new_id = cursor.lastrowid
            finally:
                conn.close()

            _json_response(
                self,
                201,
                {
                    'id': new_id,
                    'title': title,
                    'phone': phone,
                    'arm': arm,
                    'disarm': disarm,
                },
            )
            return

        _json_response(self, 404, {'message': 'not found'})

    def do_PATCH(self) -> None:
        _log_request_start(self)
        path = urlparse(self.path).path

        if path == '/api/alarms/reorder':
            if _authorized_username(self) is None:
                _json_response(self, 401, {'message': 'unauthorized'})
                return

            payload = _read_json(self)
            ids = payload.get('ids', [])

            if not isinstance(ids, list):
                _json_response(self, 400, {'message': 'ids must be a list'})
                return

            numeric_ids = []
            for value in ids:
                try:
                    numeric_ids.append(int(value))
                except Exception:
                    _json_response(self, 400, {'message': 'ids must be integers'})
                    return

            conn = _get_conn()
            try:
                for index, alarm_id in enumerate(numeric_ids):
                    conn.execute(
                        'UPDATE alarms SET sort_order = ? WHERE id = ?',
                        (index, alarm_id),
                    )
                conn.commit()
            finally:
                conn.close()

            _json_response(self, 200, {'message': 'ok'})
            return

        if path.startswith('/api/alarms/'):
            if _authorized_username(self) is None:
                _json_response(self, 401, {'message': 'unauthorized'})
                return

            alarm_id_str = path.replace('/api/alarms/', '', 1).strip()
            try:
                alarm_id = int(alarm_id_str)
            except ValueError:
                _json_response(self, 400, {'message': 'invalid alarm id'})
                return

            payload = _read_json(self)
            title = str(payload.get('title', '')).strip()
            phone = str(payload.get('phone', '')).strip()
            arm = str(payload.get('arm', '')).strip()
            disarm = str(payload.get('disarm', '')).strip()

            if not title or not phone or not arm or not disarm:
                _json_response(
                    self,
                    400,
                    {'message': 'title, phone, arm and disarm are required'},
                )
                return

            conn = _get_conn()
            try:
                existing = conn.execute(
                    'SELECT id FROM alarms WHERE id = ?',
                    (alarm_id,),
                ).fetchone()
                if existing is None:
                    _json_response(self, 404, {'message': 'alarm not found'})
                    return

                conn.execute(
                    '''
                    UPDATE alarms
                    SET title = ?, phone = ?, arm = ?, disarm = ?
                    WHERE id = ?
                    ''',
                    (title, phone, arm, disarm, alarm_id),
                )
                conn.commit()
            finally:
                conn.close()

            _json_response(
                self,
                200,
                {
                    'id': alarm_id,
                    'title': title,
                    'phone': phone,
                    'arm': arm,
                    'disarm': disarm,
                },
            )
            return

        if path.startswith('/api/users/') and path.endswith('/password'):
            auth_username = _authorized_username(self)
            if auth_username is None:
                _json_response(self, 401, {'message': 'unauthorized'})
                return

            username = unquote(
                path.replace('/api/users/', '', 1).replace('/password', '', 1),
            ).strip()
            payload = _read_json(self)
            new_password = str(payload.get('newPassword', '')).strip()

            if not username or not new_password:
                _json_response(
                    self,
                    400,
                    {'message': 'username and newPassword are required'},
                )
                return

            if auth_username != username:
                _json_response(self, 403, {'message': 'forbidden'})
                return

            conn = _get_conn()
            try:
                existing = conn.execute(
                    'SELECT username FROM users WHERE username = ?',
                    (username,),
                ).fetchone()
                if existing is None:
                    _json_response(self, 404, {'message': 'user not found'})
                    return

                conn.execute(
                    'UPDATE users SET password = ? WHERE username = ?',
                    (new_password, username),
                )
                conn.commit()
            finally:
                conn.close()

            _json_response(
                self,
                200,
                {'username': username, 'password': new_password},
            )
            return

        _json_response(self, 404, {'message': 'not found'})

    def do_DELETE(self) -> None:
        _log_request_start(self)
        path = urlparse(self.path).path

        if not path.startswith('/api/alarms/'):
            _json_response(self, 404, {'message': 'not found'})
            return

        if _authorized_username(self) is None:
            _json_response(self, 401, {'message': 'unauthorized'})
            return

        alarm_id_str = path.replace('/api/alarms/', '', 1).strip()
        try:
            alarm_id = int(alarm_id_str)
        except ValueError:
            _json_response(self, 400, {'message': 'invalid alarm id'})
            return

        conn = _get_conn()
        try:
            existing = conn.execute(
                'SELECT id FROM alarms WHERE id = ?',
                (alarm_id,),
            ).fetchone()
            if existing is None:
                _json_response(self, 404, {'message': 'alarm not found'})
                return

            conn.execute('DELETE FROM alarms WHERE id = ?', (alarm_id,))
            conn.commit()
        finally:
            conn.close()

        _json_response(self, 200, {'message': 'deleted'})


if __name__ == '__main__':
    initialize_database()
    host = '0.0.0.0'
    port = int(os.environ.get('PORT', '8080'))
    try:
        server = ThreadingHTTPServer((host, port), ApiHandler)
    except OSError as error:
        print(f'Не вдалося запустити API на порту {port}: {error}')
        print('Спробуй звільнити порт 8080 або запустити так:')
        print('PowerShell: $env:PORT=8081; python scripts/api.py')
        raise SystemExit(1)

    _log(f'API started on http://{host}:{port}')
    _log(f'API log file: {LOG_PATH}')

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        _log('API stopped by user')
    finally:
        server.server_close()
