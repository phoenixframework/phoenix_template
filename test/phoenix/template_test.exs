defmodule Phoenix.TemplateTest do
  use ExUnit.Case, async: true

  doctest Phoenix.Template
  require Phoenix.Template, as: Template

  @templates Path.expand("../fixtures/templates", __DIR__)

  test "engines/0" do
    assert is_map(Template.engines())
  end

  test "find_all/3 finds all templates in the given root" do
    templates = Template.find_all(@templates)
    assert Path.join(@templates, "show.html.eex") in templates

    templates = Template.find_all(Path.expand("unknown"))
    assert templates == []
  end

  test "hash/3 returns the hash for the given root" do
    assert is_binary(Template.hash(@templates))
  end

  test "format_encoder/1 returns the formatter for a given template" do
    assert Template.format_encoder("html") == Phoenix.HTML.Engine
    assert Template.format_encoder("js") == Phoenix.HTML.Engine
    assert Template.format_encoder("unknown") == nil
  end

  describe "embed_templates/2" do
    defmodule EmbedTemplates do
      import Phoenix.Template, only: [embed_templates: 1, embed_templates: 2]

      embed_templates("../fixtures/templates/*.html")
      embed_templates("../fixtures/templates/*.json", suffix: "_json")
    end

    test "embeds templates" do
      assert EmbedTemplates.trim(%{}) == {:safe, ["12", "\n", "34", "\n", "56"]}

      assert EmbedTemplates.show(%{message: "hello"}) ==
               {:safe, ["<div>Show! ", "hello", "</div>\n"]}
    end

    test "embeds templates with suffix" do
      assert EmbedTemplates.show_json(%{}) == %{foo: "bar"}
    end
  end

  describe "compile_all/4" do
    defmodule AllTemplates do
      Template.compile_all(
        &(&1 |> Path.basename() |> String.replace(".", "_")),
        Path.expand("../fixtures/templates", __DIR__)
      )
    end

    test "compiles all templates at once" do
      assert AllTemplates.show_html_eex(%{message: "hello!"})
             |> Phoenix.HTML.safe_to_string() ==
               "<div>Show! hello!</div>\n"

      assert AllTemplates.show_html_eex(%{message: "<hello>"})
             |> Phoenix.HTML.safe_to_string() ==
               "<div>Show! &lt;hello&gt;</div>\n"

      assert AllTemplates.show_html_eex(%{message: {:safe, "<hello>"}})
             |> Phoenix.HTML.safe_to_string() ==
               "<div>Show! <hello></div>\n"

      assert AllTemplates.show_json_exs(%{}) == %{foo: "bar"}
      assert AllTemplates.show_text_eex(%{message: "hello"}) == "from hello"
      refute AllTemplates.__mix_recompile__?()
    end

    if Version.match?(System.version(), ">= 1.12.0") do
      test "trims only compiled HTML files" do
        assert AllTemplates.no_trim_text_eex(%{}) == "12\n  34\n56\n"
        assert AllTemplates.trim_html_eex(%{}) |> Phoenix.HTML.safe_to_string() == "12\n34\n56"
      end
    end

    defmodule OptionsTemplates do
      Template.compile_all(
        &(&1 |> Path.basename() |> String.replace(".", "1")),
        Path.expand("../fixtures/templates", __DIR__),
        "*.html"
      )

      [{"show2json2exs", _}] =
        Template.compile_all(
          &(&1 |> Path.basename() |> String.replace(".", "2")),
          Path.expand("../fixtures/templates", __DIR__),
          "*.json"
        )

      [{"show3html3foo", _}] =
        Template.compile_all(
          &(&1 |> Path.basename() |> String.replace(".", "3")),
          Path.expand("../fixtures/templates", __DIR__),
          "*",
          %{foo: Phoenix.Template.EExEngine}
        )
    end

    test "compiles templates across several calls" do
      assert OptionsTemplates.show1html1eex(%{message: "hello!"})
             |> Phoenix.HTML.safe_to_string() ==
               "<div>Show! hello!</div>\n"

      assert OptionsTemplates.show2json2exs(%{}) == %{foo: "bar"}

      assert OptionsTemplates.show3html3foo(%{message: "hello"})
             |> Phoenix.HTML.safe_to_string() == "from hello"

      refute OptionsTemplates.__mix_recompile__?()
    end

    test "render/4" do
      assert Template.render(AllTemplates, "show_html_eex", "html", %{message: "hello!"}) ==
               {:safe, ["<div>Show! ", "hello!", "</div>\n"]}
    end

    test "render/4 with layout" do
      assigns = %{message: "hello!", layout: {AllTemplates, "layout_html_eex"}}

      assert Template.render(AllTemplates, "show_html_eex", "html", assigns) ==
               {:safe, ["<html>", ["<div>Show! ", "hello!", "</div>\n"], "</html>"]}
    end

    test "render/4 with bad layout" do
      msg = ~r/no "bad_layout" html template defined for Phoenix.TemplateTest.AllTemplates/

      assert_raise ArgumentError, msg, fn ->
        assigns = %{message: "hello!", layout: {AllTemplates, "bad_layout"}}
        Template.render(AllTemplates, "show_html_eex", "html", assigns)
      end
    end

    test "render_to_iodata/4" do
      assert Template.render_to_iodata(AllTemplates, "show_html_eex", "html", %{message: "hello!"}) ==
               ["<div>Show! ", "hello!", "</div>\n"]
    end

    test "render_to_iodata/4 with bad layout" do
      msg = ~r/no "bad_layout" html template defined for Phoenix.TemplateTest.AllTemplates/

      assert_raise ArgumentError, msg, fn ->
        assigns = %{message: "hello!", layout: {AllTemplates, "bad_layout"}}
        Template.render_to_iodata(AllTemplates, "show_html_eex", "html", assigns)
      end
    end

    test "render_to_string/4" do
      assert Template.render_to_string(AllTemplates, "show_html_eex", "html", %{message: "hello!"}) ==
               "<div>Show! hello!</div>\n"
    end
  end
end
