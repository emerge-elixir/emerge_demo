defmodule EmergeDemo.PrimeMatrixRoute do
  use Emerge

  @width 640
  @height 420
  @frame_pause_ms 33

  def mount(opts), do: {:ok, opts}
  def render, do: el([], none())

  def run(["--" | args]), do: run(args)

  def run([producer_name, main_name]) do
    producer_api = parse_api!(producer_name)
    main_api = parse_api!(main_name)
    drm_node = System.get_env("EMERGE_DEMO_PRIME_DRM_NODE") || "/dev/dri/renderD128"
    before = resources()

    {:ok, main} =
      EmergeSkia.start(
        otp_app: :emerge_demo,
        backend: :wayland,
        rendering_api: main_api,
        width: @width,
        height: @height,
        renderer_cache: [enabled: true],
        stats: true
      )

    {:ok, target} =
      EmergeSkia.video_target(main,
        id: "prime-matrix",
        width: @width,
        height: @height,
        mode: :prime
      )

    EmergeSkia.upload_tree(main, consumer_tree(target))
    Process.sleep(250)

    {:ok, source} =
      EmergeSkia.start(
        otp_app: :emerge_demo,
        backend: :headless,
        rendering_api: producer_api,
        width: @width,
        height: @height,
        renderer_cache: [enabled: true],
        stats: true,
        headless: [
          mode: :prime,
          prime: [drm_node: drm_node, max_in_flight: 3]
        ]
      )

    {:ok, first_connection} =
      EmergeSkia.HeadlessPrimeSession.connect(source, target,
        notify: self(),
        acquire_sync: :sync_file
      )

    await_connection(first_connection)
    soak(source, 6)
    await_first_frame(first_connection)
    assert_solid_capture!(main, <<0, 0, 255, 255>>, "warmup")
    assert_submitted_pixels!(main, <<0, 0, 255, 255>>, "warmup")
    steady = resources()

    {:ok, _source_warm_stats} = EmergeSkia.stats(source, :take)
    {:ok, _main_warm_stats} = EmergeSkia.stats(main, :take)
    soak_frame_count = soak_frames()
    soak_fps = soak(source, soak_frame_count)
    soak_pixel = soak_expected_pixel(soak_frame_count)
    assert_soak_rate!(soak_fps)
    assert_solid_capture!(main, soak_pixel, "animated soak")
    assert_submitted_pixels!(main, soak_pixel, "animated-soak")
    write_screenshots!(main, producer_api, main_api, "animated-soak", soak_pixel)
    telemetry = assert_frame_telemetry!(source, main, soak_frame_count)
    assert_steady_resource_bounds!(steady, resources())

    # Hidden video must not strand producer leases. Frames sent while hidden are retired, and the
    # same stream becomes live again when the target returns to the scene.
    EmergeSkia.upload_tree(main, hidden_tree())
    Process.sleep(100)

    Enum.each(
      [{255, 0, 0}, {0, 128, 0}, {255, 0, 0}, {0, 128, 0}, {255, 0, 0}],
      &render_source(source, &1)
    )

    EmergeSkia.upload_tree(main, consumer_tree(target))
    render_source(source, {0, 0, 255})
    render_source(source, {255, 0, 0})
    assert_solid_capture!(main, <<255, 0, 0, 255>>, "hide/show")
    assert_submitted_pixels!(main, <<255, 0, 0, 255>>, "hide-show")

    :ok = EmergeSkia.HeadlessPrimeSession.disconnect(source)

    {:ok, second_connection} =
      EmergeSkia.HeadlessPrimeSession.connect(source, target,
        notify: self(),
        acquire_sync: :sync_file
      )

    await_connection(second_connection)

    Enum.each(
      [{0, 128, 0}, {0, 0, 255}, {0, 128, 0}, {0, 0, 255}, {0, 128, 0}],
      &render_source(source, &1)
    )

    await_first_frame(second_connection)
    assert_solid_capture!(main, <<0, 128, 0, 255>>, "reconnect")
    assert_submitted_pixels!(main, <<0, 128, 0, 255>>, "reconnect")
    write_screenshots!(main, producer_api, main_api, "reconnect", <<0, 128, 0, 255>>)

    :ok = EmergeSkia.HeadlessPrimeSession.disconnect(source)
    :ok = EmergeSkia.stop(source)
    :ok = EmergeSkia.stop(main)
    source = nil
    main = nil
    target = nil
    _ = {source, main, target}
    :erlang.garbage_collect(self())

    validate_renderer_restart!(producer_api, main_api, drm_node)
    :erlang.garbage_collect(self())
    Process.sleep(100)

    after_resources = resources()
    assert_fd_bound!(before, after_resources)

    IO.puts(
      "prime_matrix_route=ok producer=#{producer_api} main=#{main_api} " <>
        "soak_fps=#{Float.round(soak_fps, 2)} " <>
        "source_frames=#{telemetry.source_frames} main_frames=#{telemetry.main_frames} " <>
        "fds=#{before.fds}->#{after_resources.fds} rss_kb=#{before.rss_kb}->#{after_resources.rss_kb}"
    )
  end

  def run(other), do: raise("expected producer and main APIs, got: #{inspect(other)}")

  defp validate_renderer_restart!(producer_api, main_api, drm_node) do
    width = @width
    height = @height
    expected_pixel = <<0, 128, 0, 255>>

    {:ok, main} =
      EmergeSkia.start(
        otp_app: :emerge_demo,
        backend: :wayland,
        rendering_api: main_api,
        width: width,
        height: height,
        renderer_cache: [enabled: true]
      )

    {:ok, target} =
      EmergeSkia.video_target(main,
        id: "prime-matrix-restart",
        width: width,
        height: height,
        mode: :prime
      )

    EmergeSkia.upload_tree(main, consumer_tree(target, width, height))
    Process.sleep(250)

    {:ok, source} =
      EmergeSkia.start(
        otp_app: :emerge_demo,
        backend: :headless,
        rendering_api: producer_api,
        width: width,
        height: height,
        renderer_cache: [enabled: true],
        headless: [
          mode: :prime,
          prime: [drm_node: drm_node, max_in_flight: 3]
        ]
      )

    {:ok, connection} =
      EmergeSkia.HeadlessPrimeSession.connect(source, target,
        notify: self(),
        acquire_sync: :sync_file
      )

    await_connection(connection)

    Enum.each(1..6, fn _ ->
      EmergeSkia.upload_tree(source, source_tree({0, 128, 0}, width, height))
      Process.sleep(@frame_pause_ms)
    end)

    await_first_frame(connection)
    assert_submitted_pixels!(main, expected_pixel, "renderer restart", width, height)
    _target_keepalive = target.ref
    :ok = EmergeSkia.HeadlessPrimeSession.disconnect(source)
    :ok = EmergeSkia.stop(source)
    :ok = EmergeSkia.stop(main)
    source = nil
    main = nil
    target = nil
    _ = {source, main, target}
  end

  defp parse_api!("opengl"), do: :opengl
  defp parse_api!("vulkan"), do: :vulkan
  defp parse_api!(other), do: raise("unsupported rendering API #{inspect(other)}")

  defp consumer_tree(target), do: consumer_tree(target, @width, @height)

  defp consumer_tree(target, viewport_width, viewport_height) do
    el(
      [
        width(px(viewport_width)),
        height(px(viewport_height)),
        Background.color(:black)
      ],
      video([width(fill()), height(fill()), image_fit(:cover)], target)
    )
  end

  defp hidden_tree do
    el([width(px(@width)), height(px(@height)), Background.color(:black)], none())
  end

  defp source_tree(color), do: source_tree(color, @width, @height)

  defp source_tree({red, green, blue}, viewport_width, viewport_height) do
    el(
      [
        width(px(viewport_width)),
        height(px(viewport_height)),
        Background.color(color_rgb(red, green, blue))
      ],
      none()
    )
  end

  defp soak(source, frame_count) do
    colors = [{255, 0, 0}, {0, 128, 0}, {0, 0, 255}]
    started_at = System.monotonic_time(:microsecond)

    Enum.each(0..(frame_count - 1), fn index ->
      render_source(source, Enum.at(colors, rem(index, length(colors))))
    end)

    elapsed_us = System.monotonic_time(:microsecond) - started_at
    frame_count * 1_000_000 / Kernel.max(elapsed_us, 1)
  end

  defp soak_expected_pixel(frame_count) do
    case rem(frame_count - 1, 3) do
      0 -> <<255, 0, 0, 255>>
      1 -> <<0, 128, 0, 255>>
      2 -> <<0, 0, 255, 255>>
    end
  end

  defp soak_frames do
    System.get_env("EMERGE_DEMO_PRIME_SOAK_FRAMES", "72")
    |> String.to_integer()
    |> Kernel.max(1)
  end

  defp assert_frame_telemetry!(source, main, submitted) do
    {:ok, source_stats} = EmergeSkia.stats(source, :take)
    {:ok, main_stats} = EmergeSkia.stats(main, :take)
    source_frames = source_stats.frames.frame_count
    main_frames = main_stats.frames.frame_count
    minimum = trunc(submitted * 0.9)

    if source_frames < minimum or main_frames < minimum do
      raise(
        "PRIME soak dropped too much work: submitted=#{submitted} " <>
          "source_frames=#{source_frames} main_frames=#{main_frames} minimum=#{minimum}"
      )
    end

    %{source_frames: source_frames, main_frames: main_frames}
  end

  defp assert_soak_rate!(fps) do
    if System.get_env("EMERGE_DEMO_PRIME_REQUIRE_RATE") in ["1", "true"] and
         (fps < 29.0 or fps > 31.0) do
      raise("PRIME producer pacing outside 29-31 FPS: #{fps}")
    end
  end

  defp render_source(source, color) do
    EmergeSkia.upload_tree(source, source_tree(color))
    Process.sleep(@frame_pause_ms)
  end

  defp await_connection(connection_ref) do
    receive do
      {:emerge_video_output, _producer, ^connection_ref, :connected} -> :ok
    after
      2_000 -> raise("timed out waiting for PRIME connection")
    end
  end

  defp await_first_frame(connection_ref) do
    receive do
      {:emerge_video_output, _producer, ^connection_ref, {:first_frame_accepted, sequence}}
      when is_integer(sequence) ->
        :ok

      {:emerge_video_output, _producer, ^connection_ref, {:error, reason}} ->
        raise("PRIME connection failed before its first frame: #{inspect(reason)}")

      {:emerge_video_output, _producer, ^connection_ref, :disconnected} ->
        raise("PRIME connection disconnected before its first frame")
    after
      2_000 ->
        raise(
          "timed out waiting for first accepted PRIME frame: #{inspect(Process.info(self(), :messages))}"
        )
    end
  end

  defp assert_solid_capture!(renderer, expected, label) do
    deadline = System.monotonic_time(:millisecond) + 5_000
    assert_solid_capture_until!(renderer, expected, label, deadline)
  end

  defp assert_solid_capture_until!(renderer, expected, label, deadline) do
    case EmergeSkia.render_to_pixels(renderer,
           timeout: 2_000,
           region: {0, 0, @width, @height}
         ) do
      {:ok, pixels} when is_binary(pixels) ->
        {visible, wrong} =
          pixels
          |> :binary.bin_to_list()
          |> Enum.chunk_every(4)
          |> Enum.reduce({0, 0}, fn rgba, {visible, wrong} ->
            case :erlang.list_to_binary(rgba) do
              <<_r, _g, _b, 0>> -> {visible, wrong}
              ^expected -> {visible + 1, wrong}
              _other -> {visible + 1, wrong + 1}
            end
          end)

        cond do
          visible >= @width * @height and wrong == 0 ->
            :ok

          System.monotonic_time(:millisecond) < deadline ->
            Process.sleep(30)
            assert_solid_capture_until!(renderer, expected, label, deadline)

          true ->
            raise(
              "#{label} byte check failed: visible=#{visible} wrong=#{wrong} " <>
                "expected=#{inspect(expected)}"
            )
        end

      other ->
        if System.monotonic_time(:millisecond) < deadline do
          Process.sleep(30)
          assert_solid_capture_until!(renderer, expected, label, deadline)
        else
          raise("#{label} capture failed: #{inspect(other)}")
        end
    end
  end

  defp assert_submitted_pixels!(main, expected_pixel, label),
    do: assert_submitted_pixels!(main, expected_pixel, label, @width, @height)

  defp assert_submitted_pixels!(main, expected_pixel, label, width, height) do
    expected_pixels = :binary.copy(expected_pixel, width * height)
    deadline = System.monotonic_time(:millisecond) + 5_000
    assert_matching_capture_until!(main, expected_pixels, label, deadline, width, height)
  end

  defp assert_matching_capture_until!(main, expected_pixels, label, deadline, width, height) do
    case EmergeSkia.render_to_pixels(main,
           timeout: 2_000,
           region: {0, 0, width, height}
         ) do
      {:ok, ^expected_pixels} ->
        :ok

      {:ok, main_pixels} ->
        if System.monotonic_time(:millisecond) < deadline do
          Process.sleep(30)
          assert_matching_capture_until!(main, expected_pixels, label, deadline, width, height)
        else
          mismatch = first_pixel_mismatch(expected_pixels, main_pixels)
          expected_byte = mismatch && :binary.at(expected_pixels, mismatch)
          main_byte = mismatch && :binary.at(main_pixels, mismatch)

          raise(
            "#{label} submitted/main byte equality failed at byte #{inspect(mismatch)} " <>
              "expected=#{inspect(expected_byte)} actual=#{inspect(main_byte)} " <>
              "sizes=#{byte_size(expected_pixels)}/#{byte_size(main_pixels)} " <>
              "mailbox=#{inspect(Process.info(self(), :messages))}"
          )
        end

      other ->
        if System.monotonic_time(:millisecond) < deadline do
          Process.sleep(30)
          assert_matching_capture_until!(main, expected_pixels, label, deadline, width, height)
        else
          raise("#{label} main capture failed: #{inspect(other)}")
        end
    end
  end

  defp first_pixel_mismatch(left, right) do
    limit = Kernel.min(byte_size(left), byte_size(right))

    Enum.find(0..Kernel.max(limit - 1, 0), fn index ->
      :binary.at(left, index) != :binary.at(right, index)
    end) || if(byte_size(left) == byte_size(right), do: nil, else: limit)
  end

  defp write_screenshots!(main, producer_api, main_api, label, expected_pixel) do
    directory =
      System.get_env("EMERGE_DEMO_PRIME_ARTIFACT_DIR", "/tmp/emerge-prime-matrix")

    File.mkdir_p!(directory)
    prefix = "#{producer_api}-#{main_api}-#{label}"
    capture_opts = [timeout: 5_000, region: {0, 0, @width, @height}]
    {:ok, main_pixels} = EmergeSkia.render_to_pixels(main, capture_opts)
    {:ok, main_png} = EmergeSkia.render_to_png(main, capture_opts)

    File.write!(
      Path.join(directory, "#{prefix}-submitted.rgba"),
      :binary.copy(expected_pixel, @width * @height)
    )

    File.write!(Path.join(directory, "#{prefix}-main.rgba"), main_pixels)
    File.write!(Path.join(directory, "#{prefix}-main.png"), main_png)
  end

  defp resources do
    fd_targets =
      "/proc/self/fd/*"
      |> Path.wildcard()
      |> Enum.map(fn path -> File.read_link(path) end)
      |> Enum.flat_map(fn
        {:ok, target} -> [target]
        {:error, _reason} -> []
      end)
      |> Enum.frequencies()

    %{
      fds: Enum.sum(Map.values(fd_targets)),
      fd_targets: fd_targets,
      rss_kb: rss_kb()
    }
  end

  defp rss_kb do
    "/proc/self/status"
    |> File.read!()
    |> String.split("\n")
    |> Enum.find_value(0, fn line ->
      case Regex.run(~r/^VmRSS:\s+(\d+)\s+kB$/, line) do
        [_, value] -> String.to_integer(value)
        _ -> nil
      end
    end)
  end

  defp assert_steady_resource_bounds!(before, after_resources) do
    if after_resources.fds > before.fds + 12 do
      raise("PRIME soak leaked file descriptors: #{before.fds} -> #{after_resources.fds}")
    end

    # Measure after first-use shader/allocator warming so process-scoped driver caches do not hide
    # unbounded per-frame retirement growth.
    if after_resources.rss_kb > before.rss_kb + 1536 * 1024 do
      raise("PRIME soak RSS grew unexpectedly: #{before.rss_kb} -> #{after_resources.rss_kb} kB")
    end
  end

  defp assert_fd_bound!(before, after_resources) do
    # Each route intentionally exercises two complete renderer lifetimes. Mesa and the BEAM
    # process keep a small fixed set of stopped driver/native-thread descriptors until that fresh
    # route process exits; the in-lifetime steady-state check above remains the leak authority.
    if after_resources.fds > before.fds + 20 do
      raise(
        "PRIME route leaked file descriptors: #{before.fds} -> #{after_resources.fds}; " <>
          "before=#{inspect(before.fd_targets)} after=#{inspect(after_resources.fd_targets)}"
      )
    end
  end
end

EmergeDemo.PrimeMatrixRoute.run(System.argv())
