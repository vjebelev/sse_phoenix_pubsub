# SsePhoenixPubsub

I needed a way to stream to event source events and at first tried to use the sse + event_bus package by Mustafa Turan (https://github.com/mustafaturan/sse) but it turned out to not be a good fit for my project (main reason being that we have to deal with a large number of dynamically generated topics and event bus uses atoms for channel names, a limited number of which is available, and not garbage collected either). I then looked at the Phoenix PubSub which turned out to be a great fit as it's already used internally by Phoenix for streaming to websockets. So this package is a product of hacking Mustafa's project and replacing event bus with Phoenix PubSub.

## Installation

Detailed instructions can be found in [my blog post](http://blog.jebelev.com/posts/phoenix-pubsub-sse/).

### Sending Server-Sent Events

Add `sse_phoenix_pubsub` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sse_phoenix_pubsub, "~> 1.0"}
  ]
end
```

Broadcast your events via Phoenix Pubsub, e.g:
```elixir
Phoenix.PubSub.broadcast(SseDemo.PubSub, "time", {SseDemo.PubSub, "02:29:54.360596"})
```
`SseDemo.PubSub` is the name of the pubsub system from `application.ex`, `"time"` is a topic name, "02:29:54.360596" is the message being sent - has to be a string.

An example of a GenServer-based event generator:
```elixir
defmodule SseDemo.TimeEventsGenerator do
  use GenServer
  require Logger
  
  alias Phoenix.PubSub

  @default_interval 1_000

  def start_link(opts) do
    pubsub_name = Keyword.fetch!(opts, :pubsub_name)
    topic_name = Keyword.fetch!(opts, :topic_name)
    interval = Keyword.get(opts, :interval, @default_interval)
    GenServer.start_link(__MODULE__, {pubsub_name, topic_name, interval})
  end

  def init({pubsub_name, topic_name, interval}) do
    Process.send_after(self(), :send_time_event, interval)
    {:ok, %{pubsub_name: pubsub_name, topic_name: topic_name, interval: interval, last_run_at: nil}}
  end

  def handle_info(:send_time_event, %{pubsub_name: pubsub_name, topic_name: topic_name, interval: interval} = state) do
    message = Time.utc_now() |> Time.to_string
    PubSub.broadcast(pubsub_name, topic_name, {pubsub_name, message})
    Logger.debug(fn -> "Broadcast to topic #{topic_name}, message: #{message}" end)

    Process.send_after(self(), :send_time_event, interval)
    {:noreply, %{state | last_run_at: :calendar.local_time()}}
  end
end
```

To start, add it to specs in `application.ex`:
```elixir
{SseDemo.TimeEventsGenerator, [pubsub_name: SseDemo.PubSub, topic_name: "time"]}
```

### Receiving Server-Sent Events

Configure SSE's http endpoint with high idle timeout:

```elixir
  http: [
    port: 4000,
    protocol_options: [
      idle_timeout: 3_600_000
    ]
  ],

```

Setup a controller for SSE subscriptions and subscribe clients to selected topics:
```elixir
defmodule SseDemoWeb.SseController do
  use SseDemoWeb, :controller
  require Logger

  def subscribe(conn, params) do
    case get_topics(params) do
      topics when is_list(topics) ->
        Logger.debug(fn -> "Subscribed to topics #{inspect(topics)}" end)
        SsePhoenixPubsub.stream(conn, {SseDemo.PubSub, topics})
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

Make sure `router.ex` is setup for correct content type, e.g.:
```elixir
  pipeline :sse do
    plug :put_format, "text/event-stream"
    plug :fetch_session
  end

  scope "/sse", SseDemoWeb do
    pipe_through :sse

    get "/", SseController, :subscribe
  end
```

Webpage integration is done via built-in `EventSource` object.

## License

MIT

Copyright (c) 2020 Vlad Jebelev

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Portions of this package are copied from an open source package https://github.com/mustafaturan/sse by Mustafa Torin:

MIT

Copyright (c) 2018 Mustafa Turan

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

