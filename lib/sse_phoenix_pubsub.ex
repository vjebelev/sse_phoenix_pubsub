defmodule SsePhoenixPubsub do
  defdelegate stream(conn, pubsub_info, data \\ []),
    to: SsePhoenixPubsub.Server,
    as: :stream
end
