defmodule EmergeDemo.Showcase.CodeHover do
  @moduledoc false

  use Solve.Controller, events: [:show, :hide]

  @impl true
  def init(_init_params, _dependencies) do
    %{active: nil}
  end

  def show(example_id, _state) do
    %{active: example_id}
  end

  def hide(example_id, %{active: example_id} = state) do
    %{state | active: nil}
  end

  def hide(_other_id, state), do: state

  @impl true
  def expose(state, _dependencies, _init_params) do
    %{active: state.active}
  end
end
