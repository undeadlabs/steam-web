use Mix.Config

config :logger,
  level: :debug

config :steam_web,
  sandbox: true,
  api_key: System.get_env("STEAM_API_KEY")
