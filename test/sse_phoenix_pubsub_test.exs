defmodule SsePhoenixPubsubTest do
  use ExUnit.Case
  doctest SsePhoenixPubsub

  test "greets the world" do
    assert SsePhoenixPubsub.hello() == :world
  end
end
