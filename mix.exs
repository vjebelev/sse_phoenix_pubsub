defmodule SsePhoenixPubsub.MixProject do
  use Mix.Project

  def project do
    [
      app: :sse_phoenix_pubsub,
      version: "1.0.2",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp description do
    """
    Server Sent Events on top of Phoenix PubSub
    """
  end

  defp package do
    [
      name: :sse_phoenix_pubsub,
      maintainers: ["Vlad Jebelev"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/vjebelev/sse_phoenix_pubsub"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, ">= 1.4.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
