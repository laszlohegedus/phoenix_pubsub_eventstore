defmodule Phoenix.PubSub.EventStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_pubsub_eventstore,
      deps: deps(),
      description: "Phoenix pubsub over EventStore",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp package do
    [
      maintainers: ["Laszlo Hegedus"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/laszlohegedus/phoenix_pubsub_eventstore"}
    ]
  end

  defp elixirc_paths(:test), do: ["test/test_app" | elixirc_paths(:dev)]
  defp elixirc_paths(_other), do: ["lib"]

  defp deps do
    [
      {:eventstore, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:phoenix_pubsub, "~> 1.1.2"},
      {:elixir_uuid, "~> 1.2"}
    ]
  end
end
