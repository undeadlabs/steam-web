defmodule SteamWeb.Mixfile do
  use Mix.Project

  def project do
    [
      app: :steam_web,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps
    ]
  end

  def application do
    [
      applications: [
        :logger,
        :ssl,
        :httpoison,
        :exjsx,
      ],
      env: [
        api_url: "https://api.steampowered.com",
        api_key: nil,
        sandbox: false,
      ]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.6.0"},
      {:exjsx, "~> 3.1"},
    ]
  end
end
