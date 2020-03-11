defmodule Phoenix.PubSub.EventStore.Serializer.Base64 do
  @moduledoc """
  Default serializer of PubSub message data

  To keep published data intact and consistent (we could not differentiate
  between strings and atoms when converted to a JSON) we need to serialize
  messages before publishing them into the EventStore. Messages are
  deserialized before distributed to local subscribers.

  Any module that implements `serialize/1` and `deserialize/1` can be used
  as a serializer as long as EventStore works with it.
  """
  defstruct [:payload]

  @type t() :: %__MODULE__{payload: String.t()}

  @doc """
  Serialize EventStore messages

  Serializes the message as a base64 encoded binary and wraps
  it in a `%Phoenix.PubSub.EventStore.Serializer.Base64{}` struct.
  """
  def serialize(msg) do
    %__MODULE__{
      payload:
        msg
        |> :erlang.term_to_binary()
        |> Base.encode64()
    }
  end

  @doc """
  Deserialize EventStore messages

  Extracts and deserializes the base64 encoded binary
  """
  def deserialize(%__MODULE__{payload: payload}) do
    payload
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end
end
