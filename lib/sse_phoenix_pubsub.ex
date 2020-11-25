defmodule SsePhoenixPubsub do
  @moduledoc """
  Server-Sent Events on top of `Phoenix PubSub`.

  ### Installation

  Add to dependencies in mix.exs:
  ```elixir
    {:sse_phoenix_pubsub, "~> 1.0"}
  ```

  ### Sending SSE

  Start the PubSub system in `application.ex`:

  ```elixir
    {Phoenix.PubSub, name: MyApp.PubSub}
  ```

  Publish messages via `Phoenix.PubSub.broadcast` method on a selected topic:

  ```elixir
    Phoenix.PubSub.broadcast(MyApp.PubSub, "time", {MyApp.PubSub, "01:34:55.123567"})
  ```

  ### Receiving SSE

  Configure http endpoint for SSE with `idle_timeout` option to keep
  the SSE connection running:

  ```elixir
    config :my_app, MyAppWeb.Endpoint,
      http: [
        port: 4000,
        protocol_options: [
          idle_timeout: 3_600_000
        ]
      ]
  ```

  Configure phoenix or plug routing:

  ```elixir
    pipeline :sse do
      plug :put_format, "text/event-stream"
      plug :fetch_session
    end

    scope "/sse", MyAppWeb do
      pipe_through :sse

      get "/", SseController, :subscribe
    end
  ```

  Create a Phoenix controller for subscribing http clients to desired topics:

  ```elixir
    defmodule MyAppWeb.SseController do
      use MyAppWeb, :controller

      def subscribe(conn, params) do
        case get_topics(params) do
          topics when is_list(topics) ->
            SsePhoenixPubsub.stream(conn, {MyApp.PubSub, topics})
           _ ->
            Logger.error("No topics provided")
        end
      end

      defp get_topics(params) do
        case params["topics"] do
          str when is_binary(str) -> String.split(str, ",")
          nil -> []
        end
      end
    end
  ```

  """

  defdelegate stream(conn, pubsub_info, data \\ []),
    to: SsePhoenixPubsub.Server,
    as: :stream
end
