defmodule Phoenix.PubSub.EventStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_pubsub_eventstore,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["test/test_app" | elixirc_paths(:dev)]
  defp elixirc_paths(_other), do: ["lib"]

  defp deps do
    [
      {:eventstore, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:phoenix, "~> 1.4.12"},
      {:phoenix_pubsub,
       github: "phoenixframework/phoenix_pubsub", branch: "master", override: true},
      {:elixir_uuid, "~> 1.2"}
    ]
  end
end
