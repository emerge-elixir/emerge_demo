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

  for source_name <- [:dma_buf_source, :binary_source] do
    test "#{source_name} accepts the headless producer's actual frame message" do
      {[spec: branches], _state} = EmergeDemo.VideoPipeline.handle_init(%{children: %{}}, [])

      source_opts =
        branches
        |> Enum.take(2)
        |> Enum.flat_map(fn {branch, _opts} -> branch.children end)
        |> Enum.find_value(fn
          {unquote(source_name), opts, _metadata} -> opts
          _other -> nil
        end)

      assert %Membrane.VideoInterop.Source{message_tag: :emerge_skia_frame} = source_opts

      # Use the production ingress options, not hand-written matching tags. Sending a real
      # raster producer through each ingress catches the silent message-drop regression
      # without requiring a GPU. The live showcase separately exercises DMA-BUF leases.
      capture_log(fn ->
        pipeline =
          Membrane.Testing.Pipeline.start_link_supervised!(
            spec: child(:source, source_opts) |> child(:sink, Membrane.Testing.Sink)
          )

        assert_receive {:video_interop_source_ready, ingress}, 2_000
        assert {:ok, viewport} = BinarySource.start_link(video_output_target: ingress)

        on_exit(fn ->
          if Process.alive?(viewport), do: GenServer.stop(viewport)
        end)

        assert_sink_buffer(
          pipeline,
          :sink,
          %Buffer{
            payload: %VideoInterop.Frame{storage: %VideoInterop.Binary{data: pixels}} = frame
          },
          3_000
        )

        assert byte_size(pixels) == 640 * 420 * 4
        assert :ok = VideoInterop.validate(frame)
        assert :ok = VideoInterop.release(frame)
        assert :ok = GenServer.stop(viewport)
        assert :ok = Membrane.Testing.Pipeline.terminate(pipeline)
      end)
    end
  end

  test "main viewport exposes separate codec, decoded DMA-BUF, GPU, and binary targets" do
    assert {:ok, state, _opts} = EmergeDemo.mount([])

    assert state.video_targets == %{
             dma_buf: {:starting, :headless_prime_validation},
             binary: {:starting, :headless_binary_validation},
             h264: {:starting, :h264_file_playback},
             h264_dmabuf: {:starting, :h264_dmabuf_playback},
             h265_dmabuf: {:starting, :h265_dmabuf_playback}
           }
  end

  test "pipeline keeps standard H.264 playback and adds H.264 and H.265 DMA-BUF playback" do
    assert {[
              spec: [
                _dma_buf_branch,
                _binary_branch,
                {h264_branch, group: :h264_playback, crash_group_mode: :temporary},
                {h264_dmabuf_branch, group: :h264_dmabuf_playback, crash_group_mode: :temporary},
                {h265_dmabuf_branch, group: :h265_dmabuf_playback, crash_group_mode: :temporary}
              ]
            ], state} = EmergeDemo.VideoPipeline.handle_init(%{children: %{}}, [])

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
               :h264_dmabuf_gate,
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
               :h265_dmabuf_gate,
               :h265_dmabuf_decoder,
               :h265_dmabuf_sink
             ])

    assert is_reference(state.viewport_monitor)

    assert state == %{
             sources: %{dma_buf: nil, binary: nil},
             notify: nil,
             viewport_monitor: state.viewport_monitor,
             viewport_closed?: false,
             draining_sinks: MapSet.new(),
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
      draining_sinks: MapSet.new(),
      restarting_playbacks: MapSet.new()
    }

    assert {[remove_children: :h264_playback], restarting} =
             EmergeDemo.VideoPipeline.handle_element_end_of_stream(
               :h264_sink,
               :input,
               %{children: %{}},
               state
             )

    assert MapSet.member?(restarting.restarting_playbacks, :h264)

    assert {[spec: {_branch, group: :h264_playback, crash_group_mode: :temporary}], restarted} =
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
               %{children: %{}},
               state
             )

    assert MapSet.member?(dmabuf_restarting.restarting_playbacks, :h264_dmabuf)

    assert {[spec: {_branch, group: :h264_dmabuf_playback, crash_group_mode: :temporary}],
            dmabuf_restarted} =
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
               %{children: %{}},
               state
             )

    assert MapSet.member?(h265_restarting.restarting_playbacks, :h265_dmabuf)

    assert {[spec: {_branch, group: :h265_dmabuf_playback, crash_group_mode: :temporary}],
            h265_restarted} =
             EmergeDemo.VideoPipeline.handle_child_terminated(
               :h265_dmabuf_sink,
               %{children: %{}},
               h265_restarting
             )

    assert MapSet.size(h265_restarted.restarting_playbacks) == 0
  end

  for reason <- [:viewport_not_ready, :viewport_unavailable] do
    test "pipeline stops producers and terminates quietly when #{reason} arrives first" do
      supervisor =
        start_supervised!(
          {DynamicSupervisor, name: EmergeDemo.VideoSupervisor, strategy: :one_for_one}
        )

      producers =
        for name <- [PrimeSource, BinarySource] do
          {:ok, producer} =
            DynamicSupervisor.start_child(supervisor, {Task, fn -> Process.sleep(:infinity) end})

          Process.register(producer, name)
          {producer, Process.monitor(producer)}
        end

      state = %{
        sources: %{dma_buf: self(), binary: self()},
        notify: self(),
        viewport_closed?: false,
        draining_sinks: MapSet.new(),
        restarting_playbacks: MapSet.new([:h264])
      }

      log =
        capture_log(fn ->
          assert {[terminate: :normal], closed_state} =
                   EmergeDemo.VideoPipeline.handle_child_notification(
                     {:video_interop_sink_error, unquote(reason)},
                     :dma_buf_sink,
                     %{children: %{}},
                     state
                   )

          assert closed_state.sources == %{dma_buf: nil, binary: nil}
          assert closed_state.viewport_closed?
          assert closed_state.restarting_playbacks == MapSet.new()

          for reason <- [:viewport_unavailable, :viewport_not_ready] do
            assert {[], ^closed_state} =
                     EmergeDemo.VideoPipeline.handle_child_notification(
                       {:video_interop_sink_error, reason},
                       :binary_sink,
                       %{children: %{}},
                       closed_state
                     )
          end

          assert {[], ^closed_state} =
                   EmergeDemo.VideoPipeline.handle_info(
                     {:start_video_source, :binary},
                     %{children: %{}},
                     closed_state
                   )

          assert {[], ^closed_state} =
                   EmergeDemo.VideoPipeline.handle_info(
                     {:video_interop_source_ready, self()},
                     %{children: %{}},
                     closed_state
                   )

          assert {[], ^closed_state} =
                   EmergeDemo.VideoPipeline.handle_element_end_of_stream(
                     :h264_sink,
                     :input,
                     %{children: %{}},
                     closed_state
                   )

          assert {[], ^closed_state} =
                   EmergeDemo.VideoPipeline.handle_child_terminated(
                     :h264_sink,
                     %{children: %{}},
                     closed_state
                   )
        end)

      for {producer, monitor} <- producers do
        assert_receive {:DOWN, ^monitor, :process, ^producer, :shutdown}
      end

      assert DynamicSupervisor.count_children(supervisor).active == 0
      assert log == ""
      refute_receive {:video_interop_sink_error, _reason}
    end
  end

  test "viewport monitor triggers graceful termination without waiting for a frame" do
    viewport = start_supervised!({Task, fn -> Process.sleep(:infinity) end})
    Process.register(viewport, EmergeDemo)
    {_actions, state} = EmergeDemo.VideoPipeline.handle_init(%{children: %{}}, [])
    monitor = state.viewport_monitor

    unrelated_down = {:DOWN, make_ref(), :process, self(), :normal}

    assert {[], ^state} =
             EmergeDemo.VideoPipeline.handle_info(unrelated_down, %{children: %{}}, state)

    Process.exit(viewport, :shutdown)
    assert_receive {:DOWN, ^monitor, :process, _object, :shutdown} = down

    assert {[terminate: :normal], closed_state} =
             EmergeDemo.VideoPipeline.handle_info(down, %{children: %{}}, state)

    assert closed_state.viewport_closed?

    assert {[], ^closed_state} =
             EmergeDemo.VideoPipeline.handle_info(down, %{children: %{}}, closed_state)
  end

  test "pipeline also terminates if the viewport closed before initialization" do
    {_actions, state} = EmergeDemo.VideoPipeline.handle_init(%{children: %{}}, [])
    monitor = state.viewport_monitor
    assert_receive {:DOWN, ^monitor, :process, _object, :noproc} = down

    assert {[terminate: :normal], %{viewport_closed?: true}} =
             EmergeDemo.VideoPipeline.handle_info(down, %{children: %{}}, state)
  end

  test "viewport not ready during startup is not treated as a window close" do
    Process.register(self(), EmergeDemo)
    {_actions, state} = EmergeDemo.VideoPipeline.handle_init(%{children: %{}}, [])

    assert {[], ^state} =
             EmergeDemo.VideoPipeline.handle_child_notification(
               {:video_interop_sink_error, :viewport_not_ready},
               :binary_sink,
               %{children: %{}},
               state
             )
  end

  test "closing the viewport gracefully stops the supervised pipeline and its ingress branches" do
    assert EmergeDemo.VideoPipeline.child_spec([]).restart == :transient
    viewport = start_supervised!({Task, fn -> receive do: (:close -> :ok) end})
    Process.register(viewport, EmergeDemo)

    log =
      capture_log(fn ->
        # No VideoSupervisor is started, so this exercises the real Membrane branches
        # without starting native headless renderers.
        {:ok, supervisor, pipeline} = start_supervised(EmergeDemo.VideoPipeline)

        children =
          for child <- [:dma_buf_source, :dma_buf_sink, :binary_source, :binary_sink] do
            Membrane.Testing.Pipeline.get_child_pid!(pipeline, child)
          end

        monitors = for pid <- children ++ [pipeline, supervisor], do: {pid, Process.monitor(pid)}
        send(viewport, :close)

        for {pid, monitor} <- monitors do
          assert_receive {:DOWN, ^monitor, :process, ^pid, :normal}, 5_000
        end

        refute Process.whereis(EmergeDemo.VideoPipeline)
      end)

    refute log =~ "video_interop_sink_error"
  end

  test "shutdown waits for both hardware sinks to consume decoder flush output" do
    {_actions, state} = EmergeDemo.VideoPipeline.handle_init(%{}, [])

    ctx = %{
      children: %{
        h264_dmabuf_gate: %{terminating?: false},
        h265_dmabuf_gate: %{terminating?: false}
      }
    }

    assert {[
              notify_child: {:h264_dmabuf_gate, :drain},
              notify_child: {:h265_dmabuf_gate, :drain}
            ], draining} = EmergeDemo.VideoPipeline.handle_terminate_request(ctx, state)

    assert draining.viewport_closed?
    assert draining.draining_sinks == MapSet.new([:h264_dmabuf_sink, :h265_dmabuf_sink])
    assert {[], ^draining} = EmergeDemo.VideoPipeline.handle_terminate_request(ctx, draining)

    assert {[], half_drained} =
             EmergeDemo.VideoPipeline.handle_element_end_of_stream(
               :h264_dmabuf_sink,
               :input,
               ctx,
               draining
             )

    assert half_drained.draining_sinks == MapSet.new([:h265_dmabuf_sink])

    assert {[terminate: :normal], drained} =
             EmergeDemo.VideoPipeline.handle_element_end_of_stream(
               :h265_dmabuf_sink,
               :input,
               ctx,
               half_drained
             )

    assert drained.draining_sinks == MapSet.new()
  end

  test "shutdown skips removed branches and finishes if a draining branch crashes" do
    {_actions, state} = EmergeDemo.VideoPipeline.handle_init(%{}, [])

    ctx = %{
      children: %{
        h264_dmabuf_gate: %{terminating?: true},
        h265_dmabuf_gate: %{terminating?: false}
      }
    }

    assert {[notify_child: {:h265_dmabuf_gate, :drain}], draining} =
             EmergeDemo.VideoPipeline.handle_terminate_request(ctx, state)

    assert {[terminate: :normal], _state} =
             EmergeDemo.VideoPipeline.handle_crash_group_down(
               :h265_dmabuf_playback,
               %{crash_reason: :decoder_failed},
               draining
             )
  end

  test "closing during hardware playback drains all decoder leases without quarantine" do
    if File.exists?(EmergeDemo.Application.video_decode_drm_node()) do
      viewport = start_supervised!({Task, fn -> receive do: (:close -> :ok) end})
      Process.register(viewport, EmergeDemo)

      log =
        capture_log(fn ->
          {:ok, supervisor, pipeline} = start_supervised(EmergeDemo.VideoPipeline)

          decoder_processes =
            Enum.flat_map([:h264_dmabuf_decoder, :h265_dmabuf_decoder], fn name ->
              decoder = Membrane.Testing.Pipeline.get_child_pid!(pipeline, name)
              state = await_decoder_frames(decoder)
              [decoder, state.lease_owner, state.release_dispatcher_custodian]
            end)

          monitors =
            for pid <- decoder_processes ++ [pipeline, supervisor],
                do: {pid, Process.monitor(pid)}

          send(viewport, :close)

          for {pid, monitor} <- monitors do
            assert_receive {:DOWN, ^monitor, :process, ^pid, :normal}, 5_000
          end

          refute Membrane.VideoTranscode.Decoder.Native.release_dispatcher_quarantined()
        end)

      refute log =~ "video_interop_shutdown_failed"
      refute log =~ "video_interop_sink_error"
    end
  end

  test "explicit termination uses the same cleanup as closing the window" do
    {_actions, state} = EmergeDemo.VideoPipeline.handle_init(%{children: %{}}, [])

    assert {[terminate: :normal], %{viewport_closed?: true}} =
             EmergeDemo.VideoPipeline.handle_terminate_request(%{children: %{}}, state)
  end

  test "pipeline forwards unexpected child errors without returning an invalid action" do
    state = %{
      sources: %{dma_buf: nil, binary: nil},
      notify: self(),
      viewport_closed?: false,
      draining_sinks: MapSet.new(),
      restarting_playbacks: MapSet.new()
    }

    log =
      capture_log(fn ->
        assert {[], ^state} =
                 EmergeDemo.VideoPipeline.handle_child_notification(
                   {:video_interop_sink_error, :rejected},
                   :binary_sink,
                   %{children: %{}},
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

  test "a failed hardware branch reports its own status without stopping the pipeline" do
    Process.register(self(), EmergeDemo)
    {_actions, state} = EmergeDemo.VideoPipeline.handle_init(%{children: %{}}, [])

    assert {[], ^state} =
             EmergeDemo.VideoPipeline.handle_crash_group_down(
               :h264_dmabuf_playback,
               %{crash_reason: :unsupported},
               state
             )

    assert_receive {:video_status, :h264_dmabuf_playback, {:error, :unsupported}}
    refute_receive {:video_status, :headless_binary_validation, _}
    refute state.viewport_closed?
  end

  defp await_decoder_frames(decoder, attempts \\ 250) do
    state = :sys.get_state(decoder).internal_state

    if state.lease_owner && VideoInterop.LeaseOwner.stats(state.lease_owner).issued_leases >= 3 do
      state
    else
      assert attempts > 0, "decoder did not produce frames before shutdown"
      Process.sleep(20)
      await_decoder_frames(decoder, attempts - 1)
    end
  end
end
