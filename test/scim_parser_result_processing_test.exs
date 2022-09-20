defmodule ScimParserResultProcessingTest do
  use ParserCase, async: true

  _ecto_struct_example = """
  iex(15)> from(License) |> where([l], l.id == "1") |> join(:left, [l], u in User, on: u.license_id == l.id) |> where([l, _], l.id != "2") |> or_where([l, _], (l.id == "3" or l.id == "4") and (l.id != "5")) |> IO.inspect(pretty: true, structs: false)
  %{
    __struct__: Ecto.Query,
    aliases: %{},
    assocs: [],
    combinations: [],
    distinct: nil,
    from: %{
      __struct__: Ecto.Query.FromExpr,
      as: nil,
      hints: [],
      prefix: nil,
      source: {"license", Ase.Accounts.License}
    },
    group_bys: [],
    havings: [],
    joins: [
      %{
        __struct__: Ecto.Query.JoinExpr,
        as: nil,
        assoc: nil,
        file: "iex",
        hints: [],
        ix: nil,
        line: 15,
        on: %{
          __struct__: Ecto.Query.QueryExpr,
          expr: {:==, [],
           [
             {{:., [], [{:&, [], [1]}, :license_id]}, [], []},
             {{:., [], [{:&, [], [0]}, :id]}, [], []}
           ]},
          file: "iex",
          line: 15,
          params: []
        },
        params: [],
        prefix: nil,
        qual: :left,
        source: {nil, Ase.Accounts.User}
      }
    ],
    limit: nil,
    lock: nil,
    offset: nil,
    order_bys: [],
    prefix: nil,
    preloads: [],
    select: nil,
    sources: nil,
    updates: [],
    wheres: [
      %{
        __struct__: Ecto.Query.BooleanExpr,
        expr: {:==, [],
         [
           {{:., [], [{:&, [], [0]}, :id]}, [], []},
           %{__struct__: Ecto.Query.Tagged, tag: nil, type: {0, :id}, value: "1"}
         ]},
        file: "iex",
        line: 15,
        op: :and,
        params: [],
        subqueries: []
      },
      %{
        __struct__: Ecto.Query.BooleanExpr,
        expr: {:!=, [],
         [
           {{:., [], [{:&, [], [0]}, :id]}, [], []},
           %{__struct__: Ecto.Query.Tagged, tag: nil, type: {0, :id}, value: "2"}
         ]},
        file: "iex",
        line: 15,
        op: :and,
        params: [],
        subqueries: []
      },
      %{
        __struct__: Ecto.Query.BooleanExpr,
        expr: {:and, [],
         [
           {:or, [],
            [
              {:==, [],
               [
                 {{:., [], [{:&, [], [0]}, :id]}, [], []},
                 %{
                   __struct__: Ecto.Query.Tagged,
                   tag: nil,
                   type: {0, :id},
                   value: "3"
                 }
               ]},
              {:==, [],
               [
                 {{:., [], [{:&, [], [0]}, :id]}, [], []},
                 %{
                   __struct__: Ecto.Query.Tagged,
                   tag: nil,
                   type: {0, :id},
                   value: "4"
                 }
               ]}
            ]},
           {:!=, [],
            [
              {{:., [], [{:&, [], [0]}, :id]}, [], []},
              %{
                __struct__: Ecto.Query.Tagged,
                tag: nil,
                type: {0, :id},
                value: "5"
              }
            ]}
         ]},
        file: "iex",
        line: 15,
        op: :or,
        params: [],
        subqueries: []
      }
    ],
    windows: [],
    with_ctes: nil
  }
  #Ecto.Query<from l0 in Ase.Accounts.License, left_join: u1 in Ase.Accounts.User,
   on: u1.license_id == l0.id, where: l0.id == "1", where: l0.id != "2",
   or_where: (l0.id == "3" or l0.id == "4") and l0.id != "5">
  """
end
