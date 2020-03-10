# phoenix_pubsub_eventstore

Phoenix pubsub adapter using EventStore. It is still work in progress and I do not recommend it to be used in a production environment.

This library can be used to provide Phoenix PubSub over [EventStore](https://hexdocs.pm/eventstore).

## Usage

Add `Phoenix.PubSub.EventStore` to your supervision tree specifying your event store in the option `:eventstore`.

```elixir
{Phoenix.PubSub.EventStore, [name: MyApp.PubSub, eventstore: MyApp.EventStore]}
```

or

```elixir
{Phoenix.PubSub.EventStore, MyApp.PubSub, [eventstore: MyApp.EventStore]}
```

You should have `MyApp.EventStore` configured separately. Consult the [EventStore](https://hexdocs.pm/eventstore/EventStore.html) documentation for hints. Make sure that `MyApp.EventStore` is started **before** the PubSub.
