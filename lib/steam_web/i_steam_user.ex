#
# The MIT License (MIT)
#
# Copyright (c) 2015 Undead Labs, LLC
#

defmodule SteamWeb.ISteamUser do
  use SteamWeb.Endpoint, interface: "ISteamUser"
  alias HTTPoison.Response

  def check_app_ownership(app_id, steam_id) do
    query = build_query(appid: app_id, steamid: steam_id)
    case get("CheckAppOwnership/v1?#{query}") do
      {:ok, %{"appownership" => appownership}} ->
        {:ok, appownership}
      error -> error
    end
  end

  def get_app_price_info(app_ids, steam_id) when is_list(app_ids) do
    Enum.join(app_ids, ",")
    |> get_app_price_info(steam_id)
  end
  def get_app_price_info(app_id, steam_id) do
    query = build_query(appids: app_id, steamid: steam_id)
    case get("GetAppPriceInfo/v1?#{query}") do
      {:ok, %{"price_info" => info}} ->
        {:ok, info}
      error -> error
    end
  end

  def get_friends_list(steam_id) do
    query = build_query(steamid: steam_id)
    case get("GetFriendList/v1?#{query}") do
      {:ok, %{"friendslist" => friends}} ->
        {:ok, friends}
      error -> error
    end
  end

  def get_publisher_app_ownership(steam_id) do
    query = build_query(steamid: steam_id)
    get("GetPublisherAppOwnership/v2?#{query}")
  end
end
