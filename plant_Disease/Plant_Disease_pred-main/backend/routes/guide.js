const express = require('express');
const router  = express.Router();

// Static guide data — extend as needed
const guideData = {
  lifecycle: [
    { range: '0-14 Days',  title: 'Nursery Phase',                    description: 'Critical root formation phase. Use fine soil + husk charcoal.',              tip: 'Keep humidity at 80%. Don\'t overwater to avoid damping off disease. Shade from heavy rain.' },
    { range: '15-35 Days', title: 'Transplanting & Early Vegetative', description: 'Plant focuses on stem and leaf growth. Needs high Nitrogen (N).',            tip: 'Perform pruning (remove water shoots at lower leaf axils) to focus nutrients upwards. Install stakes/support sticks.' },
    { range: '36-70 Days', title: 'Generative (Flowering & Fruiting)', description: 'Flower formation phase. Switch fertilizer to high Phosphorus (P) and Potassium (K).', tip: 'If flowers drop, plant might lack Calcium or have water stress. Reduce Nitrogen to avoid excessive foliage.' },
    { range: '75+ Days',   title: 'Harvest Phase',                    description: 'Monitor fruit color and size. Harvest regularly to stimulate more fruiting.', tip: 'Harvest in the morning for best quality. Leave some fruit to mature for seeds.' },
  ],
  diseases: [
    { name: 'Bacterial Spot',    type: 'BACTERIA', scientific: 'Xanthomonas campestris',  symptoms: 'Small necrotic black spots surrounded by yellow halos. Leaves yellow and drop severely during rain.',      solution: 'Reduce field humidity (pruning). Avoid overhead watering (sprinklers). Spray bactericides containing Copper Hydroxide or Streptomycin sulfate.' },
    { name: 'Cercospora Leaf Spot', type: 'FUNGUS', scientific: 'Cercospora capsici',    symptoms: 'Round spots with light gray centers and distinct dark brown edges (like an eye). Often attacks older leaves first.', solution: 'Sanitation: Burn fallen/infected leaves. Adjust planting distance to avoid overcrowding. Spray fungicides containing Mancozeb or Chlorothalonil.' },
    { name: 'Powdery Mildew',    type: 'FUNGUS',   scientific: 'Leveillula taurica',     symptoms: 'White powdery coating on upper leaf surface. Leaves curl and drop prematurely.',                            solution: 'Improve air circulation. Apply sulfur-based fungicides or potassium bicarbonate sprays.' },
    { name: 'Chili Mosaic Virus', type: 'VIRUS',   scientific: 'Cucumber Mosaic Virus',  symptoms: 'Mosaic-like yellowing and green mottling on leaves. Stunted growth and distorted fruit.',                  solution: 'No cure. Remove and destroy infected plants immediately. Control aphid vectors with insecticide.' },
    { name: 'Anthracnose',       type: 'FUNGUS',   scientific: 'Colletotrichum capsici',  symptoms: 'Sunken, dark, water-soaked lesions on fruit. White/pink spore masses in the center of lesions.',          solution: 'Avoid fruit wounds. Apply Mancozeb or Azoxystrobin fungicide. Harvest fruit before full ripeness.' },
  ],
  tips: [
    'Use clean water when watering plants to prevent disease spread through contaminated water.',
    'Inspect your plants daily — early detection is the best cure.',
    'Rotate crops every season to break pest and disease cycles.',
    'Maintain proper plant spacing to ensure good air circulation.',
    'Remove and destroy fallen leaves to eliminate disease reservoirs.',
  ],
};

router.get('/', (req, res) => res.json(guideData));
router.get('/lifecycle', (req, res) => res.json(guideData.lifecycle));
router.get('/diseases',  (req, res) => res.json(guideData.diseases));
router.get('/tips',      (req, res) => res.json(guideData.tips));

module.exports = router;
