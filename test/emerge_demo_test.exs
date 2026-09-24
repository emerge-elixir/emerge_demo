defmodule EmergeDemoTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.AssetCatalog

  test "handle_solve_updated schedules viewport rerender" do
    state = %{
      __emerge__: %Emerge.Runtime.Viewport.State{module: EmergeDemo}
    }

    assert {:ok, next_state} =
             EmergeDemo.handle_solve_updated(%{EmergeDemo.Todo.App => [:entries]}, state)

    assert next_state.__emerge__.dirty?
    assert next_state.__emerge__.flush_scheduled?
    assert_receive {:"$gen_cast", {:emerge_viewport, :flush}}
  end

  test "stream failure changes only its card and duplicate status does not rerender" do
    {:ok, initial, _opts} = EmergeDemo.mount([])
    state = Map.put(initial, :__emerge__, %Emerge.Runtime.Viewport.State{module: EmergeDemo})
    message = {:video_status, :h264_dmabuf_playback, {:error, :unsupported}}
    assert {:noreply, next} = EmergeDemo.handle_info(message, state)
    assert next.video_targets.binary == state.video_targets.binary
    assert next.video_targets.h264_dmabuf == {{:error, :unsupported}, :h264_dmabuf_playback}
    assert_receive {:"$gen_cast", {:emerge_viewport, :flush}}
    assert {:noreply, ^next} = EmergeDemo.handle_info(message, next)
    refute_receive {:"$gen_cast", {:emerge_viewport, :flush}}
  end

  test "mount configures the platform renderer" do
    {backend, rendering_api} =
      if :os.type() == {:unix, :darwin}, do: {:macos, :raster}, else: {:wayland, :vulkan}

    assert {:ok,
            %{
              video_targets: %{
                dma_buf: {:starting, :headless_prime_validation},
                binary: {:starting, :headless_binary_validation},
                h264: {:starting, :h264_file_playback},
                h264_dmabuf: {:starting, :h264_dmabuf_playback},
                h265_dmabuf: {:starting, :h265_dmabuf_playback}
              }
            }, opts} = EmergeDemo.mount([])

    assert opts[:emerge_skia] == [
             otp_app: :emerge_demo,
             backend: backend,
             title: "Emerge Example",
             rendering_api: rendering_api,
             assets: AssetCatalog.renderer_assets_config(),
             renderer_cache: [enabled: true],
             renderer_stats_log: true,
             render_log: false
           ]
  end

  test "DMA-BUF source has an independently configured rendering API" do
    assert {:ok, opts} = EmergeDemo.PrimeSource.mount(video_output_target: self())
    renderer_opts = opts[:emerge_skia]

    assert renderer_opts[:rendering_api] == :opengl

    assert renderer_opts[:headless][:prime] == [
             max_in_flight: 3,
             on_backpressure: :drop_new
           ]
  end

  test "dev children include the hot reloader" do
    assert [{Emerge.Runtime.CodeReloader, opts}] =
             EmergeDemo.Application.children(:dev)
             |> Enum.filter(fn
               {Emerge.Runtime.CodeReloader, _opts} -> true
               _other -> false
             end)

    assert opts[:reloadable_apps] == [:emerge_demo]
    assert Enum.all?(opts[:dirs], &is_binary/1)
  end

  test "dev children always include the video pipeline and source supervisor" do
    children = EmergeDemo.Application.children(:dev)

    assert children
           |> Enum.take(4)
           |> Enum.map(&child_module/1) == [
             EmergeDemo.Todo.App,
             EmergeDemo.Showcase.App,
             EmergeDemo.AppSelector.App,
             EmergeDemo
           ]

    refute Enum.any?(children, &(child_module(&1) == EmergeDemo.PrimeSource))
    refute Enum.any?(children, &(child_module(&1) == EmergeDemo.BinarySource))
    assert EmergeDemo.VideoPipeline in children

    assert {DynamicSupervisor, strategy: :one_for_one, name: EmergeDemo.VideoSupervisor} in children
  end

  defp child_module(%{start: {module, :start_link, _args}}), do: module
  defp child_module({module, _opts}), do: module
  defp child_module(module) when is_atom(module), do: module
end
