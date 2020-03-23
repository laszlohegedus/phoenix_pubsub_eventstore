import Config

config :phoenix_pubsub_eventstore,
  pubsub: [
    name: EventStoreTest.PubSub,
    adapter: Phoenix.PubSub.EventStore,
    eventstore: Phoenix.PubSub.EventStoreTest.TestApp.EventStore
  ]

config :phoenix_pubsub_eventstore, Phoenix.PubSub.EventStoreTest.TestApp.EventStore,
  serializer: EventStore.TermSerializer,
  registry: :distributed,
  username: "postgres",
  password: "postgres",
  database: "eventstore",
  hostname: "localhost"

config :phoenix_pubsub_eventstore,
  event_stores: [Phoenix.PubSub.EventStoreTest.TestApp.EventStore]
