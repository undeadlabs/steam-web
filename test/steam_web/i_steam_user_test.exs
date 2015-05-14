defmodule SteamWeb.ISteamUserTest do
  use ExUnit.Case

  setup do
    {:ok, %{app_id: 351040, steam_id: 76561197964105156}}
  end

  test "check_app_ownership/2", ctx do
    assert {:ok, %{"result" => "OK"}} = SteamWeb.ISteamUser.check_app_ownership(ctx[:steam_id], ctx[:app_id])
  end

  test "get_app_price_info/2", ctx do
    assert {:ok, %{}} = SteamWeb.ISteamUser.get_app_price_info(ctx[:steam_id], ctx[:app_id])
  end

  test "get_friends_list/1", ctx do
    assert {:ok, %{"friends" => _}} = SteamWeb.ISteamUser.get_friends_list(ctx[:steam_id])
  end

  test "get_publisher_app_ownership/1", ctx do
    assert {:ok, %{"appownership" => _}} = SteamWeb.ISteamUser.get_publisher_app_ownership(ctx[:steam_id])
  end
end
