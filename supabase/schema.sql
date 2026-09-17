-- Base du planning partagé.
-- Lecture ouverte à tous, écriture derrière un code d'équipe vérifié côté serveur.
-- Rejouable tel quel sur un projet Supabase neuf.

create extension if not exists pgcrypto with schema extensions;

-- Le planning : une seule ligne, lisible par tous, écrivable par personne en direct.
create table public.planning (
  id      text primary key,
  corps   jsonb not null,
  version bigint not null default 1,
  maj     timestamptz not null default now()
);
alter table public.planning enable row level security;

create policy "lecture publique" on public.planning
  for select to anon, authenticated using (true);

-- Le code d'accès, haché. Aucune policy : seules les fonctions security definer y touchent.
create table public.planning_acces (
  id        text primary key,
  code_hash text not null,
  maj       timestamptz not null default now()
);
alter table public.planning_acces enable row level security;

-- Tentatives ratées, pour freiner le tâtonnement sur le code.
create table public.planning_tentatives (
  ip text not null,
  au timestamptz not null default now()
);
create index planning_tentatives_ip_au on public.planning_tentatives (ip, au desc);
alter table public.planning_tentatives enable row level security;

-- IP de l'appelant, telle que PostgREST la reçoit.
create or replace function public.ip_appelant() returns text
language plpgsql stable security definer set search_path = ''
as $$
declare entetes jsonb;
begin
  begin
    entetes := current_setting('request.headers', true)::jsonb;
  exception when others then
    return 'inconnu';
  end;
  if entetes is null then return 'inconnu'; end if;
  return coalesce(nullif(split_part(entetes->>'x-forwarded-for', ',', 1), ''), 'inconnu');
end $$;

revoke all on function public.ip_appelant() from public, anon, authenticated;

-- Vérifie le code, avec un plafond de dix essais ratés par quart d'heure et par IP.
create or replace function public.verifier_code(p_code text) returns boolean
language plpgsql volatile security definer set search_path = ''
as $$
declare v_hash text; v_ip text; v_ratees int;
begin
  v_ip := public.ip_appelant();
  delete from public.planning_tentatives where au < now() - interval '15 minutes';
  select count(*) into v_ratees
    from public.planning_tentatives
   where ip = v_ip and au > now() - interval '15 minutes';
  if v_ratees >= 10 then
    raise exception 'Trop de tentatives. Réessayez dans un quart d''heure.' using errcode = 'P0001';
  end if;

  select code_hash into v_hash from public.planning_acces where id = 'saison-2026-2027';
  if v_hash is null then return false; end if;

  if extensions.crypt(coalesce(p_code, ''), v_hash) = v_hash then
    delete from public.planning_tentatives where ip = v_ip;
    return true;
  end if;

  insert into public.planning_tentatives(ip) values (v_ip);
  return false;
end $$;

-- Enregistre, si le code est bon et si personne n'a écrit entre-temps.
create or replace function public.enregistrer_planning(p_code text, p_corps jsonb, p_version bigint)
returns public.planning
language plpgsql volatile security definer set search_path = ''
as $$
declare v_ligne public.planning; v_actuelle bigint;
begin
  if not public.verifier_code(p_code) then
    raise exception 'Code d''accès invalide.' using errcode = '28000';
  end if;

  select version into v_actuelle from public.planning where id = 'saison-2026-2027' for update;

  if v_actuelle is null then
    insert into public.planning(id, corps, version) values ('saison-2026-2027', p_corps, 1)
      returning * into v_ligne;
    return v_ligne;
  end if;

  if p_version is not null and p_version <> v_actuelle then
    raise exception 'Le planning a changé entre-temps.' using errcode = '40001';
  end if;

  update public.planning
     set corps = p_corps, version = v_actuelle + 1, maj = now()
   where id = 'saison-2026-2027'
   returning * into v_ligne;
  return v_ligne;
end $$;

-- Changer le code, en connaissant l'actuel.
create or replace function public.changer_code(p_code_actuel text, p_nouveau text) returns boolean
language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not public.verifier_code(p_code_actuel) then
    raise exception 'Code d''accès invalide.' using errcode = '28000';
  end if;
  if length(coalesce(p_nouveau, '')) < 8 then
    raise exception 'Le nouveau code doit faire au moins huit caractères.' using errcode = 'P0001';
  end if;
  update public.planning_acces
     set code_hash = extensions.crypt(p_nouveau, extensions.gen_salt('bf')), maj = now()
   where id = 'saison-2026-2027';
  return true;
end $$;

grant execute on function public.verifier_code(text) to anon, authenticated;
grant execute on function public.enregistrer_planning(text, jsonb, bigint) to anon, authenticated;
grant execute on function public.changer_code(text, text) to anon, authenticated;

-- Pour que chacun voie les modifications des autres en direct.
alter publication supabase_realtime add table public.planning;

-- Poser le code d'équipe. Ne jamais committer le code en clair : à lancer à la main.
-- insert into public.planning_acces (id, code_hash)
-- values ('saison-2026-2027', extensions.crypt('<le code choisi>', extensions.gen_salt('bf')))
-- on conflict (id) do update set code_hash = excluded.code_hash, maj = now();
