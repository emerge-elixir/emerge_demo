defmodule EmergeDemo.Showcase.View.VideoInterop do
  @moduledoc false

  use Emerge.UI

  alias EmergeDemo.Showcase.View.{CodeBlock, Example}
  require CodeBlock

  def layout(%{
        dma_buf: gpu,
        binary: binary,
        h264: h264,
        h264_dmabuf: h264_gpu,
        h265_dmabuf: h265_gpu
      }) do
    column([width(fill()), spacing(32)], [
      Example.heading("First, separate the frame from its source"),
      Example.prose(
        "The video element names a target. Every producer below sends VideoInterop frames to a Membrane sink, which submits them to that target. A failed stream does not stop the other examples."
      ),
      stream_example(
        "Start with pixels the CPU owns",
        "The raster renderer produces an owned RGBA8888 binary. No borrowed GPU storage needs to stay alive after submission. Watch the moving source arrive in the video element.",
        :binary,
        binary_code(),
        "RGBA8888 · owned storage",
        binary
      ),
      stream_example(
        "Let a file supply the frames",
        "Replace the renderer with a file source, H.264 parser, and software decoder. Convert the result to RGBA and pace it before submission. The target element does not need to know how the frame was decoded.",
        :h264,
        h264_code(),
        "H.264 · software decode",
        h264
      ),
      Example.heading("Now borrow GPU storage instead"),
      Example.prose(
        "A DMA-BUF frame carries a lease and, when required, a synchronization fence. Submission consumes that frame; do not release it again afterwards. These paths need compatible Linux GPU hardware."
      ),
      stream_example(
        "Decode H.264 without a CPU pixel copy",
        "Keep the file and parser, but use VAAPI decoding with DMA-BUF output. The resulting NV12 frame is leased until the consumer finishes using it.",
        :h264_dmabuf,
        h264_dmabuf_code(),
        "NV12 · VAAPI · sync-file",
        h264_gpu
      ),
      stream_example(
        "Change the codec, keep the frame contract",
        "An H.265 parser and decoder produce the same kind of VideoInterop frame. This branch has its own target and leases, so it can run alongside H.264.",
        :h265_dmabuf,
        h265_dmabuf_code(),
        "NV12 · HEVC · sync-file",
        h265_gpu
      ),
      stream_example(
        "A renderer can be a producer too",
        "The headless GPU renderer exports its scene as a DMA-BUF. OpenGL or Vulkan can produce it, and the visible viewport imports it through the same submission API.",
        :dma_buf,
        gpu_code(),
        "ABGR8888 · GPU rendering",
        gpu
      ),
      Example.heading("Who keeps a borrowed frame alive?"),
      Example.prose(
        "The consumer may retain the displayed frame. On shutdown, quiesce the consumer and release queued frames before waiting for the producer's borrowed pool to drain. The validation script exercises all four OpenGL/Vulkan routes, hide/show, and restart."
      ),
      Example.prose(
        "The bundled H.264 and H.265 clips are derived from Big Buck Bunny. © Blender Foundation, CC BY 3.0; attribution is in priv/video/README.md."
      )
    ])
  end

  def layout(_targets) do
    layout(
      Map.new([:dma_buf, :binary, :h264, :h264_dmabuf, :h265_dmabuf], &{&1, {:starting, nil}})
    )
  end

  defp stream_example(title, explanation, id, code, format, {status, target}) do
    Example.layout(
      title,
      explanation,
      {:video_interop, id},
      code,
      column([width(fill()), spacing(12)], [
        row([width(fill()), spacing(12)], [
          paragraph([width(fill()), Font.size(13), Font.color(color_rgb(80, 89, 105))], [
            text(format)
          ]),
          status_badge(status)
        ]),
        video_panel(target, status)
      ])
    )
  end

  defp binary_code do
    CodeBlock.snippet(~S"""
    {:ok, producer} = EmergeSkia.start(
      otp_app: :emerge_demo,
      backend: :headless,
      rendering_api: :raster,
      width: 640, height: 420,
      headless: [
        target: ingress,
        mode: :binary,
        pixel_format: :rgba8888
      ]
    )
    EmergeSkia.upload_tree(producer, scene)

    # The Membrane sink submits each received frame.
    Emerge.submit_video_frame(
      viewport, :headless_binary_validation, frame
    )
    video([width(fill()), height(fill())],
      :headless_binary_validation)
    """)
  end

  defp h264_code do
    CodeBlock.snippet(~S"""
    import Membrane.ChildrenSpec

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
    |> child(:rgba, %Membrane.FFmpeg.SWScale.Converter{format: :RGBA})
    |> child(:pace, Membrane.Realtimer)
    |> child(:frames, EmergeDemo.RawVideoToVideoInterop)
    |> child(:sink, %Membrane.VideoInterop.Sink{
      submit: {EmergeDemo.VideoPipeline, :submit, []},
      target: :h264_file_playback
    })
    """)
  end

  defp h264_dmabuf_code do
    CodeBlock.snippet(~S"""
    import Membrane.ChildrenSpec

    # After the H.264 file source, parser, and pacer:
    child(:decoder, %Membrane.H264.Decoder{
      decoder: :vaapi,
      output: :dmabuf,
      hw_device: EmergeDemo.Application.video_decode_drm_node(),
      max_in_flight: 4
    })
    |> child(:sink, %Membrane.VideoInterop.Sink{
      submit: {EmergeDemo.VideoPipeline, :submit, []},
      target: :h264_dmabuf_playback
    })

    video([width(fill()), height(fill())],
      :h264_dmabuf_playback)
    """)
  end

  defp h265_dmabuf_code do
    CodeBlock.snippet(~S"""
    import Membrane.ChildrenSpec

    # Use the H.265 file source and Membrane.H265.Parser.
    child(:decoder, %Membrane.H265.Decoder{
      decoder: :vaapi,
      output: :dmabuf,
      hw_device: EmergeDemo.Application.video_decode_drm_node(),
      max_in_flight: 4
    })
    |> child(:sink, %Membrane.VideoInterop.Sink{
      submit: {EmergeDemo.VideoPipeline, :submit, []},
      target: :h265_dmabuf_playback
    })

    video([width(fill()), height(fill())],
      :h265_dmabuf_playback)
    """)
  end

  defp gpu_code do
    CodeBlock.snippet(~S"""
    # The Membrane source must accept the renderer's tag.
    %Membrane.VideoInterop.Source{
      message_tag: :emerge_skia_frame
    }

    {:ok, producer} = EmergeSkia.start(
      otp_app: :emerge_demo,
      backend: :headless,
      rendering_api: :vulkan, # or :opengl
      width: 640, height: 420,
      headless: [
        mode: :prime,
        target: ingress,
        prime: [max_in_flight: 3, drm_node: drm_node]
      ]
    )
    EmergeSkia.upload_tree(producer, scene)

    # Submission consumes the borrowed frame.
    Emerge.submit_video_frame(
      viewport, :headless_prime_validation, frame
    )
    video([width(fill()), height(fill())],
      :headless_prime_validation)
    """)
  end

  defp video_panel(_target, {:error, reason}) do
    el(
      [width(fill()), height(px(280)), padding(20), Font.color(color_rgb(153, 27, 27))],
      paragraph([width(fill())], [
        text("Stream failed: #{failure_reason(reason)}")
      ])
    )
  end

  defp video_panel(target, _status) when is_atom(target) and not is_nil(target) do
    el(
      [
        width(fill()),
        height(px(280)),
        padding(8),
        Background.color(color_rgb(14, 20, 36)),
        Border.rounded(12)
      ],
      video(
        [
          width(fill()),
          height(fill()),
          image_fit(:contain),
          Background.color(color_rgb(5, 9, 18)),
          Border.rounded(8)
        ],
        target
      )
    )
  end

  defp video_panel(_target, _status) do
    el(
      [
        width(fill()),
        height(px(280)),
        center_x(),
        center_y(),
        padding(20),
        Background.color(color_rgb(14, 20, 36)),
        Border.rounded(12),
        Font.size(13),
        Font.color(color_rgb(190, 199, 220))
      ],
      text("Waiting for frames…")
    )
  end

  defp failure_reason(:dma_buf_requires_linux), do: "DMA-BUF requires Linux."
  defp failure_reason(:renderer_start_failed), do: "The requested renderer could not start."
  defp failure_reason({%{__exception__: true} = error, _stack}), do: Exception.message(error)
  defp failure_reason(reason), do: inspect(reason, limit: 3, printable_limit: 120)

  defp status_badge(:streaming),
    do: badge("STREAMING", color_rgb(220, 252, 231), color_rgb(22, 101, 52))

  defp status_badge(:waiting),
    do: badge("WAITING", color_rgb(224, 242, 254), color_rgb(3, 105, 161))

  defp status_badge(:starting),
    do: badge("STARTING", color_rgb(254, 249, 195), color_rgb(133, 77, 14))

  defp status_badge({:error, _reason}),
    do: badge("FAILED", color_rgb(254, 226, 226), color_rgb(153, 27, 27))

  defp status_badge(_status),
    do: badge("WAITING", color_rgb(224, 242, 254), color_rgb(3, 105, 161))

  defp badge(label, background, foreground) do
    el(
      [
        padding_each(7, 11, 7, 11),
        Background.color(background),
        Border.rounded(999),
        Font.size(12),
        Font.bold(),
        Font.color(foreground)
      ],
      text(label)
    )
  end
end
