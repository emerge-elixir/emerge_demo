defmodule EmergeDemo.AppSelector.View do
  use Emerge.UI
  use Solve.Lookup, :helpers

  alias EmergeDemo.AppSelector
  alias EmergeDemo.Showcase
  alias EmergeDemo.Todo

  @shell_surface color(:white)
  @shell_line color_rgb(230, 230, 230)
  @shell_text color_rgb(24, 24, 32)
  @shell_muted color_rgb(108, 108, 122)
  @shell_active_bg color_rgb(245, 245, 249)
  @shell_active_border color_rgb(208, 208, 220)
  @shell_focus_border color_rgb(158, 174, 220)
  @shell_focus_glow color_rgba(116, 138, 210, 0.28)

  def layout do
    selector = solve(AppSelector.App, :screens)

    el(
      root_attrs(selector),
      active_screen()
    )
  end

  defp app_selector() do
    el(
      [padding(16)],
      menu_button()
    )
  end

  defp menu_button() do
    selector = solve(AppSelector.App, :screens)

    Input.button(
      [
        Event.on_press(event(selector, :toggle_menu)),
        if(!selector.menu_open?, do: Event.on_mouse_leave(event(selector, :close_menu))),
        Nearby.below(menu()),
        width(px(40)),
        height(px(40)),
        center_x(),
        center_y(),
        Background.color(color(:white)),
        Interactive.mouse_over([Background.color(color(:gray, 100))]),
        Interactive.focused([
          Border.color(@shell_focus_border),
          Border.glow(@shell_focus_glow, 2)
        ]),
        Interactive.mouse_down([Background.color(color(:gray, 200))]),
        Border.rounded(999),
        Border.width(1),
        Border.color(@shell_line),
        Border.shadow(offset: {0, 8}, blur: 24, size: 0, color: color_rgba(0, 0, 0, 0.12))
      ],
      hamburger_icon()
    )
  end

  defp hamburger_icon() do
    column(
      [center_x(), center_y(), spacing(4)],
      Enum.map(1..3, fn _ ->
        el(
          [
            width(px(14)),
            height(px(2)),
            Background.color(@shell_text),
            Border.rounded(999)
          ],
          none()
        )
      end)
    )
  end

  defp menu() do
    selector = solve(AppSelector.App, :screens)

    if selector.menu_open? do
      screen_items =
        Enum.map(
          selector.screens,
          &menu_item(
            &1.id == selector.current,
            &1.label,
            event(selector, :set_screen, &1.id)
          )
        )

      el(
        [
          Event.on_mouse_leave(event(selector, :close_menu)),
          Animation.animate_enter([[Transform.alpha(0.1)], [Transform.alpha(1.0)]], 100, :linear),
          Animation.animate_exit([[Transform.alpha(1.0)], [Transform.alpha(0.1)]], 100, :linear),
          width(px(196)),
          padding(8),
          spacing(4),
          Background.color(@shell_surface),
          Border.rounded(14),
          Border.width(1),
          Border.color(@shell_line),
          Border.shadow(offset: {0, 12}, blur: 28, size: 0, color: color_rgba(0, 0, 0, 0.12))
        ],
        column(
          [spacing(4)],
          screen_items ++ [menu_divider(), scale_control(selector), rotate_control(selector)]
        )
      )
    else
      none()
    end
  end

  defp menu_item(active?, label, on_press) do
    Input.button(
      [
        Event.on_press(on_press),
        width(fill()),
        padding_each(10, 12, 10, 12),
        Background.color(if(active?, do: @shell_active_bg, else: @shell_surface)),
        Border.rounded(10),
        Border.width(1),
        Border.color(if(active?, do: @shell_active_border, else: color_rgba(255, 255, 255, 0.0))),
        Interactive.focused([
          Border.color(@shell_focus_border),
          Border.glow(@shell_focus_glow, 2)
        ]),
        Font.size(13),
        Font.color(if(active?, do: @shell_text, else: @shell_muted))
      ],
      text(label)
    )
  end

  defp menu_divider do
    el(
      [
        width(fill()),
        height(px(1)),
        Background.color(@shell_line)
      ],
      none()
    )
  end

  defp scale_control(selector) do
    column([width(fill()), padding_each(6, 2, 2, 2), spacing(6)], [
      el([Font.size(11), Font.color(@shell_muted), Font.bold()], text("Scale")),
      row(
        [width(fill()), spacing(4)],
        Enum.map(selector.scale_options, fn option ->
          selector_option_button(
            option.value == selector.scale,
            option,
            event(selector, :set_scale, option.value)
          )
        end)
      )
    ])
  end

  defp rotate_control(selector) do
    column([width(fill()), padding_each(4, 2, 2, 2), spacing(6)], [
      el([Font.size(11), Font.color(@shell_muted), Font.bold()], text("Rotate")),
      row(
        [width(fill()), spacing(4)],
        Enum.map(selector.rotate_options, fn option ->
          selector_option_button(
            option.value == selector.rotate,
            option,
            event(selector, :set_rotate, option.value)
          )
        end)
      )
    ])
  end

  defp selector_option_button(active?, option, on_press) do
    Input.button(
      [
        Event.on_press(on_press),
        width(fill()),
        padding_each(7, 0, 7, 0),
        Background.color(if(active?, do: @shell_active_bg, else: @shell_surface)),
        Border.rounded(8),
        Border.width(1),
        Border.color(if(active?, do: @shell_active_border, else: @shell_line)),
        Interactive.mouse_over([
          Background.color(if(active?, do: @shell_active_bg, else: color_rgb(248, 248, 251))),
          Border.color(if(active?, do: @shell_active_border, else: color_rgb(210, 214, 226)))
        ]),
        Interactive.focused([
          Border.color(@shell_focus_border),
          Border.glow(@shell_focus_glow, 2)
        ]),
        Interactive.mouse_down([Background.color(color(:gray, 200))]),
        Font.size(11),
        Font.color(if(active?, do: @shell_text, else: @shell_muted))
      ],
      el([center_x()], text(option.label))
    )
  end

  defp active_screen() do
    selector = solve(AppSelector.App, :screens)

    case selector.current do
      :showcase -> Showcase.View.layout()
      :todo -> Todo.View.layout()
      _other -> Todo.View.layout()
    end
  end

  defp root_attrs(selector) do
    [
      width(fill()),
      height(fill()),
      clip_nearby(),
      Nearby.in_front(app_selector())
    ] ++ root_scale_attrs(selector.scale) ++ root_rotate_attrs(selector.rotate)
  end

  defp root_scale_attrs(1.0), do: []
  defp root_scale_attrs(value), do: [scale(value)]

  defp root_rotate_attrs(value) when value == 0.0, do: []
  defp root_rotate_attrs(value), do: [rotate(value)]
end
