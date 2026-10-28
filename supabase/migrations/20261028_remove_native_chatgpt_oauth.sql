-- ChatGPT-specific *native* OAuth integration cleanup for the main Supabase project.
-- MANUAL MIGRATION: never run before disabling the Custom Access Token hook in
-- Authentication > Hooks and reviewing OAuth clients under Authentication > OAuth Apps.
-- DISABLE/REMOVE ChatGPT OAuth clients in the dashboard first. If any native
-- clients remain this migration aborts rather than affecting unrelated clients.
-- Preserves standard Supabase Auth, school data, manager MFA, account_ready(),
-- oauth_no_direct_access RLS, oauth_no_direct_storage and the pre-request guard.
-- These guards must remain until any old OAuth-issued JWT has expired.
-- No CASCADE; all unexpected dependencies abort and roll back.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';

DO $native_chatgpt_preflight$
DECLARE
  v_count bigint;
  v_def text;
BEGIN
  IF to_regclass('auth.oauth_clients') IS NOT NULL THEN
    EXECUTE 'SELECT count(*) FROM auth.oauth_clients' INTO v_count;
    IF v_count > 0 THEN
      RAISE EXCEPTION 'NATIVE_OAUTH_CLIENTS_EXIST: %; review Authentication > OAuth Apps and delete only the intended ChatGPT clients first', v_count;
    END IF;
  END IF;
  IF to_regclass('public.oauth_connected_apps') IS NOT NULL THEN
    EXECUTE 'SELECT count(*) FROM public.oauth_connected_apps' INTO v_count;
    IF v_count > 0 THEN
      RAISE EXCEPTION 'OAUTH_CONNECTED_APPS_NOT_EMPTY: %; review and revoke before cleanup', v_count;
    END IF;
  END IF;
  IF to_regprocedure('system_private.chatgpt_access_token_hook(jsonb)') IS NOT NULL THEN
    SELECT pg_get_functiondef(to_regprocedure('system_private.chatgpt_access_token_hook(jsonb)')) INTO v_def;
    IF v_def NOT ILIKE '%chatgpt_oauth_config%' THEN
      RAISE EXCEPTION 'UNEXPECTED_CUSTOM_ACCESS_TOKEN_HOOK: manual review required';
    END IF;
  END IF;
  IF to_regprocedure('system_private.audit_oauth_apps()') IS NOT NULL THEN
    SELECT pg_get_functiondef(to_regprocedure('system_private.audit_oauth_apps()')) INTO v_def;
    IF v_def NOT ILIKE '%oauth_connected_apps%' THEN
      RAISE EXCEPTION 'UNEXPECTED_CONNECTED_APPS_AUDIT: manual review required';
    END IF;
  END IF;
  -- SQL alone cannot confirm that Authentication > Hooks has been disabled.
  -- The operator must disable that setting and test normal sign-in first.
END
$native_chatgpt_preflight$;

DO $native_chatgpt_cleanup$
BEGIN
  IF to_regclass('public.oauth_connected_apps') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS oauth_connections_audit ON public.oauth_connected_apps';
  END IF;
  EXECUTE 'DROP FUNCTION IF EXISTS system_private.audit_oauth_apps() RESTRICT';
  EXECUTE 'DROP TABLE IF EXISTS public.oauth_connected_apps RESTRICT';

  EXECUTE 'DROP FUNCTION IF EXISTS system_private.chatgpt_access_token_hook(jsonb) RESTRICT';
  EXECUTE 'DROP TABLE IF EXISTS system_private.chatgpt_oauth_config RESTRICT';
END
$native_chatgpt_cleanup$;

NOTIFY pgrst, 'reload schema';
COMMIT;

-- Leave the school RLS restrictions, manager session guard, account_ready(),
-- and PostgREST authenticator pre-request guard intact. They are defensive.
