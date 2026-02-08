drop function if exists public.lead_blockers;
create or replace function public.lead_blockers()
returns table (pid_s_p int, kill_cmd_s_p text, blocked_user_s_p name, blocking_pid_s_p int, blocked_statement_s_p text, blocked_sec_s_p numeric(10,4), 
lead_blockers bigint, date_collection_s_p timestamp with time zone)
--select  pid_s_p as  pid, kill_cmd_s_p as kill_cmd, blocked_user_s_p as blocked_user, blocking_pid_s_p as blocking_pid, blocked_statement_s_p as blocked_statement, blocked_sec_s_p as blocked_sec, lead_blockers , date_collection_s_p as date_collection from public.lead_blockers();
language 'plpgsql'
as $body$
begin
return query (
WITH  
RECURSIVE recursive_cte (blocked_pid, blocking_pid)
AS 
(
SELECT DISTINCT blocked_pid, blocking_pid
FROM dba_only_block1
UNION distinct
SELECT e.blocked_pid, d.blocking_pid
FROM dba_only_block1 e
INNER JOIN recursive_cte d
ON d.blocked_pid=e.blocking_pid
WHERE d.blocking_pid!=0
),
dba_all_waiting_locks (blocked_pid, blocked_user, blocked_statement,
blocking_pid, blocking_user, blocking_query,
blocked_sec
)
AS 
(
SELECT
    activity.pid,
    activity.usename,
    activity.query,
    blocking.pid AS blocking_pid,
	blocking.usename as blocking_user,	
    blocking.query AS blocking_query,
	extract(epoch from age(clock_timestamp(),activity.query_start)) as blocked_sec--,
FROM pg_stat_activity AS activity
JOIN pg_stat_activity AS blocking ON blocking.pid = ANY(pg_blocking_pids(activity.pid))),
dba_only_block (blocked_pid, blocked_user, blocked_statement,
blocking_pid, blocking_user, blocking_query,
blocked_sec
)
as 
(
SELECT pid,  usename, query, cast(null as int), null, null, extract(epoch from age(clock_timestamp(),psa.query_start)) 
FROM pg_stat_activity psa
where 
psa.pid in (select blocking_pid from dba_all_waiting_locks where blocking_pid=psa.pid)
and
psa.pid not in (select blocked_pid from dba_all_waiting_locks where blocked_pid=psa.pid)
),
dba_only_block1 (blocked_pid, blocked_user, blocked_statement,
blocking_pid, blocking_user, blocking_query,
blocked_sec
)
as
(
select blocked_pid, blocked_user, blocked_statement,
blocking_pid, blocking_user, blocking_query,
blocked_sec
from dba_only_block
union all
select blocked_pid, blocked_user, blocked_statement,
blocking_pid, blocking_user, blocking_query,
blocked_sec
from dba_all_waiting_locks  
where (blocking_pid<>0 or blocked_pid in (select blocking_pid from dba_all_waiting_locks))
)
 
SELECT  distinct der.blocked_pid, 'pg_terminate_backend('|| der.blocked_pid || ');' as kill_cmd,
der.blocked_user,
der.blocking_pid,
der.blocked_statement,
der.blocked_sec,
count(cte.blocking_pid) AS lead_blockers,
now() as date_collect
FROM (SELECT DISTINCT  blocked_pid,
blocked_user,
blocking_pid,
blocked_statement ,
blocked_sec
FROM  dba_only_block1) der
LEFT JOIN recursive_cte cte
ON der.blocked_pid=cte.blocking_pid AND cte.blocking_pid!=0
GROUP BY  
der.blocked_pid, der.blocking_pid, der.blocked_statement, der.blocked_user, der.blocked_sec
ORDER BY lead_blockers DESC, der.blocked_sec desc);
end;
$body$;
