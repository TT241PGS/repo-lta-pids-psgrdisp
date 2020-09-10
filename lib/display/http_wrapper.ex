defmodule HTTPWrapper do
  @moduledoc """
  This module should be used to make http requests
  """
  require Logger
  require OK

  defp decode_body(body) do
    case Jason.decode(body) do
      {:ok, decoded} ->
        {:ok, decoded}

      {:error, %Jason.DecodeError{data: data}} ->
        {:ok, data}

      {:error, error} ->
        {:error, error}
    end
  end

  defp handle_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, decode_body(body)}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:status_code, status_code}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      err ->
        {:error, err}
    end
  end

  defp do_post(url, payload, headers) do
    HTTPoison.post(url, payload, headers) |> handle_response
  end

  defp do_get(url, headers, options) do
    HTTPoison.get(url, headers, options) |> handle_response
  end

  def get(nil, _headers, _options), do: {:error, :missing_url}

  def get(url, headers, options) do
    OK.for do
      body <- do_get(url, headers, options)
    after
      body
    end
  end

  def post(nil, _payload, _headers), do: {:error, :missing_url}

  def post(url, payload, headers) do
    OK.for do
      body <- do_post(url, payload, headers)
      decoded = decode_body(body)
    after
      decoded
    end
  end
end
