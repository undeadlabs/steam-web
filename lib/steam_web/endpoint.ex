#
# The MIT License (MIT)
#
# Copyright (c) 2015 Undead Labs, LLC
#

defmodule SteamWeb.Endpoint do
  @type result_success :: {:ok, map}
  @type result_error :: {:error, {:api_error, {integer, binary}}}
  @type http_error :: {:error, {:http_error, integer, term}}
  @type response :: result_success | result_error | http_error

  defmacro __using__(opts) do
    quote location: :keep do
      alias HTTPoison.Response
      use HTTPoison.Base
      import URI, only: [encode_query: 1, encode_www_form: 1]

      @default_interface Module.split(__MODULE__) |> List.last
      @interface Keyword.get(unquote(opts), :interface, @default_interface)
      @sandbox Keyword.get(unquote(opts), :sandbox, @interface)

      defp build_query(pairs) do
        Enum.filter(pairs, fn
          {_key, nil} -> false
          _ -> true
        end) |> encode_query()
      end

      defp encode_api_url(url) do
        case String.downcase(url) do
          <<"http://"::utf8, _::binary>> ->
            url
          <<"https://"::utf8, _::binary>> ->
            url
          _ ->
            interface = if SteamWeb.sandbox?, do: @sandbox, else: @interface
            Path.join([SteamWeb.api_url, interface, url])
        end
      end

      defp encode_api_key(url) do
        URI.parse(url) |> encode_api_key(url)
      end

      defp encode_api_key(%URI{query: nil}, url) do
        url <> "?" <> URI.encode_query(key: SteamWeb.api_key)
      end
      defp encode_api_key(%URI{query: query}, url) do
        encoded = URI.decode_query(query)
          |> Map.put_new("key", SteamWeb.api_key)
          |> URI.encode_query
        [uri, _] = String.split(url, "?", parts: 2)
        uri <> "?" <> encoded
      end

      defp process_url(url) do
        encode_api_url(url)
          |> encode_api_key()
      end

      defp process_request_headers(headers) do
        :orddict.store("Content-Type", "application/x-www-form-urlencoded", headers)
      end

      defp process_response_body(nil), do: nil
      defp process_response_body(""), do: nil
      defp process_response_body(body) do
        case IO.iodata_to_binary(body) |> JSX.decode do
          {:ok, parsed_body} -> parsed_body
          {:error, _} -> body
        end
      end

      #
      # Handlers
      #

      defp handle_response(%Response{status_code: 200, body: %{"response" => %{"result" => "OK"} = response}}) do
        {:ok, Map.fetch!(response, "params")}
      end
      defp handle_response(%Response{status_code: 200, body: %{"response" => %{"params" => params}}}) do
        {:ok, params}
      end
      defp handle_response(%Response{status_code: 200, body: %{"response" => %{"error" => error}}}) do
        {:error, {:api_error, {error["errorcode"], error["errordesc"]}}}
      end
      defp handle_response(%Response{status_code: code, body: body}), do: {:error, {:http_error, code, body}}
    end
  end
end
