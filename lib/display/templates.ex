defmodule Display.Templates do
  @moduledoc """
  The Templates context.
  """

  import Ecto.Query, warn: false
  alias Display.Repo

  alias Display.Templates.{TemplateAssignment, TemplateData}
  alias Display.Workflow.CmsWorkflow

  def list_templates_by_panel_id(panel_id) do
    from(ctd in TemplateData,
      join: cta in TemplateAssignment,
      on: ctd.template_data_id == cta.template_data_id,
      where: cta.bus_stop_panel_id == ^panel_id,
      select: %{
        panel_id: cta.bus_stop_panel_id,
        template_data_id: cta.template_data_id,
        template_set_code: cta.template_set_code,
        template_detail: ctd.template_detail
      },
      order_by: cta.template_set_code
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of cms_template_data.

  ## Examples

      iex> list_cms_template_data()
      [%TemplateData{}, ...]

  """
  def list_cms_template_data do
    Repo.all(TemplateData)
  end

  @doc """
  Gets a single template_data.

  Raises `Ecto.NoResultsError` if the Template data does not exist.

  ## Examples

      iex> get_template_data!(123)
      %TemplateData{}

      iex> get_template_data!(456)
      ** (Ecto.NoResultsError)

  """
  def get_template_data!(id), do: Repo.get!(TemplateData, id)

  @doc """
  Creates a template_data.

  ## Examples

      iex> create_template_data(%{field: value})
      {:ok, %TemplateData{}}

      iex> create_template_data(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_template_data(attrs \\ %{}) do
    %TemplateData{}
    |> TemplateData.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template_data.

  ## Examples

      iex> update_template_data(template_data, %{field: new_value})
      {:ok, %TemplateData{}}

      iex> update_template_data(template_data, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_template_data(%TemplateData{} = template_data, attrs) do
    template_data
    |> TemplateData.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a template_data.

  ## Examples

      iex> delete_template_data(template_data)
      {:ok, %TemplateData{}}

      iex> delete_template_data(template_data)
      {:error, %Ecto.Changeset{}}

  """
  def delete_template_data(%TemplateData{} = template_data) do
    Repo.delete(template_data)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template_data changes.

  ## Examples

      iex> change_template_data(template_data)
      %Ecto.Changeset{data: %TemplateData{}}

  """
  def change_template_data(%TemplateData{} = template_data, attrs \\ %{}) do
    TemplateData.changeset(template_data, attrs)
  end

  alias Display.Templates.TemplateAssignment

  @doc """
  Returns the list of cms_template_assignment.

  ## Examples

      iex> list_cms_template_assignment()
      [%TemplateAssignment{}, ...]

  """
  def list_cms_template_assignment do
    Repo.all(TemplateAssignment)
  end

  @doc """
  Gets a single template_assignment.

  Raises `Ecto.NoResultsError` if the Template assignment does not exist.

  ## Examples

      iex> get_template_assignment!(123)
      %TemplateAssignment{}

      iex> get_template_assignment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_template_assignment!(id), do: Repo.get!(TemplateAssignment, id)

  @doc """
  Creates a template_assignment.

  ## Examples

      iex> create_template_assignment(%{field: value})
      {:ok, %TemplateAssignment{}}

      iex> create_template_assignment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_template_assignment(attrs \\ %{}) do
    %TemplateAssignment{}
    |> TemplateAssignment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template_assignment.

  ## Examples

      iex> update_template_assignment(template_assignment, %{field: new_value})
      {:ok, %TemplateAssignment{}}

      iex> update_template_assignment(template_assignment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_template_assignment(%TemplateAssignment{} = template_assignment, attrs) do
    template_assignment
    |> TemplateAssignment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a template_assignment.

  ## Examples

      iex> delete_template_assignment(template_assignment)
      {:ok, %TemplateAssignment{}}

      iex> delete_template_assignment(template_assignment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_template_assignment(%TemplateAssignment{} = template_assignment) do
    Repo.delete(template_assignment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template_assignment changes.

  ## Examples

      iex> change_template_assignment(template_assignment)
      %Ecto.Changeset{data: %TemplateAssignment{}}

  """
  def change_template_assignment(%TemplateAssignment{} = template_assignment, attrs \\ %{}) do
    TemplateAssignment.changeset(template_assignment, attrs)
  end

  defp get_workflow_payload_text_from_cms_workflow(workflow_id) do
    case Repo.get_by(CmsWorkflow, wrkflw_id_num: workflow_id) do
      nil ->
        nil

      data ->
        workflow_payload = data |> Map.get(:wrkflw_payload_txt) |> Jason.decode!()

        %{
          :template_set_a => workflow_payload["templateDataIdForSet1"]["templateDataId"],
          :template_set_b => workflow_payload["templateDataIdForSet2"]["templateDataId"],
          :panel_id => workflow_payload["busStopPanelId"]
        }
    end
  end

  @doc """
  Returns workflow payload text for assign template
  ## Examples

      iex> get_template_detail_by_workflow_id("768956557B91")
  """
  def get_template_detail_by_workflow_id(workflow_id) do
    template_data_map = get_workflow_payload_text_from_cms_workflow(workflow_id)

    template_set_a = Repo.get(TemplateData, template_data_map[:template_set_a])

    template_set_a = %{
      :template_data_id => template_set_a |> Map.get(:template_data_id),
      :template_detail => template_set_a |> Map.get(:template_detail),
      :template_set_code => "A"
    }

    template_set_b = Repo.get(TemplateData, template_data_map[:template_set_b])

    template_set_b = %{
      :template_data_id => template_set_b |> Map.get(:template_data_id),
      :template_detail => template_set_b |> Map.get(:template_detail),
      :template_set_code => "B"
    }

    [template_set_a, template_set_b]
  end
end
