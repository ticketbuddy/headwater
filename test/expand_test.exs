defmodule Headwater.ExpandTest do
  use ExUnit.Case

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  defmodule ToBeExpanded do
    defstruct people: ["one", "two", "three"], last_login: "login-id-5"

    def aggregate_prefix, do: ""
  end

  defmodule Person do
    defstruct name: "James", age: 23, accounts: ["abc", "def"]

    def aggregate_prefix, do: ""
  end

  defmodule Account do
    defstruct id: "account-123"

    def aggregate_prefix, do: ""
  end

  defmodule EmptyStatePerson do
    defstruct name: "James", age: 23, accounts: ["abc", "def"]

    def aggregate_prefix, do: ""
  end

  defmodule Login do
    defstruct time: "2019"

    def aggregate_prefix, do: "login_"
  end

  defmodule ModuleWithExpandLogic do
    use Headwater.Aggregate.Expand, aggregate_directory: Headwater.AggregateMock
  end

  setup do
    Headwater.AggregateMock
    |> stub(:read_state, fn
      %Headwater.AggregateDirectory.ReadRequest{
        aggregate_id: "login_login-id-5",
        handler: Headwater.ExpandTest.Login
      } ->
        {:ok, %{state: %Headwater.ExpandTest.Login{}}}

      %Headwater.AggregateDirectory.ReadRequest{
        aggregate_id: "one",
        handler: Headwater.ExpandTest.Person
      } ->
        {:ok, %{state: %Headwater.ExpandTest.Person{}}}

      %Headwater.AggregateDirectory.ReadRequest{
        aggregate_id: "two",
        handler: Headwater.ExpandTest.Person
      } ->
        {:ok, %{state: %Headwater.ExpandTest.Person{}}}

      %Headwater.AggregateDirectory.ReadRequest{
        aggregate_id: "three",
        handler: Headwater.ExpandTest.Person
      } ->
        {:ok, %{state: %Headwater.ExpandTest.Person{}}}

      %Headwater.AggregateDirectory.ReadRequest{
        aggregate_id: "one",
        handler: Headwater.ExpandTest.EmptyStatePerson
      } ->
        {:ok, %{state: nil}}

      %Headwater.AggregateDirectory.ReadRequest{
        aggregate_id: "two",
        handler: Headwater.ExpandTest.EmptyStatePerson
      } ->
        {:ok, %{state: nil}}

      %Headwater.AggregateDirectory.ReadRequest{
        aggregate_id: "three",
        handler: Headwater.ExpandTest.EmptyStatePerson
      } ->
        {:ok, %{state: nil}}

      %Headwater.AggregateDirectory.ReadRequest{
        aggregate_id: "abc",
        handler: Headwater.ExpandTest.Account
      } ->
        {:ok, %{state: %Headwater.ExpandTest.Account{}}}

      %Headwater.AggregateDirectory.ReadRequest{
        aggregate_id: "def",
        handler: Headwater.ExpandTest.Account
      } ->
        {:ok, %{state: %Headwater.ExpandTest.Account{}}}
    end)

    :ok
  end

  test "expands one layer" do
    assert %Headwater.ExpandTest.ToBeExpanded{
             people: [
               %Headwater.ExpandTest.Person{age: 23, name: "James"},
               %Headwater.ExpandTest.Person{age: 23, name: "James"},
               %Headwater.ExpandTest.Person{age: 23, name: "James"}
             ]
           } ==
             %ToBeExpanded{}
             |> ModuleWithExpandLogic.expand([people: Person], [:people])
  end

  test "expand/2 when mapping is empty" do
    assert %ToBeExpanded{} ==
             %ToBeExpanded{}
             |> ModuleWithExpandLogic.expand([])
  end

  describe "when expansion layer has empty state" do
    test "expand/2" do
      assert %Headwater.ExpandTest.ToBeExpanded{people: []} ==
               %ToBeExpanded{}
               |> ModuleWithExpandLogic.expand(people: EmptyStatePerson)
    end

    test "expand/3" do
      assert %Headwater.ExpandTest.ToBeExpanded{people: []} ==
               %ToBeExpanded{}
               |> ModuleWithExpandLogic.expand([people: EmptyStatePerson], [:people])
    end
  end

  describe "expands single value" do
    test "expand/2" do
      assert %Headwater.ExpandTest.ToBeExpanded{last_login: %Login{time: "2019"}} ==
               %ToBeExpanded{}
               |> ModuleWithExpandLogic.expand(last_login: Login)
    end

    test "expand/3" do
      assert %Headwater.ExpandTest.ToBeExpanded{last_login: %Login{time: "2019"}} ==
               %ToBeExpanded{}
               |> ModuleWithExpandLogic.expand([last_login: Login], [:last_login])
    end
  end

  test "when trying to expand a nil" do
    assert nil ==
             nil
             |> ModuleWithExpandLogic.expand([people: Person, accounts: Account], [
               :people,
               :accounts
             ])
  end

  test "when saving expanded output to a different key in, the state converts to map" do
    assert %{
             expanded_key: %Headwater.ExpandTest.Login{time: "2019"},
             last_login: "login-id-5",
             people: ["one", "two", "three"]
           } ==
             %ToBeExpanded{}
             |> ModuleWithExpandLogic.expand([last_login: Login], last_login: :expanded_key)
  end

  test "expands nested layer" do
    result =
      %ToBeExpanded{}
      |> ModuleWithExpandLogic.expand([people: Person, accounts: Account], [:people, :accounts])

    assert result == %Headwater.ExpandTest.ToBeExpanded{
             people: [
               %Headwater.ExpandTest.Person{
                 accounts: [
                   %Headwater.ExpandTest.Account{id: "account-123"},
                   %Headwater.ExpandTest.Account{id: "account-123"}
                 ],
                 age: 23,
                 name: "James"
               },
               %Headwater.ExpandTest.Person{
                 accounts: [
                   %Headwater.ExpandTest.Account{id: "account-123"},
                   %Headwater.ExpandTest.Account{id: "account-123"}
                 ],
                 age: 23,
                 name: "James"
               },
               %Headwater.ExpandTest.Person{
                 accounts: [
                   %Headwater.ExpandTest.Account{id: "account-123"},
                   %Headwater.ExpandTest.Account{id: "account-123"}
                 ],
                 age: 23,
                 name: "James"
               }
             ]
           }
  end
end
