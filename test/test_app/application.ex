defmodule Phoenix.PubSub.EventStoreTest.TestApp.Application do
  use Application

  def start(_type, _args) do
    pubsub_config = Application.get_env(:phoenix_pubsub_eventstore, :pubsub)

    children = [
      Phoenix.PubSub.EventStoreTest.TestApp.EventStore,
      {Phoenix.PubSub, pubsub_config}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
