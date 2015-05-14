use Mix.Config

config :logger,
  level: :warn

config :steam_web,
  api_key: System.get_env("STEAM_API_KEY")
