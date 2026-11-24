const express = require('express');
const History = require('../models/History');

const router = express.Router();

// GET /api/history — list all, newest first
router.get('/', async (req, res) => {
  try {
    const items = await History.find()
      .sort({ created_at: -1 })
      .limit(50)
      .select('-image_base64');  // exclude large field from list
    return res.json(items);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/history/:id — single record with image
router.get('/:id', async (req, res) => {
  try {
    const item = await History.findById(req.params.id);
    if (!item) return res.status(404).json({ error: 'Not found' });
    return res.json(item);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// DELETE /api/history/:id
router.delete('/:id', async (req, res) => {
  try {
    await History.findByIdAndDelete(req.params.id);
    return res.json({ deleted: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
