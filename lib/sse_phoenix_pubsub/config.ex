defmodule SsePhoenixPubsub.Config do
  @moduledoc """

  Configuration for `sse_phoenix_pubsub`:
    * `:keep_alive` - Optional. Keep-alive interval to send a ping to the client.
      Default is `20_000` (milliseconds).
    * `:retry` - Optional. The reconnection time to use when attempting to send the event.
      Default is `2_000` (milliseconds).

  ### Example
  Configured defaults with override from environment variables, if present:

    config :sse_phoenix_pubsub,
      retry: {:system, "SSE_RETRY_IN_MS", 2_000},
      keep_alive: {:system, "SSE_KEEP_ALIVE_IN_MS", 20_000}

  """

  @app :sse_phoenix_pubsub

  @doc """
  Keep alive
  """
  @spec keep_alive() :: integer()
  def keep_alive do
    @app
    |> Application.get_env(:keep_alive, 20_000)
    |> get_env_var()
    |> to_integer()
  end

  @spec retry() :: integer()
  def retry do
    @app
    |> Application.get_env(:retry, 2_000)
    |> get_env_var()
    |> to_integer()
  end

  defp get_env_var({:system, name, default}) do
    System.get_env(name) || default
  end

  defp get_env_var(val) do
    val
  end

  defp to_integer(val) when is_integer(val) do
    val
  end

  defp to_integer(val) do
    String.to_integer(val)
  end
end
