defmodule Phoenix.Template.EExEngine do
  @moduledoc """
  The Phoenix engine that handles the `.eex` extension.
  """

  @behaviour Phoenix.Template.Engine

  def compile(path, _name) do
    EEx.compile_file(path, [line: 1] ++ options_for(path))
  end

  defp options_for(path) do
    format =
      case path |> Path.rootname() |> Path.extname() do
        "." <> format ->
          format

        _ ->
          raise ArgumentError,
                "template paths in Phoenix require the format extension, got: #{path}"
      end

    if html_format?(format) do
      if not Code.ensure_loaded?(Phoenix.HTML.Engine) do
        raise "could not load Phoenix.HTML.Engine to use with .#{format}.eex templates. " <>
                "You can configure your own format encoder for HTML but we recommend " <>
                "adding phoenix_html as a dependency as it provides XSS protection."
      end

      trim =
        case Application.get_env(:phoenix_template, :trim_on_html_eex_engine) do
          nil ->
            case Application.get_env(:phoenix_view, :trim_on_html_eex_engine) do
              nil ->
                Application.get_env(:phoenix, :trim_on_html_eex_engine, true)

              boolean ->
                IO.warn(
                  "config :phoenix_view, :trim_on_html_eex_engine is deprecated, please use config :phoenix_template, :trim_on_html_eex_engine instead"
                )

                boolean
            end

          boolean ->
            boolean
        end

      [engine: Phoenix.HTML.Engine, trim: trim]
    else
      [engine: EEx.SmartEngine]
    end
  end

  defp html_format?(format) do
    Phoenix.Template.format_encoder(format) == Phoenix.HTML.Engine or
      format in html_formats()
  end

  defp html_formats do
    :phoenix_template
    |> Application.get_env(:html_formats, [])
    |> Enum.map(&to_string/1)
  end
end
