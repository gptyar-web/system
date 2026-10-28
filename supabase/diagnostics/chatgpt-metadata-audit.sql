-- READ ONLY: share the safe_report result, never credentials or user data.
SELECT jsonb_pretty(jsonb_build_object(
  'report_type','school-chatgpt-connector-metadata-v1',
  'database_name',current_database(),
  'schemas',coalesce((
    SELECT jsonb_agg(nspname ORDER BY nspname)
    FROM pg_namespace
    WHERE nspname IN ('system_oauth','school_oauth','school','school_private')
  ),'[]'::jsonb),
  'connector_tables',coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'schema',schemaname,'name',relname,'estimated_rows',n_live_tup
    ) ORDER BY schemaname,relname)
    FROM pg_stat_user_tables WHERE schemaname IN ('system_oauth','school_oauth')
  ),'[]'::jsonb),
  'routines',coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'schema',n.nspname,'name',p.proname,
      'arguments',pg_get_function_identity_arguments(p.oid)
    ) ORDER BY n.nspname,p.proname)
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname IN ('system_oauth','school_oauth')
       OR (n.nspname IN ('public','school') AND p.proname IN (
         'oauth_operation','oauth_api','oauth_cleanup','oauth_postgrest_guard',
         'assert_manager_session'))
  ),'[]'::jsonb),
  'triggers',coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'schema',n.nspname,'table',c.relname,'name',t.tgname,'enabled',t.tgenabled
    ) ORDER BY n.nspname,c.relname,t.tgname)
    FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE NOT t.tgisinternal AND t.tgname ~* '(chatgpt|oauth|mcp)'
  ),'[]'::jsonb),
  'policies',coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'schema',schemaname,'table',tablename,'name',policyname
    ) ORDER BY schemaname,tablename,policyname)
    FROM pg_policies WHERE policyname ~* '(chatgpt|oauth|mcp)'
  ),'[]'::jsonb),
  'external_functions_referencing_oauth',coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'schema',n.nspname,'name',p.proname,
      'arguments',pg_get_function_identity_arguments(p.oid)
    ) ORDER BY n.nspname,p.proname)
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname IN ('public','school','school_private') AND p.prokind='f'
      AND (pg_get_functiondef(p.oid) ILIKE '%system_oauth%'
        OR pg_get_functiondef(p.oid) ILIKE '%school_oauth%')
  ),'[]'::jsonb),
  'cron_available',to_regclass('cron.job') IS NOT NULL,
  'manager_session_guard_present',
     to_regprocedure('public.assert_manager_session(uuid,uuid)') IS NOT NULL,
  'postgrest_pre_request_configured',
     nullif(current_setting('pgrst.db_pre_request',true),'') IS NOT NULL
)) AS safe_report;
-- Run separately on both Supabase projects. This reports catalog metadata only.
-- Edge Functions, OAuth clients in Auth, installed ChatGPT apps are not listed by SQL.
