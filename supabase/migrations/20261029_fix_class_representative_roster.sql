-- Repair class representative discipline roster and reject cross-class scores.
-- Only enrolled students may represent a class; existing representative rows remain intact.
-- The bootstrap function keeps its original privacy filtering of profile data.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';

DO $check$
BEGIN
 IF EXISTS (
   SELECT 1 FROM public.class_representatives cr
   WHERE NOT EXISTS (
     SELECT 1 FROM public.class_students cs
     WHERE cs.class_id=cr.class_id AND cs.student_id=cr.student_id
   )
 ) THEN
   RAISE EXCEPTION 'REPRESENTATIVE_NOT_ENROLLED: review existing records before migration';
 END IF;
END
$check$;

-- Enforce membership atomically; withdrawing a student also revokes their
-- representative appointment. No personally identifiable data is modified.
DO $fk$
BEGIN
 IF NOT EXISTS(
   SELECT 1 FROM pg_constraint
   WHERE conrelid='public.class_representatives'::regclass
     AND conname='class_representatives_membership_fkey'
 ) THEN
   ALTER TABLE public.class_representatives
   ADD CONSTRAINT class_representatives_membership_fkey
   FOREIGN KEY (class_id,student_id)
   REFERENCES public.class_students(class_id,student_id)
   ON DELETE CASCADE;
 END IF;
END
$fk$;

-- Prevent privilege from surviving removal from the class.
CREATE OR REPLACE FUNCTION public.is_class_representative(p_class uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public
AS $rep$
  SELECT public.student_in_class(p_class)
  AND EXISTS (
    SELECT 1 FROM public.class_representatives cr
    WHERE cr.class_id=p_class AND cr.student_id=auth.uid()
  )
$rep$;

-- The previous RLS policy allowed the representative to see only their own
-- membership. Grant SELECT to the roster of their own representative class.
ALTER POLICY cs_read ON public.class_students USING (
  public.is_manager()
  OR student_id=auth.uid()
  OR public.is_class_representative(class_id)
  OR EXISTS (
    SELECT 1 FROM public.teacher_assignments ta
    WHERE ta.teacher_id=auth.uid()
      AND ta.class_id=class_students.class_id
  )
);

-- The real frontend uses this optimized bootstrap RPC rather than the table
-- fallback. It must return all classmates of the representative's class.
create or replace function public.get_app_bootstrap() returns jsonb
language plpgsql stable security definer set search_path=public
as $$ begin perform public.require_account_ready();
return jsonb_build_object(
'profiles',(select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'full_name',p.full_name,'role',p.role,'active',p.active,
'national_id',case when public.can_read_student(p.id) or p.id=auth.uid() or public.is_manager() then p.national_id else null end) order by p.full_name),'[]')
from public.profiles p where p.id=auth.uid() or public.is_manager() or (p.role='student' and public.can_read_student(p.id))
or (p.role='student' and public.current_role()='student' and public.students_share_class(p.id))
or p.role in ('teacher','manager')
or exists(select 1 from public.extracurricular_enrollments en join public.extracurricular_classes ec on ec.id=en.class_id where en.student_id=p.id and ec.teacher_id=auth.uid())
or exists(select 1 from public.appointments ap join public.appointment_slots sl on sl.id=ap.slot_id where ap.requester_id=p.id and sl.staff_id=auth.uid())),
'grades',(select coalesce(jsonb_agg(g order by g.sort_order),'[]') from public.grade_levels g where public.is_manager() or exists(select 1 from public.classes c where c.grade_id=g.id and public.can_read_class(c.id))),
'classes',(select coalesce(jsonb_agg(c order by c.title),'[]') from public.classes c where public.can_read_class(c.id)),
'subjects',(select coalesce(jsonb_agg(s order by s.title),'[]') from public.subjects s where public.is_manager() or exists(select 1 from public.classes c where c.grade_id=s.grade_id and public.can_read_class(c.id))),
'assignments',(select coalesce(jsonb_agg(t),'[]') from public.teacher_assignments t where public.is_manager() or t.teacher_id=auth.uid() or public.student_in_class(t.class_id)),
'classStudents',(select coalesce(jsonb_agg(cs),'[]') from public.class_students cs where public.is_manager() or cs.student_id=auth.uid() or public.can_manage_class(cs.class_id) or public.is_class_representative(cs.class_id)),
'representatives',(select coalesce(jsonb_agg(cr),'[]') from public.class_representatives cr where public.can_read_class(cr.class_id)));
end $$;

-- RLS must also protect scores from being assigned to students outside the
-- representative's class even if an API caller forges the request payload.
ALTER POLICY discipline_write ON public.discipline_scores
WITH CHECK (
  updated_by=auth.uid()
  AND (public.is_manager() OR public.is_class_representative(class_id))
  AND EXISTS (
    SELECT 1 FROM public.class_students cs
    WHERE cs.class_id=discipline_scores.class_id
      AND cs.student_id=discipline_scores.student_id
  )
);
ALTER POLICY discipline_update ON public.discipline_scores
USING (
  public.is_manager()
  OR (
    public.is_class_representative(class_id)
    AND EXISTS (
      SELECT 1 FROM public.class_students cs
      WHERE cs.class_id=discipline_scores.class_id
        AND cs.student_id=discipline_scores.student_id
    )
  )
)
WITH CHECK (
  updated_by=auth.uid()
  AND (public.is_manager() OR public.is_class_representative(class_id))
  AND EXISTS (
    SELECT 1 FROM public.class_students cs
    WHERE cs.class_id=discipline_scores.class_id
      AND cs.student_id=discipline_scores.student_id
  )
);

REVOKE EXECUTE ON FUNCTION public.is_class_representative(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.is_class_representative(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_app_bootstrap() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_app_bootstrap() TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
