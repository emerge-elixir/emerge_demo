import Config

config :logger, level: :debug

macos? = :os.type() == {:unix, :darwin}

rendering_api = fn env_key, default ->
  case System.get_env(env_key) do
    nil -> default
    "opengl" -> :opengl
    "vulkan" -> :vulkan
    "raster" -> :raster
    value -> raise "#{env_key} must be opengl, vulkan, or raster, got: #{inspect(value)}"
  end
end

config :emerge,
  load_macos_nif: macos?,
  compiled_backends: if(macos?, do: [:macos], else: [:wayland, :drm]),
  compiled_vulkan_backends: if(macos?, do: [], else: [:wayland, :headless])

config :emerge_demo, EmergeDemo.Application,
  auto_start?: true,
  main_rendering_api:
    rendering_api.("EMERGE_DEMO_MAIN_RENDERING_API", if(macos?, do: :raster, else: :vulkan)),
  prime_source_rendering_api: rendering_api.("EMERGE_DEMO_PRIME_SOURCE_RENDERING_API", :vulkan),
  prime_drm_node: System.get_env("EMERGE_DEMO_PRIME_DRM_NODE")

import_config "#{config_env()}.exs"
