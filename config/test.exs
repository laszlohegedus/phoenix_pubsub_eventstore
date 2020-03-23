import Config

config :phoenix_pubsub_eventstore,
  pubsub: [
    name: EventStoreTest.PubSub,
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
