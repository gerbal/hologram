defmodule Hologram.Runtime.Templatable do
  alias Hologram.Compiler.AST
  alias Hologram.Component

  defmacro __using__(opts \\ []) do
    [
      if opts[:initiable_on_client?] do
        quote do
          @doc """
          Initializes component client data (when run on the client).
          """
          @callback init(%{atom => any}, Component.Client.t()) :: Component.Client.t()
        end
      end,
      quote do
        alias Hologram.Runtime.Templatable

        @doc """
        Initializes component client and server data (when run on the server).
        """
        @callback init(%{atom => any}, Component.Client.t(), Component.Server.t()) ::
                    {Component.Client.t(), Component.Server.t()}
                    | Component.Client.t()
                    | Component.Server.t()

        @doc """
        Returns a template in the form of an anonymous function that given variable bindings returns a DOM tree.
        """
        @callback template() :: (map -> list)
      end
    ]
  end

  @doc """
  Resolves the colocated template path for the given templatable module (page, layout, component) given its file path.
  """
  @spec colocated_template_path(String.t()) :: String.t()
  def colocated_template_path(templatable_file) do
    Path.rootname(templatable_file) <> ".holo"
  end

  @doc """
  Returns the AST of template/0 function definition that uses markup fetched from the give template file.
  If the given template file doesn't exist nil is returned.
  """
  @spec maybe_define_template_fun(String.t(), module) :: AST.t() | nil
  def maybe_define_template_fun(template_path, behaviour) do
    if File.exists?(template_path) do
      markup = File.read!(template_path)

      quote do
        @impl unquote(behaviour)
        def template do
          sigil_H(unquote(markup), [])
        end
      end
    end
  end

  @doc """
  Puts the given key-value entries to the component client state.
  """
  @spec put_state(Component.Client.t(), keyword) :: Component.Client.t()
  def put_state(%{state: state} = client, entries) do
    new_state = Map.merge(state, Enum.into(entries, %{}))
    %{client | state: new_state}
  end

  @doc """
  Puts the given key-value pair to the component client state.
  """
  @spec put_state(Component.Client.t(), atom, any) :: Component.Client.t()
  def put_state(%{state: state} = client, key, value) do
    %{client | state: Map.put(state, key, value)}
  end
end
