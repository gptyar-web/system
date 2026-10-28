-- Retire only the previous school OAuth account connector.
-- Requires verified backup; removes connector clients and token hashes.
begin;
do $retire_oauth$
declare v_job bigint;
begin
  if to_regnamespace('system_oauth') is not null and exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='system_oauth' and c.relkind in ('r','p','v','m','f')
      and c.relname not in ('clients','requests','grants','codes','access_tokens','refresh_tokens','rate_limits')
  ) then raise exception 'REVIEW_UNEXPECTED_OAUTH_SCHEMA_OBJECTS'; end if;
  if to_regclass('cron.job') is not null then
    select jobid into v_job from cron.job where jobname='system-oauth-cleanup';
    if v_job is not null then perform cron.unschedule(v_job); end if;
  end if;
end $retire_oauth$;
drop trigger if exists oauth_profile_security on public.profiles;
drop trigger if exists oauth_auth_security on auth.users;
drop function if exists public.oauth_operation(text,jsonb);
drop function if exists public.oauth_api(text,text,jsonb);
drop function if exists public.oauth_cleanup();
drop schema if exists system_oauth cascade;
notify pgrst,'reload schema';
commit;
