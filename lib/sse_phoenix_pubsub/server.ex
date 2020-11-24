defmodule SsePhoenixPubsub.Server do
  @moduledoc false
  # Server for SSE / Phoenix Pubsub
  #
  require Logger

  alias Plug.Conn
  alias Phoenix.PubSub
  alias SsePhoenixPubsub.{Chunk, Config}

  @type chunk :: Chunk.t()
  @type chunk_conn :: {:ok, conn()} | {:error, term()}
  @type chunk_data :: list(String.t())
  @type conn :: Conn.t()
  @type topic :: String.t()
  @type topics :: list(topic())
  @type pubsub_info :: {atom(), topics()}

  @doc """
  Stream SSE events
  """
  @spec stream(conn(), pubsub_info(), chunk_data()) :: conn()
  def stream(conn, pubsub_info, data) do
    chunk = %Chunk{data: data, retry: Config.retry()}
    {:ok, conn} = init_sse(conn, chunk)
    subscribe_sse(pubsub_info)

    reset_timeout()
    Process.flag(:trap_exit, true)
    listen_sse(conn, pubsub_info)
  end

  # Init SSE connection
  @spec init_sse(conn(), chunk()) :: chunk_conn()
  defp init_sse(conn, chunk) do
    Logger.debug(fn -> "SSE connection (#{inspect(self())}) opened!" end)

    conn
    |> Conn.put_resp_header("cache-control", "no-cache")
    |> Conn.put_resp_content_type("text/event-stream")
    |> Conn.send_chunked(200)
    |> Conn.chunk(Chunk.build(chunk))
  end

  # Subscribe to pubsub topics
  defp subscribe_sse({pubsub_name, topics}) do
    for c <- topics do
      Logger.debug(fn -> "Subscribing #{inspect(self())} to topic #{c}" end)
      PubSub.subscribe(pubsub_name, c)
    end
  end

  # Unsubscribe from pubsub topics
  defp unsubscribe_sse({pubsub_name, topics}) do
    for c <- topics do
      Logger.debug(fn -> "Unsubscribing #{inspect(self())} from topic #{c}" end)
      PubSub.unsubscribe(pubsub_name, c)
    end
  end

  # Send SSE chunk
  defp send_sse(conn, pubsub_info, chunk) do
    case Conn.chunk(conn, Chunk.build(chunk)) do
      {:ok, conn} ->
        reset_timeout()
        listen_sse(conn, pubsub_info)

      {:error, _reason} ->
        unsubscribe_sse(pubsub_info)
        conn
    end
  end

  # Listen for Pubsub events (Phoenix Pubsub broadcasts)
  defp listen_sse(conn, {pubsub_name, _topics} = pubsub_info) do
    receive do
      {^pubsub_name, data} ->
        chunk = %Chunk{data: data}
        send_sse(conn, pubsub_info, chunk)

      {:send_idle} ->
        send_sse(conn, pubsub_info, keep_alive_chunk())

      {:close} ->
        unsubscribe_sse(pubsub_info)

      {:EXIT, _from, _reason} ->
        unsubscribe_sse(pubsub_info)
        Process.exit(self(), :normal)

      _ ->
        listen_sse(conn, pubsub_info)
    end
  end

  @spec reset_timeout() :: :ok
  defp reset_timeout do
    new_ref = Process.send_after(self(), {:send_idle}, Config.keep_alive())
    old_ref = Process.put(:timer_ref, new_ref)
    unless is_nil(old_ref), do: Process.cancel_timer(old_ref)
    :ok
  end

  @spec keep_alive_chunk() :: chunk()
  defp keep_alive_chunk do
    %Chunk{comment: "ping", data: []}
  end
end
