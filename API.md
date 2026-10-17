# TeamUp Server — API Documentation

Бэкенд мессенджера/платформы поиска команд. Spring Boot 4.1, JWT-аутентификация (Resource Server OAuth2 JWT), WebSocket (STOMP) для реального времени, Firebase Cloud Messaging (FCM) для пуш-уведомлений, PostgreSQL + MinIO (S3).

## Содержание

- [Общие соглашения](#общие-соглашения)
  - [Аутентификация](#аутентификация)
  - [Форматы](#форматы)
- [REST API](#rest-api)
  - [Auth](#auth)
  - [Users](#users)
  - [Chats](#chats)
  - [Messages](#messages)
  - [Games](#games)
  - [Search](#search)
  - [Notifications (FCM)](#notifications-fcm)
- [WebSocket (STOMP)](#websocket-stomp)
  - [Подключение](#подключение)
  - [Входящие (клиент → сервер)](#входящие-клиент--сервер)
  - [Рассылки (сервер → клиент)](#рассылки-сервер--клиент)
- [События автоматических уведомлений](#события-автоматических-уведомлений)
- [Примечания и замеченные проблемы](#примечания)

---

## Общие соглашения

### Аутентификация

Все REST-эндпоинты, **кроме** `/auth/**`, требуют JWT.

Заголовок:

```
Authorization: Bearer <accessToken>
```

- `/auth/login`, `/auth/register`, `/auth/google`, `/auth/verify-email`, `/auth/forgot` — публичные.
- Всё остальное закрыто.
- Пользователь идентифицируется по `uid` (subject токена), берётся из `Authentication.getName()`.

### Форматы

- Тело запроса/ответа — JSON (`application/json`), если не указано иное.
- Даты в `Instant` сериализуются в ISO-8601 (UTC).
- Файлы — `multipart/form-data`, поле `file`.
- В БД: `Instant` хранится как `timestamptz` (Hibernate `jdbc.time_zone=UTC`).

---

## REST API

### Auth

Базовый путь: `/auth`

#### `GET /auth/me`

Данные текущего аккаунта (по токену).

Ответ: `200` — `AccountResponse`:

```json
{ "uid": "<uuid>", "email": "user@example.com", "isVerified": true }
```

#### `POST /auth/register`

Регистрация. Создаёт аккаунт и отправляет письмо со ссылкой подтверждения.

Запрос:

```json
{ "email": "user@example.com", "password": "secret123" }
```

Ответ: `200`

```
Please, check your email for verification!
```

Ошибки: `400` если email уже существует.

#### `POST /auth/login`

Логин. Возвращает JWT-токен.

Запрос:

```json
{ "email": "user@example.com", "password": "secret123" }
```

Ответ: `200`

```json
{ "accessToken": "<jwt>", "tokenType": "Bearer" }
```

Ошибки: `401` — неверные учётные данные или аккаунт отключён.

#### `POST /auth/google`

Вход через Google (OAuth-верификация `id_token`).

Запрос (`GoogleAuthRequest`):

```json
{ "provider_id_token": "<google id token>" }
```

Ответ: `200` — `AuthResponse` (см. выше). Если такого пользователя нет — создаётся автоматически.

#### `GET /auth/verify-email?token=<token>`

Подтверждение email через токен из письма.

Query param: `token` (string).

Ответ: `200` — `AuthResponse` (авторизует сразу после подтверждения).

Ошибки: `400` — неверный/протухший/использованный токен.

#### `POST /auth/forgot`

Запрос на сброс пароля. Отправляет письмо со ссылкой.

Запрос:

```json
{ "email": "user@example.com" }
```

Ответ: `200`

```
Please, check your email for reset password
```

#### `GET /auth/username/{username}/exists`

Проверка занятости username (вспомогательный эндпоинт для форм).

Path param: `username` (string).

Ответ: `200` — `true`/`false` (boolean).

#### `GET /auth/email/{email}/exists`

Проверка занятости email (вспомогательный эндпоинт для форм).

Path param: `email` (string).

Ответ: `200` — `true`/`false` (boolean).

---

### Users

Базовый путь: `/users`

#### `GET /users/me`

Текущий пользователь (по токену).

Ответ: `200` — `UserEntity`:

```json
{
  "uid": "1",
  "username": "matvey",
  "email": "user@example.com",
  "age": 25,
  "gender": "male",
  "description": null,
  "favouriteGame": 3,
  "online": true,
  "avatar": null
}
```

#### `GET /users/?page=<n>&limit=<n>`

Список пользователей с пагинацией.

Query params: `page` (int, обязательный), `limit` (int, обязательный).

Ответ: `200` — массив `UserEntity`.

#### `GET /users/{uid}`

Получить пользователя по uid.

Path param: `uid` (string).

Ответ: `200` — `UserEntity` (см. `/users/me`).

#### `POST /users/`

Создать/до-заполнить профиль текущего пользователя.

Запрос (request body `CreateUserRequest`):

```json
{ "username": "matvey", "description": "hello", "gender": "male", "age": 25, "game": 3 }
```

Ответ: `200` — `UserEntity`.

#### `PUT /users/`

Изменить профиль текущего пользователя. Тело — то же `CreateUserRequest`.

Ответ: `200` — `UserEntity`.

#### `GET /users/friends/{uid}`

Список друзей пользователя.

Path param: `uid` (string).

Ответ: `200` — массив `FriendshipEntity`:

```json
[ { "id": 1, "fromUser": "1", "toUser": "2", "status": true } ]
```

#### `POST /users/friends`

Отправить заявку в друзья. После отправки автоматически шлёт FCM-уведомление получателю (если он оффлайн).

Запрос:

```json
{ "fromUser": "1", "toUser": "2" }
```

Ответ: `200`.

#### `PUT /users/friends`

Принять заявку в друзья (пользователь `toUser` принимает заявку от `fromUser`).

Запрос:

```json
{ "fromUser": "1", "toUser": "2" }
```

Ответ: `200`.

#### `DELETE /users/friends`

Удалить дружбу.

Запрос:

```json
{ "fromUser": "1", "toUser": "2" }
```

Ответ: `200`.

#### `GET /users/status/{uid}`

Онлайн-статус пользователя.

Path param: `uid` (string).

Ответ: `200` — `true`/`false` (boolean).

#### `POST /users/avatars`

Загрузить аватар текущего пользователя.

Body: `multipart/form-data`, поле `file`.

Ответ: `200`.

#### `GET /users/{uid}/avatar`

URL аватара пользователя.

Path param: `uid` (string).

Ответ: `200` — string (Presigned URL на файл в S3).

#### `DELETE /users/avatars`

Удалить аватар текущего пользователя.

Ответ: `200`.

---

### Chats

Базовый путь: `/chats`

#### `GET /chats/`

Список чатов текущего пользователя.

Ответ: `200` — массив `ChatEntity`:

```json
[
  {
    "id": 1,
    "name": "Команда",
    "team": false,
    "public": false,
    "game": null,
    "createdAt": "2026-08-31T10:00:00Z",
    "icon": null
  }
]
```

#### `POST /chats/?other=<uid>`

Создать личный чат с другим пользователем.

Query param: `other` (uid string).

Ответ: `200` — `ChatEntity` (созданный чат).

#### `GET /chats/{chatId}`

Получить чат по id (только если пользователь участник).

Path param: `chatId` (long).

Ответ: `200` — `ChatEntity`.

#### `GET /chats/{chatId}/users`

Участники чата (только если пользователь участник).

Path param: `chatId` (long).

Ответ: `200` — массив `UserEntity`.

#### `DELETE /chats/{chatId}`

Удалить чат (только если пользователь участник).

Path param: `chatId` (long).

Ответ: `200`.

#### `GET /chats/{chatId}/reads`

Список id прочитанных сообщений в чате.

Path param: `chatId` (long).

Ответ: `200` — массив `Long` (id прочитанных сообщений).

---

### Messages

Базовый путь: `/messages`

#### `GET /messages/{chatId}`

История сообщений чата (только для участника).

Path param: `chatId` (long).

Ответ: `200` — массив `MessageEntity`:

```json
[
  {
    "id": 1,
    "uid": "1",
    "chat": { "id": 1, ... },
    "text": "привет",
    "repliedMessage": null,
    "attachment": null,
    "sendedAt": "2026-08-31T10:00:00Z"
  }
]
```

Ошибки: `401` — не участник; `404` — чат не найден.

#### `POST /messages/{messageId}/read`

Отметить сообщение прочитанным (только участник чата). Шлёт WebSocket-событие `READ` и FCM-уведомление о прочтении.

Path param: `messageId` (long).

Ответ: `200`.

#### `POST /messages/{messageId}/attachment`

Загрузить вложение к сообщению (только автор сообщения).

Path param: `messageId` (long).
Body: `multipart/form-data`, поле `file`.

Ответ: `200`.

#### `GET /messages/{messageId}/attachment`

Presigned URL вложения сообщения (только участник чата).

Path param: `messageId` (long).

Ответ: `200` — string (URL).

---

### Games

Базовый путь: `/games`

Каталог игр. id игры (`GameEntity.id`) используется другими модулями как справочная величина: `UserEntity.favouriteGame`, `ChatEntity.game`, `CreateUserRequest.game` (при создании/редактировании профиля) и `SearchRequest.game` (поиск команд в `/searches/`).

Требуется JWT (`anyRequest().authenticated()`), в методах `Authentication` не используется.

#### `GET /games/`

Список всех игр.

Ответ: `200` — массив `GameEntity`:

```json
[
  {
    "id": 1,
    "title": "Dota 2",
    "addedAt": "2026-01-01T00:00:00Z",
    "gameCoverId": "<uuid>"
  }
]
```

#### `GET /games/{gameId}/url`

Presigned URL обложки игры.

Path param: `gameId` (long).

Ответ: `200` — string (URL на файл в S3).

Ошибки: `404` — игра не найдена / обложка не найдена.

---

### Search

Базовый путь: `/searches`

#### `POST /searches/`

Начать (или присоединиться к) поиску команды по параметрам. Логика сопоставляет пользователя с уже существующей «сессией поиска» по ключу `(game, age, size, gender)`.

Параметры приходят query-string'ом (`SearchRequest` биндится из query/формы).

Query/форма: `game` (int), `gender` (string), `size` (int), `age` (int).

**Возможные ответы (наследники `SearchResponse`):**

`SearchCreatedResponse` — сессия поиска создана впервые:

```json
{ "result": "created", "search": { "id": "<uuid>", "users": [ ... ] } }
```

`SearchFoundResponse` — пользователь присоединился к существующей сессии:

```json
{ "result": "found", "search": { "id": "<uuid>", "users": [ ... ] } }
```

`SearchFormedResponse` — команда набрана (команда автоматически создаётся):

```json
{ "result": "found", "team": { ...ChatEntity } }
```

При `FORMED` дополнительно рассылается FCM-уведомление участникам, которые оффлайн.

#### `POST /searches/{searchId}/leave`

Покинуть сессию поиска.

Path param: `searchId` (UUID).

Ответ: `200`.

Рассылается WebSocket-событие `LEAVE_USER` в `/topic/searches/{searchId}`.

---

### Notifications (FCM)

Базовый путь: `/fcm`

#### `POST /fcm/token`

Зарегистрировать (или обновить) FCM-токен текущего пользователя. Клиент должен вызывать этот эндпоинт при запуске приложения и при каждом обновлении токена.

Query param: `fcm_token` (string, обязательный).

Ответ: `200`.

Ошибки: `401` — не авторизован.

#### `DELETE /fcm/token`

Удалить (отозвать) FCM-токен. Клиент должен вызывать при logout.

Query param: `fcm_token` (string, обязательный).

Ответ: `200`.

Ошибки: `401` — не авторизован.

#### Таблица `fcm_tokens`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `id` | `Long` | PK, auto-increment | Идентификатор записи |
| `fcm_token` | `String` | NOT NULL, UNIQUE | FCM-токен устройства |
| `uid` | `String` | NOT NULL | ID пользователя (`UserEntity.uid`) |

#### Форматы push-уведомлений

При отправке FCM-уведомления клиенту приходит:

```
title: <строка>
body: <строка>
data.type: new_message | friend_request | search_complete
```

Таблица полей `data` по типам:

| `type` | Дополнительные поля | Генерируется при |
|---|---|---|
| `new_message` | `chatId` | входящее сообщение (только оффлайн-участники чата, кроме отправителя) |
| `friend_request` | `fromUser` | заявка в друзья (только оффлайн-получатель) |
| `search_complete` | `uid` | завершение поиска — команда набрана (только оффлайн-участники) |

---

## WebSocket (STOMP)

### Подключение

Эндпоинт: `GET /ws` (с поддержкой SockJS).

```
ws://<host>/ws
```

Handshake через STOMP `CONNECT` с JWT в заголовке `Authorization`:

```json
{ "Authorization": "Bearer <accessToken>" }
```

- Без токена — отказ (`BadCredentialsException`).
- Конфигурация брокера: `enableSimpleBroker("/topic")`, application prefix `/realtime`.
- При подключении пользователь становится `online=true`, при отключении — `online=false` (события `SessionConnectEvent`/`SessionDisconnectEvent`).

### Входящие (клиент → сервер)

Отправка от клиента на адреса с префиксом `/realtime/...` (секция `applicationDestinationPrefixes`).

Требуется доступ: все входящие проходят проверку членства в чате / авторства сообщения интерцепторами.

#### `SEND /realtime/chats/{chatId}/send`

Отправить сообщение в чат (только участник). После сохранения в БД автоматически рассылает FCM-уведомление участникам, которые оффлайн.

Body (`Message`):

```json
{
  "text": "привет",
  "localDateTime": "2026-08-31T13:00:00",
  "zoneId": "Europe/Moscow",
  "repliedMessage": 5
}
```

Все участники чата получают событие `SEND` в `/topic/chats/{chatId}`.

#### `SEND /realtime/messages/{messageId}/edit`

Отредактировать текст сообщения (только автор — проверка `isSender`).

Body: `Message` (см. выше).

Участники получают событие `EDIT`.

#### `SEND /realtime/messages/{messageId}/delete`

Удалить сообщение (только автор).

Участники получают событие `DELETE`.

#### `SEND /realtime/user/status/{status}`

Установить онлайн-статус текущего пользователя.

Path: `status` (boolean).

---

### Рассылки (сервер → клиент)

Подписка на `/topic/**`. Доступ к `chats` и `messages` контролируется интерцепторами членства.

| Канал | Событие | Описание |
|---|---|---|
| `SUBSCRIBE /topic/chats/{chatId}` | `MessageResponse` / `MessageResponseById` | События по чату: `SEND`, `EDIT`, `DELETE`, `READ` |
| `SUBSCRIBE /topic/searches/{searchId}` | `SearchMessage` | События поиска: `new_user`, `leave_user`, `formed` |
| `SUBSCRIBE /topic/user/{uid}/status` | `Boolean` | Изменение онлайн-статуса пользователя |

**`MessageResponse`** для `SEND`/`EDIT`:

```json
{ "event": "SEND", "message": { ...MessageEntity } }
```

**`MessageResponseById`** для `DELETE`/`READ`:

```json
{ "event": "DELETE", "messageId": 5 }
```

**`SearchMessage`**:

```json
{ "event": "new_user", "payload": { ...UserEntity } }
```

```json
{ "event": "formed", "payload": { ...ChatEntity } }
```

**Enum значения:**
- `MessageEvent`: `SEND`, `EDIT`, `DELETE`, `READ`
- `SearchEvent`: `new_user`, `leave_user`, `formed`
- `SearchResult`: `created`, `found`, `formed` (используются только `created` и `found`)

---

## События автоматических уведомлений

Помимо WebSocket-рассылок, сервер автоматически отправляет push-уведомления через FCM при следующих условиях:

| Триггер | Получатели | Условие |
|---|---|---|
| **Входящее сообщение** | Все участники чата, кроме отправителя | `isOnline = false` |
| **Заявка в друзья** | Получатель заявки (`toUser`) | `isOnline = false` |
| **Команда набрана (search formed)** | Все участники сессии поиска | `isOnline = false` |

Все уведомления — только для пользователей, у которых нет активной WebSocket-сессии (оффлайн). Если пользователь онлайн — он получает обновление через WebSocket в реальном времени.

---

## Примечания

Замечания по текущему коду:

1. `UserController.GET /users/status/{uid}` возвращает сырой `Boolean`, хотя есть DTO `OnlineStatusResponse(boolean isOnline)`.
2. Кэш `Search` и древовидная структура хранятся в памяти (`HashMap`), при рестарте/нескольких инстансах теряются.
3. Парсинг в `ChatMemberInterceptor` и `MessageInterceptor` завязан на строгий формат пути (`split("/")[2]`) — небезопасно для произвольных destination.
4. `FcmService.sendChatMessageNotification` вызывает `memberRepository.findByChat_Id()` — при большом количестве участников чата может быть эффективнее один запрос с фильтрацией по онлайн-статусу в SQL.
5. В DTO `Message` поле `repliedMessage` осталось `Optional<Integer>`, хотя id сообщений были переведены на `Long` — потенциальный переполнение при больших id.
