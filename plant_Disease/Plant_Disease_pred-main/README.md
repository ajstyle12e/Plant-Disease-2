# Backend — Node.js API Gateway

Express server that acts as middleware between the Flutter app and the Python FastAPI service.

## Responsibilities

- Receives image uploads from Flutter, forwards to Python, saves results to MongoDB
- Proxies all chat API calls to Python
- Serves prediction history and plant guide data
- Handles CORS for the Flutter web frontend

## Setup

```bash
npm install
cp .env.example .env
node server.js
```

Server runs on **port 3000** by default.

## Routes

| Method | Path | Handler |
|---|---|---|
| POST | `/api/predict` | `routes/predict.js` |
| GET/DELETE | `/api/history` | `routes/history.js` |
| GET | `/api/guide` | `routes/guide.js` |
| POST/GET/DELETE | `/api/chat/*` | `routes/chat.js` |

## Environment

See `.env.example` for all required variables.
