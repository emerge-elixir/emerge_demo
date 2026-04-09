defmodule EmergeDemo.Showcase.SoftKeyboard do
  @moduledoc false

  use Solve.Controller,
    events: [
      :toggle_shift,
      :show_alternates,
      :popup_key_selected,
      :clear_popup,
      :text_committed
    ]

  @alternate_keys MapSet.new([:a, :e, :i, :o, :u, :c, :n])

  @impl true
  def init(_init_params, _dependencies) do
    %{
      shift_active?: false,
      popup: nil,
      hold_count: 0,
      last_action: "Tap the text input, then use the soft keys below."
    }
  end

  def toggle_shift(_payload, state) do
    shift_active? = !state.shift_active?

    %{
      state
      | shift_active?: shift_active?,
        popup: nil,
        last_action:
          if(shift_active?, do: "Soft keyboard: shift on", else: "Soft keyboard: shift off")
    }
  end

  def show_alternates(key, state) do
    if MapSet.member?(@alternate_keys, key) do
      next_hold_count = state.hold_count + 1

      %{
        state
        | popup: key,
          hold_count: next_hold_count,
          last_action:
            "Soft keyboard hold: #{String.upcase(Atom.to_string(key))} alternates (#{next_hold_count})"
      }
    else
      state
    end
  end

  def popup_key_selected(label, state) when is_binary(label) do
    %{state | popup: nil, last_action: "Soft keyboard: selected #{label}"}
  end

  def clear_popup(_payload, %{popup: nil} = state), do: state
  def clear_popup(_payload, state), do: %{state | popup: nil}

  def text_committed(_payload, %{popup: nil} = state), do: state

  def text_committed(_payload, state) do
    %{state | popup: nil, last_action: "Soft keyboard: alternate committed"}
  end

  @impl true
  def expose(state, dependencies, _init_params) do
    %{
      shift_active?: state.shift_active?,
      popup: state.popup,
      hold_count: state.hold_count,
      last_action: state.last_action,
      target_label: target_label(dependencies)
    }
  end

  defp target_label(%{text_input: %{focused?: true}}), do: "Text input"
  defp target_label(%{key_listener: %{focused?: true}}), do: "Keyboard listener pad"
  defp target_label(%{input_button: %{focused?: true}}), do: "Run action button"
  defp target_label(_dependencies), do: "Nothing focused"
end
