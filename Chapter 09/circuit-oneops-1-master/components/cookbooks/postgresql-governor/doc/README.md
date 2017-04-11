PostgreSQL HA Cookbook
=============
A cookbook to install and configure PostgreSQL in HA environment. The deployment architecture follows the **best practices** introduced as below:

- [Governor: A Template for PostgreSQL HA with etcd](https://github.com/compose/governor)
- [High Availability for PostgreSQL, Batteries Not Included](https://www.compose.io/articles/high-availability-for-postgresql-batteries-not-included/)

Some monitoring scripts will also be installed and configured as the part of the deployments. The monitoring graphs could be visualized in OneOps UI.

- `check_backup`: in the past `X` minutes, the number of database files that has been backed up to the remote storage (e.g. AWS S3). By default, this is `disabled`. If needed, enable it from OneOps UI.
- `check_replicator`: the number of replication processes (e.g. wal sender, wal receiver). By default, this is `disabled`. If needed, enable it from OneOps UI.
- `perf_stats`: many database performance stats: `active_queries`, `disk_usage`, `heap_hit`, `heap_hit_ratio`, `heap_read`, `index_hit`, `index_hit_ratio`, `index_read`, `locks`, `wait_locks`

Only PostgreSQL version 9.4 or above are available.

Requirements
------------
* OS     : **>= CentOS/RHEL 7.x**
* Kernel : **>= 3.10.x**
* Ruby   : **>= 2.x**

Post Deployment
---------------
- Allow non-local access: login each VM and add some "hosts" to `pg_hba.conf`. For example, 
```
host	all	all	0.0.0.0/0	trust
```
Then restart the PostgrSQL process via `service governor restart`

- Create `perfstat` PostgreSQL user and grant it access:
```
CREATE USER perfstat WITH PASSWORD 'perfstat';
GRANT ALL PRIVILEGES ON DATABASE template1 to perfstat;
```

License and Authors
-------------------
- Author : OneOps
- Apache License, Version 2.0

To-Do List
----------
- Support more OS types
- Support secondary clouds as an additional layer of failover
- Support synchronous replication
