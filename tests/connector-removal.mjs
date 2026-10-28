import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {database} from './database-setup.mjs';
import {seed,migrate} from './fixtures.mjs';
const [page,app,auth,config,pkg]=await Promise.all([
  readFile('index.html','utf8'),readFile('app.js','utf8'),readFile('js/auth.js','utf8'),
  readFile('supabase/config.toml','utf8'),readFile('package.json','utf8')
]);
assert.doesNotMatch(page,/oauthView|js\/oauth\.js|oauthContent/);
assert.doesNotMatch(app,/resumeOAuth|oauthView|connected-apps/);
assert.doesNotMatch(auth,/connected-apps|showConnectedApps/);
assert.doesNotMatch(config,/functions\.oauth-connector/);
assert.doesNotMatch(pkg,/test:oauth|package:plugin|test:plugin/);
const db=await database();
try{
  await seed(db);await migrate(db);
  const before=(await db.query('select count(*)::int n from public.profiles')).rows[0].n;
  await db.exec(`
    create schema system_oauth;
    create table system_oauth.clients(client_id text primary key);
    create table system_oauth.grants(id uuid primary key);
    create function public.oauth_operation(text,jsonb) returns jsonb language sql as 'select null::jsonb';
    create function public.oauth_api(text,text,jsonb) returns jsonb language sql as 'select null::jsonb';
    create function public.oauth_cleanup() returns jsonb language sql as 'select null::jsonb';
    create function system_oauth.profile_security_changed() returns trigger language plpgsql as 'begin return new; end';
    create function system_oauth.auth_security_changed() returns trigger language plpgsql as 'begin return new; end';
    create trigger oauth_profile_security after update on public.profiles for each row execute function system_oauth.profile_security_changed();
    create trigger oauth_auth_security after update on auth.users for each row execute function system_oauth.auth_security_changed();
  `);
  assert.equal((await db.query("select to_regnamespace('system_oauth') is not null as present")).rows[0].present,true);
  const retire=await readFile('supabase/migrations/20261028_remove_chatgpt_connector.sql','utf8');
  await db.exec(retire);await db.exec(retire);
  assert.equal((await db.query("select to_regnamespace('system_oauth') is null as gone")).rows[0].gone,true);
  for(const routine of ['oauth_operation(text,jsonb)','oauth_api(text,text,jsonb)','oauth_cleanup()']){
    assert.equal((await db.query('select to_regprocedure($1) is not null as present',['public.'+routine])).rows[0].present,false);
  }
  assert.equal((await db.query("select to_regprocedure('public.assert_manager_session(uuid,uuid)') is not null as present")).rows[0].present,true);
  assert.equal((await db.query('select count(*)::int n from public.profiles')).rows[0].n,before);
  console.log('Connector retirement checked: runtime references removed, SQL idempotent and profiles preserved.');
}finally{await db.close();}
