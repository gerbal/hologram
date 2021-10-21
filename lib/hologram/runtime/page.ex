defmodule Hologram.Page do
  @default_layout Application.get_env(:hologram, :default_layout)

  defmacro __using__(_) do
    quote do
      require Hologram.Page
      import Hologram.Page
      import Hologram.Runtime.Commons, only: [sigil_H: 2, update: 3]

      def layout do
        if Keyword.has_key?(__MODULE__.__info__(:functions), :page_layout) do
          apply(__MODULE__, :page_layout, [])
        else
          unquote(@default_layout)
        end
      end
    end
  end

  defmacro layout(module) do
    quote do
      def page_layout do
        unquote(module)
      end
    end
  end

  defmacro route(path) do
    quote do
      def route do
        unquote(path)
      end
    end
  end
end
