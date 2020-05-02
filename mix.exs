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
      source_url: "https://github.com/laszlohegedus/phoenix_pubsub_eventstore/",
      docs: [
        main: "Phoenix.PubSub.EventStore",
        source_ref: "master"
      ],
      version: "2.0.1"
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
      {:elixir_uuid, "~> 1.2"},
      {:eventstore, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:phoenix_pubsub, "~> 2.0"}
    ]
  end
end
