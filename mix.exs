defmodule EmergeDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :emerge_demo,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      listeners: [Emerge.Runtime.CodeReloader.MixListener],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EmergeDemo.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:video_interop, "~> 0.1.0"},
      {:membrane_video_interop, "~> 0.1.0"},
      {:membrane_core, "~> 1.3"},
      {:membrane_file_plugin, "~> 0.17.5"},
      {:membrane_ffmpeg_swscale_plugin, "~> 0.16.5"},
      {:membrane_h264_ffmpeg_plugin, "~> 0.32.7"},
      {:membrane_h26x_plugin, "~> 0.11.2"},
      {:membrane_realtimer_plugin, "~> 0.11.1"},
      {:membrane_video_transcode, path: "../membrane_video_transcode"},
      {:emerge, path: "../emerge-headless"},
      {:solve, "~> 0.2.0"},
      {:file_system, "~> 1.0", only: :dev},
      {:rustler, "~> 0.38", optional: true}
    ]
  end
end
