-- DESTRUCTIVE: previous system_oauth connector only; never remove Auth or school profiles.
-- Requires verified backup and review of the read-only diagnostic report.
-- No CASCADE. Unexpected dependencies or objects abort the whole transaction.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '90s';
DO $retire_oauth$
DECLARE v_job_id bigint; v_proc oid;
BEGIN
  FOR v_proc IN
    SELECT to_regprocedure(signature)::oid FROM (VALUES
      ('public.oauth_operation(text,jsonb)'),
      ('public.oauth_api(text,text,jsonb)'),
      ('public.oauth_cleanup()')
    ) AS f(signature) WHERE to_regprocedure(signature) IS NOT NULL
  LOOP
    IF pg_get_functiondef(v_proc) NOT ILIKE '%system_oauth%' THEN
      RAISE EXCEPTION 'REVIEW_UNEXPECTED_PUBLIC_OAUTH_ROUTINE';
    END IF;
  END LOOP;

  IF EXISTS (
    SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE (
      (n.nspname='public' AND c.relname='profiles' AND t.tgname='oauth_profile_security')
      OR (n.nspname='auth' AND c.relname='users' AND t.tgname='oauth_auth_security')
    ) AND t.tgfoid::regprocedure::text NOT IN (
       'system_oauth.profile_security_changed()', 'system_oauth.auth_security_changed()'
    )
  ) THEN RAISE EXCEPTION 'REVIEW_UNEXPECTED_OAUTH_TRIGGER'; END IF;

  -- PL/pgSQL body references are not always represented by pg_depend.
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname IN ('public','school','school_private','auth') AND p.prokind='f'
      AND p.proname NOT IN ('oauth_operation','oauth_api','oauth_cleanup')
      AND pg_get_functiondef(p.oid) ILIKE '%system_oauth%'
  ) THEN RAISE EXCEPTION 'REVIEW_EXTERNAL_ROUTINE_DEPENDENCY'; END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE coalesce(qual,'') ILIKE '%system_oauth%'
       OR coalesce(with_check,'') ILIKE '%system_oauth%'
  ) THEN RAISE EXCEPTION 'REVIEW_EXTERNAL_POLICY_DEPENDENCY'; END IF;

  IF to_regnamespace('system_oauth') IS NOT NULL AND EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='system_oauth' AND c.relkind IN ('r','p','v','m','f')
      AND c.relname NOT IN (
        'clients','requests','grants','codes','access_tokens','refresh_tokens','rate_limits'
      )
  ) THEN RAISE EXCEPTION 'REVIEW_UNEXPECTED_OAUTH_SCHEMA_OBJECTS'; END IF;

  IF to_regclass('cron.job') IS NOT NULL THEN
    EXECUTE 'SELECT jobid FROM cron.job WHERE jobname=$1'
      INTO v_job_id USING 'system-oauth-cleanup';
    IF v_job_id IS NOT NULL THEN
      EXECUTE 'SELECT cron.unschedule($1)' USING v_job_id;
    END IF;
  END IF;

  IF to_regclass('public.profiles') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS oauth_profile_security ON public.profiles';
  END IF;
  IF to_regclass('auth.users') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS oauth_auth_security ON auth.users';
  END IF;

  EXECUTE 'DROP FUNCTION IF EXISTS public.oauth_operation(text,jsonb) RESTRICT';
  EXECUTE 'DROP FUNCTION IF EXISTS public.oauth_api(text,text,jsonb) RESTRICT';
  EXECUTE 'DROP FUNCTION IF EXISTS public.oauth_cleanup() RESTRICT';

  IF to_regnamespace('system_oauth') IS NOT NULL THEN
    EXECUTE 'DROP FUNCTION IF EXISTS system_oauth.profile_security_changed() RESTRICT';
    EXECUTE 'DROP FUNCTION IF EXISTS system_oauth.auth_security_changed() RESTRICT';
    EXECUTE 'DROP FUNCTION IF EXISTS system_oauth.revoke_matching(uuid,text) RESTRICT';
    EXECUTE 'DROP FUNCTION IF EXISTS system_oauth.revoke_grant(uuid) RESTRICT';
    IF to_regclass('system_oauth.grants') IS NOT NULL THEN
      EXECUTE 'DROP FUNCTION IF EXISTS system_oauth.grant_live(system_oauth.grants) RESTRICT';
    END IF;
    EXECUTE 'DROP FUNCTION IF EXISTS system_oauth.browser_error(uuid,numeric,uuid) RESTRICT';
    EXECUTE 'DROP FUNCTION IF EXISTS system_oauth.live_user(uuid) RESTRICT';
    EXECUTE 'DROP FUNCTION IF EXISTS system_oauth.audit(uuid,text,text,jsonb) RESTRICT';
    EXECUTE 'DROP FUNCTION IF EXISTS system_oauth.strings(jsonb) RESTRICT';
    EXECUTE 'DROP TABLE IF EXISTS system_oauth.codes RESTRICT';
    EXECUTE 'DROP TABLE IF EXISTS system_oauth.access_tokens RESTRICT';
    EXECUTE 'DROP TABLE IF EXISTS system_oauth.refresh_tokens RESTRICT';
    EXECUTE 'DROP TABLE IF EXISTS system_oauth.requests RESTRICT';
    EXECUTE 'DROP TABLE IF EXISTS system_oauth.grants RESTRICT';
    EXECUTE 'DROP TABLE IF EXISTS system_oauth.rate_limits RESTRICT';
    EXECUTE 'DROP TABLE IF EXISTS system_oauth.clients RESTRICT';
    EXECUTE 'DROP SCHEMA system_oauth RESTRICT';
  END IF;
END $retire_oauth$;
NOTIFY pgrst, 'reload schema';
COMMIT;
