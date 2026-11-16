-- TravelBucket: isolate bucket list and favorites by the signed-in Supabase user.
-- Run once from Supabase Dashboard > SQL Editor.
alter table public.bucket_list add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.favorites add column if not exists user_id uuid references auth.users(id) on delete cascade;
-- Previous records had no owner. Remove them rather than show shared data to every account.
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
alter table public.bucket_list enable row level security;
alter table public.favorites enable row level security;
drop policy if exists "bucket list manageable" on public.bucket_list;
drop policy if exists "favorites manageable" on public.favorites;
drop policy if exists "users manage own bucket list" on public.bucket_list;
drop policy if exists "users manage own favorites" on public.favorites;
create policy "users manage own bucket list" on public.bucket_list for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "users manage own favorites" on public.favorites for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);

-- Refresh the three destination photos in the catalog.
update public.destinations set image='https://images.unsplash.com/photo-1619880889144-d6e252999afa?auto=format&fit=crop&w=1200&q=85' where name='Labuan Bajo';
update public.destinations set image='https://bimasbuddha.kemenag.go.id/borobudur/360/pictures/25.jpg' where name='Candi Borobudur';
update public.destinations set image='https://images.unsplash.com/photo-1532253240322-146d5987f692?auto=format&fit=crop&w=1200&q=85' where name='Nusa Penida';
