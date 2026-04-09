defmodule EmergeDemo.Todo.App do
  @moduledoc """
  Solve implementation of TodoMVC example app
  """

  alias EmergeDemo.Todo

  use Solve

  def child_spec(opts) do
    %{
      id: {__MODULE__, Keyword.get(opts, :name, __MODULE__)},
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  @impl Solve
  def controllers do
    [
      controller!(name: :entries, module: Todo.Entries),
      controller!(
        name: :create,
        module: Todo.Create,
        params: fn _ -> true end,
        callbacks: %{
          create: fn title -> dispatch(:entries, :create, title) end
        }
      ),
      controller!(
        name: :filter,
        module: Todo.Filter,
        dependencies: [:entries],
        params: fn %{dependencies: %{entries: entries}} -> not is_nil(entries) end
      ),
      controller!(
        name: :editor,
        module: Todo.Editor,
        variant: :collection,
        dependencies: [:entries],
        params: fn %{dependencies: %{entries: entries}} -> not is_nil(entries) end,
        callbacks: %{
          save: fn id, title ->
            dispatch(:entries, :update, %{id: id, title: title})
          end
        },
        collect: fn %{dependencies: %{entries: entries}} ->
          Enum.map(entries.ids, fn id ->
            {id, [params: %{id: id, title: entries.todos[id].title}]}
          end)
        end
      )
    ]
  end
end
