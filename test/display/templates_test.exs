defmodule Display.TemplatesTest do
  use Display.DataCase

  alias Display.Templates

  describe "cms_template_data" do
    alias Display.Templates.TemplateData

    @valid_attrs %{
      orientation: "some orientation",
      requestor: "some requestor",
      template_data_id: "some template_data_id",
      template_detail: "some template_detail",
      template_name: "some template_name"
    }
    @update_attrs %{
      orientation: "some updated orientation",
      requestor: "some updated requestor",
      template_data_id: "some updated template_data_id",
      template_detail: "some updated template_detail",
      template_name: "some updated template_name"
    }
    @invalid_attrs %{
      orientation: nil,
      requestor: nil,
      template_data_id: nil,
      template_detail: nil,
      template_name: nil
    }

    def template_data_fixture(attrs \\ %{}) do
      {:ok, template_data} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Templates.create_template_data()

      template_data
    end

    test "list_cms_template_data/0 returns all cms_template_data" do
      template_data = template_data_fixture()
      assert Templates.list_cms_template_data() == [template_data]
    end

    test "get_template_data!/1 returns the template_data with given id" do
      template_data = template_data_fixture()
      assert Templates.get_template_data!(template_data.id) == template_data
    end

    test "create_template_data/1 with valid data creates a template_data" do
      assert {:ok, %TemplateData{} = template_data} = Templates.create_template_data(@valid_attrs)
      assert template_data.orientation == "some orientation"
      assert template_data.requestor == "some requestor"
      assert template_data.template_data_id == "some template_data_id"
      assert template_data.template_detail == "some template_detail"
      assert template_data.template_name == "some template_name"
    end

    test "create_template_data/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Templates.create_template_data(@invalid_attrs)
    end

    test "update_template_data/2 with valid data updates the template_data" do
      template_data = template_data_fixture()

      assert {:ok, %TemplateData{} = template_data} =
               Templates.update_template_data(template_data, @update_attrs)

      assert template_data.orientation == "some updated orientation"
      assert template_data.requestor == "some updated requestor"
      assert template_data.template_data_id == "some updated template_data_id"
      assert template_data.template_detail == "some updated template_detail"
      assert template_data.template_name == "some updated template_name"
    end

    test "update_template_data/2 with invalid data returns error changeset" do
      template_data = template_data_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Templates.update_template_data(template_data, @invalid_attrs)

      assert template_data == Templates.get_template_data!(template_data.id)
    end

    test "delete_template_data/1 deletes the template_data" do
      template_data = template_data_fixture()
      assert {:ok, %TemplateData{}} = Templates.delete_template_data(template_data)
      assert_raise Ecto.NoResultsError, fn -> Templates.get_template_data!(template_data.id) end
    end

    test "change_template_data/1 returns a template_data changeset" do
      template_data = template_data_fixture()
      assert %Ecto.Changeset{} = Templates.change_template_data(template_data)
    end
  end

  describe "cms_template_assignment" do
    alias Display.Templates.TemplateAssignment

    @valid_attrs %{
      bus_stop_group_id: "some bus_stop_group_id",
      bus_stop_panel_id: "some bus_stop_panel_id",
      template_data_id: "some template_data_id",
      template_set_code: "some template_set_code"
    }
    @update_attrs %{
      bus_stop_group_id: "some updated bus_stop_group_id",
      bus_stop_panel_id: "some updated bus_stop_panel_id",
      template_data_id: "some updated template_data_id",
      template_set_code: "some updated template_set_code"
    }
    @invalid_attrs %{
      bus_stop_group_id: nil,
      bus_stop_panel_id: nil,
      template_data_id: nil,
      template_set_code: nil
    }

    def template_assignment_fixture(attrs \\ %{}) do
      {:ok, template_assignment} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Templates.create_template_assignment()

      template_assignment
    end

    test "list_cms_template_assignment/0 returns all cms_template_assignment" do
      template_assignment = template_assignment_fixture()
      assert Templates.list_cms_template_assignment() == [template_assignment]
    end

    test "get_template_assignment!/1 returns the template_assignment with given id" do
      template_assignment = template_assignment_fixture()
      assert Templates.get_template_assignment!(template_assignment.id) == template_assignment
    end

    test "create_template_assignment/1 with valid data creates a template_assignment" do
      assert {:ok, %TemplateAssignment{} = template_assignment} =
               Templates.create_template_assignment(@valid_attrs)

      assert template_assignment.bus_stop_group_id == "some bus_stop_group_id"
      assert template_assignment.bus_stop_panel_id == "some bus_stop_panel_id"
      assert template_assignment.template_data_id == "some template_data_id"
      assert template_assignment.template_set_code == "some template_set_code"
    end

    test "create_template_assignment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Templates.create_template_assignment(@invalid_attrs)
    end

    test "update_template_assignment/2 with valid data updates the template_assignment" do
      template_assignment = template_assignment_fixture()

      assert {:ok, %TemplateAssignment{} = template_assignment} =
               Templates.update_template_assignment(template_assignment, @update_attrs)

      assert template_assignment.bus_stop_group_id == "some updated bus_stop_group_id"
      assert template_assignment.bus_stop_panel_id == "some updated bus_stop_panel_id"
      assert template_assignment.template_data_id == "some updated template_data_id"
      assert template_assignment.template_set_code == "some updated template_set_code"
    end

    test "update_template_assignment/2 with invalid data returns error changeset" do
      template_assignment = template_assignment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Templates.update_template_assignment(template_assignment, @invalid_attrs)

      assert template_assignment == Templates.get_template_assignment!(template_assignment.id)
    end

    test "delete_template_assignment/1 deletes the template_assignment" do
      template_assignment = template_assignment_fixture()

      assert {:ok, %TemplateAssignment{}} =
               Templates.delete_template_assignment(template_assignment)

      assert_raise Ecto.NoResultsError, fn ->
        Templates.get_template_assignment!(template_assignment.id)
      end
    end

    test "change_template_assignment/1 returns a template_assignment changeset" do
      template_assignment = template_assignment_fixture()
      assert %Ecto.Changeset{} = Templates.change_template_assignment(template_assignment)
    end
  end
end
