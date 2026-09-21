import Config

config :logger, :console, colors: [enabled: false]
config :phoenix_template, :json_library, Jason
config :phoenix_template, :trim_on_html_eex_engine, true

config :phoenix_template, :format_encoders,
  markup: Phoenix.TemplateTest.MarkupEncoder,
  custom: Phoenix.TemplateTest.CustomEncoder

config :phoenix_template, :html_formats, [:markup]
