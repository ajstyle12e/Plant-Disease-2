require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const morgan  = require('morgan');
const mongoose = require('mongoose');

const predictRouter = require('./routes/predict');
const historyRouter = require('./routes/history');
const guideRouter   = require('./routes/guide');
const chatRouter    = require('./routes/chat');

const app  = express();
const PORT = process.env.PORT || 3000;

const allowedOrigins = (process.env.CORS_ORIGINS || 'http://localhost:5000')
  .split(',').map(s => s.trim());

app.use(cors({
  origin: allowedOrigins,
  methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type'],
}));
app.use(morgan('dev'));
app.use(express.json());

// Routes
app.use('/api/predict', predictRouter);
app.use('/api/history', historyRouter);
app.use('/api/guide',   guideRouter);
app.use('/api/chat',    chatRouter);

app.get('/', (req, res) => res.json({ status: 'Plant Disease API running' }));

// MongoDB connect
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('MongoDB connected');
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch(err => {
    console.error('MongoDB connection failed:', err.message);
    // Still start server without DB (history won't work)
    app.listen(PORT, () => console.log(`Server running on port ${PORT} (no DB)`));
  });
