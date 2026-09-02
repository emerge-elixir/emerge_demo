defmodule EmergeDemo.VideoInteropTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias EmergeDemo.{BinarySource, PrimeSource}

  test "GPU source sends DMA-BUF VideoInterop frames to its Membrane ingress" do
    assert {:ok, opts} = PrimeSource.mount(video_output_target: self())

    refute opts[:viewport]
    assert opts[:emerge_skia][:backend] == :headless
    assert opts[:emerge_skia][:rendering_api] == :opengl
    assert opts[:emerge_skia][:width] == 640
    assert opts[:emerge_skia][:height] == 420
    assert opts[:emerge_skia][:renderer_stats_log]
    assert opts[:emerge_skia][:headless][:target] == self()
    assert opts[:emerge_skia][:headless][:mode] == :prime
    assert opts[:emerge_skia][:headless][:prime][:max_in_flight] == 3
  end

  test "CPU source sends RGBA8888 binary VideoInterop frames to its Membrane ingress" do
    assert {:ok, opts} = BinarySource.mount(video_output_target: self())

    renderer = opts[:emerge_skia]
    assert renderer[:backend] == :headless
    assert renderer[:rendering_api] == :raster
    assert renderer[:width] == 640
    assert renderer[:height] == 420
    assert renderer[:renderer_stats_log]

    assert renderer[:headless] == [
             mode: :binary,
             target: self(),
             target_fps: 30,
             pixel_format: :rgba8888
           ]
  end

  test "CPU source emits valid owned RGBA8888 frames" do
    assert {:ok, viewport} = BinarySource.start_link(video_output_target: self())

    on_exit(fn ->
      if Process.alive?(viewport), do: GenServer.stop(viewport)
    end)

    assert_receive {:emerge_skia_frame,
                    %VideoInterop.Frame{
                      coded_width: 640,
                      coded_height: 420,
                      format: %VideoInterop.Format{
                        storage: %VideoInterop.Binary.Format{pixel_format: :rgba8888},
                        acquire_sync: :implicit
                      },
                      storage: %VideoInterop.Binary{data: pixels},
                      acquire_sync: :implicit,
                      lease: nil
                    } = frame},
                   2_000

    assert byte_size(pixels) == 640 * 420 * 4
    assert :ok = VideoInterop.validate(frame)
    assert :ok = VideoInterop.release(frame)
    assert :ok = GenServer.stop(viewport)
  end

  test "main viewport exposes atom targets for DMA-BUF and binary imports" do
    config = Application.get_env(:emerge_demo, EmergeDemo.Application, [])
    Application.put_env(:emerge_demo, EmergeDemo.Application, prime_validation?: true)
    on_exit(fn -> Application.put_env(:emerge_demo, EmergeDemo.Application, config) end)

    assert {:ok, state, _opts} = EmergeDemo.mount([])

    assert state.video_targets == %{
             dma_buf: {:streaming, :headless_prime_validation},
             binary: {:streaming, :headless_binary_validation}
           }
  end

  test "pipeline defines independent DMA-BUF and binary transport branches" do
    assert {[spec: [_dma_buf_branch, _binary_branch]], state} =
             EmergeDemo.VideoPipeline.handle_init(%{}, [])

    assert state == %{
             sources: %{dma_buf: nil, binary: nil},
             notify: nil,
             viewport_closed?: false
           }
  end

  test "pipeline stops producers quietly when the main viewport closes" do
    state = %{
      sources: %{dma_buf: self(), binary: self()},
      notify: self(),
      viewport_closed?: false
    }

    log =
      capture_log(fn ->
        assert {[], closed_state} =
                 EmergeDemo.VideoPipeline.handle_child_notification(
                   {:video_interop_sink_error, :viewport_not_ready},
                   :dma_buf_sink,
                   %{},
                   state
                 )

        assert closed_state.sources == %{dma_buf: nil, binary: nil}
        assert closed_state.viewport_closed?

        assert {[], ^closed_state} =
                 EmergeDemo.VideoPipeline.handle_child_notification(
                   {:video_interop_sink_error, :viewport_unavailable},
                   :binary_sink,
                   %{},
                   closed_state
                 )

        assert {[], ^closed_state} =
                 EmergeDemo.VideoPipeline.handle_info(
                   {:start_video_source, :binary},
                   %{},
                   closed_state
                 )

        assert {[], ^closed_state} =
                 EmergeDemo.VideoPipeline.handle_info(
                   {:video_interop_source_ready, self()},
                   %{},
                   closed_state
                 )
      end)

    assert log == ""
    refute_receive {:video_interop_sink_error, _reason}
  end

  test "pipeline forwards unexpected child errors without returning an invalid action" do
    state = %{
      sources: %{dma_buf: nil, binary: nil},
      notify: self(),
      viewport_closed?: false
    }

    log =
      capture_log(fn ->
        assert {[], ^state} =
                 EmergeDemo.VideoPipeline.handle_child_notification(
                   {:video_interop_sink_error, :rejected},
                   :binary_sink,
                   %{},
                   state
                 )

        assert_receive {:video_interop_sink_error, :rejected}
      end)

    assert log =~ "video_interop_sink_error: :rejected"
  end

  test "pipeline callback consumes frames while the viewport is unavailable" do
    frame =
      VideoInterop.Frame.binary(<<0, 0, 0, 255>>,
        width: 1,
        height: 1,
        pixel_format: :rgba8888
      )

    assert {:error, :viewport_unavailable} =
             EmergeDemo.VideoPipeline.submit(frame, :headless_binary_validation)
  end
end
