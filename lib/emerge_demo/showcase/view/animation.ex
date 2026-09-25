defmodule EmergeDemo.Showcase.View.Animation do
  use Emerge.UI
  use Solve.Lookup, :helpers

  alias EmergeDemo.Showcase
  alias EmergeDemo.Showcase.AssetCatalog
  alias EmergeDemo.Showcase.View.AnimationCode

  def layout do
    animation = solve(Showcase.App, :animation)

    column([width(fill()), spacing(28)], [
      example(
        :expansion,
        "Expanding labels",
        "The text changes immediately, while each retained content width eases to its new measurement. Toggle again mid-flight to reverse it.",
        text_expansion(animation.expanded?),
        toggle(
          animation,
          :expanded?,
          if(animation.expanded?, do: "Collapse label", else: "Expand label")
        )
      ),
      example(
        :highlight,
        "SVG highlight sweep",
        "A second copy of the SVG carries a moving white gradient. Dense gradient stops and evenly timed keyframes keep the sweep smooth; transparent ends hide direction changes.",
        svg_highlight(),
        caption("Looping · SVG tint + Nearby.in_front")
      ),
      example(
        :sidebar,
        "Open a sidebar",
        "Animate the retained sidebar width, not a paint-only translation. The workspace gets the remaining space on every frame. Rapid toggles continue from the current width.",
        sidebar(animation.sidebar_open?),
        toggle(
          animation,
          :sidebar_open?,
          if(animation.sidebar_open?, do: "Close sidebar", else: "Open sidebar")
        )
      ),
      example(
        :accordion,
        "Content-sized accordion",
        "No measured pixel height in app state: changing the children changes height(content()). The row below follows the animated layout.",
        accordion(animation.details_open?),
        toggle(
          animation,
          :details_open?,
          if(animation.details_open?, do: "Hide details", else: "Show details")
        )
      ),
      example(
        :notification,
        "Enter and exit",
        "Mount a keyed notification to play animate_enter. Remove it to play animate_exit: native rendering keeps it alive until the exit finishes.",
        notification(animation.notification_visible?),
        toggle(
          animation,
          :notification_visible?,
          if(animation.notification_visible?,
            do: "Dismiss notification",
            else: "Show notification"
          )
        )
      ),
      example(
        :glow,
        "Orbiting highlight",
        "Shadow offsets trace a closed path. The native loop needs no Elixir timer or per-frame state updates.",
        orbiting_glow(),
        caption("Looping · Border.shadow")
      )
    ])
  end

  def text_expansion(expanded?) do
    row([key(:expanding_label), center_x(), center_y(), Font.size(38), Font.bold()], [
      el(
        [key(:first_word), Animation.change([width(content())], 500, :linear)],
        text(if(expanded?, do: "Live ", else: "L"))
      ),
      el(
        [key(:second_word), Animation.change([width(content())], 500, :linear)],
        text(if(expanded?, do: "Preview", else: "P"))
      )
    ])
  end

  @sweep_steps 180
  @sweep_count 3
  @highlight_fps 60
  @highlight_duration div(@sweep_steps * @sweep_count * 1000, @highlight_fps)

  # N keyframes have N - 1 intervals: 541 samples over 9 seconds = 60 Hz.
  # Extra travel outside the SVG makes each direction change fully transparent.
  @highlight_keyframes (for frame <- 0..(@sweep_steps * @sweep_count) do
                          progress = rem(frame, @sweep_steps) / @sweep_steps
                          direction = rem(div(frame, @sweep_steps), @sweep_count) - 1
                          position = -12 + 204 * progress

                          stops =
                            for stop <- 0..180 do
                              alpha = Kernel.max(0, 1 - abs(stop - position) / 8)
                              color_rgba(255, 255, 255, alpha)
                            end

                          angle = direction * 60 * Kernel.max(0, 1 - progress * 1.5)
                          [Svg.color(gradient(stops, angle))]
                        end)

  # This tree is static: normalize the dense keyframes once, not on each toggle.
  @svg_highlight (
                   source = AssetCatalog.template_cloud()

                   el(
                     [
                       center_x(),
                       center_y(),
                       width(px(200)),
                       height(px(140)),
                       Nearby.in_front(
                         svg(
                           [
                             width(fill()),
                             height(fill()),
                             Animation.animate(
                               @highlight_keyframes,
                               @highlight_duration,
                               :linear,
                               :loop
                             )
                           ],
                           source
                         )
                       )
                     ],
                     svg(
                       [width(fill()), height(fill()), Svg.color(color_rgb(43, 145, 203))],
                       source
                     )
                   )
                 )

  def svg_highlight, do: @svg_highlight

  def sidebar(open?) do
    row([width(fill()), height(fill())], [
      el(
        [
          key(:sidebar),
          Animation.change([width(px(if(open?, do: 150, else: 0)))], 350, :ease_in_out),
          height(fill()),
          Background.color(color_rgb(48, 64, 104))
        ],
        if open? do
          column([padding(14), spacing(16), Font.size(14)], [
            text("Workspace"),
            text("Overview"),
            text("Projects"),
            text("Settings")
          ])
        else
          none()
        end
      ),
      column([key(:workspace), width(fill()), height(fill()), padding(16), spacing(12)], [
        text("Your workspace"),
        el(
          [
            width(fill()),
            height(px(12)),
            Background.color(color_rgb(64, 83, 122)),
            Border.rounded(6)
          ],
          none()
        ),
        el(
          [
            width(fill()),
            height(px(12)),
            Background.color(color_rgb(48, 64, 96)),
            Border.rounded(6)
          ],
          none()
        ),
        paragraph([width(fill()), Font.size(13), Font.color(muted())], [
          text("This area resizes with the sidebar.")
        ])
      ])
    ])
  end

  def accordion(open?) do
    column([width(fill()), center_y(), spacing(12), padding(16)], [
      el([key(:heading)], text("Animation details")),
      el(
        [
          key(:details),
          width(fill()),
          Animation.change([height(content())], 450, :ease_in_out),
          Background.color(color_rgb(48, 64, 104)),
          Border.rounded(8)
        ],
        if open? do
          paragraph([width(fill()), padding(14), Font.size(14)], [
            text(
              "Content can grow, wrap, or disappear. Emerge animates the resolved height, and siblings move with it."
            )
          ])
        else
          none()
        end
      ),
      el([key(:following)], caption("↑ This row follows the content height"))
    ])
  end

  def notification(visible?) do
    el(
      [width(fill()), height(fill()), padding(18)],
      if visible? do
        el(
          [
            key(:notification),
            width(fill()),
            padding(16),
            Border.rounded(10),
            Background.color(color_rgb(39, 105, 94)),
            Animation.animate_enter(
              [
                [Transform.move_y(24), Transform.alpha(0)],
                [Transform.move_y(0), Transform.alpha(1)]
              ],
              350,
              :ease_out
            ),
            Animation.animate_exit(
              [
                [Transform.move_y(0), Transform.alpha(1)],
                [Transform.move_y(24), Transform.alpha(0)]
              ],
              300,
              :ease_in
            )
          ],
          text("Changes saved")
        )
      else
        none()
      end
    )
  end

  def orbiting_glow do
    positions = [{0, -3}, {3, -3}, {3, 0}, {3, 3}, {0, 3}, {-3, 3}, {-3, 0}, {-3, -3}, {0, -3}]

    keyframes =
      Enum.map(positions, fn offset ->
        [Border.shadow(offset: offset, blur: 12, size: 2, color: color_rgb(43, 145, 203))]
      end)

    el(
      [
        center_x(),
        center_y(),
        padding(18),
        Border.rounded(10),
        Background.color(color_rgb(20, 26, 40)),
        Animation.animate(keyframes, 2000, :linear, :loop)
      ],
      text("Highlighted")
    )
  end

  defp example(id, title, description, demo, controls) do
    column([key({:animation, id}), width(fill()), spacing(12)], [
      el([Font.size(23), Font.bold(), Font.color(color_rgb(28, 38, 60))], text(title)),
      paragraph([width(fill()), Font.size(14), Font.color(color_rgb(92, 100, 114))], [
        text(description)
      ]),
      # Keep the code and demo together even in a narrow window. The outer page
      # scrolls vertically, and this pair scrolls horizontally if necessary.
      el(
        [width(fill()), scrollbar_x()],
        row([width(max(px(860), fill())), spacing(18)], [
          AnimationCode.layout(id),
          column([width(fill()), spacing(12)], [
            el(
              [Font.size(12), Font.bold(), Font.color(color_rgb(72, 96, 168))],
              text("LIVE DEMO")
            ),
            el(
              [
                width(fill()),
                height(px(220)),
                Background.color(color_rgb(24, 31, 47)),
                Border.rounded(12),
                Font.size(16),
                Font.color(color_rgb(239, 244, 255))
              ],
              demo
            ),
            controls
          ])
        ])
      )
    ])
  end

  defp toggle(animation, field, label) do
    Input.button(
      [
        Event.on_press(event(animation, :toggle, field)),
        padding_xy(14, 10),
        Background.color(color_rgb(238, 243, 255)),
        Font.color(color_rgb(45, 70, 142)),
        Font.size(14),
        Border.rounded(8),
        Interactive.mouse_over([Background.color(color_rgb(220, 230, 255))]),
        Interactive.focused([Border.glow(color_rgb(116, 138, 210), 2)]),
        Interactive.mouse_down([Transform.move_y(1)])
      ],
      text(label)
    )
  end

  defp caption(value),
    do: paragraph([width(fill()), Font.size(13), Font.color(muted())], [text(value)])

  defp muted, do: color_rgb(148, 163, 191)
end
