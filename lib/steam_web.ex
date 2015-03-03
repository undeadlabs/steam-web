#
# The MIT License (MIT)
#
# Copyright (c) 2015 Undead Labs, LLC
#

defmodule SteamWeb do
  @moduledoc """
  An HTTP API Client for communicating with the SteamWorks API
  """

  @default_api "https://api.steampowered.com"

  @spec api_key :: binary
  def api_key do
    Application.get_env(:steam_web, :api_key, "") |> to_string
  end

  @spec api_url :: binary
  def api_url do
    Application.get_env(:steam_web, :api_url, @default_api) |> to_string
  end

  @spec sandbox? :: boolean
  def sandbox? do
    Application.get_env(:steam_web, :sandbox, false)
  end
end
