# TravelBucket

PWA untuk menemukan destinasi, menyusun bucket list, menandai favorit, dan mencatat tempat yang sudah dikunjungi. Frontend dibuat dengan HTML/CSS/JavaScript, API memakai Express, dan data disimpan di Supabase.

## Jalankan aplikasi

1. Instal Node.js LTS jika belum ada.
2. Buka terminal VS Code di folder TravelBucket dan jalankan `npm install`.
3. Salin `.env.example` menjadi `.env`, lalu isi `SUPABASE_URL` dan `SUPABASE_ANON_KEY` dari Supabase Dashboard → Project Settings → API.
4. Jalankan `npm run dev`.
5. Buka `http://localhost:3001`.

Jalankan `backend/db/schema.sql` di Supabase Dashboard → SQL Editor untuk membuat tabel, kebijakan akses, kategori, dan data destinasi contoh. Konfigurasi frontend berada di `frontend/public/config.example.js` dan dimuat saat deploy. Pastikan URL dan publishable/anon key di file itu sesuai proyek Supabase. Key publishable/anon memang digunakan browser; jangan pernah masukkan `service_role` key ke frontend.

`.env` berisi konfigurasi lokal dan dikecualikan oleh `.gitignore`. Jangan mengirim file tersebut ke GitHub. `.env.example` aman dibagikan karena hanya berisi nama variabel dan nilai contoh.

## Mode statis

Jika hanya memakai `python -m http.server`, halaman dapat ditampilkan, tetapi endpoint Express `/api` tidak berjalan. Untuk fitur sinkronisasi API, gunakan `npm run dev`.

## Struktur

Lihat [`docs/struktur-proyek.md`](docs/struktur-proyek.md). Aplikasi memuat PWA manifest dan service worker sehingga dapat dipasang ketika dibuka dari `localhost` atau HTTPS.

Untuk membuat tabel profil pengguna di Supabase, jalankan ulang backend/db/schema.sql. Pendaftaran membuat baris profil otomatis lewat trigger; akun dan password dikelola oleh Supabase Auth.

## Deploy ke Vercel

Proyek ini sudah memiliki `vercel.json` yang menunjuk output statis ke `frontend/public`. Import repository TravelBucket di Vercel dengan Root Directory `./` dan Framework Preset `Other`, lalu deploy. Untuk endpoint Express, tambahkan Environment Variables `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di Vercel. Setelah perubahan ini dikirim ke GitHub, jalankan Redeploy dari Vercel.
