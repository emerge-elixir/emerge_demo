defmodule EmergeDemo.Showcase.InputButton do
  @moduledoc false

  use Solve.Controller, events: [:pressed, :focused, :blurred]

  @impl true
  def init(_init_params, _dependencies) do
    %{focused?: false, press_count: 0, focus_count: 0, blur_count: 0}
  end

  def pressed(_payload, state) do
    %{state | press_count: state.press_count + 1}
  end

  def focused(_payload, state, _dependencies, callbacks) do
    if clear_popup = callbacks[:clear_popup], do: clear_popup.()
    %{state | focused?: true, focus_count: state.focus_count + 1}
  end

  def blurred(_payload, state, _dependencies, callbacks) do
    if clear_popup = callbacks[:clear_popup], do: clear_popup.()
    %{state | focused?: false, blur_count: state.blur_count + 1}
  end
end
