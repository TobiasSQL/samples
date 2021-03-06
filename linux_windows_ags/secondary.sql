-- SECONDARY 
SELECT @@version;
SELECT @@servername;

-- Copy certificate: 
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'aaKD9023!wKS~!qqwsSA';

CREATE LOGIN dbm_login WITH PASSWORD = '1Sample_Strong_Password!@#';
CREATE USER dbm_user FOR LOGIN dbm_login;

CREATE CERTIFICATE dbm_certificate   
	AUTHORIZATION dbm_user
	FROM FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dbm_certificate.cer'
	WITH PRIVATE KEY (
		FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dbm_certificate.pvk',
		DECRYPTION BY PASSWORD = 'as3jsdjhaj304SDF'
);

CREATE ENDPOINT [Hadr_endpoint]
	AS TCP (LISTENER_IP = (0.0.0.0), LISTENER_PORT = 5022)
	FOR DATA_MIRRORING (
		ROLE = ALL,
		AUTHENTICATION = CERTIFICATE dbm_certificate,
		ENCRYPTION = REQUIRED ALGORITHM AES
	);
	
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [dbm_login];

CREATE AVAILABILITY GROUP MyAGSecondary
	WITH (DB_FAILOVER = ON, CLUSTER_TYPE = NONE)
	FOR REPLICA ON
	N'SQLVNEXTWIN' WITH (
		ENDPOINT_URL = N'tcp://SQLVNEXTWIN:5022',
		AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
		FAILOVER_MODE = MANUAL,
		SEEDING_MODE = AUTOMATIC,
		SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
	);

ALTER AVAILABILITY GROUP MyAGDistr
	JOIN AVAILABILITY GROUP ON
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

ALTER AVAILABILITY GROUP MyAGSecondary GRANT CREATE ANY DATABASE;

USE pgbenchtest;
SELECT * FROM sys.tables;
SELECT COUNT(*) FROM pgbench_history;

USE tobias;
SELECT * FROM sys.tables;
SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('slava');
