defmodule EmergeDemo.Showcase.TextInput do
  @moduledoc false

  use Solve.Controller, events: [:changed, :focused, :blurred]

  @impl true
  def init(_init_params, _dependencies) do
    %{value: "quick brown fox", focused?: false, focus_count: 0, blur_count: 0}
  end

  def changed(value, state, _dependencies, callbacks) when is_binary(value) do
    if text_committed = callbacks[:text_committed], do: text_committed.()
    %{state | value: value}
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
