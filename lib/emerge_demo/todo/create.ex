defmodule EmergeDemo.Todo.Create do
  @moduledoc false

  use Solve.Controller, events: [:set, :create]

  @impl true
  def init(_params, _dependencies), do: %{title: ""}

  def set(title) when is_binary(title) do
    %{title: title}
  end

  def create(_payload, state, _dependencies, callbacks) do
    case String.trim(state.title) do
      "" ->
        %{title: ""}

      title ->
        callbacks.create.(title)
        %{title: ""}
    end
  end
end
