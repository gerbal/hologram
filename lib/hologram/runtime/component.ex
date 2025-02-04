defmodule Hologram.Component do
  use Hologram.Runtime.Templatable, initiable_on_client?: true
  alias Hologram.Component

  defmacro __using__(_opts) do
    template_path = Templatable.colocated_template_path(__CALLER__.file)

    [
      quote do
        import Hologram.Component
        import Hologram.Router.Helpers, only: [asset_path: 1]
        import Hologram.Template, only: [sigil_H: 2]
        import Templatable, only: [prop: 2, prop: 3, put_context: 3, put_state: 2, put_state: 3]

        alias Hologram.Component

        @before_compile Templatable

        @behaviour Component

        @external_resource unquote(template_path)

        @doc """
        Returns true to indicate that the callee module is a component module (has "use Hologram.Component" directive).

        ## Examples

            iex> __is_hologram_component__()
            true
        """
        @spec __is_hologram_component__() :: boolean
        def __is_hologram_component__, do: true

        @impl Component
        def init(_props, client), do: client

        @impl Component
        def init(_props, client, server), do: {client, server}

        defoverridable init: 2, init: 3
      end,
      Templatable.maybe_define_template_fun(template_path, __MODULE__),
      Templatable.register_props_accumulator()
    ]
  end
end
