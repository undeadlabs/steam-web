#
# The MIT License (MIT)
#
# Copyright (c) 2015 Undead Labs, LLC
#

defmodule SteamWeb.ISteamMicroTXN do
  use SteamWeb.Endpoint, interface: "ISteamMicroTxn", sandbox: "ISteamMicroTxnSandbox"

  @type item_list :: {integer, integer, integer, binary} | {integer, integer, integer, binary, binary}

  @doc """
  See: https://partner.steamgames.com/documentation/MicroTxn#InitTxn
  """
  @spec init_txn(integer, integer, integer, binary, binary, item_list, list) :: Endpoint.response
  def init_txn(app_id, steam_id, order_id, language, currency, items, opts \\ []) do
    defaults = [appid: app_id, steamid: steam_id, orderid: order_id, itemcount: length(items), language: language,
      currency: currency]
    base_query = Keyword.take(opts, [:usersession, :ipaddress])
      |> Keyword.merge(defaults)
      |> build_query()
    post!("InitTxn/V0002", base_query <> "&" <> format_items(items))
      |> handle_response()
  end

  @doc """
  See: https://partner.steamgames.com/documentation/MicroTxn#FinalizeTxn
  """
  @spec finalize_txn(integer, integer) :: Endpoint.response
  def finalize_txn(app_id, order_id) do
    post!("FinalizeTxn/V0001", build_query(orderid: order_id, appid: app_id))
      |> handle_response()
  end

  @doc """
  See: https://partner.steamgames.com/documentation/MicroTxn#GetUserInfo
  """
  @spec get_user_info(integer, list) :: Endpoint.response
  def get_user_info(steam_id, opts \\ []) do
    query = Keyword.take(opts, [:ipaddress])
      |> Keyword.merge([steamid: steam_id])
      |> build_query()
    get!("GetUserInfo/V0001?#{query}")
      |> handle_response()
  end

  @doc """
  See: https://partner.steamgames.com/documentation/MicroTxn#QueryTxn
  """
  @spec query_txn(integer, integer) :: Endpoint.response
  def query_txn(app_id, order_id) do
    get!("QueryTxn/V0001?#{build_query(appid: app_id, orderid: order_id)}")
      |> handle_response()
  end

  @doc """
  See: https://partner.steamgames.com/documentation/MicroTxn#RefundTxn
  """
  @spec refund_txn(integer, integer) :: Endpoint.response
  def refund_txn(app_id, order_id) do
    post!("RefundTxn/V0001?", build_query(appid: app_id, orderid: order_id))
      |> handle_response()
  end

  #
  # Private
  #

  defp encode_line_item(index, pairs) do
    Enum.map pairs, fn({k, v}) ->
      encode_www_form(to_string(k)) <> "[#{index}]" <> "=" <> encode_www_form(to_string(v))
    end
  end

  defp format_items(items) do
    Enum.with_index(items) |> Enum.map(fn
      {{item_id, quantity, amount, desc, category}, index} ->
        encode_line_item(index, itemid: item_id, qty: quantity, amount: amount, description: desc, category: category)
      {{item_id, quantity, amount, desc}, index} ->
        encode_line_item(index, itemid: item_id, qty: quantity, amount: amount, description: desc)
    end) |> List.flatten |> Enum.join("&")
  end
end
