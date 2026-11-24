const express  = require('express');
const multer   = require('multer');
const axios    = require('axios');
const FormData = require('form-data');
const History  = require('../models/History');

const router  = express.Router();
const storage = multer.memoryStorage();
const upload  = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

// POST /api/predict  — accepts multipart image, forwards to Python, saves history
router.post('/', upload.single('image'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No image uploaded' });

  try {
    // Forward image to Python FastAPI
    const form = new FormData();
    form.append('file', req.file.buffer, {
      filename:    req.file.originalname || 'image.jpg',
      contentType: req.file.mimetype,
    });

    const pythonRes = await axios.post(
      `${process.env.PYTHON_API_URL}/predict`,
      form,
      { headers: form.getHeaders(), timeout: 60000 }
    );

    const result = pythonRes.data;

    // Save to MongoDB (store small base64 thumbnail)
    const imgBase64 = req.file.buffer.toString('base64');
    try {
      await History.create({
        predicted_class:   result.predicted_class,
        confidence:        result.confidence,
        top_5_predictions: result.top_5_predictions,
        explanation:       result.explanation,
        image_base64:      imgBase64.substring(0, 20000), // cap size
      });
    } catch (dbErr) {
      console.warn('History save failed:', dbErr.message);
    }

    return res.json(result);
  } catch (err) {
    const status  = err.response?.status || 502;
    const message = err.response?.data?.detail || err.message;
    return res.status(status).json({ error: message });
  }
});

module.exports = router;
