defmodule EmergeDemo.Todo.Editor do
  @moduledoc false

  use Solve.Controller,
    events: [
      :begin,
      :cancel,
      :set,
      :save
    ]

  @impl true
  def init(params, _dependencies), do: %{editing?: false, title: params.title}

  def begin(_payload, state), do: %{state | editing?: true}

  def set(title, %{editing?: true} = state) when is_binary(title),
    do: %{state | title: title}

  def cancel(_payload, _state, _dependencies, _callbacks, params),
    do: %{editing?: false, title: params.title}

  def save(_payload, state, _dependencies, callbacks, params) do
    callbacks.save.(params.id, state.title)
    %{editing?: false, title: params.title}
  end

  def expose(state, _dependencies, params), do: Map.put(state, :id, params.id)
end
