import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {database} from './database-setup.mjs';
import {seed,migrate,asUser,ids,uuid} from './fixtures.mjs';

const db=await database();
const path=ids.student+'/submitted.txt';
const as=(user,sql,params=[])=>asUser(db,user,()=>db.query(sql,params));
try{
  await seed(db);await migrate(db);
  await db.query(
    "insert into assignment_submissions(assignment_id,student_id,file_path,original_name) values($1,$2,$3,'submitted.txt')",
    [uuid(42),ids.student,path]
  );
  await db.exec(`
    create policy oauth_no_direct_access on public.scores
    as restrictive for all to authenticated
    using(coalesce(auth.jwt()->>'client_id','')='')
    with check(coalesce(auth.jwt()->>'client_id','')='');
  `);

  assert.equal((await as(ids.teacher,'select public.can_read_assignment_file($1) as allowed',[path])).rows[0].allowed,true);
  assert.equal((await as(ids.student,'select public.can_read_assignment_file($1) as allowed',[path])).rows[0].allowed,true);
  assert.equal((await as(ids.teacher,'select public.teacher_group_matches($1,$2,$3) as allowed',[uuid(40),ids.class,ids.subject])).rows[0].allowed,true);
  assert.equal((await as(ids.teacher,'select public.can_review_group_field($1) as allowed',[uuid(41)])).rows[0].allowed,true);

  const migration=await readFile('supabase/migrations/20261028_school_security_hardening.sql','utf8');
  await db.exec(migration);

  assert.equal((await as(ids.teacher,'select public.can_read_assignment_file($1) as allowed',[path])).rows[0].allowed,true);
  assert.equal((await as(ids.student,'select public.can_read_assignment_file($1) as allowed',[path])).rows[0].allowed,true);
  assert.equal((await as(ids.student,'select public.can_review_group_field($1) as allowed',[uuid(41)])).rows[0].allowed,true);

  await db.query('delete from teacher_assignments where teacher_id=$1 and class_id=$2 and subject_id=$3',
    [ids.teacher,ids.class,ids.subject]);

  assert.equal((await as(ids.teacher,'select public.can_read_assignment_file($1) as allowed',[path])).rows[0].allowed,false,
    'Removed teacher could still inspect a private student file');
  assert.equal((await as(ids.teacher,'select public.teacher_group_matches($1,$2,$3) as allowed',[uuid(40),ids.class,ids.subject])).rows[0].allowed,false);
  assert.equal((await as(ids.teacher,'select public.can_review_group_field($1) as allowed',[uuid(41)])).rows[0].allowed,false);
  assert.equal((await as(ids.student,'select public.can_read_assignment_file($1) as allowed',[path])).rows[0].allowed,true);
  assert.equal((await as(ids.manager,'select public.can_read_assignment_file($1) as allowed',[path])).rows[0].allowed,true);

  await db.exec('reset role');
  await db.exec('set role anon');
  await assert.rejects(()=>db.query('select public.can_read_assignment_file($1)',[path]),/permission denied/);
  await assert.rejects(()=>db.query('select public.is_manager()'),/permission denied/);
  await db.exec('reset role');

  const policy=(await db.query("select qual,with_check from pg_policies where schemaname='public' and tablename='scores' and policyname='oauth_no_direct_access'")).rows[0];
  assert.match(policy.qual,/SELECT auth.jwt\(\)/i);
  assert.match(policy.with_check,/SELECT auth.jwt\(\)/i);
  assert.equal((await db.query('select count(*)::int n from profiles')).rows[0].n,7);
  console.log('PASS school private assignment access, group revocation, anonymous RPC and JWT policy optimizations');
} finally {await db.close();}
