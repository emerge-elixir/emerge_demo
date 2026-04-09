defmodule EmergeDemo.Showcase.View.Interaction do
  use Emerge.UI
  use Solve.Lookup, :helpers

  alias EmergeDemo.Showcase
  alias EmergeDemo.Showcase.View

  # Page composition

  def layout do
    column([width(fill()), spacing(28)], [
      interactive_section(),
      hover_section(),
      mouse_section(),
      swipe_section(),
      transformed_hit_testing_section(),
      text_input_section(),
      multiline_input_section(),
      input_styles_section(),
      input_button_section(),
      key_listener_section(),
      virtual_keyboard_section()
    ])
  end

  # Pointer sections

  defp interactive_section do
    column([width(fill()), spacing(16)], [
      section_title("Interactive"),
      section_copy(
        "Interactive states are decorative. mouse_over and mouse_down change paint on the element without sending messages by themselves."
      ),
      interaction_example(
        "mouse_over + mouse_down",
        "Hover and press the card. Styling stays local to the element.",
        {:interaction, :interactive_states},
        interactive_states_code(),
        interactive_states_demo()
      )
    ])
  end

  defp hover_section do
    column([width(fill()), spacing(16)], [
      section_title("Hover"),
      section_copy(
        "Compare event-managed hover with declarative mouse_over styling. They feel similar on screen, but only one updates app state."
      ),
      interaction_example(
        "on_mouse_enter / on_mouse_leave vs mouse_over",
        "The left panel toggles Solve state with enter and leave events. The right panel stays fully declarative.",
        {:interaction, :hover_compare},
        hover_compare_code(),
        hover_compare_demo()
      )
    ])
  end

  defp mouse_section do
    column([width(fill()), spacing(16)], [
      section_title("Mouse Down + Up"),
      section_copy(
        "Mouse down and mouse up send explicit messages you can count or route into domain behavior."
      ),
      interaction_example(
        "on_mouse_down + on_mouse_up",
        "Press and release the card to update the counters below.",
        {:interaction, :mouse_press},
        mouse_press_code(),
        mouse_press_demo()
      )
    ])
  end

  defp swipe_section do
    column([width(fill()), spacing(16)], [
      section_title("Swipe"),
      section_copy(
        "Swipe gestures resolve on release. Press, drag past the deadzone, and release to send the final net direction into Solve state."
      ),
      interaction_example(
        "Swipe pad",
        "Drag in any direction, then release. Short drags and balanced diagonals are ignored so the pad does not misfire on casual movement.",
        {:interaction, :swipe_pad},
        swipe_code(),
        swipe_demo()
      )
    ])
  end

  defp transformed_hit_testing_section do
    column([width(fill()), spacing(16)], [
      section_title("Transformed Hit Testing"),
      section_copy(
        "The faint outline shows the original slot. Pointer events should follow the transformed card you see in front, not the untouched slot behind it."
      ),
      interaction_example(
        "Translated, rotated, and scaled hit targets",
        "Hover, move, and press the transformed cards. The counters and last-move label should follow the painted shape you see in front.",
        {:interaction, :transformed_hit_testing},
        transformed_hit_testing_code(),
        transformed_hit_testing_demo()
      )
    ])
  end

  # Input sections

  defp text_input_section do
    text_input = solve(Showcase.App, :text_input)

    {status_label, status_bg, status_text, border_color} =
      if text_input.focused? do
        {
          "Focused",
          color_rgb(72, 96, 70),
          color_rgb(227, 244, 223),
          color_rgb(228, 183, 104)
        }
      else
        {
          "Blurred",
          color_rgb(72, 74, 102),
          color_rgb(220, 224, 240),
          color_rgb(120, 130, 175)
        }
      end

    value_label = if(text_input.value == "", do: "(empty)", else: text_input.value)

    column([width(fill()), spacing(16)], [
      section_title("Text Input"),
      section_copy(
        "Input.text routes text changes and focus transitions through events. This first pass stops at routed element events and skips preedit diagnostics."
      ),
      interaction_example(
        "Input.text + on_change, on_focus, and on_blur",
        "Type into the field, focus it, and blur it to update the value and counters below.",
        {:interaction, :text_input},
        text_input_code(),
        el(
          [
            width(fill()),
            padding(14),
            Background.color(panel_bg()),
            Border.rounded(10)
          ],
          column([spacing(10)], [
            Input.text(
              [
                width(fill()),
                padding_xy(10, 8),
                Font.size(16),
                Font.color(color(:white)),
                Background.color(color_rgb(62, 62, 94)),
                Border.rounded(8),
                Border.width(1),
                Border.color(border_color),
                Event.on_change(event(text_input, :changed)),
                Event.on_focus(event(text_input, :focused)),
                Event.on_blur(event(text_input, :blurred))
              ],
              text_input.value
            ),
            el(
              [Font.size(11), Font.color(panel_muted())],
              text(
                "on_change emits each edit from Rust; on_focus and on_blur fire on focus transitions."
              )
            ),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              status_chip("State", status_label, status_bg, status_text),
              status_chip(
                "Focus",
                text_input.focus_count,
                color_rgb(64, 74, 106),
                color_rgb(205, 216, 246)
              ),
              status_chip(
                "Blur",
                text_input.blur_count,
                color_rgb(78, 68, 100),
                color_rgb(228, 212, 246)
              )
            ]),
            el(
              [Font.size(12), Font.color(color_rgb(225, 228, 244))],
              text("Value: #{value_label}")
            ),
            el(
              [Font.size(11), Font.color(panel_muted())],
              text("Length: #{String.length(text_input.value)}")
            )
          ])
        )
      )
    ])
  end

  defp multiline_input_section do
    multiline_input = solve(Showcase.App, :multiline_input)

    column([width(fill()), spacing(16)], [
      section_title("Multiline Input"),
      section_copy(
        "Input.multiline defaults to a one-line minimum height, grows with wrapped content when height is omitted, and lets Enter insert newlines unless a matching key handler suppresses that default behavior."
      ),
      interaction_example(
        "Auto-growing Input.multiline",
        "Type more text, add blank lines, or resize the page narrower to watch the field grow with its wrapped content.",
        {:interaction, :multiline_auto_grow},
        multiline_auto_grow_code(),
        multiline_auto_grow_demo(multiline_input.grow)
      ),
      interaction_example(
        "on_key_down(:enter) suppresses default newline",
        "This second field intercepts Enter. The handler count increases, but the value stays on the same line unless you paste a newline explicitly.",
        {:interaction, :multiline_submit},
        multiline_submit_code(),
        multiline_submit_demo(multiline_input.submit)
      )
    ])
  end

  defp input_styles_section do
    column([width(fill()), spacing(16)], [
      section_title("Declarative Input Styling"),
      section_copy(
        "Interactive states also work on inputs. Hover, focus, and press styles can live directly on the field without separate event state."
      ),
      interaction_example(
        "mouse_over + focused + mouse_down on Input.text",
        "Click into the field and hold the mouse to see how the decorative states layer.",
        {:interaction, :input_styles},
        input_styles_code(),
        el(
          [
            width(fill()),
            padding(14),
            Background.color(panel_bg()),
            Border.rounded(10)
          ],
          column([spacing(10)], [
            Input.text(
              [
                width(fill()),
                padding_xy(10, 8),
                Font.size(16),
                Font.color(color_rgb(228, 232, 246)),
                Background.color(color_rgb(58, 62, 90)),
                Border.rounded(8),
                Border.width(1),
                Border.color(color_rgb(110, 120, 162)),
                Interactive.mouse_over([
                  Background.color(color_rgb(64, 70, 100)),
                  Border.color(color_rgb(132, 143, 189))
                ]),
                Interactive.focused([
                  Background.color(color_rgb(70, 78, 112)),
                  Border.color(color_rgb(164, 188, 236))
                ]),
                Interactive.mouse_down([
                  Background.color(color_rgb(63, 70, 100)),
                  Border.color(color_rgb(224, 186, 124)),
                  Transform.move_y(1)
                ])
              ],
              "Style showcase input"
            ),
            el(
              [Font.size(10), Font.color(panel_muted())],
              text(
                "Merge order: mouse_over -> focused -> mouse_down (later styles win conflicts)."
              )
            )
          ])
        )
      )
    ])
  end

  defp input_button_section do
    input_button = solve(Showcase.App, :input_button)

    {state_label, state_bg, state_text} =
      if input_button.focused? do
        {"Focused", color_rgb(70, 96, 82), color_rgb(224, 244, 236)}
      else
        {"Blurred", color_rgb(72, 74, 102), color_rgb(220, 224, 240)}
      end

    column([width(fill()), spacing(16)], [
      section_title("Input.button"),
      section_copy(
        "Buttons belong on the input half of the page. on_press, on_focus, and on_blur all route through Solve state."
      ),
      interaction_example(
        "Input.button + on_press",
        "Click or Tab to focus the button, then press Enter to trigger on_press.",
        {:interaction, :input_button},
        input_button_code(),
        el(
          [
            width(fill()),
            padding(14),
            Background.color(panel_bg()),
            Border.rounded(10)
          ],
          column([spacing(10)], [
            Input.button(
              [
                width(fill()),
                padding_xy(10, 8),
                Font.size(14),
                Font.color(color_rgb(230, 234, 246)),
                Background.color(color_rgb(58, 62, 90)),
                Border.rounded(8),
                Border.width(1),
                Border.color(color_rgb(110, 120, 162)),
                Event.on_press(event(input_button, :pressed)),
                Event.on_focus(event(input_button, :focused)),
                Event.on_blur(event(input_button, :blurred)),
                Interactive.mouse_over([
                  Background.color(color_rgb(64, 70, 100)),
                  Border.color(color_rgb(132, 143, 189))
                ]),
                Interactive.focused([
                  Border.color(color_rgb(166, 186, 236)),
                  Border.glow(color_rgba(132, 158, 232, 100 / 255), 2)
                ]),
                Interactive.mouse_down([
                  Background.color(color_rgb(56, 60, 88)),
                  Border.color(color_rgb(176, 190, 228)),
                  Border.inner_shadow(
                    offset: {0, 1},
                    blur: 6,
                    size: 1,
                    color: color_rgba(0, 0, 0, 120 / 255)
                  ),
                  Transform.move_y(1)
                ])
              ],
              text("Run action")
            ),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              status_chip("State", state_label, state_bg, state_text),
              status_chip(
                "Press",
                input_button.press_count,
                color_rgb(66, 74, 108),
                color_rgb(208, 218, 246)
              ),
              status_chip(
                "Focus",
                input_button.focus_count,
                color_rgb(64, 82, 96),
                color_rgb(210, 238, 236)
              ),
              status_chip(
                "Blur",
                input_button.blur_count,
                color_rgb(78, 68, 100),
                color_rgb(228, 212, 246)
              )
            ]),
            el(
              [Font.size(10), Font.color(panel_muted())],
              text("Press fires on click, and also on Enter when this button is focused.")
            )
          ])
        )
      )
    ])
  end

  defp key_listener_section do
    key_listener = solve(Showcase.App, :key_listener)

    {state_label, state_bg, state_text} =
      if key_listener.focused? do
        {"Focused", color_rgb(70, 96, 82), color_rgb(224, 244, 236)}
      else
        {"Blurred", color_rgb(72, 74, 102), color_rgb(220, 224, 240)}
      end

    column([width(fill()), spacing(16)], [
      section_title("Focused Key Listener"),
      section_copy(
        "Focused elements can listen for direct keyboard events. This pad demonstrates down, up, and completed key press handling."
      ),
      interaction_example(
        "on_key_down, on_key_up, and on_key_press",
        "Click or Tab onto the pad, then try Enter, Ctrl+1, Arrow Left, Escape, and Space.",
        {:interaction, :key_listener},
        key_listener_code(),
        el(
          [
            width(fill()),
            padding(14),
            Background.color(panel_bg()),
            Border.rounded(10)
          ],
          column([spacing(10)], [
            el(
              [
                width(fill()),
                padding(14),
                Background.color(color_rgb(56, 60, 88)),
                Border.rounded(10),
                Border.width(1),
                Border.color(color_rgb(112, 122, 164)),
                Event.on_focus(event(key_listener, :focused)),
                Event.on_blur(event(key_listener, :blurred)),
                Event.on_key_down(:enter, event(key_listener, :enter_down)),
                Event.on_key_down(
                  [key: :digit_1, mods: [:ctrl], match: :all],
                  event(key_listener, :ctrl_digit_1_down)
                ),
                Event.on_key_down(:arrow_left, event(key_listener, :arrow_left_down)),
                Event.on_key_up(:escape, event(key_listener, :escape_up)),
                Event.on_key_press(:space, event(key_listener, :space_press)),
                Interactive.mouse_over([
                  Background.color(color_rgb(62, 68, 98)),
                  Border.color(color_rgb(138, 148, 190))
                ]),
                Interactive.focused([
                  Background.color(color_rgb(66, 74, 106)),
                  Border.color(color_rgb(176, 196, 244)),
                  Border.glow(color_rgba(132, 158, 232, 110 / 255), 2)
                ])
              ],
              column([spacing(8)], [
                el([Font.size(14), Font.color(color(:white))], text("Keyboard listener pad")),
                el(
                  [Font.size(11), Font.color(color_rgb(214, 220, 240))],
                  text("Focused-only routing. No on_press handler here - only direct key events.")
                ),
                wrapped_row([width(fill()), spacing_xy(8, 8)], [
                  status_chip(
                    "Enter",
                    "down",
                    color_rgb(78, 86, 124),
                    color_rgb(232, 238, 252)
                  ),
                  status_chip(
                    "Ctrl+1",
                    "down",
                    color_rgb(82, 76, 132),
                    color_rgb(238, 232, 252)
                  ),
                  status_chip(
                    "Arrow Left",
                    "down",
                    color_rgb(74, 92, 122),
                    color_rgb(226, 240, 250)
                  ),
                  status_chip(
                    "Escape",
                    "up",
                    color_rgb(98, 76, 112),
                    color_rgb(244, 226, 246)
                  ),
                  status_chip(
                    "Space",
                    "press",
                    color_rgb(108, 86, 120),
                    color_rgb(248, 234, 246)
                  )
                ]),
                el(
                  [Font.size(10), Font.color(color_rgb(196, 204, 228))],
                  text(
                    "Tip: click once to focus, then hold Ctrl while pressing 1 to hit the modifier matcher. Space completes on key release here, so the press counter updates after the key comes back up."
                  )
                )
              ])
            ),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              status_chip("State", state_label, state_bg, state_text),
              status_chip(
                "Focus",
                key_listener.focus_count,
                color_rgb(64, 74, 106),
                color_rgb(205, 216, 246)
              ),
              status_chip(
                "Blur",
                key_listener.blur_count,
                color_rgb(78, 68, 100),
                color_rgb(228, 212, 246)
              ),
              status_chip(
                "Down",
                key_listener.key_down_count,
                color_rgb(70, 84, 114),
                color_rgb(220, 232, 248)
              ),
              status_chip(
                "Up",
                key_listener.key_up_count,
                color_rgb(96, 76, 116),
                color_rgb(244, 228, 246)
              ),
              status_chip(
                "Press",
                key_listener.key_press_count,
                color_rgb(112, 82, 120),
                color_rgb(248, 236, 246)
              )
            ]),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              status_chip(
                "Enter",
                key_listener.enter_count,
                color_rgb(76, 88, 134),
                color_rgb(234, 240, 252)
              ),
              status_chip(
                "Ctrl+1",
                key_listener.ctrl_digit_1_count,
                color_rgb(86, 78, 138),
                color_rgb(240, 234, 252)
              ),
              status_chip(
                "Arrow Left",
                key_listener.arrow_left_count,
                color_rgb(72, 96, 128),
                color_rgb(228, 242, 250)
              ),
              status_chip(
                "Escape up",
                key_listener.escape_count,
                color_rgb(102, 76, 120),
                color_rgb(246, 230, 248)
              ),
              status_chip(
                "Space press",
                key_listener.space_press_count,
                color_rgb(114, 84, 126),
                color_rgb(248, 236, 248)
              )
            ]),
            el(
              [Font.size(11), Font.color(color_rgb(230, 234, 246))],
              text("Last action: #{key_listener.last_action}")
            )
          ])
        )
      )
    ])
  end

  defp virtual_keyboard_section do
    soft_keyboard = solve(Showcase.App, :soft_keyboard)

    column([width(fill()), spacing(16)], [
      section_title("Virtual Keyboard"),
      section_copy(
        "Each key below is a plain Emerge tree node using Event.virtual_key/1. Use the nearby targets to test text input, buttons, focused key listeners, and Tab-based focus switching."
      ),
      interaction_example(
        "Event.virtual_key/1",
        "Use Tab to move focus through the nearby targets, use Shift for uppercase and symbols, and hold accented letters like A, E, I, O, U, C, or N to open alternates that close after selection.",
        {:interaction, :virtual_keyboard},
        virtual_keyboard_code(),
        el(
          [
            width(fill()),
            padding(14),
            Background.color(panel_bg()),
            Border.rounded(10)
          ],
          column([spacing(10)], [
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              status_chip(
                "Target",
                soft_keyboard.target_label,
                color_rgb(70, 82, 112),
                color_rgb(226, 234, 248)
              ),
              status_chip(
                "Shift",
                if(soft_keyboard.shift_active?, do: "On", else: "Off"),
                if(soft_keyboard.shift_active?,
                  do: color_rgb(88, 118, 78),
                  else: color_rgb(76, 74, 102)
                ),
                if(soft_keyboard.shift_active?,
                  do: color_rgb(230, 246, 228),
                  else: color_rgb(224, 228, 242)
                )
              ),
              status_chip(
                "Popup",
                popup_label(soft_keyboard.popup, soft_keyboard.shift_active?),
                color_rgb(92, 76, 116),
                color_rgb(244, 232, 248)
              ),
              status_chip(
                "Hold events",
                soft_keyboard.hold_count,
                color_rgb(74, 90, 124),
                color_rgb(230, 238, 250)
              )
            ]),
            soft_keyboard_targets(),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              soft_symbol_key("`", "~", :grave, soft_keyboard),
              soft_symbol_key("1", "!", :digit_1, soft_keyboard),
              soft_symbol_key("2", "@", :digit_2, soft_keyboard),
              soft_symbol_key("3", "#", :digit_3, soft_keyboard),
              soft_symbol_key("4", "$", :digit_4, soft_keyboard),
              soft_symbol_key("5", "%", :digit_5, soft_keyboard),
              soft_symbol_key("6", "^", :digit_6, soft_keyboard),
              soft_symbol_key("7", "&", :digit_7, soft_keyboard),
              soft_symbol_key("8", "*", :digit_8, soft_keyboard),
              soft_symbol_key("9", "(", :digit_9, soft_keyboard),
              soft_symbol_key("0", ")", :digit_0, soft_keyboard),
              soft_symbol_key("-", "_", :minus, soft_keyboard),
              soft_symbol_key("=", "+", :equal, soft_keyboard),
              soft_special_key_button(
                "Backspace",
                [tap: {:key, :backspace, []}, hold: :repeat],
                id: :backspace,
                width: px(124),
                background: color_rgb(88, 68, 84),
                hover_background: color_rgb(104, 82, 98),
                border_color: color_rgb(168, 126, 152)
              )
            ]),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              soft_tab_key(soft_keyboard),
              soft_letter_key(:q, "q", "Q", :q, soft_keyboard),
              soft_letter_key(:w, "w", "W", :w, soft_keyboard),
              soft_letter_key(:e, "e", "E", :e, soft_keyboard),
              soft_letter_key(:r, "r", "R", :r, soft_keyboard),
              soft_letter_key(:t, "t", "T", :t, soft_keyboard),
              soft_letter_key(:y, "y", "Y", :y, soft_keyboard),
              soft_letter_key(:u, "u", "U", :u, soft_keyboard),
              soft_letter_key(:i, "i", "I", :i, soft_keyboard),
              soft_letter_key(:o, "o", "O", :o, soft_keyboard),
              soft_letter_key(:p, "p", "P", :p, soft_keyboard),
              soft_symbol_key("[", "{", :left_bracket, soft_keyboard),
              soft_symbol_key("]", "}", :right_bracket, soft_keyboard),
              soft_symbol_key("\\", "|", :backslash, soft_keyboard)
            ]),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              soft_shift_toggle_key(soft_keyboard),
              soft_letter_key(:a, "a", "A", :a, soft_keyboard),
              soft_letter_key(:s, "s", "S", :s, soft_keyboard),
              soft_letter_key(:d, "d", "D", :d, soft_keyboard),
              soft_letter_key(:f, "f", "F", :f, soft_keyboard),
              soft_letter_key(:g, "g", "G", :g, soft_keyboard),
              soft_letter_key(:h, "h", "H", :h, soft_keyboard),
              soft_letter_key(:j, "j", "J", :j, soft_keyboard),
              soft_letter_key(:k, "k", "K", :k, soft_keyboard),
              soft_letter_key(:l, "l", "L", :l, soft_keyboard),
              soft_symbol_key(";", ":", :semicolon, soft_keyboard),
              soft_symbol_key("'", "\"", :apostrophe, soft_keyboard),
              soft_special_key_button(
                "Enter",
                [tap: {:key, :enter, []}],
                id: :enter,
                width: px(110),
                background: color_rgb(72, 92, 78),
                hover_background: color_rgb(86, 108, 92),
                border_color: color_rgb(156, 196, 164)
              )
            ]),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              soft_letter_key(:z, "z", "Z", :z, soft_keyboard),
              soft_letter_key(:x, "x", "X", :x, soft_keyboard),
              soft_letter_key(:c, "c", "C", :c, soft_keyboard),
              soft_letter_key(:v, "v", "V", :v, soft_keyboard),
              soft_letter_key(:b, "b", "B", :b, soft_keyboard),
              soft_letter_key(:n, "n", "N", :n, soft_keyboard),
              soft_letter_key(:m, "m", "M", :m, soft_keyboard),
              soft_symbol_key(",", "<", :comma, soft_keyboard),
              soft_symbol_key(".", ">", :period, soft_keyboard),
              soft_symbol_key("/", "?", :slash, soft_keyboard),
              soft_special_key_button(
                "Left",
                [tap: {:key, :arrow_left, soft_key_mods(soft_keyboard)}, hold: :repeat],
                id: :arrow_left,
                width: px(92),
                background: color_rgb(62, 84, 108),
                hover_background: color_rgb(76, 98, 124),
                border_color: color_rgb(138, 170, 204)
              ),
              soft_special_key_button(
                "Up",
                [tap: {:key, :arrow_up, soft_key_mods(soft_keyboard)}, hold: :repeat],
                id: :arrow_up,
                width: px(92),
                background: color_rgb(62, 84, 108),
                hover_background: color_rgb(76, 98, 124),
                border_color: color_rgb(138, 170, 204)
              ),
              soft_special_key_button(
                "Right",
                [tap: {:key, :arrow_right, soft_key_mods(soft_keyboard)}, hold: :repeat],
                id: :arrow_right,
                width: px(92),
                background: color_rgb(62, 84, 108),
                hover_background: color_rgb(76, 98, 124),
                border_color: color_rgb(138, 170, 204)
              ),
              soft_special_key_button(
                "Down",
                [tap: {:key, :arrow_down, soft_key_mods(soft_keyboard)}, hold: :repeat],
                id: :arrow_down,
                width: px(92),
                background: color_rgb(62, 84, 108),
                hover_background: color_rgb(76, 98, 124),
                border_color: color_rgb(138, 170, 204)
              )
            ]),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              soft_special_key_button(
                "Space",
                [tap: {:text_and_key, " ", :space, []}],
                id: :space,
                width: px(320),
                background: color_rgb(64, 72, 110),
                hover_background: color_rgb(78, 86, 126),
                border_color: color_rgb(138, 150, 206)
              )
            ]),
            el(
              [Font.size(11), Font.color(color_rgb(230, 234, 246))],
              text("Soft keyboard status: #{soft_keyboard.last_action}")
            )
          ])
        )
      )
    ])
  end

  # Pointer helpers

  defp interactive_states_demo do
    el(
      [
        width(fill()),
        padding(14),
        Background.color(panel_bg()),
        Border.rounded(10)
      ],
      column([spacing(10)], [
        el([Font.size(12), Font.color(panel_title())], text("Decorative pointer styling")),
        el(
          [Font.size(11), Font.color(panel_muted())],
          text(
            "No Elixir state changes here. Hover and press only swap decorative attrs on the element."
          )
        ),
        el(
          [
            width(fill()),
            padding(14),
            Background.color(surface_bg()),
            Border.rounded(10),
            Border.width(1),
            Border.color(surface_border()),
            Font.color(color(:white)),
            Interactive.mouse_over([
              Background.color(surface_hover_bg()),
              Border.color(surface_hover_border()),
              Transform.move_y(-1)
            ]),
            Interactive.mouse_down([
              Background.color(surface_pressed_bg()),
              Border.color(surface_pressed_border()),
              Transform.move_y(1)
            ])
          ],
          column([spacing(6)], [
            el([Font.size(13)], text("Purely visual pointer states")),
            el(
              [Font.size(10), Font.color(panel_muted())],
              text("mouse_down wins over mouse_over while both are active.")
            )
          ])
        )
      ])
    )
  end

  defp hover_compare_demo do
    wrapped_row([width(fill()), padding_each(6, 4, 12, 4), spacing_xy(16, 16)], [
      manual_hover_panel(),
      declarative_hover_panel()
    ])
  end

  defp manual_hover_panel do
    interaction = solve(Showcase.App, :interaction)
    active? = interaction.manual_hover?

    column([width(max(px(320), fill())), padding(10), spacing(10)], [
      el([Font.size(14), Font.color(title_text())], text("on_mouse_enter / on_mouse_leave")),
      el(
        [Font.size(11), Font.color(body_text())],
        text(
          "Hover events are sent to Solve, which toggles explicit app state and rerenders the panel."
        )
      ),
      el(
        [
          width(fill()),
          padding(14),
          Background.color(
            if(active?, do: manual_hover_active_bg(), else: manual_hover_idle_bg())
          ),
          Border.rounded(10),
          Border.width(1),
          Border.color(
            if(active?, do: manual_hover_active_border(), else: manual_hover_idle_border())
          ),
          Transform.move_y(if(active?, do: -2, else: 0)),
          Event.on_mouse_enter(event(interaction, :manual_hover_enter)),
          Event.on_mouse_leave(event(interaction, :manual_hover_leave))
        ],
        column([spacing(6)], [
          el(
            [
              Font.size(13),
              Font.color(if(active?, do: color(:white), else: manual_hover_idle_text()))
            ],
            text("Event-managed hover")
          ),
          el(
            [
              Font.size(11),
              Font.color(if(active?, do: color(:white), else: manual_hover_idle_text()))
            ],
            text(if(active?, do: "state: hovered", else: "state: idle"))
          ),
          el(
            [Font.size(10), Font.color(manual_hover_detail_text())],
            text("Behavior is explicit and can trigger arbitrary app logic.")
          )
        ])
      )
    ])
  end

  defp declarative_hover_panel do
    column([width(max(px(320), fill())), padding(10), spacing(10)], [
      el([Font.size(14), Font.color(title_text())], text("mouse_over")),
      el(
        [Font.size(11), Font.color(body_text())],
        text(
          "Styles live on the element. Rust tracks hover and applies decorative attrs without Elixir state."
        )
      ),
      el(
        [
          width(fill()),
          padding(14),
          Background.color(declarative_hover_bg()),
          Border.rounded(10),
          Border.width(1),
          Border.color(declarative_hover_border()),
          Interactive.mouse_over([
            Background.color(declarative_hover_active_bg()),
            Border.color(declarative_hover_active_border()),
            Font.color(color(:white)),
            Font.underline(),
            Font.strike(),
            Font.letter_spacing(1.4),
            Font.word_spacing(2.5),
            Transform.move_y(-2),
            Transform.scale(1.02)
          ])
        ],
        column([spacing(6)], [
          el(
            [Font.size(13), Font.color(declarative_hover_text())],
            text("Declarative hover style")
          ),
          el(
            [Font.size(11), Font.color(declarative_hover_text())],
            text("No enter/leave handlers or hover state in Elixir.")
          ),
          el(
            [Font.size(10), Font.color(declarative_hover_detail_text())],
            text("Hover changes decoration, spacing, and paint-time transforms.")
          )
        ])
      )
    ])
  end

  defp mouse_press_demo do
    interaction = solve(Showcase.App, :interaction)

    el(
      [
        width(fill()),
        padding(14),
        Background.color(panel_bg()),
        Border.rounded(10)
      ],
      column([spacing(10)], [
        el([Font.size(12), Font.color(panel_title())], text("Explicit press events")),
        el(
          [Font.size(11), Font.color(panel_muted())],
          text(
            "Press and release send separate messages, so domain state can count both phases explicitly."
          )
        ),
        el(
          [
            width(fill()),
            padding(14),
            Background.color(surface_bg()),
            Border.rounded(10),
            Border.width(1),
            Border.color(surface_border()),
            Font.color(color(:white)),
            Event.on_mouse_down(event(interaction, :mouse_down)),
            Event.on_mouse_up(event(interaction, :mouse_up)),
            Interactive.mouse_over([
              Background.color(surface_hover_bg()),
              Border.color(surface_hover_border())
            ]),
            Interactive.mouse_down([
              Background.color(surface_pressed_bg()),
              Border.color(surface_pressed_border()),
              Transform.move_y(1)
            ])
          ],
          column([spacing(6)], [
            el([Font.size(13)], text("Track mouse down and up separately")),
            el(
              [Font.size(10), Font.color(panel_muted())],
              text(
                "The counters below update from Event.on_mouse_down/1 and Event.on_mouse_up/1."
              )
            )
          ])
        ),
        wrapped_row([width(fill()), spacing_xy(8, 8)], [
          status_chip(
            "Mouse down",
            interaction.mouse_down_count,
            stat_down_bg(),
            stat_down_text()
          ),
          status_chip("Mouse up", interaction.mouse_up_count, stat_up_bg(), stat_up_text())
        ])
      ])
    )
  end

  defp swipe_demo do
    interaction = solve(Showcase.App, :interaction)
    swipe = interaction.swipe

    column([width(fill()), spacing(10)], [
      wrapped_row([width(fill()), spacing_xy(8, 8)], [
        status_chip("Last", swipe.last, color_rgb(76, 72, 118), color_rgb(242, 236, 252)),
        status_chip("Up", swipe.up_count, color_rgb(72, 96, 132), color_rgb(232, 242, 252)),
        status_chip(
          "Down",
          swipe.down_count,
          color_rgb(84, 78, 130),
          color_rgb(240, 236, 252)
        ),
        status_chip(
          "Left",
          swipe.left_count,
          color_rgb(72, 106, 110),
          color_rgb(228, 246, 246)
        ),
        status_chip(
          "Right",
          swipe.right_count,
          color_rgb(104, 84, 124),
          color_rgb(246, 236, 248)
        )
      ]),
      el(
        [
          width(fill()),
          padding(14),
          Background.color(panel_bg()),
          Border.rounded(10)
        ],
        column([spacing(10)], [
          paragraph([width(fill()), spacing(3), Font.size(11), Font.color(panel_muted())], [
            text(
              "This pad is intentionally not scrollable, so drag falls through to swipe. Scroll containers still win first."
            )
          ]),
          el(
            [
              width(fill()),
              height(px(240)),
              padding(14),
              Background.color(color_rgb(62, 66, 96)),
              Border.rounded(14),
              Border.width(1),
              Border.color(color_rgb(118, 128, 178)),
              Event.on_swipe_up(event(interaction, :swiped, :up)),
              Event.on_swipe_down(event(interaction, :swiped, :down)),
              Event.on_swipe_left(event(interaction, :swiped, :left)),
              Event.on_swipe_right(event(interaction, :swiped, :right)),
              Interactive.mouse_over([
                Background.color(color_rgb(70, 76, 108)),
                Border.color(color_rgb(160, 178, 236)),
                Border.glow(color_rgba(132, 158, 232, 84 / 255), 2)
              ]),
              Interactive.mouse_down([
                Background.color(color_rgb(56, 62, 88)),
                Border.color(color_rgb(226, 192, 132)),
                Transform.move_y(1)
              ])
            ],
            column([width(fill()), height(fill()), space_evenly()], [
              el(
                [center_x(), Font.size(10), Font.color(color_rgb(214, 226, 246))],
                text("Swipe up")
              ),
              row([width(fill()), space_evenly()], [
                el([Font.size(10), Font.color(color_rgb(214, 226, 246))], text("Swipe left")),
                column([center_x(), center_y(), spacing(6)], [
                  el([Font.size(18), Font.color(color(:white))], text("Swipe Pad")),
                  el(
                    [Font.size(11), Font.color(color_rgb(216, 222, 242))],
                    text("Release decides direction")
                  ),
                  el(
                    [Font.size(10), Font.color(color_rgb(198, 206, 232))],
                    text("Quick drag + release")
                  )
                ]),
                el([Font.size(10), Font.color(color_rgb(214, 226, 246))], text("Swipe right"))
              ]),
              el(
                [center_x(), Font.size(10), Font.color(color_rgb(214, 226, 246))],
                text("Swipe down")
              )
            ])
          ),
          paragraph([width(fill()), spacing(3), Font.size(10), Font.color(panel_muted())], [
            text(
              "Counters update after release. Short drags and balanced diagonals are ignored so the demo does not misfire on casual movement."
            )
          ])
        ])
      )
    ])
  end

  defp transformed_hit_testing_demo do
    interaction = solve(Showcase.App, :interaction)
    transformed = interaction.transformed

    column([width(fill()), spacing(10)], [
      wrapped_row([width(fill()), spacing_xy(8, 8)], [
        status_chip(
          "Last move",
          transformed.last_move_target,
          color_rgb(72, 74, 108),
          color_rgb(224, 228, 246)
        ),
        status_chip(
          "Rotated enter",
          transformed.rotated_enter_count,
          color_rgb(82, 76, 132),
          color_rgb(238, 232, 252)
        ),
        status_chip(
          "Rotated leave",
          transformed.rotated_leave_count,
          color_rgb(102, 76, 120),
          color_rgb(246, 230, 248)
        ),
        status_chip(
          "Scaled down",
          transformed.scaled_down_count,
          color_rgb(72, 96, 128),
          color_rgb(228, 242, 250)
        ),
        status_chip(
          "Scaled up",
          transformed.scaled_up_count,
          color_rgb(76, 96, 84),
          color_rgb(228, 244, 236)
        )
      ]),
      wrapped_row([width(fill()), spacing_xy(14, 14)], [
        transformed_event_showcase(
          "Translated Move",
          "Transform.move_x(40), Transform.move_y(14)",
          "Hover glow and move tracking both follow the shifted card.",
          [Transform.move_x(40), Transform.move_y(14)],
          [
            Interactive.mouse_over([
              Background.color(color_rgb(92, 120, 176)),
              Border.color(color_rgb(190, 216, 255)),
              Border.glow(color_rgba(110, 160, 255, 90 / 255), 2),
              Font.color(color(:white))
            ])
          ],
          [Event.on_mouse_move(event(interaction, :transformed_move, "Translated Move"))],
          color_rgb(68, 92, 138)
        ),
        transformed_event_showcase(
          "Rotated Hover",
          "Transform.rotate(16)",
          "Enter, leave, and hover styling all follow the painted angle.",
          [Transform.rotate(16)],
          [
            Interactive.mouse_over([
              Background.color(color_rgb(128, 94, 162)),
              Border.color(color_rgb(228, 198, 255)),
              Border.glow(color_rgba(196, 132, 255, 92 / 255), 2),
              Font.color(color(:white))
            ])
          ],
          [
            Event.on_mouse_enter(event(interaction, :rotated_enter)),
            Event.on_mouse_leave(event(interaction, :rotated_leave))
          ],
          color_rgb(100, 74, 126)
        ),
        transformed_event_showcase(
          "Scaled Press",
          "Transform.scale(1.18)",
          "Hover glow and mouse_down inset both stay on the scaled shape.",
          [Transform.scale(1.18)],
          [
            Interactive.mouse_over([
              Background.color(color_rgb(104, 124, 96)),
              Border.color(color_rgb(220, 236, 204)),
              Border.glow(color_rgba(160, 212, 136, 82 / 255), 2),
              Font.color(color(:white))
            ]),
            Interactive.mouse_down([
              Background.color(color_rgb(72, 88, 64)),
              Border.color(color_rgb(214, 228, 194)),
              Border.inner_shadow(
                offset: {0, 1},
                blur: 6,
                size: 1,
                color: color_rgba(0, 0, 0, 120 / 255)
              ),
              Font.color(color(:white))
            ])
          ],
          [
            Event.on_mouse_down(event(interaction, :scaled_down)),
            Event.on_mouse_up(event(interaction, :scaled_up))
          ],
          color_rgb(86, 104, 78)
        )
      ])
    ])
  end

  defp transformed_event_showcase(
         label,
         transform_note,
         instruction,
         transform_attrs,
         state_attrs,
         event_attrs,
         bg_color
       ) do
    column([width(max(px(238), fill())), spacing(8)], [
      el([Font.size(13), Font.color(title_text()), Font.bold()], text(label)),
      paragraph([width(fill()), spacing(3), Font.size(11), Font.color(body_text())], [
        text(instruction)
      ]),
      el(
        [
          width(fill()),
          padding(12),
          Background.color(panel_bg()),
          Border.rounded(10)
        ],
        column([spacing(8)], [
          el(
            [
              width(fill()),
              height(px(150)),
              Background.color(color_rgb(56, 60, 88)),
              Border.rounded(12)
            ],
            el(
              [
                width(px(128)),
                height(px(82)),
                center_x(),
                center_y(),
                Background.color(color_rgba(255, 255, 255, 8 / 255)),
                Border.width(1),
                Border.color(color_rgba(208, 216, 240, 110 / 255)),
                Border.rounded(12),
                Nearby.in_front(
                  transformed_event_target(
                    label,
                    transform_note,
                    transform_attrs,
                    state_attrs,
                    event_attrs,
                    bg_color
                  )
                )
              ],
              el(
                [
                  center_x(),
                  align_bottom(),
                  Transform.move_y(-8),
                  Font.size(9),
                  Font.color(color_rgba(215, 222, 242, 170 / 255))
                ],
                text("Original slot")
              )
            )
          ),
          el([Font.size(10), Font.color(color_rgb(204, 214, 236))], text(transform_note))
        ])
      )
    ])
  end

  defp transformed_event_target(
         label,
         transform_note,
         transform_attrs,
         state_attrs,
         event_attrs,
         bg_color
       ) do
    el(
      [
        width(px(128)),
        height(px(82)),
        center_x(),
        center_y(),
        padding(12),
        Background.color(bg_color),
        Border.width(1),
        Border.color(color_rgba(245, 248, 255, 120 / 255)),
        Border.rounded(12)
      ] ++ transform_attrs ++ state_attrs ++ event_attrs,
      column([center_x(), center_y(), spacing(5)], [
        el([Font.size(13), Font.color(color(:white))], text(label)),
        el(
          [Font.size(10), Font.color(color_rgba(245, 248, 255, 215 / 255))],
          text(transform_note)
        )
      ])
    )
  end

  # Input helpers

  defp soft_keyboard_targets do
    wrapped_row([width(fill()), spacing_xy(12, 12)], [
      soft_keyboard_text_input(),
      soft_keyboard_button(),
      soft_keyboard_listener_pad()
    ])
  end

  defp soft_keyboard_text_input do
    text_input = solve(Showcase.App, :text_input)

    column([width(max(px(320), fill())), spacing(8)], [
      el([Font.size(12), Font.color(panel_title())], text("Keyboard target: text input")),
      Input.text(
        [
          width(fill()),
          padding_xy(10, 8),
          Font.size(15),
          Font.color(color(:white)),
          Background.color(color_rgb(62, 62, 94)),
          Border.rounded(8),
          Border.width(1),
          Border.color(
            if(text_input.focused?, do: color_rgb(228, 183, 104), else: color_rgb(120, 130, 175))
          ),
          Event.on_change(event(text_input, :changed)),
          Event.on_focus(event(text_input, :focused)),
          Event.on_blur(event(text_input, :blurred))
        ],
        text_input.value
      ),
      el(
        [Font.size(10), Font.color(panel_muted())],
        text("Type directly here or use the virtual keys below.")
      )
    ])
  end

  defp soft_keyboard_button do
    input_button = solve(Showcase.App, :input_button)

    column([width(max(px(220), fill())), spacing(8)], [
      el([Font.size(12), Font.color(panel_title())], text("Keyboard target: button")),
      Input.button(
        [
          width(fill()),
          padding_xy(10, 8),
          Font.size(13),
          Font.color(color_rgb(230, 234, 246)),
          Background.color(color_rgb(58, 62, 90)),
          Border.rounded(8),
          Border.width(1),
          Border.color(
            if(input_button.focused?,
              do: color_rgb(166, 186, 236),
              else: color_rgb(110, 120, 162)
            )
          ),
          Event.on_press(event(input_button, :pressed)),
          Event.on_focus(event(input_button, :focused)),
          Event.on_blur(event(input_button, :blurred)),
          Interactive.mouse_over([
            Background.color(color_rgb(64, 70, 100)),
            Border.color(color_rgb(132, 143, 189))
          ]),
          Interactive.focused([
            Border.color(color_rgb(166, 186, 236)),
            Border.glow(color_rgba(132, 158, 232, 100 / 255), 2)
          ]),
          Interactive.mouse_down([
            Background.color(color_rgb(56, 60, 88)),
            Border.color(color_rgb(176, 190, 228)),
            Transform.move_y(1)
          ])
        ],
        text("Run action")
      ),
      el(
        [Font.size(10), Font.color(panel_muted())],
        text("Use Tab to move focus here, then Enter to press.")
      )
    ])
  end

  defp soft_keyboard_listener_pad do
    key_listener = solve(Showcase.App, :key_listener)

    column([width(max(px(240), fill())), spacing(8)], [
      el([Font.size(12), Font.color(panel_title())], text("Keyboard target: listener")),
      el(
        [
          width(fill()),
          padding(12),
          Background.color(color_rgb(56, 60, 88)),
          Border.rounded(8),
          Border.width(1),
          Border.color(
            if(key_listener.focused?,
              do: color_rgb(176, 196, 244),
              else: color_rgb(112, 122, 164)
            )
          ),
          Event.on_focus(event(key_listener, :focused)),
          Event.on_blur(event(key_listener, :blurred)),
          Event.on_key_down(:enter, event(key_listener, :enter_down)),
          Event.on_key_down(
            [key: :digit_1, mods: [:ctrl], match: :all],
            event(key_listener, :ctrl_digit_1_down)
          ),
          Event.on_key_down(:arrow_left, event(key_listener, :arrow_left_down)),
          Event.on_key_up(:escape, event(key_listener, :escape_up)),
          Event.on_key_press(:space, event(key_listener, :space_press)),
          Interactive.mouse_over([
            Background.color(color_rgb(62, 68, 98)),
            Border.color(color_rgb(138, 148, 190))
          ]),
          Interactive.focused([
            Background.color(color_rgb(66, 74, 106)),
            Border.color(color_rgb(176, 196, 244)),
            Border.glow(color_rgba(132, 158, 232, 110 / 255), 2)
          ])
        ],
        column([spacing(4)], [
          el([Font.size(13), Font.color(color(:white))], text("Keyboard listener pad")),
          el(
            [Font.size(10), Font.color(color_rgb(214, 220, 240))],
            text("Use Tab to focus, then try arrows or Enter.")
          )
        ])
      )
    ])
  end

  defp soft_shift_toggle_key(soft_keyboard) do
    active? = soft_keyboard.shift_active?

    el(
      [
        key(:soft_shift_toggle),
        padding_xy(12, 10),
        width(px(96)),
        Background.color(if(active?, do: color_rgb(92, 118, 76), else: color_rgb(64, 68, 98))),
        Border.rounded(10),
        Border.width(1),
        Border.color(if(active?, do: color_rgb(168, 204, 144), else: color_rgb(132, 140, 188))),
        Font.size(12),
        Font.color(color(:white)),
        Event.on_mouse_down(event(soft_keyboard, :toggle_shift)),
        Interactive.mouse_over([
          Background.color(
            if(active?, do: color_rgb(106, 132, 88), else: color_rgb(76, 82, 112))
          ),
          Border.color(color_rgb(196, 208, 238))
        ]),
        Interactive.mouse_down([
          Background.color(color_rgb(58, 62, 90)),
          Transform.move_y(1)
        ])
      ],
      text(if(active?, do: "Shift On", else: "Shift"))
    )
  end

  defp soft_tab_key(soft_keyboard) do
    soft_special_key_button(
      if(soft_keyboard.shift_active?, do: "Shift+Tab", else: "Tab"),
      [tap: {:key, :tab, soft_key_mods(soft_keyboard)}],
      id: :tab,
      width: px(120),
      background: color_rgb(62, 84, 108),
      hover_background: color_rgb(76, 98, 124),
      border_color: color_rgb(138, 170, 204)
    )
  end

  defp soft_key_mods(soft_keyboard) do
    if soft_keyboard.shift_active?, do: [:shift], else: []
  end

  defp soft_letter_key(letter, lower, upper, key_name, soft_keyboard) do
    shift_active? = soft_keyboard.shift_active?

    popup_content =
      case soft_keyboard.popup do
        ^letter -> soft_alternate_popup(letter, soft_keyboard)
        _other -> nil
      end

    hold_spec =
      if alternate_labels(letter, soft_keyboard.shift_active?) == [],
        do: [],
        else: [hold: {:event, event(soft_keyboard, :show_alternates, letter)}]

    spec =
      [
        tap:
          if(shift_active?,
            do: {:text_and_key, upper, key_name, [:shift]},
            else: {:text_and_key, lower, key_name, []}
          )
      ] ++ hold_spec

    soft_special_key_button(
      if(shift_active?, do: upper, else: lower),
      spec,
      id: {:letter, letter},
      width: px(56),
      popup: popup_content,
      background: color_rgb(68, 74, 108),
      hover_background: color_rgb(82, 88, 126),
      border_color: color_rgb(142, 152, 206)
    )
  end

  defp soft_symbol_key(lower, upper, key_name, soft_keyboard) do
    shift_active? = soft_keyboard.shift_active?

    soft_special_key_button(
      if(shift_active?, do: upper, else: lower),
      [
        tap:
          if(shift_active?,
            do: {:text_and_key, upper, key_name, [:shift]},
            else: {:text_and_key, lower, key_name, []}
          )
      ],
      id: {:symbol, key_name},
      width: px(56),
      background: color_rgb(68, 74, 108),
      hover_background: color_rgb(82, 88, 126),
      border_color: color_rgb(142, 152, 206)
    )
  end

  defp soft_special_key_button(label, spec, opts) do
    attrs = [
      key({:soft_key, Keyword.fetch!(opts, :id)}),
      width(Keyword.get(opts, :width, px(64))),
      padding_xy(12, 10),
      Background.color(Keyword.fetch!(opts, :background)),
      Border.rounded(10),
      Border.width(1),
      Border.color(Keyword.fetch!(opts, :border_color)),
      Font.size(12),
      Font.color(color(:white)),
      Event.virtual_key(spec),
      Interactive.mouse_over([
        Background.color(Keyword.fetch!(opts, :hover_background)),
        Border.color(color_rgb(196, 208, 238))
      ]),
      Interactive.mouse_down([
        Background.color(color_rgb(58, 62, 90)),
        Transform.move_y(1)
      ])
    ]

    attrs =
      case Keyword.get(opts, :mouse_up) do
        nil -> attrs
        mouse_up -> [Event.on_mouse_up(mouse_up) | attrs]
      end

    attrs =
      case Keyword.get(opts, :popup) do
        nil -> attrs
        popup -> [Nearby.above(popup) | attrs]
      end

    el(attrs, text(label))
  end

  defp soft_alternate_popup(letter, soft_keyboard) do
    case alternate_labels(letter, soft_keyboard.shift_active?) do
      [] -> nil
      labels -> soft_alternate_popup_panel(letter, soft_keyboard, labels)
    end
  end

  defp soft_alternate_popup_panel(owner, soft_keyboard, labels) do
    el(
      [
        key({:soft_popup, owner}),
        padding(8),
        Background.color(color_rgb(38, 42, 64)),
        Border.rounded(12),
        Border.width(1),
        Border.color(color_rgb(154, 168, 224))
      ],
      row(
        [spacing(6)],
        Enum.map(labels, fn label ->
          soft_special_key_button(
            label,
            [tap: {:text, label}],
            id: {:popup_key, owner, label},
            width: px(48),
            mouse_up: event(soft_keyboard, :popup_key_selected, label),
            background: color_rgb(82, 72, 118),
            hover_background: color_rgb(98, 84, 134),
            border_color: color_rgb(188, 170, 236)
          )
        end)
      )
    )
  end

  defp popup_label(nil, _shift_active?), do: "none"

  defp popup_label(key, shift_active?) when is_atom(key) do
    label =
      if(shift_active?, do: Atom.to_string(key) |> String.upcase(), else: Atom.to_string(key))

    "#{label} popup"
  end

  defp alternate_labels(:a, true), do: ["Á", "À", "Ä"]
  defp alternate_labels(:a, false), do: ["á", "à", "ä"]
  defp alternate_labels(:e, true), do: ["É", "È", "Ê"]
  defp alternate_labels(:e, false), do: ["é", "è", "ê"]
  defp alternate_labels(:i, true), do: ["Í", "Ì", "Ï"]
  defp alternate_labels(:i, false), do: ["í", "ì", "ï"]
  defp alternate_labels(:o, true), do: ["Ó", "Ò", "Ö"]
  defp alternate_labels(:o, false), do: ["ó", "ò", "ö"]
  defp alternate_labels(:u, true), do: ["Ú", "Ù", "Ü"]
  defp alternate_labels(:u, false), do: ["ú", "ù", "ü"]
  defp alternate_labels(:c, true), do: ["Ç", "Ć", "Č"]
  defp alternate_labels(:c, false), do: ["ç", "ć", "č"]
  defp alternate_labels(:n, true), do: ["Ñ", "Ń", "Ň"]
  defp alternate_labels(:n, false), do: ["ñ", "ń", "ň"]
  defp alternate_labels(_letter, _shift_active?), do: []

  defp multiline_auto_grow_demo(field) do
    {state_label, state_bg, state_text, border_color} = field_status(field)

    el(
      [
        width(fill()),
        padding(14),
        Background.color(panel_bg()),
        Border.rounded(10)
      ],
      column([spacing(10)], [
        Input.multiline(
          [
            width(fill()),
            padding_xy(10, 8),
            Font.size(16),
            Font.color(color(:white)),
            Background.color(color_rgb(62, 62, 94)),
            Border.rounded(8),
            Border.width(1),
            Border.color(border_color),
            Event.on_change(event(field_controller(), :grow_changed)),
            Event.on_focus(event(field_controller(), :grow_focused)),
            Event.on_blur(event(field_controller(), :grow_blurred))
          ],
          field.value
        ),
        el(
          [Font.size(11), Font.color(panel_muted())],
          text(
            "No explicit height is set here, so the multiline input grows to fit wrapped lines and inserted newlines."
          )
        ),
        wrapped_row([width(fill()), spacing_xy(8, 8)], [
          status_chip("State", state_label, state_bg, state_text),
          status_chip(
            "Length",
            String.length(field.value),
            color_rgb(70, 84, 114),
            color_rgb(220, 232, 248)
          ),
          status_chip(
            "Focus",
            field.focus_count,
            color_rgb(64, 74, 106),
            color_rgb(205, 216, 246)
          ),
          status_chip(
            "Blur",
            field.blur_count,
            color_rgb(78, 68, 100),
            color_rgb(228, 212, 246)
          )
        ]),
        paragraph(
          [width(fill()), spacing(3), Font.size(11), Font.color(color_rgb(230, 234, 246))],
          [
            text(field.value)
          ]
        )
      ])
    )
  end

  defp multiline_submit_demo(field) do
    {state_label, state_bg, state_text, border_color} = field_status(field)

    el(
      [
        width(fill()),
        padding(14),
        Background.color(panel_bg()),
        Border.rounded(10)
      ],
      column([spacing(10)], [
        Input.multiline(
          [
            width(fill()),
            padding_xy(10, 8),
            Font.size(16),
            Font.color(color_rgb(228, 232, 246)),
            Background.color(color_rgb(58, 62, 90)),
            Border.rounded(8),
            Border.width(1),
            Border.color(border_color),
            Event.on_change(event(field_controller(), :submit_changed)),
            Event.on_focus(event(field_controller(), :submit_focused)),
            Event.on_blur(event(field_controller(), :submit_blurred)),
            Event.on_key_down(:enter, event(field_controller(), :submit_enter)),
            Interactive.mouse_over([
              Background.color(color_rgb(64, 70, 100)),
              Border.color(color_rgb(132, 143, 189))
            ]),
            Interactive.focused([
              Background.color(color_rgb(70, 78, 112)),
              Border.color(color_rgb(164, 188, 236))
            ])
          ],
          field.value
        ),
        el(
          [Font.size(11), Font.color(panel_muted())],
          text(
            "The Enter keydown handler fires first here, so the default multiline newline is suppressed."
          )
        ),
        wrapped_row([width(fill()), spacing_xy(8, 8)], [
          status_chip("State", state_label, state_bg, state_text),
          status_chip(
            "Enter",
            field.submit_count,
            color_rgb(82, 76, 132),
            color_rgb(238, 232, 252)
          ),
          status_chip(
            "Length",
            String.length(field.value),
            color_rgb(74, 92, 122),
            color_rgb(226, 240, 250)
          ),
          status_chip(
            "Focus",
            field.focus_count,
            color_rgb(64, 82, 96),
            color_rgb(210, 238, 236)
          ),
          status_chip(
            "Blur",
            field.blur_count,
            color_rgb(102, 76, 120),
            color_rgb(246, 230, 248)
          )
        ]),
        el(
          [Font.size(11), Font.color(color_rgb(230, 234, 246))],
          text("Current value: #{field.value}")
        )
      ])
    )
  end

  defp field_status(field) do
    if field.focused? do
      {
        "Focused",
        color_rgb(72, 96, 70),
        color_rgb(227, 244, 223),
        color_rgb(228, 183, 104)
      }
    else
      {
        "Blurred",
        color_rgb(72, 74, 102),
        color_rgb(220, 224, 240),
        color_rgb(120, 130, 175)
      }
    end
  end

  defp field_controller, do: solve(Showcase.App, :multiline_input)

  # Code previews

  defp interactive_states_code do
    ~S"""
    el(
      [
        Interactive.mouse_over([Transform.move_y(-1)]),
        Interactive.mouse_down([Transform.move_y(1)])
      ],
      text("Purely visual pointer states")
    )
    """
  end

  defp hover_compare_code do
    ~S"""
    interaction = solve(Showcase.App, :interaction)

    el(
      [
        Event.on_mouse_enter(event(interaction, :manual_hover_enter)),
        Event.on_mouse_leave(event(interaction, :manual_hover_leave))
      ],
      text("Event-managed hover")
    )

    el(
      [
        Interactive.mouse_over([
          Transform.move_y(-2),
          Transform.scale(1.02)
        ])
      ],
      text("Declarative hover")
    )
    """
  end

  defp mouse_press_code do
    ~S"""
    interaction = solve(Showcase.App, :interaction)

    el(
      [
        Event.on_mouse_down(event(interaction, :mouse_down)),
        Event.on_mouse_up(event(interaction, :mouse_up))
      ],
      text("Track mouse down and up separately")
    )
    """
  end

  defp swipe_code do
    ~S"""
    interaction = solve(Showcase.App, :interaction)

    el(
      [
        Event.on_swipe_up(event(interaction, :swiped, :up)),
        Event.on_swipe_down(event(interaction, :swiped, :down)),
        Event.on_swipe_left(event(interaction, :swiped, :left)),
        Event.on_swipe_right(event(interaction, :swiped, :right))
      ],
      text("Swipe Pad")
    )
    """
  end

  defp transformed_hit_testing_code do
    ~S"""
    interaction = solve(Showcase.App, :interaction)

    el([
      Nearby.in_front(
        el([
          Transform.move_x(40),
          Transform.move_y(14),
          Event.on_mouse_move(event(interaction, :transformed_move, "Translated Move"))
        ], text("Translated Move"))
      )
    ], text("Original slot"))
    """
  end

  defp text_input_code do
    ~S"""
    text_input = solve(Showcase.App, :text_input)

    Input.text(
      [
        Event.on_change(event(text_input, :changed)),
        Event.on_focus(event(text_input, :focused)),
        Event.on_blur(event(text_input, :blurred))
      ],
      text_input.value
    )
    """
  end

  defp multiline_auto_grow_code do
    ~S"""
    multiline_input = solve(Showcase.App, :multiline_input)

    Input.multiline(
      [
        Event.on_change(event(multiline_input, :grow_changed)),
        Event.on_focus(event(multiline_input, :grow_focused)),
        Event.on_blur(event(multiline_input, :grow_blurred))
      ],
      multiline_input.grow.value
    )
    """
  end

  defp multiline_submit_code do
    ~S"""
    multiline_input = solve(Showcase.App, :multiline_input)

    Input.multiline(
      [
        Event.on_change(event(multiline_input, :submit_changed)),
        Event.on_key_down(:enter, event(multiline_input, :submit_enter))
      ],
      multiline_input.submit.value
    )
    """
  end

  defp input_styles_code do
    ~S"""
    Input.text(
      [
        Interactive.mouse_over([Background.color(color(:slate, 600))]),
        Interactive.focused([Border.color(color(:sky, 400))]),
        Interactive.mouse_down([Transform.move_y(1)])
      ],
      "Style showcase input"
    )
    """
  end

  defp input_button_code do
    ~S"""
    input_button = solve(Showcase.App, :input_button)

    Input.button(
      [
        Event.on_press(event(input_button, :pressed)),
        Event.on_focus(event(input_button, :focused)),
        Event.on_blur(event(input_button, :blurred))
      ],
      text("Run action")
    )
    """
  end

  defp key_listener_code do
    ~S"""
    key_listener = solve(Showcase.App, :key_listener)

    el(
      [
        Event.on_key_down(:enter, event(key_listener, :enter_down)),
        Event.on_key_up(:escape, event(key_listener, :escape_up)),
        Event.on_key_press(:space, event(key_listener, :space_press))
      ],
      text("Keyboard listener pad")
    )
    """
  end

  defp virtual_keyboard_code do
    ~S"""
    soft_keyboard = solve(Showcase.App, :soft_keyboard)
    text_input = solve(Showcase.App, :text_input)

    Input.text([Event.on_change(event(text_input, :changed))], text_input.value)

    soft_special_key_button("Tab", [tap: {:key, :tab, []}], id: :tab)

    soft_special_key_button(
      "A",
      [
        tap: {:text_and_key, "a", :a, []},
        hold: {:event, event(soft_keyboard, :show_alternates, :a)}
      ],
      id: {:letter, :a},
      popup: soft_alternate_popup(:a, soft_keyboard)
    )
    """
  end

  # Generic elements

  defp section_title(label) do
    el([Font.size(18), Font.color(title_text())], text(label))
  end

  defp section_copy(content) do
    paragraph([width(fill()), spacing(3), Font.size(13), Font.color(body_text())], [
      text(content)
    ])
  end

  defp interaction_example(title, note, example_id, code, content) do
    View.hover_example(
      example_id,
      code,
      column([width(fill()), spacing(10)], [
        el([Font.size(12), Font.color(body_text()), Font.bold()], text(title)),
        paragraph([width(fill()), spacing(3), Font.size(12), Font.color(body_text())], [
          text(note)
        ]),
        content
      ])
    )
  end

  defp status_chip(label, value, bg, fg) do
    el(
      [padding_each(6, 10, 6, 10), Background.color(bg), Border.rounded(999)],
      el([Font.size(11), Font.color(fg)], text("#{label}: #{value}"))
    )
  end

  # Palette

  defp panel_bg, do: color_rgb(46, 50, 72)
  defp panel_title, do: color_rgb(225, 230, 244)
  defp panel_muted, do: color_rgb(190, 198, 224)
  defp surface_bg, do: color_rgb(58, 62, 90)
  defp surface_hover_bg, do: color_rgb(64, 70, 100)
  defp surface_pressed_bg, do: color_rgb(56, 60, 88)
  defp surface_border, do: color_rgb(110, 120, 162)
  defp surface_hover_border, do: color_rgb(132, 143, 189)
  defp surface_pressed_border, do: color_rgb(176, 190, 228)
  defp manual_hover_idle_bg, do: color_rgb(58, 52, 82)
  defp manual_hover_active_bg, do: color_rgb(88, 72, 122)
  defp manual_hover_idle_border, do: color_rgb(120, 112, 150)
  defp manual_hover_active_border, do: color_rgb(188, 154, 250)
  defp manual_hover_idle_text, do: color_rgb(220, 210, 240)
  defp manual_hover_detail_text, do: color_rgb(225, 215, 245)
  defp declarative_hover_bg, do: color_rgb(52, 70, 84)
  defp declarative_hover_active_bg, do: color_rgb(86, 112, 140)
  defp declarative_hover_border, do: color_rgb(102, 124, 150)
  defp declarative_hover_active_border, do: color_rgb(168, 210, 250)
  defp declarative_hover_text, do: color_rgb(210, 222, 240)
  defp declarative_hover_detail_text, do: color_rgb(214, 228, 246)
  defp stat_down_bg, do: color_rgb(72, 76, 110)
  defp stat_down_text, do: color_rgb(220, 226, 246)
  defp stat_up_bg, do: color_rgb(64, 82, 96)
  defp stat_up_text, do: color_rgb(210, 238, 236)
  defp title_text, do: color_rgb(24, 30, 38)
  defp body_text, do: color_rgb(92, 100, 114)
end
