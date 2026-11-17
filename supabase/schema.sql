-- DRAFT schema for Azm cloud sync, friends and challenges.
-- NOT wired into the app yet and NOT tested. Review before use.
-- Run in the Supabase SQL editor of YOUR OWN project.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester uuid not null references public.profiles(id) on delete cascade,
  addressee uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  unique (requester, addressee),
  check (requester <> addressee)
);

create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  goal_completions int not null check (goal_completions > 0),
  starts_on date not null,
  ends_on date not null,
  created_at timestamptz not null default now(),
  check (ends_on >= starts_on)
);

create table if not exists public.challenge_members (
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  completions int not null default 0,
  primary key (challenge_id, user_id)
);

alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_members enable row level security;

create policy "profiles readable by signed-in users" on public.profiles
  for select using (auth.role() = 'authenticated');
create policy "users manage own profile" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "friendships visible to both sides" on public.friendships
  for select using (auth.uid() in (requester, addressee));
create policy "users send requests" on public.friendships
  for insert with check (auth.uid() = requester);
create policy "addressee answers requests" on public.friendships
  for update using (auth.uid() = addressee);

create policy "members see challenges" on public.challenges
  for select using (
    owner = auth.uid() or exists (
      select 1 from public.challenge_members m
      where m.challenge_id = id and m.user_id = auth.uid())
  );
create policy "owner manages challenge" on public.challenges
  for all using (owner = auth.uid()) with check (owner = auth.uid());

create policy "members see members" on public.challenge_members
  for select using (
    user_id = auth.uid() or exists (
      select 1 from public.challenge_members m
      where m.challenge_id = challenge_members.challenge_id and m.user_id = auth.uid())
  );
create policy "users update own progress" on public.challenge_members
  for update using (user_id = auth.uid());
