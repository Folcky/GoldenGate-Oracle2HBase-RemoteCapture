# GoldenGate-Oracle2HBase-RemoteCapture
Oracle DB Source -> ORacle GoldenGate for Oracle-> [Oracle GoldenGate for Bigdata + Apache HBase 1.2.0]

![Alt text](Diagram_HBase.png?raw=true "Diagram") 

# 0. Prerequisites

## Oracle Source DB credentials
> sqlplus system/oracle@datasource:1521/xe  
> sqlplus sys/oracle@datasource:1521/xe as sysdba  

## Used Docker images
* oracle/goldengate-standard:12.3.0.1.4 (Read here https://github.com/oracle/docker-images/tree/master/OracleGoldenGate)  
* sath89/oracle-12c

## Docker consoles for Terminal
> docker exec -it GG-datasource-bd bash  
> docker exec -it GG-goldengateora-bd bash  
> docker exec -it GG-hbase-bd bash  

# 1. Oracle DB Source Init

## Database params
```sql
alter system set enable_goldengate_replication=TRUE;  
alter database add supplemental log data;  
alter database force logging;  
alter system switch logfile;  
```

## Credentials

### OGG user
```sql
CREATE USER gg_extract IDENTIFIED BY gg_extract;  
GRANT CREATE SESSION, CONNECT, RESOURCE, ALTER ANY TABLE, ALTER SYSTEM, DBA, SELECT ANY TRANSACTION TO gg_extract;
```

### Transaction user
```sql
CREATE USER trans_user IDENTIFIED BY trans_user;  
GRANT CREATE SESSION, CONNECT, RESOURCE TO trans_user;  
ALTER USER trans_user QUOTA UNLIMITED ON USERS;
```

## Data source objects
```sql
CREATE TABLE trans_user.test (  
         empno      NUMBER(5) PRIMARY KEY,  
         ename      VARCHAR2(15) NOT NULL);  


 COMMENT ON TABLE test IS 'Testing GoldenGate';
```

# 2. TO-HBase DB Target Init

nothing required

# 3. Oracle GoldenGate for Oracle Init

## Credentials of sources

### Connect as oracle to GoldenGate for Oracle instance:
> su oracle 

### Run GGSCI:
> **GGSCI (a3abfded7bc7) 2>** add credentialstore  
Credential store created.  
>  **GGSCI (a3abfded7bc7) 2>** alter credentialstore add user gg_extract@datasource:1521/xe password gg_extract alias oggadmin  
Credential store altered.  
> **GGSCI (a3abfded7bc7) 2>** info credentialstore  
Reading from credential store:  
Default domain: OracleGoldenGate  
  Alias: oggadmin  
  Userid: gg_extract@datasource:1521/xe

## Change metadata in source

### Connect as oracle to GoldenGate for Oracle instance:
> su oracle  

### Run GGSCI and change source schema configuration:
> **GGSCI (a3abfded7bc7) 2>** dblogin useridalias oggadmin  
Successfully logged into database.  
> **GGSCI (a3abfded7bc7) 2>** add schematrandata trans_user ALLCOLS  
2018-10-09 10:48:56  INFO    OGG-01788  SCHEMATRANDATA has been added on schema "trans_user".  

# 4. Oracle GoldenGate for Oracle - Configure extract 

## Extract configuration

### Connect as oracle to GoldenGate instance:
> su oracle  

### Run GGSCI and edit extract params file(e.g. VIM will be runned):
> **GGSCI (a3abfded7bc7) 2>** edit params getExt  
```
EXTRACT getExt
USERIDALIAS oggadmin
LOGALLSUPCOLS
TRANLOGOPTIONS EXCLUDEUSER gg_extract
TRANLOGOPTIONS DBLOGREADER
EXTTRAIL ./dirdat/in
TABLE trans_user.test;
```

### Run GGSCI and register&start extract params file:
> **GGSCI (a3abfded7bc7) 2>** ADD EXTRACT getExt, TRANLOG, BEGIN NOW  
> **GGSCI (a3abfded7bc7) 2>** ADD EXTTRAIL ./dirdat/in, EXTRACT getext  
> **GGSCI (a3abfded7bc7) 2>** START EXTRACT getExt  
> **GGSCI (a3abfded7bc7) 2>** info extract getext, detail 

## DataPump configuration

### Connect as oracle to GoldenGate instance:
> su oracle  

### Run GGSCI and edit extract params file(e.g. VIM will be runned):
> **GGSCI (a3abfded7bc7) 2>** edit params pumpExt  
```
EXTRACT pumpext
RMTHOST hbase, MGRPORT 7801, TIMEOUT 30
RMTTRAIL /ogg/oggbd/dirdat/in
PASSTHRU
TABLE trans_user.*;
```

### Run GGSCI and register&start extract params file:
> **GGSCI (a3abfded7bc7) 2>** add extract pumpext, EXTTRAILSOURCE ./dirdat/in, begin now
> **GGSCI (a3abfded7bc7) 2>** add rmttrail /ogg/oggbd/dirdat/in, extract pumpext, megabytes 50
> **GGSCI (a3abfded7bc7) 2>** start pumpext
> **GGSCI (a3abfded7bc7) 2>** info extract pumpext, detail


# 5. Oracle GoldenGate for Oracle - Configure replicat 

## Replicat configuration

### Connect as oracle to GoldenGate instance:
> su oracle  

### Run GGSCI and edit extract params file(e.g. VIM will be runned):
> **GGSCI (a3abfded7bc7) 2>** edit params putExt  
```
REPLICAT putext
TARGETDB LIBFILE libggjava.so SET property=dirprm/hbase.props
REPORTCOUNT EVERY 1 MINUTES, RATE
GROUPTRANSOPS 10000
MAP trans_user.test, TARGET trans_user.test;
```

### Run GGSCI and register&start extract params file:
> **GGSCI (a3abfded7bc7) 2>** ADD ??????????????
> **GGSCI (a3abfded7bc7) 2>** ADD EXTTRAIL ??????????????
> **GGSCI (a3abfded7bc7) 2>** START REPLICAT putExt  
> **GGSCI (a3abfded7bc7) 2>** info REPLICAT putext, detail 
