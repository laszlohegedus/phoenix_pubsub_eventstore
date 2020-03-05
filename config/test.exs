import Config

config :phoenix, json_library: Jason

config :phoenix_pubsub_eventstore,
  pubsub: [
    name: EventStoreTest.PubSub,
    adapter: Phoenix.PubSub.EventStore,
    eventstore: Phoenix.PubSub.EventStoreTest.TestApp.EventStore
  ]

config :phoenix_pubsub_eventstore, Phoenix.PubSub.EventStoreTest.TestApp.EventStore,
  column_data_type: "jsonb",
  serializer: EventStore.JsonbSerializer,
  types: EventStore.PostgresTypes,
  registry: :distributed,
  username: "postgres",
  password: "postgres",
  database: "eventstore",
  hostname: "localhost"

config :phoenix_pubsub_eventstore,
  event_stores: [Phoenix.PubSub.EventStoreTest.TestApp.EventStore]
