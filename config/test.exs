import Config

config :emerge_demo, EmergeDemo.Application,
  auto_start?: false,
  prime_validation?: false,
  prime_source_rendering_api: :opengl
