-- The Strange Quark: accounts, progress and community submissions.
-- Paste into the Supabase SQL editor and run once on a new project.

-- Profiles: one per auth user, created by trigger from the username given at sign-up.
create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text not null check (username ~ '^[A-Za-z0-9_]{3,20}$'),
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);
create unique index profiles_username_key on public.profiles (lower(username));

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, username)
  values (new.id, new.raw_user_meta_data ->> 'username');
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.username_available(name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select not exists (select 1 from public.profiles where lower(username) = lower(name))
$$;

create function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false)
$$;

-- Visits: one row per day a user opened the site. Days count from 2026-01-01 in the visitor's local time.
create table public.visits (
  user_id uuid not null references public.profiles on delete cascade,
  day integer not null,
  primary key (user_id, day)
);

-- Quiz scores: best and most recent score per fact, plus how many times it was taken.
create table public.quiz_scores (
  user_id uuid not null references public.profiles on delete cascade,
  fact_id text not null check (char_length(fact_id) <= 40),
  best smallint not null check (best between 0 and 20),
  last smallint not null check (last between 0 and 20),
  attempts integer not null default 1 check (attempts >= 1),
  updated_at timestamptz not null default now(),
  primary key (user_id, fact_id)
);

-- Records a finished quiz atomically, so two devices can't overwrite each other's best score.
create function public.record_quiz(p_fact_id text, p_score integer, p_attempts integer default 1)
returns public.quiz_scores
language sql as $$
  insert into public.quiz_scores as q (user_id, fact_id, best, last, attempts)
  values (auth.uid(), p_fact_id, p_score, p_score, p_attempts)
  on conflict (user_id, fact_id) do update
    set best = greatest(q.best, excluded.best),
        last = excluded.last,
        attempts = q.attempts + excluded.attempts,
        updated_at = now()
  returning *
$$;

-- Submissions: facts and topic ideas from readers, published once an admin approves them.
create table public.submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  kind text not null check (kind in ('fact', 'topic')),
  field text not null check (field in ('Physics', 'Mathematics')),
  title text not null check (char_length(title) between 3 and 120),
  body text not null check (char_length(body) between 10 and 2000),
  source_url text check (source_url is null or (source_url ~* '^https?://' and char_length(source_url) <= 500)),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);
create index submissions_status_idx on public.submissions (status, created_at desc);

-- Row level security
alter table public.profiles enable row level security;
alter table public.visits enable row level security;
alter table public.quiz_scores enable row level security;
alter table public.submissions enable row level security;

create policy "Profiles are public" on public.profiles
  for select using (true);

create policy "Users manage their own visits" on public.visits
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Users manage their own scores" on public.quiz_scores
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Read approved, your own, or everything as admin" on public.submissions
  for select using (status = 'approved' or user_id = auth.uid() or public.is_admin());

create policy "Submit as yourself, up to 5 pending" on public.submissions
  for insert to authenticated
  with check (
    user_id = auth.uid() and status = 'pending' and reviewed_at is null
    and (select count(*) from public.submissions s where s.user_id = auth.uid() and s.status = 'pending') < 5
  );

create policy "Admins review submissions" on public.submissions
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "Withdraw your pending submissions, or delete as admin" on public.submissions
  for delete to authenticated
  using ((user_id = auth.uid() and status = 'pending') or public.is_admin());
