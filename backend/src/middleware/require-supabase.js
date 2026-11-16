module.exports = function requireSupabase(_req, res, next) {
  if (!require('../db')) return res.status(503).json({ error: 'Supabase belum dikonfigurasi.' });
  next();
};
