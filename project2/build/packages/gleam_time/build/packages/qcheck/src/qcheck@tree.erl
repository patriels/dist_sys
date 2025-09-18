-module(qcheck@tree).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([new/2, map/2, bind/2, apply/2, return/1, option/1, collect/2, to_string/2, to_string_max_depth/3, map2/3, sequence_trees/1]).
-export_type([tree/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Trees\n"
    "\n"
    " This module contains functions for creating and manipulating shrink trees.\n"
    "\n"
    " They are mostly inteded for internal use or \"advanced\" manual construction\n"
    " of generators.  In typical usage, you will probably not need to interact\n"
    " with these functions much, if at all.  As such, they are currently mostly\n"
    " undocumented.\n"
    "\n"
    " In fact, if you are using these functions a lot, file a issue on GitHub\n"
    " and let me know if there are any generator combinators that you're missing.\n"
    "\n"
    " There are functions for dealing with the [Tree](#Tree) type directly, but\n"
    " they are low-level and you should not need to use them much.\n"
    "\n"
    " - The [Tree](#Tree) type\n"
    " - [new](#new)\n"
    " - [return](#return)\n"
    " - [map](#map)\n"
    " - [map2](#map2)\n"
    " - [bind](#bind)\n"
    " - [apply](#apply)\n"
    " - [collect](#collect)\n"
    " - [sequence_trees](#sequence_trees)\n"
    " - [option](#option)\n"
    " - [to_string](#to_string)\n"
    " - [to_string_with_max_depth](#to_string_with_max_depth)\n"
    "\n"
).

-type tree(NWN) :: {tree, NWN, gleam@yielder:yielder(tree(NWN))}.

-file("src/qcheck/tree.gleam", 39).
-spec new(NWO, fun((NWO) -> gleam@yielder:yielder(NWO))) -> tree(NWO).
new(X, Shrink) ->
    Shrink_trees = begin
        _pipe = Shrink(X),
        gleam@yielder:map(_pipe, fun(_capture) -> new(_capture, Shrink) end)
    end,
    {tree, X, Shrink_trees}.

-file("src/qcheck/tree.gleam", 47).
-spec map(tree(NWR), fun((NWR) -> NWT)) -> tree(NWT).
map(Tree, F) ->
    {tree, X, Xs} = Tree,
    Y = F(X),
    Ys = gleam@yielder:map(Xs, fun(Smaller_x) -> map(Smaller_x, F) end),
    {tree, Y, Ys}.

-file("src/qcheck/tree.gleam", 55).
-spec bind(tree(NWV), fun((NWV) -> tree(NWX))) -> tree(NWX).
bind(Tree, F) ->
    {tree, X, Xs} = Tree,
    {tree, Y, Ys_of_x} = F(X),
    Ys_of_xs = gleam@yielder:map(Xs, fun(Smaller_x) -> bind(Smaller_x, F) end),
    Ys = gleam@yielder:append(Ys_of_xs, Ys_of_x),
    {tree, Y, Ys}.

-file("src/qcheck/tree.gleam", 67).
-spec apply(tree(fun((NXA) -> NXB)), tree(NXA)) -> tree(NXB).
apply(F, X) ->
    {tree, X0, Xs} = X,
    {tree, F0, Fs} = F,
    Y = F0(X0),
    Ys = gleam@yielder:append(
        gleam@yielder:map(Fs, fun(F_) -> apply(F_, X) end),
        gleam@yielder:map(Xs, fun(X_) -> apply(F, X_) end)
    ),
    {tree, Y, Ys}.

-file("src/qcheck/tree.gleam", 82).
-spec return(NXF) -> tree(NXF).
return(X) ->
    {tree, X, gleam@yielder:empty()}.

-file("src/qcheck/tree.gleam", 108).
-spec yielder_cons(NXS, fun(() -> gleam@yielder:yielder(NXS))) -> gleam@yielder:yielder(NXS).
yielder_cons(Element, Yielder) ->
    gleam@yielder:yield(Element, Yielder).

-file("src/qcheck/tree.gleam", 112).
-spec option(tree(NXV)) -> tree(gleam@option:option(NXV)).
option(Tree) ->
    {tree, X, Xs} = Tree,
    Shrinks = yielder_cons(
        return(none),
        fun() -> gleam@yielder:map(Xs, fun option/1) end
    ),
    {tree, {some, X}, Shrinks}.

-file("src/qcheck/tree.gleam", 130).
-spec do_collect(tree(NYD), fun((NYD) -> NYF), list(NYF)) -> list(NYF).
do_collect(Tree, F, Acc) ->
    {tree, Root, Children} = Tree,
    Acc@1 = gleam@yielder:fold(
        Children,
        Acc,
        fun(A_list, A_tree) -> do_collect(A_tree, F, A_list) end
    ),
    [F(Root) | Acc@1].

-file("src/qcheck/tree.gleam", 126).
?DOC(
    " Collect values of the tree into a list, while processing them with the\n"
    " mapping given function `f`.\n"
).
-spec collect(tree(NXZ), fun((NXZ) -> NYB)) -> list(NYB).
collect(Tree, F) ->
    do_collect(Tree, F, []).

-file("src/qcheck/tree.gleam", 159).
-spec do_to_string(
    tree(NYM),
    fun((NYM) -> binary()),
    integer(),
    integer(),
    list(binary())
) -> binary().
do_to_string(Tree, A_to_string, Level, Max_level, Acc) ->
    case Tree of
        {tree, Root, Children} ->
            Padding = gleam@string:repeat(<<"-"/utf8>>, Level),
            Children@1 = case Level > Max_level of
                false ->
                    _pipe = Children,
                    _pipe@1 = gleam@yielder:map(
                        _pipe,
                        fun(Tree@1) ->
                            do_to_string(
                                Tree@1,
                                A_to_string,
                                Level + 1,
                                Max_level,
                                Acc
                            )
                        end
                    ),
                    _pipe@2 = gleam@yielder:to_list(_pipe@1),
                    gleam@string:join(_pipe@2, <<""/utf8>>);

                true ->
                    _pipe@3 = Children,
                    _pipe@4 = gleam@yielder:map(
                        _pipe@3,
                        fun(_) -> <<""/utf8>> end
                    ),
                    _pipe@5 = gleam@yielder:to_list(_pipe@4),
                    gleam@string:join(_pipe@5, <<""/utf8>>)
            end,
            Root@1 = <<Padding/binary, (A_to_string(Root))/binary>>,
            <<<<Root@1/binary, "\n"/utf8>>/binary, Children@1/binary>>
    end.

-file("src/qcheck/tree.gleam", 145).
?DOC(
    " `to_string(tree, element_to_string)` converts a tree into an unspecified string representation.\n"
    "\n"
    " - `element_to_string`: a function that converts individual elements of the tree to strings.\n"
).
-spec to_string(tree(NYI), fun((NYI) -> binary())) -> binary().
to_string(Tree, A_to_string) ->
    do_to_string(Tree, A_to_string, 0, 99999999, []).

-file("src/qcheck/tree.gleam", 151).
?DOC(" Like `to_string` but with a configurable `max_depth`.\n").
-spec to_string_max_depth(tree(NYK), fun((NYK) -> binary()), integer()) -> binary().
to_string_max_depth(Tree, A_to_string, Max_depth) ->
    do_to_string(Tree, A_to_string, 0, Max_depth, []).

-file("src/qcheck/tree.gleam", 193).
-spec parameter(fun((NYP) -> NYQ)) -> fun((NYP) -> NYQ).
parameter(F) ->
    F.

-file("src/qcheck/tree.gleam", 86).
-spec map2(tree(NXH), tree(NXJ), fun((NXH, NXJ) -> NXL)) -> tree(NXL).
map2(A, B, F) ->
    _pipe = begin
        parameter(fun(X1) -> parameter(fun(X2) -> F(X1, X2) end) end)
    end,
    _pipe@1 = return(_pipe),
    _pipe@2 = apply(_pipe@1, A),
    apply(_pipe@2, B).

-file("src/qcheck/tree.gleam", 197).
-spec list_cons(NYR, list(NYR)) -> list(NYR).
list_cons(X, Xs) ->
    [X | Xs].

-file("src/qcheck/tree.gleam", 99).
?DOC(" `sequence_trees(list_of_trees)` sequences a list of trees into a tree of lists.\n").
-spec sequence_trees(list(tree(NXN))) -> tree(list(NXN)).
sequence_trees(L) ->
    case L of
        [] ->
            return([]);

        [Hd | Tl] ->
            map2(Hd, sequence_trees(Tl), fun list_cons/2)
    end.
