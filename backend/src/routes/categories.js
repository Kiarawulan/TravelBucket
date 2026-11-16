const router = require('express').Router();
const supabase = require('../db');

router.get('/', async (_req, res) => {
  const { data, error } = await supabase.from('categories').select('*').order('name');
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});
module.exports = router;
