import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {database} from './database-setup.mjs';
import {seed,migrate,asUser,ids,uuid} from './fixtures.mjs';

const db=await database();
const as=async(user,sql,params=[])=>asUser(db,user,()=>db.query(sql,params));

try {
  await seed(db);
  await migrate(db);
  await db.query('insert into public.class_representatives(class_id,student_id) values($1,$2)',[ids.class,ids.student]);

  const before=(await as(ids.student,'select public.get_app_bootstrap() as boot')).rows[0].boot;
  assert.equal(before.classStudents.filter(x=>x.class_id===ids.class).length,1,
    'Regression setup: representative incorrectly receives only their own roster row');

  await db.exec(await readFile('supabase/migrations/20261029_fix_class_representative_roster.sql','utf8'));

  const after=(await as(ids.student,'select public.get_app_bootstrap() as boot')).rows[0].boot;
  const classRoster=after.classStudents.filter(x=>x.class_id===ids.class);
  assert.equal(classRoster.length,3,'Representative must receive the full roster of their own class');
  assert.equal(after.classStudents.some(x=>x.class_id===ids.otherClass),false,
    'Representative must not receive the roster of an unrelated class');

  assert.equal((await as(ids.student,'select count(*)::int n from public.class_students where class_id=$1',[ids.class])).rows[0].n,3);
  assert.equal((await as(ids.student,'select count(*)::int n from public.class_students where class_id=$1',[ids.otherClass])).rows[0].n,0);
  assert.equal((await as(ids.classmate,'select count(*)::int n from public.class_students where class_id=$1',[ids.class])).rows[0].n,1,
    'An ordinary student still sees only their own membership');
  assert.equal((await as(ids.student,'select public.is_class_representative($1) as yes',[ids.otherClass])).rows[0].yes,false);

  // A representative may grade an enrolled classmate, never a student from a
  // different class even when the submitted class_id is forged.
  await as(ids.student,'insert into public.discipline_scores(class_id,student_id,score,updated_by) values($1,$2,2,$3)',
    [ids.class,ids.classmate,ids.student]);
  await assert.rejects(()=>as(ids.student,
    'insert into public.discipline_scores(class_id,student_id,score,updated_by) values($1,$2,3,$3)',
    [ids.class,ids.otherStudent,ids.student]),/row-level security|permission denied/i);
  await assert.rejects(()=>as(ids.student,
    'update public.discipline_scores set student_id=$1 where class_id=$2 and student_id=$3',
    [ids.otherStudent,ids.class,ids.classmate]),/row-level security|permission denied/i);

  await assert.rejects(()=>db.query(
    'insert into public.class_representatives(class_id,student_id) values($1,$2)',
    [ids.otherClass,ids.student]
  ),/foreign key|violates foreign key/i);

  // Removing the representative from the class must revoke their appointment.
  await db.query('delete from public.class_students where class_id=$1 and student_id=$2',[ids.class,ids.student]);
  assert.equal((await db.query('select count(*)::int n from public.class_representatives where student_id=$1',[ids.student])).rows[0].n,0);
  assert.equal((await as(ids.student,'select public.is_class_representative($1) as yes',[ids.class])).rows[0].yes,false);
  assert.equal((await as(ids.student,'select count(*)::int n from public.class_students where class_id=$1',[ids.class])).rows[0].n,0);
  assert.equal((await db.query('select count(*)::int n from public.profiles')).rows[0].n,7,
    'No student profile is removed as a side-effect');
  console.log('PASS: representative roster, class isolation, discipline write scope and membership revocation');
} finally {
  await db.close();
}
