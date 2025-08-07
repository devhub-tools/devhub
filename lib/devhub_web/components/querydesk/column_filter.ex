defmodule DevhubWeb.Components.QueryDesk.ColumnFilter do
  @moduledoc false
  use DevhubWeb, :html

  attr :id, :string, required: true
  attr :columns, :list, required: true
  attr :filters, :list, default: []
  attr :table, :string, required: true

  defmodule Form do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      embeds_many :filters, Filter, primary_key: false do
        field :column, :string
        field :value, :string

        field :operator, Ecto.Enum,
          values: [
            :equals,
            :not_equals,
            :contains,
            :does_not_contain,
            :like,
            :greater_than,
            :less_than,
            :greater_than_or_equal,
            :less_than_or_equal,
            :is_null,
            :is_not_null
          ]
      end
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [])
      |> cast_embed(:filters, with: &filter_changeset/2)
    end

    def filter_changeset(filter, attrs) do
      filter
      |> cast(attrs, [:column, :value, :operator])
      |> validate_required([:column, :operator])
      |> then(fn changeset ->
        operator = get_field(changeset, :operator)

        if operator in [:is_null, :is_not_null] do
          changeset
        else
          validate_required(changeset, [:value])
        end
      end)
    end
  end

  def column_filter(assigns) do
    column_names = Enum.map(assigns[:columns] || [], &elem(&1, 0))
    assigns = assign(assigns, columns: column_names)

    ~H"""
    <div class={[
      "bg-surface-1 mb-4 rounded-lg p-4",
      if(map_size(@column_filters.changes) > 0, do: "block", else: "hidden")
    ]}>
      <span class="text-alpha-64 block text-xs uppercase">
        Filters
      </span>
      <.form
        :let={form}
        for={@column_filters}
        phx-change="apply_filters"
        id="column-filter-form"
        phx-hook="PreventSubmit"
      >
        <.inputs_for :let={filter_form} field={form[:filters]}>
          <div class="flex w-full items-center gap-2">
            <.input field={filter_form[:column]} type="select" options={@columns} />
            <.input field={filter_form[:operator]} type="select">
              <option
                value="equals"
                selected={filter_form[:operator].value == :equals}
                class="bg-alpha-4 text-alpha-88"
              >
                equals
              </option>
              <option
                value="not_equals"
                selected={filter_form[:operator].value == :not_equals}
                class="bg-alpha-4 text-alpha-88"
              >
                not equals
              </option>
              <option
                value="contains"
                selected={filter_form[:operator].value == :contains}
                class="bg-alpha-4 text-alpha-88"
              >
                contains
              </option>
              <option
                value="does_not_contain"
                selected={filter_form[:operator].value == :does_not_contain}
                class="bg-alpha-4 text-alpha-88"
              >
                does not contain
              </option>
              <option
                value="like"
                selected={filter_form[:operator].value == :like}
                class="bg-alpha-4 text-alpha-88"
              >
                like
              </option>
              <hr />
              <option
                value="greater_than"
                selected={filter_form[:operator].value == :greater_than}
                class="bg-alpha-4 text-alpha-88"
              >
                &gt;
              </option>
              <option
                value="less_than"
                selected={filter_form[:operator].value == :less_than}
                class="bg-alpha-4 text-alpha-88"
              >
                &lt;
              </option>
              <option
                value="greater_than_or_equal"
                selected={filter_form[:operator].value == :greater_than_or_equal}
                class="bg-alpha-4 text-alpha-88"
              >
                &gt;=
              </option>
              <option
                value="less_than_or_equal"
                selected={filter_form[:operator].value == :less_than_or_equal}
                class="bg-alpha-4 text-alpha-88"
              >
                &lt;=
              </option>
              <hr />
              <option
                value="is_null"
                selected={filter_form[:operator].value == :is_null}
                class="bg-alpha-4 text-alpha-88"
              >
                is null
              </option>
              <option
                value="is_not_null"
                selected={filter_form[:operator].value == :is_not_null}
                class="bg-alpha-4 text-alpha-88"
              >
                is not null
              </option>
            </.input>
            <div class="flex-1">
              <.input
                :if={filter_form[:operator].value not in [:is_null, :is_not_null]}
                field={filter_form[:value]}
                phx-debounce
              />
            </div>
            <button
              type="button"
              phx-click="remove_column_filter"
              phx-value-index={filter_form.index}
              class="bg-alpha-4 size-6 mt-2 flex items-center justify-center rounded-md"
            >
              <.icon name="hero-x-mark-mini" class="size-5 align-bottom text-gray-900" />
            </button>
          </div>
        </.inputs_for>
      </.form>
    </div>
    """
  end
end
