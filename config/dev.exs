username: System.get_env("PGUSER", "postgres"),
password: System.get_env("PGPASSWORD", "postgres"),
database: System.get_env("PGDATABASE", "myapp_dev"),
hostname: System.get_env("PGHOST", "localhost"),
port: String.to_integer(System.get_env("PGPORT", "5432")),
#http: [ip: {127, 0, 0, 1}, port: 4000],
#to
http: [ip: {0, 0, 0, 0}, port: 4000],
