defmodule EmergeDemo.AppSelector.Screens do
  @moduledoc false

  use Solve.Controller,
    events: [:toggle_menu, :close_menu, :set_screen, :set_scale, :set_rotate]

  @screens [%{id: :todo, label: "Todo"}, %{id: :showcase, label: "Showcase"}]
  @screen_ids Enum.map(@screens, & &1.id)
  @scale_options [
    %{value: 1.0, label: "100%"},
    %{value: 1.25, label: "125%"},
    %{value: 1.5, label: "150%"}
  ]
  @scale_values Enum.map(@scale_options, & &1.value)
  @rotate_options [
    %{value: 0.0, label: "0"},
    %{value: 90.0, label: "90"},
    %{value: 180.0, label: "180"},
    %{value: 270.0, label: "270"}
  ]
  @rotate_values Enum.map(@rotate_options, & &1.value)

  @impl true
  def init(_init_params, _dependencies) do
    %{current: :todo, menu_open?: false, scale: 1.0, rotate: 0.0}
  end

  def toggle_menu(_payload, state), do: %{state | menu_open?: !state.menu_open?}

  def close_menu(_payload, state), do: %{state | menu_open?: false}

  def set_screen(screen, state) when screen in @screen_ids,
    do: %{state | current: screen, menu_open?: false}

  def set_screen(_other, state), do: state

  def set_scale(scale, state) when scale in @scale_values, do: Map.put(state, :scale, scale)

  def set_scale(_other, state), do: state

  def set_rotate(rotate, state) when rotate in @rotate_values, do: Map.put(state, :rotate, rotate)

  def set_rotate(_other, state), do: state

  @impl true
  def expose(state, _dependencies, _init_params) do
    %{
      current: state.current,
      menu_open?: state.menu_open?,
      rotate: Map.get(state, :rotate, 0.0),
      rotate_options: @rotate_options,
      scale: Map.get(state, :scale, 1.0),
      scale_options: @scale_options,
      screens: @screens
    }
  end
end
