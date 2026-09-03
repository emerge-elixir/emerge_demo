defmodule EmergeDemo do
  @moduledoc """
  Desktop example shell built with `Emerge` and `Solve`.
  """

  use Emerge
  use Solve.Lookup, handle_info: :manual

  alias EmergeDemo.Showcase.AssetCatalog

  @dma_buf_target :headless_prime_validation
  @binary_target :headless_binary_validation
  @h264_target :h264_file_playback
  @h264_dmabuf_target :h264_dmabuf_playback
  @h265_dmabuf_target :h265_dmabuf_playback

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

    video_targets =
      if EmergeDemo.Application.prime_validation?() do
        %{
          dma_buf: {:streaming, @dma_buf_target},
          binary: {:streaming, @binary_target},
          h264: {:streaming, @h264_target},
          h264_dmabuf: {:streaming, @h264_dmabuf_target},
          h265_dmabuf: {:streaming, @h265_dmabuf_target}
        }
      else
        %{
          dma_buf: {{:error, :video_interop_disabled}, nil},
          binary: {{:error, :video_interop_disabled}, nil},
          h264: {{:error, :video_interop_disabled}, nil},
          h264_dmabuf: {{:error, :video_interop_disabled}, nil},
          h265_dmabuf: {{:error, :video_interop_disabled}, nil}
        }
      end

    {:ok, %{video_targets: video_targets}, viewport_opts}
  end

  @impl Viewport
  def render(state), do: EmergeDemo.AppSelector.View.layout(state.video_targets)

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
