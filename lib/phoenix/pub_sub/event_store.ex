defmodule Phoenix.PubSub.EventStore do
  @moduledoc """
  Doc
  """
  @behaviour Phoenix.PubSub.Adapter
  use GenServer

  def start_link(opts) do
    name = opts[:adapter_name]
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    event_store = opts[:eventstore]

    send(self(), :subscribe)

    {:ok, %{id: UUID.uuid1(), event_store: event_store, name: opts[:name]}}
  end

  def node_name(nil), do: node()
  def node_name(configured_name), do: configured_name

  def direct_broadcast(server, node_name, topic, message, dispatcher) do
    metadata = %{
      dispatcher: dispatcher,
      destination_node: node_name
    }

    publish(server, topic, message, metadata)
  end

  def broadcast(server, topic, message, dispatcher) do
    metadata = %{
      dispatcher: dispatcher
    }

    publish(server, topic, message, metadata)
  end

  defp publish(server, topic, message, metadata) do
    GenServer.call(server, {:publish, topic, message, metadata})
  end

  def handle_call(
        {:publish, topic, message, metadata},
        _from_pid,
        %{id: id, event_store: event_store} = state
      ) do
    metadata =
      metadata
      |> Map.put(:source, id)
      |> Map.put(:source_node, Node.self())

    message = %EventStore.EventData{
      event_type: "Elixir.Phoenix.PubSub.EventStore.Data",
      data: %Phoenix.PubSub.EventStore.Data{
        payload: encode(message),
        topic: topic
      },
      metadata: metadata
    }

    res = event_store.append_to_stream(topic, :any_version, [message])

    {:reply, res, state}
  end

  def handle_info(:subscribe, %{event_store: event_store} = state) do
    event_store.subscribe("$all")

    {:noreply, state}
  end

  def handle_info({:events, events}, state) do
    Enum.each(events, &local_broadcast_event(&1, state))

    {:noreply, state}
  end

  def handle_info({:subscribed, _subscription}, state) do
    {:noreply, state}
  end

  defp local_broadcast_event(
         %EventStore.RecordedEvent{
           data: %Phoenix.PubSub.EventStore.Data{
             topic: topic,
             payload: payload
           },
           metadata: %{
             "dispatcher" => dispatcher,
             "source" => source_id,
             "destination_node" => destination_node
           }
         },
         %{id: id, name: name} = _state
       ) do
    if to_string(Node.self()) == destination_node and
         id != source_id do
      Phoenix.PubSub.local_broadcast(
        name,
        topic,
        decode(payload),
        String.to_existing_atom(dispatcher)
      )
    end
  end

  defp local_broadcast_event(
         %EventStore.RecordedEvent{
           data: %Phoenix.PubSub.EventStore.Data{
             topic: topic,
             payload: payload
           },
           metadata: %{
             "dispatcher" => dispatcher,
             "source" => source_id
           }
         },
         %{id: id, name: name} = _state
       ) do
    if id != source_id do
      Phoenix.PubSub.local_broadcast(
        name,
        topic,
        decode(payload),
        String.to_existing_atom(dispatcher)
      )
    end
  end

  defp encode(msg) do
    msg
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  defp decode(payload) do
    payload
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end
end
