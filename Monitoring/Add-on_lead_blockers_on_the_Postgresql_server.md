Written by Pavel A. Polikov https://github.com/PahanDba/postgresql_dba

Getting a list of the lead blockers with an indication number of the blocked processes in the Postgresql server.


# **Table of contents**
[**Function goal: 'Find the lead blockers in the Postgresql server'**](#_toc221128672)

[**System requirements**](#_toc221128673)

[**List of servers for demonstrating the 'lead blockers' operation function on the Postgresql server.**](#_toc221128674)

[**Server Standalone**](#_toc221128675)

[**Server standalone**](#_toc221128676)

[**Creation of the 'lead blockers' function on the Postgresql server**.](#_toc221128677)

[**Description of the logic of the 'lead blockers' function**](#_toc221128678)

[**Example of executing the function**](#_toc221128679)

[**Summary**](#_toc221128680)



# <a name="_toc221128672"></a>**Function goal: 'Find the lead blockers in the Postgresql server'**
- It helps Postgresql DBAs quickly identify the lead blockers of processes and the number of processes blocked by those leaders in Postgresql.

# <a name="_toc221128673"></a>**System requirements**

- The function runs on Postgresql 14.0-17.0.

# <a name="_hlk160717248"></a><a name="_toc221128674"></a>**List of servers for demonstrating the 'lead blockers' operation function on the Postgresql server.**

Below is a list of servers that shows the descriptions for each server with installed software used to check the functionality of this function.


## <a name="_toc221128675"></a>**Server Standalone** 
     ServerName: Postgresql5020
     IP address: 10.10.50.20
     OS: Debian 11/12
     RDBMS: Postgresql 14.0
     Server configuration: 2 CPU, 4GB RAM, 30GB

## <a name="_toc221128676"></a>**Server standalone** 
     ServerName: Postgresql5025
     IP address: 10.10.50.25
     OS: Debian 11/12
     RDBMS: Postgresql 17.0
     Server configuration: 2 CPU, 4GB RAM, 30GB

# <a name="_toc221128677"></a>**Creation of the 'lead blockers' function on the Postgresql server**.

1\. I will demonstrate how the 'lead blockers' function works on Postgresql5020 (Postgresql 14.0). The function works in a similar way on the Postgresql5025 server (Postgresql 17.0).

2\. Create the necessary objects. 

You need to download and execute the script from <https://github.com/PahanDba/postgresql_dba/blob/main/Monitoring/lead_blockers/lead_blockers.sql> 
This script will create the function 'lead_blockers' in the *postgres* database.

# <a name="_toc221128678"></a>**Description of the logic of the 'lead blockers' function**

This section describes the logic of the lead_blockers function, which allows us to identify the blocking leaders of processes and the number of processes blocked by those leaders in PostgreSQL. 

1. The function works on the standalone servers, master and replica read-only servers.
1. The function uses the ordinary CTEs and recursive CTE.


## <a name="_toc221128679"></a>**Example of executing the function**

This function is executed the following way.

```sql
select  blocked_pid_s_p as  blocked_pid, kill_cmd_s_p as kill_cmd, blocked_user_s_p as blocked_user, blocking_pid_s_p as blocking_pid, blocked_statement_s_p as blocked_statement, blocked_sec_s_p as blocked_sec, lead_blockers , date_collection_s_p as date_collection from public.lead_blockers();
```

For the demonstration of the way the 'lead blockers' works, I prepared the tables with the data.

```sql
drop table if exists public.test_block123;
CREATE TABLE public.test_block123
(
id serial NOT NULL,
words1 text,
words2 text,
PRIMARY KEY (id)
);

insert into public.test_block123 (words1, words2)
values 
('test11','test21'), 
('test12','test22'),
('test13','test23'),
('test14','test24'),
('test15','test25'),
('test16','test26'),
('test17','test27'),
('test18','test28'),
('test19','test29'),
('test110','test210');
```

I will create the connections and execute different scripts. Script №1 is used to demonstrate data blocking.\
The script is called *script_block1*.

```sql
--script_block1
BEGIN;
SELECT now(), pg_backend_pid();
SELECT * FROM public.test_block123 WHERE id=1 FOR UPDATE;
--rollback;
```

**Table 1**

|**now()**|**pg_backend_pid**|
| :- | :- |
|2026-01-08 12:14:26.146103+03|1562|

The result shows the query execution time and the process ID of this query.

Now I will create a few connections to work with the row being updated in a transaction using the *select11* script.

```sql
--select11 script
SELECT now(), pg_backend_pid();
SELECT * FROM public.test_block123 WHERE id=1 FOR UPDATE;
```

The script will return the result for the first query immediately, while the second query will wait.

**Table 2**

|**now()**|**pg_backend_pid**|
| :- | :- |
|2026-01-08 12:14:27.146103+03|1596|

The result of the first query shows the start time of the query and its process ID.

The *select12* script

```sql
--select12 script
SELECT now(), pg_backend_pid();
SELECT * FROM public.test_block123 WHERE id=1 FOR UPDATE;\
```

The script will return the result for the first query only, while the second query will wait.

**Table 3**

|**now()**|**pg_backend_pid**|
| :- | :- |
|2026-01-08 12:14:28.146103+03|1558|

The result of the first query shows the start time of the query and its process ID.

The *select13* script

```sql
--select13 script
SELECT now(), pg_backend_pid();
SELECT * FROM public.test_block123 WHERE id=1 FOR UPDATE;
```

The script will return the result for the first query only, while the second query will wait.

**Table 4**

|**now()**|**pg_backend_pid**|
| :- | :- |
|2026-01-08 12:14:29.146103+03|1560|

The result of the first query shows the start time of the query and its process ID.

The *select14* script

```sql
--select14 script
BEGIN;
SELECT now(), pg_backend_pid();
SELECT * FROM public.test_block123 WHERE id=3 FOR UPDATE;
SELECT * FROM public.test_block123 WHERE id=1 FOR UPDATE;	
--rollback;
```

The script will return the result for the first query only, while the second query will wait.

**Table 5**

|**now()**|**pg_backend_pid**|
| :- | :- |
|2026-01-08 12:14:30.146103+03|4927|

The result of the first query shows the start time of the query and its process ID.

The *select15* script

```sql
--select15 script
SELECT now(), pg_backend_pid();
SELECT * FROM public.test_block123 WHERE id=3 FOR UPDATE;
```

The script will return the result for the first query only, while the second query will wait.

**Table 6**

|**now()**|**pg_backend_pid**|
| :- | :- |
|2026-01-08 12:14:31.146103+03|4947|

The result of the first query shows the start time of the query and its process ID.


I will create the connections and execute different scripts. Script №2 is used to demonstrate data blocking.\
The script is called *script_block2*

```sql
BEGIN;
SELECT now(), pg_backend_pid();
SELECT * FROM public.test_block123 WHERE id=2 FOR UPDATE;
```

The result shows the query execution time and the process ID of the query.

**Table 7**

|**now()**|**pg_backend_pid**|
| :- | :- |
|2026-01-08 12:14:32.146103+03|1564|

Now I will create a few connections to work with the row being updated in a transaction using the *select21* script.

```sql
--select21 script
SELECT now(), pg_backend_pid();
SELECT * FROM public.test_block123 WHERE id=2 FOR UPDATE;
```

The script will return the result of the first query only, while the second query will wait.

**Table 8**

|**now()**|**pg_backend_pid**|
| :- | :- |
|2026-01-08 12:14:33.146103+03|1557|

The result of the first query shows the start time of the query and its process ID.

The *select22* script

```sql
--select22 script
SELECT now(), pg_backend_pid();
SELECT * FROM public.test_block123 WHERE id=2 FOR UPDATE;
```

The script will return the result of the first query only, while the second query will wait.

**Table 9**

|**now()**|**pg_backend_pid**|
| :- | :- |
|2026-01-08 12:14:34.146103+03|1563|

The result of the first query shows the start time of the query and its process ID.


For illustrative purposes I'll demonstrate in the table how the blocking queries and selection queries look.

**Table 10**

|**Tbl №**|**script_name**|**where id=**|**now()**|**pg_backend_pid**|
| :- | :- | :- | :- | :- |
|1|script_block1|1|2026-01-08 12:14:26.146103+03|1562|
|2|select11|1|2026-01-08 12:14:27.146103+03|1596|
|3|select12|1|2026-01-08 12:14:28.146103+03|1558|
|4|select13|1|2026-01-08 12:14:29.146103+03|1560|
|5|select14|3 and 1|2026-01-08 12:14:30.146103+03|4927|
|6|select15|3|2026-01-08 12:14:31.146103+03|4947|
|7|script_block2|2|2026-01-08 12:14:32.146103+03|1564|
|8|select21|2|2026-01-08 12:14:33.146103+03|1557|
|9|select22|2|2026-01-08 12:14:34.146103+03|1563|


Now, I want to find which process is blocking which, so I will execute the lead_blockers function.

```sql
select  backend_pid_s_p as backend_pid, kill_cmd_s_p as kill_cmd, blocked_user_s_p as blocked_user, 
blocking_pid_s_p as blocking_pid, blocked_statement_s_p as blocked_statement, blocked_sec_s_p as blocked_sec, 
blocking_sec_s_p as blocking_sec, leader_blocks , date_collection_s_p as date_collection
from public.lead_blockers();
```

The result of executing the function.

2

**Table 11**

|**pid**|**kill_cmd**|**blocked_user**|**blocking_pid**|**blocked_statement**|**blocked_sec**|**lead_blockers**|**date_collection**|
| :- | :- | :- | :- | :- | :- | :- | :- |
|1562|pg_terminate_backend(1562);|postgres| |SELECT oid, pg_catalog.format_type(oid, NULL) AS typname FROM pg_catalog.pg_type WHERE oid = ANY($1) ORDER BY oid;|36\.357258|5|2026-01-08 12:15:02.146103+03|
|1596|pg_terminate_backend(1596);|postgres|1562|--select11 script<br>SELECT now(), pg_backend_pid();<br>SELECT * FROM public.test_block123 WHERE id=1 FOR UPDATE;|31\.915709|4|2026-01-08 12:15:02.146103+03|
|1558|pg_terminate_backend(1558);|postgres|1596|--select12 script<br>SELECT now(), pg_backend_pid();<br>SELECT * FROM public.test_block123 WHERE id=1 FOR UPDATE;|28\.947858|3|2026-01-08 12:15:02.146103+03|
|1560|pg_terminate_backend(1560);|postgres|1596|--select13 script<br>SELECT now(), pg_backend_pid();<br>SELECT * FROM public.test_block123 WHERE id=1 FOR UPDATE;|26\.236976|2|2026-01-08 12:15:02.146103+03|
|1560|pg_terminate_backend(1560);|postgres|1558|--select13 script<br>SELECT now(), pg_backend_pid();<br>SELECT * FROM public.test_block123 WHERE id=1 FOR UPDATE;|26\.236971|2|2026-01-08 12:15:02.146103+03|
|1564|pg_terminate_backend(1564);|postgres| |SELECT oid, pg_catalog.format_type(oid, NULL) AS typname FROM pg_catalog.pg_type WHERE oid = ANY($1) ORDER BY oid;|11\.909485|2|2026-01-08 12:15:02.146103+03|
|4927|pg_terminate_backend(4927);|postgres|1596|--select14 script<br>SELECT now(), pg_backend_pid();<br>BEGIN;<br>SELECT now(),* FROM public.test_block123 WHERE id=3 FOR UPDATE;<br>SELECT now(),* FROM public.test_block123 WHERE id=1 FOR UPDATE; <br>rollback;|21\.571132|1|2026-01-08 12:15:02.146103+03|
|4927|pg_terminate_backend(4927);|postgres|1560|--select14 script<br>SELECT now(), pg_backend_pid();<br>BEGIN;<br>SELECT now(),* FROM public.test_block123 WHERE id=3 FOR UPDATE;<br>SELECT now(),* FROM public.test_block123 WHERE id=1 FOR UPDATE; <br>rollback;|21\.571125|1|2026-01-08 12:15:02.146103+03|
|4927|pg_terminate_backend(4927);|postgres|1558|--select14 script<br>SELECT now(), pg_backend_pid();<br>BEGIN;<br>SELECT now(),* FROM public.test_block123 WHERE id=3 FOR UPDATE;<br>SELECT now(),* FROM public.test_block123 WHERE id=1 FOR UPDATE;<br>rollback;|21\.571123|1|2026-01-08 12:15:02.146103+03|
|1557|pg_terminate_backend(1557);|postgres|1564|--select21 script<br>SELECT now(), pg_backend_pid();<br>SELECT * FROM public.test_block123 WHERE id=2 FOR UPDATE;|7\.33625|1|2026-01-08 12:15:02.146103+03|
|4947|pg_terminate_backend(4947);|postgres|4927|--select15 script<br>SELECT now(), pg_backend_pid();<br>SELECT * FROM public.test_block123 WHERE id=3 FOR UPDATE;|18\.282674|0|2026-01-08 12:15:02.146103+03|
|1563|pg_terminate_backend(1563);|postgres|1557|--select22 script<br>SELECT now(), pg_backend_pid();<br>SELECT * FROM public.test_block123 WHERE id=2 FOR UPDATE;|3\.689057|0|2026-01-08 12:15:02.146103+03|

Written by Pavel A. Polikov https://github.com/PahanDba/postgresql_dba


**pid** – The process ID of the running process.

**kill_cmd** – The command to kill the process.

**blocked_user** – The user who started the process.

**blocking_pid** – The process id that is blocking the process (from the `pid` column).

**blocked_statement** – The query being executed by the process (from the `pid` column).

**blocked_sec** – The number of seconds the process (from the `pid` column) has been waiting to complete its query.

**lead_blockers** – The number of processes blocked by the process (from the `waiting_thread` column).

**date_collection** – The date and time when the `lead_blockers` function was executed.


<a name="_hlk220418411"></a>In the Table 11, I can see two processes that are not blocked 1562 and 1564. 

`	`I will examine one of those processes with ID 1562 from the '**pid**' column. In the '**lead_blockers**' column, it shows that process 1562 blocked five processes. I start looking for these five processes. 

`	`Process 1562 from the '**pid**' column is visible in the '**blocking_pid**' column for process 1596. This was the first process which was blocked by process 1562. Process 1562 blocked one process, 1596.

`	`Process 1596 from the '**pid**' column is visible in the '**blocking_pid**' column for process 1558. This was the second process, which was blocked by process 1562, and the first process, which was blocked by process 1596. Process 1562 blocked two processes, 1596 and 1558 (the cascade block to process 1558). Process 1596 blocked one process, 1558.

`	`Process 1596 from the '**pid**' column is visible in the '**blocking_pid**' column for process 1560. This was the second process, which was blocked by process 1596, and the third process, which was blocked by process 1562. Process 1562 blocked three processes, 1596, 1558 and 1560 (the cascade block to processes 1558 and 1560). Process 1596 blocked two process, 1558 and 1560 (the cascade block to process 1560).

`	`Process 1596 from the '**pid**' column is visible in the '**blocking_pid**' column for process 4927. This was the third process, which was blocked by process 1596, and the fourth process, which was blocked by process 1562. Process 1562 blocked four processes, 1596, 1558,1560 and 4927 (the cascade block to processes 1558,1560 and 4927). Process 1596 blocked three processes, 1558, 1560 and 4927 (the cascade block to the processes 1560 and 4927).

`	`Process 1558 from the '**pid**' column is visible in the '**blocking_pid**' column for process 1560. This was the first process which was blocked by process 1558. Process 1558 blocked one process, 1560.

`	`Process 1558 from the '**pid**' column is visible in the '**blocking_pid**' column for process 4927. This was the second process which was blocked by process 1558. Process 1558 blocked two processes, 1560 and 4927 (the cascade block to process 4927).

`	`Process 1560 from the '**pid**' column is visible in the '**blocking_pid**' column for process 4927. This was the first process which was blocked by process 1560. Process 1560 blocked one process, 4927.

`	`Process 4927 from the '**pid**' column is visible in the '**blocking_pid**' column for process 4947. This was the first process which was blocked by process 4927, the second process which was blocked by process 1560, the third process which was blocked by process 1558, the fourth process which was blocked by process 1596, the fifth process which was blocked by process 1562.

`	`Process 1562 blocked five processes 1596, 1558, 1560, 4927, 4947 (the cascade block to processes 1558, 1560, 4927, 4947).

`	`Process 1596 blocked four processes 1558, 1560, 4927, 4947 (the cascade block to processes 1560, 4927, 4947).

`	`Process 1558 blocked three processes 1560, 4927, 4947 (the cascade block to processes 4927, 4947).

`	`Process 1560 blocked two processes 4927, 4947 (the cascade block to process 4947).

`	`Process 4927 blocked one process 4947.

`	`Similarly, you can find the processes which are blocked by process 1564 from the '**pid**' column in Table 11.

`	`This investigation can demonstrate which process blocked another process.


# <a name="_toc221128680"></a>**Summary**
This function helps identify the processes that block certain queries, even if it is not immediately apparent.

You can download this script (lead_blockers.sql) and other related scripts from:

<https://github.com/PahanDba/postgresql_dba/>.

