const mongoose = require('mongoose');

const historySchema = new mongoose.Schema({
  predicted_class: { type: String, required: true },
  confidence:      { type: Number, required: true },
  top_5_predictions: [{ class: String, confidence: Number }],
  explanation:     { type: String, default: '' },
  image_base64:    { type: String, default: '' },  // thumbnail stored as base64
  created_at:      { type: Date, default: Date.now },
});

module.exports = mongoose.model('History', historySchema);
