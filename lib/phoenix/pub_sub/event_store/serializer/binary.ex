defmodule Phoenix.PubSub.EventStore.Serializer.Base64 do
  defstruct [:payload]

  def serialize(msg) do
    %__MODULE__{
      payload:
        msg
        |> :erlang.term_to_binary()
        |> Base.encode64()
    }
  end

  def deserialize(%__MODULE__{payload: payload}) do
    payload
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end
end
