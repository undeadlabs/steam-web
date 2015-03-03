#
# The MIT License (MIT)
#
# Copyright (c) 2015 Undead Labs, LLC
#

defmodule SteamWeb.ISteamUserAuth do
  use SteamWeb.Endpoint, interface: "ISteamUserAuth"

  def authenticate_user_ticket(app_id, ticket) when is_binary(ticket) do
    query = build_query(appid: app_id, ticket: ticket)
    get!("AuthenticateUserTicket/v0001?#{query}")
      |> handle_response()
  end
end
