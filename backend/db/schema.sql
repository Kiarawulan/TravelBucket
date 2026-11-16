-- Jalankan skrip ini di Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;
-- Profil publik terhubung satu-ke-satu dengan akun Supabase Auth.
-- Password tetap hanya dikelola oleh auth.users dan tidak disalin ke profiles.
create table if not exists public.profiles(
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "users read own profile" on public.profiles;
drop policy if exists "users update own profile" on public.profiles;
create policy "users read own profile" on public.profiles for select to authenticated using (auth.uid() = id);
create policy "users update own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id,email,full_name)
  values(new.id,new.email,coalesce(new.raw_user_meta_data ->> 'name',''))
  on conflict(id) do update set email=excluded.email,full_name=excluded.full_name,updated_at=now();
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile after insert on auth.users
for each row execute procedure public.create_profile_for_new_user();
insert into public.profiles(id,email,full_name)
select id,email,coalesce(raw_user_meta_data ->> 'name','') from auth.users
on conflict(id) do update set email=excluded.email,full_name=excluded.full_name,updated_at=now();
create table if not exists public.categories(id uuid primary key default gen_random_uuid(),name text not null unique,description text not null default '');
create table if not exists public.destinations(id uuid primary key default gen_random_uuid(),name text not null,description text not null default '',location text not null default '',price bigint not null default 0 check(price>=0),image text not null default '',ideal_duration text not null default '2–3 hari',category_id uuid references public.categories(id) on delete set null,created_at timestamptz not null default now());
alter table public.destinations add column if not exists ideal_duration text not null default '2–3 hari';
create table if not exists public.bucket_list(user_id uuid not null references auth.users(id) on delete cascade,destination_id uuid not null references public.destinations(id) on delete cascade,status text not null default 'planned' check(status in('planned','visited')),created_at timestamptz not null default now(),primary key(user_id,destination_id));
create table if not exists public.favorites(user_id uuid not null references auth.users(id) on delete cascade,destination_id uuid not null references public.destinations(id) on delete cascade,created_at timestamptz not null default now(),primary key(user_id,destination_id));
-- Upgrade legacy global travel lists to account-owned rows. Old anonymous rows have no owner, so discard them instead of exposing them to every account.
alter table public.bucket_list add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.favorites add column if not exists user_id uuid references auth.users(id) on delete cascade;
delete from public.bucket_list where user_id is null;
delete from public.favorites where user_id is null;
do $$ declare c record; begin
  for c in select conname from pg_constraint where conrelid='public.bucket_list'::regclass and contype='p' loop execute format('alter table public.bucket_list drop constraint %I',c.conname); end loop;
  for c in select conname from pg_constraint where conrelid='public.favorites'::regclass and contype='p' loop execute format('alter table public.favorites drop constraint %I',c.conname); end loop;
end $$;
alter table public.bucket_list alter column user_id set not null;
alter table public.favorites alter column user_id set not null;
create unique index if not exists bucket_list_user_destination_uidx on public.bucket_list(user_id,destination_id);
create unique index if not exists favorites_user_destination_uidx on public.favorites(user_id,destination_id);
alter table public.categories enable row level security;alter table public.destinations enable row level security;alter table public.bucket_list enable row level security;alter table public.favorites enable row level security;
drop policy if exists "categories readable" on public.categories;
drop policy if exists "destinations readable" on public.destinations;
drop policy if exists "destinations insertable" on public.destinations;
drop policy if exists "bucket list manageable" on public.bucket_list;
drop policy if exists "users manage own bucket list" on public.bucket_list;
drop policy if exists "favorites manageable" on public.favorites;
drop policy if exists "users manage own favorites" on public.favorites;
create policy "categories readable" on public.categories for select to anon,authenticated using(true);
create policy "destinations readable" on public.destinations for select to anon,authenticated using(true);
create policy "destinations insertable" on public.destinations for insert to anon,authenticated with check(true);
create policy "users manage own bucket list" on public.bucket_list for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "users manage own favorites" on public.favorites for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
insert into public.categories(name,description) values('Bahari','Pantai, pulau, dan petualangan laut'),('Alam','Pegunungan dan lanskap alam'),('Budaya','Sejarah, seni, dan tradisi'),('Kuliner','Rasa lokal dan perjalanan kuliner') on conflict(name) do nothing;
insert into public.categories(name,description) values('Pantai','Laut biru, pasir hangat, dan senja yang panjang.'),('Pegunungan','Udara sejuk dan pemandangan yang menenangkan.') on conflict(name) do nothing;
update public.destinations d set category_id=(select id from public.categories where name='Pantai') where d.category_id=(select id from public.categories where name='Bahari');
update public.destinations d set category_id=(select id from public.categories where name='Pegunungan') where d.name in('Gunung Bromo','Dataran Tinggi Dieng');
delete from public.categories where name='Bahari';
update public.destinations set ideal_duration=case name
 when 'Raja Ampat' then '4–5 hari' when 'Gunung Bromo' then '2–3 hari'
 when 'Ubud' then '3–4 hari' when 'Labuan Bajo' then '3–4 hari'
 when 'Yogyakarta' then '3–4 hari' when 'Dataran Tinggi Dieng' then '2 hari'
 when 'Bandung' then '2–3 hari' when 'Candi Borobudur' then '1–2 hari'
 when 'Taman Nasional Komodo' then '3–4 hari' when 'Danau Toba' then '3–4 hari'
 when 'Nusa Penida' then '2–3 hari' else ideal_duration end;
update public.destinations set image='https://images.unsplash.com/photo-1623598122059-9b5ef17619c8?auto=format&fit=crop&w=900&q=85' where name='Danau Toba';
insert into public.destinations(name,description,location,price,image,category_id)
select x.name,x.description,x.location,x.price,x.image,c.id from (values
 ('Raja Ampat','Kepulauan dengan air sebening kaca, gugusan karst ikonik, dan keanekaragaman hayati laut.','Papua Barat Daya',6500000,'https://images.unsplash.com/photo-1516690561799-46d8f74f9abf?auto=format&fit=crop&w=900&q=85','Pantai'),
 ('Gunung Bromo','Nikmati matahari terbit di lautan pasir dan pemandangan kaldera dari Penanjakan.','Jawa Timur',1800000,'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=900&q=85','Pegunungan'),
 ('Ubud','Pusat seni dan budaya Bali yang dikelilingi sawah berundak, hutan tropis, dan pura.','Bali',2400000,'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=900&q=85','Budaya'),
 ('Labuan Bajo','Gerbang menuju Taman Nasional Komodo dengan pulau, teluk biru, dan pantai pasir merah muda.','Nusa Tenggara Timur',5200000,'https://images.unsplash.com/photo-1619880889144-d6e252999afa?auto=format&fit=crop&w=1200&q=85','Pantai'),
 ('Yogyakarta','Kota istimewa dengan warisan sejarah, seni, dan kuliner.','DI Yogyakarta',1600000,'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?auto=format&fit=crop&w=900&q=85','Budaya'),
 ('Dataran Tinggi Dieng','Dataran tinggi dengan telaga, kawah vulkanik, dan kompleks candi kuno.','Jawa Tengah',1300000,'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=900&q=85','Pegunungan'),
 ('Bandung','Kota kreatif dengan suasana sejuk, kedai kopi, jajanan, dan wisata alam.','Jawa Barat',1200000,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=85','Kuliner'),
 ('Candi Borobudur','Candi Buddha dengan relief dan warisan sejarah yang menakjubkan.','Magelang, Jawa Tengah',1400000,'https://bimasbuddha.kemenag.go.id/borobudur/360/pictures/25.jpg','Budaya'),
 ('Taman Nasional Komodo','Habitat komodo dengan lanskap pulau, savana, dan kehidupan laut yang kaya.','Nusa Tenggara Timur',4800000,'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?auto=format&fit=crop&w=900&q=85','Alam'),
 ('Danau Toba','Danau vulkanik luas dengan Pulau Samosir di tengahnya. Nikmati pemandangan perbukitan dan budaya Batak.','Sumatra Utara',2200000,'https://images.unsplash.com/photo-1511497584788-876760111969?auto=format&fit=crop&w=900&q=85','Alam'),
 ('Nusa Penida','Pulau dengan tebing dramatis, pantai jernih, dan pemandangan laut lepas.','Klungkung, Bali',1800000,'https://images.unsplash.com/photo-1532253240322-146d5987f692?auto=format&fit=crop&w=1200&q=85','Pantai')
) as x(name,description,location,price,image,category) join public.categories c on c.name=x.category
where not exists(select 1 from public.destinations d where d.name=x.name);
update public.destinations set ideal_duration=case name
 when 'Raja Ampat' then '4–5 hari' when 'Gunung Bromo' then '2–3 hari'
 when 'Ubud' then '3–4 hari' when 'Labuan Bajo' then '3–4 hari'
 when 'Yogyakarta' then '3–4 hari' when 'Dataran Tinggi Dieng' then '2 hari'
 when 'Bandung' then '2–3 hari' when 'Candi Borobudur' then '1–2 hari'
 when 'Taman Nasional Komodo' then '3–4 hari' when 'Danau Toba' then '3–4 hari'
 when 'Nusa Penida' then '2–3 hari' else ideal_duration end;
update public.destinations set image='https://images.unsplash.com/photo-1623598122059-9b5ef17619c8?auto=format&fit=crop&w=900&q=85' where name='Danau Toba';

update public.destinations set image='https://images.unsplash.com/photo-1619880889144-d6e252999afa?auto=format&fit=crop&w=1200&q=85' where name='Labuan Bajo';
update public.destinations set image='https://bimasbuddha.kemenag.go.id/borobudur/360/pictures/25.jpg' where name='Candi Borobudur';
update public.destinations set image='https://images.unsplash.com/photo-1532253240322-146d5987f692?auto=format&fit=crop&w=1200&q=85' where name='Nusa Penida';
