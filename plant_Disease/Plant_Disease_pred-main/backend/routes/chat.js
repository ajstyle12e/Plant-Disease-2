const express = require('express');
const axios   = require('axios');
const router  = express.Router();

const PYTHON = process.env.PYTHON_API_URL || 'http://localhost:8000';

// POST /api/chat  — send message
router.post('/', async (req, res) => {
  const { session_id, message, disease_context } = req.body;
  if (!session_id || !message) {
    return res.status(400).json({ error: 'session_id and message required' });
  }
  try {
    const r = await axios.post(`${PYTHON}/chat`, {
      session_id,
      message,
      disease_context: disease_context || '',
    }, { timeout: 90000 });
    return res.json(r.data);
  } catch (err) {
    const msg = err.response?.data?.detail || err.message;
    return res.status(err.response?.status || 502).json({ error: msg });
  }
});

// GET /api/chat/sessions  — all sessions
router.get('/sessions', async (req, res) => {
  try {
    const r = await axios.get(`${PYTHON}/chat/sessions`, { timeout: 10000 });
    return res.json(r.data);
  } catch (err) {
    return res.status(502).json({ error: err.message });
  }
});

// GET /api/chat/sessions/:id  — messages for a session
router.get('/sessions/:id', async (req, res) => {
  try {
    const r = await axios.get(`${PYTHON}/chat/sessions/${req.params.id}`, { timeout: 10000 });
    return res.json(r.data);
  } catch (err) {
    return res.status(502).json({ error: err.message });
  }
});

// DELETE /api/chat/sessions/:id
router.delete('/sessions/:id', async (req, res) => {
  try {
    const r = await axios.delete(`${PYTHON}/chat/sessions/${req.params.id}`, { timeout: 10000 });
    return res.json(r.data);
  } catch (err) {
    return res.status(502).json({ error: err.message });
  }
});

module.exports = router;
