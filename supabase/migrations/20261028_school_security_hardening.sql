-- Harden live school authorization without altering records, Auth or third-party applications.
-- This migration fixes stale teacher access to submitted files, group permissions,
-- anonymous EXECUTE on school security helpers and repeated JWT evaluation.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';

-- A former teacher must not see a student's private submission just because
-- the old assignment still lists that teacher. Current class+subject authority
-- is required, exactly as in the assignment review RPC.
CREATE OR REPLACE FUNCTION public.can_read_assignment_file(p_path text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public,pg_catalog
AS $school_file$
  SELECT public.is_manager()
      OR EXISTS (
        SELECT 1
        FROM public.assignment_submissions s
        JOIN public.assignments a ON a.id=s.assignment_id
        WHERE s.file_path=p_path
          AND (
            s.student_id=auth.uid()
            OR (
              a.teacher_id=auth.uid()
              AND public.teacher_has_access(a.class_id,a.subject_id)
            )
          )
      )
$school_file$;

-- Group teacher access must be revoked when the actual assignment is removed.
CREATE OR REPLACE FUNCTION public.teacher_group_matches(
  p_group uuid,p_class uuid,p_subject uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public,pg_catalog
AS $school_group$
  SELECT public.teacher_has_access(p_class,p_subject)
     AND EXISTS (
       SELECT 1 FROM public.student_groups g
       WHERE g.id=p_group AND g.teacher_id=auth.uid()
         AND g.class_id=p_class AND g.subject_id=p_subject
     )
$school_group$;

CREATE OR REPLACE FUNCTION public.can_review_group_field(p_field uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public,pg_catalog
AS $school_review$
  SELECT public.is_manager()
    OR EXISTS (
      SELECT 1
      FROM public.group_score_fields f
      JOIN public.student_groups g ON g.id=f.group_id
      WHERE f.id=p_field
        AND (
          (g.teacher_id=auth.uid()
            AND public.teacher_has_access(g.class_id,g.subject_id))
          OR
          (g.leader_id=auth.uid()
            AND public.account_ready()
            AND public.current_role()='student'
            AND EXISTS (
               SELECT 1 FROM public.student_group_members gm
               WHERE gm.group_id=g.id AND gm.student_id=auth.uid()
            ))
        )
    )
$school_review$;

-- Restrictive policies already prevent OAuth JWTs from touching school tables.
-- Change only their repeated JWT evaluation, not the authorization result.
DO $optimize_oauth_policy$
DECLARE p record;
BEGIN
  FOR p IN
    SELECT * FROM pg_policies
    WHERE schemaname='public' AND policyname='oauth_no_direct_access'
  LOOP
    IF p.cmd <> 'ALL' OR p.roles <> ARRAY['authenticated']::name[]
       OR p.qual NOT ILIKE '%auth.jwt()%client_id%'
       OR p.with_check NOT ILIKE '%auth.jwt()%client_id%'
    THEN RAISE EXCEPTION 'UNEXPECTED_OAUTH_POLICY: %.%',p.schemaname,p.tablename;
    END IF;
    EXECUTE format(
      'ALTER POLICY %I ON %I.%I
       USING (coalesce((select auth.jwt())->>''client_id'','''')='''')
       WITH CHECK (coalesce((select auth.jwt())->>''client_id'','''')='''')',
      p.policyname,p.schemaname,p.tablename
    );
  END LOOP;
END $optimize_oauth_policy$;

-- Public functions named below are internal school authorization helpers.
-- Grant signed-in school users explicit EXECUTE, but deny anonymous RPC access.
-- Event/row trigger functions keep working without a browser EXECUTE grant.
DO $limit_anonymous_definers$
DECLARE p record;
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE ('anon'=ANY(roles) OR 'public'=ANY(roles))
      AND (
        coalesce(qual,'') ILIKE ANY (ARRAY[
          '%is_manager(%','%can_manage_group(%','%teacher_has_access(%',
          '%student_in_class(%','%can_read_assignment_file(%'
        ])
        OR coalesce(with_check,'') ILIKE ANY (ARRAY[
          '%is_manager(%','%can_manage_group(%','%teacher_has_access(%',
          '%student_in_class(%','%can_read_assignment_file(%'
        ])
      )
  ) THEN RAISE EXCEPTION 'ANONYMOUS_POLICY_USES_SCHOOL_HELPER'; END IF;

  FOR p IN
    SELECT f.oid,f.prorettype, f.oid::regprocedure AS signature
    FROM pg_proc f JOIN pg_namespace n ON n.oid=f.pronamespace
    WHERE n.nspname='public' AND f.prosecdef
      AND f.proname IN (
        'current_role','can_manage_group','can_read_assignment_file',
        'can_review_group_field','can_submit_group_score','can_view_group_field',
        'can_view_group','is_class_representative','is_manager',
        'rls_auto_enable','student_can_access_assignment','student_in_class',
        'students_share_class','sync_homework_on_assignment',
        'sync_homework_on_class_student','sync_homework_on_group_member',
        'teacher_group_matches','teacher_has_access'
      )
  LOOP
    IF p.prorettype NOT IN ('pg_catalog.trigger'::regtype,'pg_catalog.event_trigger'::regtype) THEN
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated,service_role',p.signature);
    END IF;
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC,anon',p.signature);
  END LOOP;
END $limit_anonymous_definers$;

NOTIFY pgrst,'reload schema';
COMMIT;
