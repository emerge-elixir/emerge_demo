defmodule EmergeDemo.Showcase.App do
  @moduledoc """
  Solve app for the example showcase.
  """

  alias EmergeDemo.Showcase

  use Solve

  def child_spec(opts) do
    %{
      id: {__MODULE__, Keyword.get(opts, :name, __MODULE__)},
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  @impl Solve
  def controllers do
    [
      controller!(name: :pages, module: Showcase.Pages),
      controller!(name: :interaction, module: Showcase.Interaction),
      controller!(name: :keys, module: Showcase.Keys),
      controller!(
        name: :text_input,
        module: Showcase.TextInput,
        callbacks: %{
          text_committed: fn -> dispatch(:soft_keyboard, :text_committed) end,
          clear_popup: fn -> dispatch(:soft_keyboard, :clear_popup) end
        }
      ),
      controller!(name: :multiline_input, module: Showcase.MultilineInput),
      controller!(
        name: :input_button,
        module: Showcase.InputButton,
        callbacks: %{
          clear_popup: fn -> dispatch(:soft_keyboard, :clear_popup) end
        }
      ),
      controller!(
        name: :key_listener,
        module: Showcase.KeyListener,
        callbacks: %{
          clear_popup: fn -> dispatch(:soft_keyboard, :clear_popup) end
        }
      ),
      controller!(
        name: :soft_keyboard,
        module: Showcase.SoftKeyboard,
        dependencies: [:text_input, :input_button, :key_listener]
      ),
      controller!(name: :code_hover, module: Showcase.CodeHover)
    ]
  end
end
