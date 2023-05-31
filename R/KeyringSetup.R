library(keyring)

key_set_with_value(service = 'YourDatabase',
                   username = "dbms",
                   password = "redshift")

key_set_with_value(service = 'YourDatabase',
                   username = "connectionString",
                   password = "jdbc:redshift://server:port/database")

key_set_with_value(service = 'YourDatabase',
                   username = "username",
                   password = "yourUserName")

key_set_with_value(service = 'YourDatabase',
                   username = "password",
                   password = "yourPassword")
