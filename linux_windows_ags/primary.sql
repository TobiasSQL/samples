-- PRIMARY 

SELECT @@version;
SELECT @@servername;

-- Create cert
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'dfkjf921E"E"wi9019sa"';

CREATE CERTIFICATE dbm_certificate 
	WITH SUBJECT = 'dbm';

BACKUP CERTIFICATE dbm_certificate
	TO FILE = '/var/opt/mssql/data/dbm_certificate.cer'
	WITH PRIVATE KEY (
		FILE = '/var/opt/mssql/data/dbm_certificate.pvk',
		ENCRYPTION BY PASSWORD = 'as3jsdjhaj304SDF'
	);

CREATE LOGIN dbm_login WITH PASSWORD = '1Sample_Strong_Password!@#';
CREATE USER dbm_user FOR LOGIN dbm_login;

CREATE ENDPOINT [Hadr_endpoint]
	AS TCP (LISTENER_IP = (0.0.0.0), LISTENER_PORT = 5022)
	FOR DATA_MIRRORING (
		ROLE = ALL,
		AUTHENTICATION = CERTIFICATE dbm_certificate,
		ENCRYPTION = REQUIRED ALGORITHM AES
	);
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [dbm_login];

CREATE AVAILABILITY GROUP MyAG
	WITH (DB_FAILOVER = ON, CLUSTER_TYPE = NONE)
	FOR REPLICA ON
	N'ChoicePMPerfHos' WITH (
		ENDPOINT_URL = N'tcp://ChoicePMPerfHos:5022',
		AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
		FAILOVER_MODE = MANUAL,
		SEEDING_MODE = AUTOMATIC,
		SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
	);

CREATE AVAILABILITY GROUP MyAGDistr
	WITH (DISTRIBUTED)
	AVAILABILITY GROUP ON
	N'MyAG' WITH (
		LISTENER_URL = N'tcp://ChoicePMPerfHos:5022',
		AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
		FAILOVER_MODE = MANUAL,
		SEEDING_MODE = AUTOMATIC
	),
	N'MyAGSecondary' WITH (
		LISTENER_URL  = N'tcp://SQLVNEXTWIN:5022',
		AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
		FAILOVER_MODE = MANUAL,
		SEEDING_MODE = AUTOMATIC
	);

ALTER AVAILABILITY GROUP MyAG GRANT CREATE ANY DATABASE;

-- CREATE DATABASE pgbenchtest;
-- dotnet run -w pg_bench_tpc_b_mssql -tc 1 -p 0 -t 172800 -ld "..\..\..\logs" -cs "server=ChoicePMPerfHos;database=pgbenchtest;uid=sa;password=Mission-123;max pool size=1000;" -scs "server=ChoicePMPerfHos;database=master;uid=sa;password=Mission-123;max pool size=1000;"

ALTER DATABASE pgbenchtest SET RECOVERY FULL;
BACKUP DATABASE pgbenchtest TO DISK = N'NUL';
ALTER AVAILABILITY GROUP MyAG ADD DATABASE pgbenchtest;

CREATE DATABASE tobias
ALTER DATABASE tobias SET RECOVERY FULL;
BACKUP DATABASE tobias TO DISK = N'NUL';
ALTER AVAILABILITY GROUP MyAG ADD DATABASE tobias;

-- Start BBC workload
USE pgbenchtest;
SELECT * FROM sys.tables;
SELECT COUNT(*) FROM pgbench_history;

USE tobias;
SELECT * FROM sys.tables;
SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('slava');
CREATE TABLE slava (scott TINYINT);
