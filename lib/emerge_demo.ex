defmodule EmergeDemo do
  @moduledoc """
  Desktop example shell built with `Emerge` and `Solve`.
  """

  use Emerge
  use Solve.Lookup, handle_info: :manual

  alias EmergeDemo.Showcase.AssetCatalog

  @video_target :headless_prime_validation

  @impl Viewport
  def mount(opts) do
    viewport_opts =
      Keyword.merge(
        [
          emerge_skia: [
            otp_app: :emerge_demo,
            backend: :wayland,
            title: "Emerge Example",
            rendering_api: EmergeDemo.Application.main_rendering_api(),
            # backend: :drm,
            # drm_card: "/dev/dri/card0",
            assets: AssetCatalog.renderer_assets_config(),
            renderer_cache: [enabled: true],
            renderer_stats_log: true,
            render_log: false
          ]
        ],
        opts
      )

    video =
      if EmergeDemo.Application.prime_validation?(),
        do: {:streaming, @video_target},
        else: {{:error, :prime_validation_disabled}, nil}

    {:ok, %{video: video}, viewport_opts}
  end

  @impl Viewport
  def render(state), do: EmergeDemo.AppSelector.View.layout(state.video)

  @impl Viewport
  def handle_info(%Solve.Message{} = message, state) do
    updated = handle_message(message)

    if map_size(updated) == 0 do
      {:noreply, state}
    else
      {:ok, state} = handle_solve_updated(updated, state)
      {:noreply, state}
    end
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl Solve.Lookup
  def handle_solve_updated(_updated, state) do
    {:ok, Viewport.rerender(state)}
  end
end
