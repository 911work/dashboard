-- Optional demo seed data.
-- Run AFTER at least one user has signed up so a profile exists.
-- Replace <YOUR_PROFILE_ID> with the id from the `profiles` table.

-- Example:
--   select id from profiles limit 1;
--   then substitute the value below.

do $$
declare
  pid uuid;
  team_eng uuid;
  team_growth uuid;
  obj1 uuid;
  obj2 uuid;
  kr1 uuid;
  kr2 uuid;
begin
  select id into pid from profiles limit 1;
  if pid is null then
    raise notice 'No profiles yet — sign up first, then re-run.';
    return;
  end if;

  insert into teams (name) values ('Engineering') returning id into team_eng;
  insert into teams (name) values ('Growth')      returning id into team_growth;

  update profiles set team_id = team_eng where id = pid;

  insert into objectives (title, description, owner_id, team_id, quarter, year)
    values ('Ship reliable platform', 'Reduce production incidents and improve perf.', pid, team_eng, 2, 2026)
    returning id into obj1;

  insert into objectives (title, description, owner_id, team_id, quarter, year)
    values ('Grow weekly active users', 'Improve activation funnel.', pid, team_growth, 2, 2026)
    returning id into obj2;

  insert into key_results (objective_id, title, metric_type, start_value, target_value, current_value, unit, owner_id)
    values (obj1, 'p99 latency under 200ms', 'number', 480, 200, 380, 'ms', pid)
    returning id into kr1;
  insert into key_results (objective_id, title, metric_type, start_value, target_value, current_value, unit, owner_id)
    values (obj1, 'Reduce SEV1 incidents to 0', 'number', 4, 0, 2, 'incidents', pid);

  insert into key_results (objective_id, title, metric_type, start_value, target_value, current_value, unit, owner_id)
    values (obj2, 'Activation rate', 'percent', 18, 30, 22, '%', pid)
    returning id into kr2;
  insert into key_results (objective_id, title, metric_type, start_value, target_value, current_value, unit, owner_id)
    values (obj2, 'Launch onboarding revamp', 'boolean', 0, 1, 0, null, pid);

  insert into tasks (key_result_id, title, status, assignee_id) values
    (kr1, 'Profile slow endpoints', 'in_progress', pid),
    (kr1, 'Add caching to /search', 'todo', pid),
    (kr2, 'A/B test new onboarding copy', 'todo', pid);
end $$;
