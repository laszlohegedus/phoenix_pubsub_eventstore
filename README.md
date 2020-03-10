# phoenix_pubsub_eventstore

Phoenix pubsub adapter using EventStore.

This library can be used to provide Phoenix PubSub over [EventStore](https://hexdocs.pm/eventstore).

## Usage

Add `Phoenix.PubSub` to your supervision tree by specifying `Phoenix.PubSub.EventStore` as an adapter and passing your event store in the `:eventstore` option.

```elixir
{Phoenix.PubSub,
  [name: MyApp.PubSub,
   adapter: Phoenix.PubSub.EventStore,
   eventstore: MyApp.EventStore]
}
```

You should have `MyApp.EventStore` configured separately. Consult the [EventStore](https://hexdocs.pm/eventstore/EventStore.html) documentation for hints. Make sure that `MyApp.EventStore` is started **before** the PubSub.
