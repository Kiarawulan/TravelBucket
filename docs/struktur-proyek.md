# Struktur proyek

- `frontend/public`: PWA (HTML, CSS, JavaScript, manifest, service worker).
- `backend/src`: Express API, koneksi Supabase, middleware, dan route.
- `backend/db/schema.sql`: skema tabel dan data awal Supabase.
- `api/index.js`: entry point untuk deployment serverless.
- `package.json`: perintah dan dependensi backend.
- `.env.example`: contoh nama konfigurasi; salin menjadi `.env` dan isi lokal.
- `.gitignore`: mengecualikan `.env`, kredensial browser, dependencies, dan hasil build dari Git.
