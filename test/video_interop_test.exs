defmodule EmergeDemo.VideoInteropTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions

  alias EmergeDemo.{BinarySource, PrimeSource}
  alias Membrane.Buffer

  def consume_decoded_dmabuf(frame, _target, test_pid) do
    summary = %{
      coded_size: {frame.coded_width, frame.coded_height},
      stream_storage: frame.format.storage,
      stream_acquire_sync: frame.format.acquire_sync,
      stream_colorimetry: frame.format.colorimetry,
      frame_acquire_sync: frame.acquire_sync,
      descriptor: frame.storage,
      leased?: not is_nil(frame.lease),
      validation: VideoInterop.validate(frame)
    }

    release_result = VideoInterop.release(frame)
    send(test_pid, {:decoded_dmabuf_frame, summary, release_result})
    :ok
  end

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

  test "main viewport exposes separate codec, decoded DMA-BUF, GPU, and binary targets" do
    config = Application.get_env(:emerge_demo, EmergeDemo.Application, [])
    Application.put_env(:emerge_demo, EmergeDemo.Application, prime_validation?: true)
    on_exit(fn -> Application.put_env(:emerge_demo, EmergeDemo.Application, config) end)

    assert {:ok, state, _opts} = EmergeDemo.mount([])

    assert state.video_targets == %{
             dma_buf: {:streaming, :headless_prime_validation},
             binary: {:streaming, :headless_binary_validation},
             h264: {:streaming, :h264_file_playback},
             h264_dmabuf: {:streaming, :h264_dmabuf_playback},
             h265_dmabuf: {:streaming, :h265_dmabuf_playback}
           }
  end

  test "pipeline keeps standard H.264 playback and adds H.264 and H.265 DMA-BUF playback" do
    assert {[
              spec: [
                _dma_buf_branch,
                _binary_branch,
                {h264_branch, group: :h264_playback},
                {h264_dmabuf_branch, group: :h264_dmabuf_playback},
                {h265_dmabuf_branch, group: :h265_dmabuf_playback}
              ]
            ], state} = EmergeDemo.VideoPipeline.handle_init(%{}, [])

    assert h264_branch.children
           |> Enum.map(&elem(&1, 0))
           |> MapSet.new() ==
             MapSet.new([
               :h264_file,
               :h264_parser,
               :h264_decoder,
               :h264_converter,
               :h264_realtimer,
               :h264_frame_converter,
               :h264_sink
             ])

    assert h264_dmabuf_branch.children
           |> Enum.map(&elem(&1, 0))
           |> MapSet.new() ==
             MapSet.new([
               :h264_dmabuf_file,
               :h264_dmabuf_parser,
               :h264_dmabuf_realtimer,
               :h264_dmabuf_decoder,
               :h264_dmabuf_sink
             ])

    assert h265_dmabuf_branch.children
           |> Enum.map(&elem(&1, 0))
           |> MapSet.new() ==
             MapSet.new([
               :h265_dmabuf_file,
               :h265_dmabuf_parser,
               :h265_dmabuf_realtimer,
               :h265_dmabuf_decoder,
               :h265_dmabuf_sink
             ])

    assert state == %{
             sources: %{dma_buf: nil, binary: nil},
             notify: nil,
             viewport_closed?: false,
             restarting_playbacks: MapSet.new()
           }
  end

  test "bundled H.264 clip decodes to a valid owned RGBA8888 frame" do
    spec =
      child(:file, %Membrane.File.Source{
        location: EmergeDemo.VideoPipeline.h264_source_path(),
        content_format: Membrane.H264
      })
      |> child(:parser, %Membrane.H264.Parser{
        output_alignment: :au,
        output_stream_structure: :annexb,
        generate_best_effort_timestamps: %{framerate: {24, 1}}
      })
      |> child(:decoder, Membrane.H264.FFmpeg.Decoder)
      |> child(:converter, %Membrane.FFmpeg.SWScale.Converter{format: :RGBA})
      |> child(:realtimer, Membrane.Realtimer)
      |> child(:frame_converter, EmergeDemo.RawVideoToVideoInterop)
      |> child(:sink, Membrane.Testing.Sink)

    capture_log(fn ->
      pipeline = Membrane.Testing.Pipeline.start_link_supervised!(spec: spec)

      assert_sink_stream_format(
        pipeline,
        :sink,
        %VideoInterop.Format{
          width: 480,
          height: 270,
          framerate: {24, 1},
          storage: %VideoInterop.Binary.Format{pixel_format: :rgba8888},
          acquire_sync: :implicit,
          alpha_mode: :straight
        },
        5_000
      )

      assert_sink_buffer(
        pipeline,
        :sink,
        %Buffer{
          payload:
            %VideoInterop.Frame{
              coded_width: 480,
              coded_height: 270,
              storage: %VideoInterop.Binary{data: pixels},
              lease: nil
            } = frame
        },
        5_000
      )

      assert byte_size(pixels) == 480 * 270 * 4
      assert :ok = VideoInterop.validate(frame)
      assert :ok = VideoInterop.release(frame)
      assert :ok = Membrane.Testing.Pipeline.terminate(pipeline)
    end)
  end

  test "bundled H.264 clip emits valid leased NV12 DMA-BUF frames when VAAPI is available" do
    if File.exists?(EmergeDemo.Application.video_decode_drm_node()) do
      spec =
        child(:file, %Membrane.File.Source{
          location: EmergeDemo.VideoPipeline.h264_source_path(),
          content_format: Membrane.H264
        })
        |> child(:parser, %Membrane.H264.Parser{
          output_alignment: :au,
          output_stream_structure: :annexb,
          generate_best_effort_timestamps: %{framerate: {24, 1}}
        })
        |> child(:realtimer, Membrane.Realtimer)
        |> child(:decoder, %Membrane.H264.Decoder{
          output: :dmabuf,
          decoder: :vaapi,
          hw_device: EmergeDemo.Application.video_decode_drm_node(),
          max_in_flight: 4
        })
        |> child(:sink, %Membrane.VideoInterop.Sink{
          submit: {__MODULE__, :consume_decoded_dmabuf, [self()]},
          target: :test
        })

      capture_log(fn ->
        pipeline = Membrane.Testing.Pipeline.start_link_supervised!(spec: spec)

        Enum.each(1..6, fn _index ->
          assert_receive {:decoded_dmabuf_frame,
                          %{
                            coded_size: {480, 270},
                            stream_storage: %VideoInterop.DMABuf.Format{
                              fourcc: 0x3231_564E,
                              modifier: modifier
                            },
                            stream_acquire_sync: :sync_file,
                            stream_colorimetry: %VideoInterop.Colorimetry{
                              primaries: :bt709,
                              transfer: :bt709,
                              matrix: :bt709,
                              range: :limited,
                              chroma_location: :left
                            },
                            frame_acquire_sync: %VideoInterop.SyncFile{
                              acquire_fence_fd: acquire_fence_fd
                            },
                            descriptor: %VideoInterop.DMABuf.Descriptor{
                              objects: objects,
                              layers: layers
                            },
                            leased?: true,
                            validation: :ok
                          }, :ok},
                         5_000

          assert modifier != :per_buffer
          assert acquire_fence_fd >= 0
          assert objects != []
          assert layers != []
        end)

        assert :ok = Membrane.Testing.Pipeline.terminate(pipeline)
      end)
    end
  end

  test "bundled H.265 clip emits valid leased NV12 DMA-BUF frames when VAAPI is available" do
    if File.exists?(EmergeDemo.Application.video_decode_drm_node()) do
      spec =
        child(:file, %Membrane.File.Source{
          location: EmergeDemo.VideoPipeline.h265_source_path(),
          content_format: Membrane.H265
        })
        |> child(:parser, %Membrane.H265.Parser{
          output_alignment: :au,
          output_stream_structure: :annexb,
          generate_best_effort_timestamps: %{framerate: {24, 1}}
        })
        |> child(:realtimer, Membrane.Realtimer)
        |> child(:decoder, %Membrane.H265.Decoder{
          output: :dmabuf,
          decoder: :vaapi,
          hw_device: EmergeDemo.Application.video_decode_drm_node(),
          max_in_flight: 4
        })
        |> child(:sink, %Membrane.VideoInterop.Sink{
          submit: {__MODULE__, :consume_decoded_dmabuf, [self()]},
          target: :test
        })

      capture_log(fn ->
        pipeline = Membrane.Testing.Pipeline.start_link_supervised!(spec: spec)

        Enum.each(1..177, fn _index ->
          assert_receive {:decoded_dmabuf_frame,
                          %{
                            coded_size: {480, 270},
                            stream_storage: %VideoInterop.DMABuf.Format{
                              fourcc: 0x3231_564E,
                              modifier: modifier
                            },
                            stream_acquire_sync: :sync_file,
                            stream_colorimetry: %VideoInterop.Colorimetry{
                              primaries: :bt709,
                              transfer: :bt709,
                              matrix: :bt709,
                              range: :limited,
                              chroma_location: :left
                            },
                            frame_acquire_sync: %VideoInterop.SyncFile{
                              acquire_fence_fd: acquire_fence_fd
                            },
                            descriptor: %VideoInterop.DMABuf.Descriptor{
                              objects: objects,
                              layers: layers
                            },
                            leased?: true,
                            validation: :ok
                          }, :ok},
                         5_000

          assert modifier != :per_buffer
          assert acquire_fence_fd >= 0
          assert objects != []
          assert layers != []
        end)

        assert :ok = Membrane.Testing.Pipeline.terminate(pipeline)
      end)
    end
  end

  test "codec playback branches restart independently after end of stream" do
    state = %{
      sources: %{dma_buf: nil, binary: nil},
      notify: nil,
      viewport_closed?: false,
      restarting_playbacks: MapSet.new()
    }

    assert {[remove_children: :h264_playback], restarting} =
             EmergeDemo.VideoPipeline.handle_element_end_of_stream(
               :h264_sink,
               :input,
               %{},
               state
             )

    assert MapSet.member?(restarting.restarting_playbacks, :h264)

    assert {[spec: {_branch, group: :h264_playback}], restarted} =
             EmergeDemo.VideoPipeline.handle_child_terminated(
               :h264_sink,
               %{children: %{}},
               restarting
             )

    assert MapSet.size(restarted.restarting_playbacks) == 0

    assert {[remove_children: :h264_dmabuf_playback], dmabuf_restarting} =
             EmergeDemo.VideoPipeline.handle_element_end_of_stream(
               :h264_dmabuf_sink,
               :input,
               %{},
               state
             )

    assert MapSet.member?(dmabuf_restarting.restarting_playbacks, :h264_dmabuf)

    assert {[spec: {_branch, group: :h264_dmabuf_playback}], dmabuf_restarted} =
             EmergeDemo.VideoPipeline.handle_child_terminated(
               :h264_dmabuf_sink,
               %{children: %{}},
               dmabuf_restarting
             )

    assert MapSet.size(dmabuf_restarted.restarting_playbacks) == 0

    assert {[remove_children: :h265_dmabuf_playback], h265_restarting} =
             EmergeDemo.VideoPipeline.handle_element_end_of_stream(
               :h265_dmabuf_sink,
               :input,
               %{},
               state
             )

    assert MapSet.member?(h265_restarting.restarting_playbacks, :h265_dmabuf)

    assert {[spec: {_branch, group: :h265_dmabuf_playback}], h265_restarted} =
             EmergeDemo.VideoPipeline.handle_child_terminated(
               :h265_dmabuf_sink,
               %{children: %{}},
               h265_restarting
             )

    assert MapSet.size(h265_restarted.restarting_playbacks) == 0
  end

  test "pipeline stops producers quietly when the main viewport closes" do
    state = %{
      sources: %{dma_buf: self(), binary: self()},
      notify: self(),
      viewport_closed?: false,
      restarting_playbacks: MapSet.new()
    }

    log =
      capture_log(fn ->
        assert {[
                  remove_children: [
                    :h264_playback,
                    :h264_dmabuf_playback,
                    :h265_dmabuf_playback
                  ]
                ], closed_state} =
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
      viewport_closed?: false,
      restarting_playbacks: MapSet.new()
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
