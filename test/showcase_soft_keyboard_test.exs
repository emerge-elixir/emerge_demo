defmodule EmergeDemo.Showcase.SoftKeyboardTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.SoftKeyboard

  test "toggle shift flips state and updates last action" do
    state = SoftKeyboard.init(%{}, %{})
    shifted = SoftKeyboard.toggle_shift(nil, state)

    assert %{shift_active?: true, last_action: "Soft keyboard: shift on"} =
             SoftKeyboard.expose(shifted, %{}, %{})
  end

  test "show alternates increments hold count and opens the popup" do
    state = SoftKeyboard.init(%{}, %{})
    popup = SoftKeyboard.show_alternates(:i, state)

    assert %{popup: :i, hold_count: 1} = SoftKeyboard.expose(popup, %{}, %{})
  end

  test "text committed clears the popup and records alternate commit" do
    state = SoftKeyboard.show_alternates(:e, SoftKeyboard.init(%{}, %{}))
    committed = SoftKeyboard.text_committed(nil, state)

    assert %{popup: nil, last_action: "Soft keyboard: alternate committed"} =
             SoftKeyboard.expose(committed, %{}, %{})
  end

  test "popup key selection closes the popup immediately" do
    state = SoftKeyboard.show_alternates(:a, SoftKeyboard.init(%{}, %{}))
    selected = SoftKeyboard.popup_key_selected("á", state)

    assert %{popup: nil, last_action: "Soft keyboard: selected á"} =
             SoftKeyboard.expose(selected, %{}, %{})
  end

  test "target label follows the focused input target" do
    state = SoftKeyboard.init(%{}, %{})

    assert %{target_label: "Text input"} =
             SoftKeyboard.expose(state, %{text_input: %{focused?: true}}, %{})

    assert %{target_label: "Keyboard listener pad"} =
             SoftKeyboard.expose(state, %{key_listener: %{focused?: true}}, %{})

    assert %{target_label: "Run action button"} =
             SoftKeyboard.expose(state, %{input_button: %{focused?: true}}, %{})
  end
end
