const path = require('path');
const express = require('express');
const cors = require('cors');
const supabase = require('./db');
const requireSupabase = require('./middleware/require-supabase');
const app = express();

app.use(cors());
app.use(express.json());
app.use('/api', requireSupabase);
app.get('/api/bootstrap', async (_req, res) => {
  const [destinations, categories] = await Promise.all([
    supabase.from('destinations').select('*, categories(name)').order('name'),
    supabase.from('categories').select('*').order('name')
  ]);
  const failed = [destinations, categories].find(result => result.error);
  if (failed) return res.status(500).json({ error: failed.error.message });
  res.json({ destinations: destinations.data, categories: categories.data });
});
app.use('/api/categories', require('./routes/categories'));
app.use('/api/destinations', require('./routes/destinations'));
app.use(express.static(path.resolve(__dirname, '../../frontend/public')));
app.use((req, res, next) => {
  if (req.method !== 'GET') return next();
  if (req.path.startsWith('/api/')) return res.status(404).json({ error: 'Endpoint API tidak ditemukan.' });
  res.sendFile(path.resolve(__dirname, '../../frontend/public/index.html'));
});
module.exports = app;
