const router = require('express').Router();
const supabase = require('../db');

router.get('/', async (_req, res) => {
  const { data, error } = await supabase.from('destinations').select('*, categories(name)').order('name');
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});
router.post('/', async (req, res) => {
  const { name, category, location, price = 0, image = '', description = '', ideal_duration = '2–3 hari' } = req.body;
  if (!name || !category || !location) return res.status(400).json({ error: 'Nama, kategori, dan lokasi wajib diisi.' });
  let { data: categoryRow, error: categoryError } = await supabase.from('categories').select('id').eq('name', category).maybeSingle();
  if (!categoryRow && category === 'Pantai') {
    const legacy = await supabase.from('categories').select('id').eq('name', 'Bahari').maybeSingle();
    categoryRow = legacy.data;
    categoryError = legacy.error;
  }
  if (categoryError) return res.status(400).json({ error: 'Kategori tidak ditemukan.' });
  const { data, error } = await supabase.from('destinations').insert({ name, category_id: categoryRow.id, location, price: Number(price) || 0, image, description, ideal_duration }).select('*, categories(name)').single();
  if (error) return res.status(400).json({ error: error.message });
  res.status(201).json(data);
});
module.exports = router;
