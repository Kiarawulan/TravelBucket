const router = require('express').Router();
const supabase = require('../db');

router.get('/', async (_req, res) => {
  const { data, error } = await supabase.from('bucket_list').select('*').order('created_at');
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});
router.post('/', async (req, res) => {
  const { destination_id, status = 'planned' } = req.body;
  if (!destination_id || !['planned', 'visited'].includes(status)) return res.status(400).json({ error: 'Destinasi atau status tidak valid.' });
  const { data, error } = await supabase.from('bucket_list').upsert({ destination_id, status }, { onConflict: 'destination_id' }).select().single();
  if (error) return res.status(400).json({ error: error.message });
  res.json(data);
});
router.delete('/:id', async (req, res) => {
  const { error } = await supabase.from('bucket_list').delete().eq('destination_id', req.params.id);
  if (error) return res.status(400).json({ error: error.message });
  res.status(204).end();
});
module.exports = router;
