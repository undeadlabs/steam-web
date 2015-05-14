defmodule SteamWeb.ISteamUserTest do
  use ExUnit.Case

  setup do
    {:ok, %{app_id: 351040, steam_id: 76561197964105156}}
  end

  test "check_app_ownership/2", %{app_id: app_id, steam_id: steam_id} do
    assert {:ok, _} = SteamWeb.ISteamUser.check_app_ownership(app_id, steam_id)
  end
end
