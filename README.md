# flutterlabslpnu

## Лабораторна робота №5: Підключення API

У проєкті реалізовано локальний Python-бекенд (HTTP API) у `scripts/` і підключено його до Flutter-апки.

### Що реалізовано

- API-сервер: [scripts/api.py](scripts/api.py)
- Ініціалізація БД: [scripts/init_db.py](scripts/init_db.py)
- SQLite база даних: [scripts/alarms.db](scripts/alarms.db)
- API-клієнт у Flutter: [lib/services/api_service.dart](lib/services/api_service.dart)
- Логін/реєстрація працюють через HTTP API:
	- [lib/pages/pin_page.dart](lib/pages/pin_page.dart)
	- [lib/pages/register_page.dart](lib/pages/register_page.dart)
- Зміна пароля працює через HTTP API:
	- [lib/pages/settings_page.dart](lib/pages/settings_page.dart)
- Усі дії з сигналізаціями працюють через HTTP API (замість локального сховища):
	- завантаження, додавання, редагування, видалення, зміна порядку
	- [lib/pages/alarm_page.dart](lib/pages/alarm_page.dart)
	- [lib/pages/settings_page.dart](lib/pages/settings_page.dart)
- Відображення даних з API через `FutureBuilder`:
	- [lib/pages/user_page.dart](lib/pages/user_page.dart)

### Запуск бекенду (Python)

1. Відкрити термінал у корені проєкту
2. Виконати:

	 - `python scripts/init_db.py`
	 - `python scripts/api.py`

3. Перевірка API:

	 - `GET http://localhost:8080/health`

### Важливо для Android-емулятора

Flutter-клієнт використовує `http://10.0.2.2:8080` на Android-емуляторі і `http://127.0.0.1:8080` на desktop/iOS.

### Примітка про автологін

Логіка автологіну залишена без змін: вхід при старті застосунку опирається на локально збереженого користувача та стан сесії.
