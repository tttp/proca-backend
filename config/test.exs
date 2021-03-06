use Mix.Config

# Configure your database
config :proca, Proca.Repo,
  username: "proca",
  password: "proca",
  database: "proca_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :proca, ProcaWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :proca, Proca, org_name: "hq"
