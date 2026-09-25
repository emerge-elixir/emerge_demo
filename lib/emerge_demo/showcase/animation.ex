defmodule EmergeDemo.Showcase.Animation do
  @moduledoc false

  use Solve.Controller, events: [:toggle]

  @fields [:expanded?, :sidebar_open?, :details_open?, :notification_visible?]

  @impl true
  def init(_init_params, _dependencies) do
    Map.new(@fields, &{&1, false})
  end

  def toggle(field, state) when field in @fields do
    Map.update!(state, field, &(!&1))
  end

  def toggle(_unknown, state), do: state

  @impl true
  def expose(state, _dependencies, _init_params), do: state
end
