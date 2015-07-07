#
# The MIT License (MIT)
#
# Copyright (c) 2015 Undead Labs, LLC
#

defmodule SteamWeb.Endpoint do
  @type result_success :: {:ok, map}
  @type result_error :: {:error, {:api_error, {integer, binary}}}
  @type http_error :: {:error, {:http_error, integer, term}}
  @type connection_error :: {:error, term}
  @type response :: result_success | result_error | http_error | connection_error

  defmacro __using__(opts) do
    quote location: :keep do
      defmodule Connection do
        use HTTPoison.Base

        @default_interface Module.split(__MODULE__) |> List.last
        @interface Keyword.get(unquote(opts), :interface, @default_interface)
        @sandbox Keyword.get(unquote(opts), :sandbox, @interface)

        #
        # HTTPoison.Base overrides
        #

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
        # Private
        #

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
      end

      alias HTTPoison.Response
      import URI, only: [encode_query: 1, encode_www_form: 1]

      @default_max_retries 5

      @spec get(binary, Connection.headers, [{atom, any}]) :: Endpoint.response
      def get(url, headers \\ [], options \\ []), do: request(:get, url, "", headers, options)

      @spec put(binary, binary, Connection.headers, [{atom, any}]) :: Endpoint.response
      def put(url, body, headers \\ [], options \\ []), do: request(:put, url, body, headers, options)

      @spec head(binary, Connection.headers, [{atom, any}]) :: Endpoint.response
      def head(url, headers \\ [], options \\ []), do: request(:head, url, "", headers, options)

      @spec post(binary, binary, Connection.headers, [{atom, any}]) :: Endpoint.response
      def post(url, body, headers \\ [], options \\ []), do: request(:post, url, body, headers, options)

      @spec patch(binary, binary, Connection.headers, [{atom, any}]) :: Endpoint.response
      def patch(url, body, headers \\ [], options \\ []), do: request(:patch, url, body, headers, options)

      @spec delete(binary, Connection.headers, [{atom, any}]) :: Endpoint.response
      def delete(url, headers \\ [], options \\ []), do: request(:delete, url, "", headers, options)

      @spec options(binary, Connection.headers, [{atom, any}]) :: Endpoint.response
      def options(url, headers \\ [], options \\ []), do: request(:options, url, "", headers, options)

      @spec request(atom, binary, binary, Connection.headers, [{atom, any}]) :: Endpoint.response
      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        {max_retries, options} = Keyword.pop(options, :retries, @default_max_retries)
        request(method, url, body, headers, options, max_retries, 0)
      end

      def handle_response(%Response{status_code: 200, body: %{"response" => %{"result" => "OK"} = response}}) do
        {:ok, Map.fetch!(response, "params")}
      end
      def handle_response(%Response{status_code: 200, body: %{"response" => %{"result" => "Failure"} = response}}) do
        error = Map.fetch!(response, "error")
        {:error, {error["errorcode"], error["errordesc"]}}
      end
      def handle_response(%Response{status_code: 200, body: %{"response" => %{"params" => params}}}) do
        {:ok, params}
      end
      def handle_response(%Response{status_code: 200, body: %{"response" => %{"error" => error}}}) do
        {:error, {:api_error, {error["errorcode"], error["errordesc"]}}}
      end
      def handle_response(%Response{status_code: 200, body: body}) do
        {:ok, body}
      end
      def handle_response(%Response{status_code: code, body: body}), do: {:error, {:http_error, code, body}}

      #
      # Private
      #

      defp build_query(pairs) do
        Enum.filter(pairs, fn
          {_key, nil} -> false
          _ -> true
        end) |> encode_query()
      end

      defp request(method, url, body, headers, options, max_retries, tries, returning \\ nil)
      defp request(_, _, _, _, _, max_retries, tries, returning) when tries >= max_retries, do: returning
      defp request(method, url, body, headers, options, max_retries, tries, returning) do
        case Connection.request(method, url, body, headers, options) do
          {:ok, response} ->
            case handle_response(response) do
              {:error, {:http_error, _, _}} = error ->
                request(method, url, body, headers, options, max_retries, (tries + 1), error)
              response -> response
            end
          {:error, %HTTPoison.Error{reason: reason}} = error ->
            request(method, url, body, headers, options, max_retries, (tries + 1), {:error, reason})
        end
      end

      defoverridable [handle_response: 1]
    end
  end
end
