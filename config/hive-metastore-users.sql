use metastore;

create user 'hive'@'localhost' identified by 'hivepwd';
revoke all privileges, grant option from 'hive'@'localhost';
grant all privileges on metastore.* to 'hive'@'localhost';
flush privileges;
