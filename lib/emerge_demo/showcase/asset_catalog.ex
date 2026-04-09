defmodule EmergeDemo.Showcase.AssetCatalog do
  @moduledoc false

  use Emerge.Assets.Path, otp_app: :emerge_demo

  @runtime_extensions [".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".svg"]

  @static_image ~m"demo_images/static.jpg"
  @fallback_image ~m"demo_images/fallback.jpg"
  @runtime_image ~m"demo_images/runtime.jpg"
  @bird_tile ~m"demo_images/tile_bird_small.jpg"
  @template_cloud ~m"demo_images/template_cloud.svg"
  @weather_sun ~m"demo_images/weather_sun.svg"
  @weather_cloud ~m"demo_images/weather_cloud.svg"
  @weather_rain ~m"demo_images/weather_rain.svg"
  @tile_quad ~m"demo_images/tile_quad.svg"
  @lobster_font ~m"demo_fonts/Lobster-Regular.ttf"

  def static_image, do: @static_image
  def fallback_image, do: @fallback_image
  def bird_tile, do: @bird_tile
  def template_cloud, do: @template_cloud
  def tile_quad, do: @tile_quad
  def lobster_font, do: @lobster_font

  def runtime_image_source, do: {:path, runtime_image_path()}
  def blocked_image_source, do: {:path, blocked_image_path()}

  def lobster_font_path, do: @lobster_font.path
  def runtime_allowlist_root, do: Path.join(source_priv_dir(), "demo_images")

  def runtime_image_path,
    do: Path.join(runtime_allowlist_root(), Path.basename(@runtime_image.path))

  def blocked_image_path, do: Path.join(source_priv_dir(), "blocked_demo_images/blocked.jpg")

  def renderer_assets_config do
    [
      fonts: [[family: "lobster-demo", source: @lobster_font, weight: 400, italic: false]],
      runtime_paths: [
        enabled: true,
        allowlist: [runtime_allowlist_root()],
        follow_symlinks: false,
        max_file_size: 25_000_000,
        extensions: @runtime_extensions
      ]
    ]
  end

  def weather_forecast_data do
    [
      %{day: "Mon", kind: :sun, high_c: 22, low_c: 13, precip: "5%"},
      %{day: "Tue", kind: :cloud, high_c: 19, low_c: 12, precip: "20%"},
      %{day: "Wed", kind: :rain, high_c: 16, low_c: 10, precip: "70%"},
      %{day: "Thu", kind: :cloud, high_c: 18, low_c: 11, precip: "25%"},
      %{day: "Fri", kind: :sun, high_c: 24, low_c: 14, precip: "5%"},
      %{day: "Sat", kind: :rain, high_c: 17, low_c: 9, precip: "80%"},
      %{day: "Sun", kind: :sun, high_c: 23, low_c: 13, precip: "10%"}
    ]
  end

  def weather_icon_source(:sun), do: @weather_sun
  def weather_icon_source(:cloud), do: @weather_cloud
  def weather_icon_source(:rain), do: @weather_rain

  defp source_priv_dir do
    Path.expand("../../../priv", __DIR__)
  end
end
