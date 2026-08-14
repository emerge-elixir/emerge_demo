import Config

config :logger, level: :debug

rendering_api = fn env_key, default ->
  case System.get_env(env_key) do
    nil -> default
    "opengl" -> :opengl
    "vulkan" -> :vulkan
    value -> raise "#{env_key} must be opengl or vulkan, got: #{inspect(value)}"
  end
end

config :emerge,
  compiled_backends: [:wayland, :drm],
  compiled_vulkan_backends: [:wayland, :headless]

config :emerge_demo, EmergeDemo.Application,
  auto_start?: true,
  prime_validation?: System.get_env("EMERGE_DEMO_PRIME_VALIDATION") in ["1", "true"],
  main_rendering_api: rendering_api.("EMERGE_DEMO_MAIN_RENDERING_API", :vulkan),
  prime_source_rendering_api: rendering_api.("EMERGE_DEMO_PRIME_SOURCE_RENDERING_API", :vulkan),
  prime_drm_node: System.get_env("EMERGE_DEMO_PRIME_DRM_NODE")

import_config "#{config_env()}.exs"
