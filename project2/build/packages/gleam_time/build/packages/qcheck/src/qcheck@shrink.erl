-module(qcheck@shrink).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([int_towards/1, float_towards/1, atomic/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Shrinking helper functions\n"
    "\n"
    " This module contains helper functions that can be used to build custom generators (not by composing other generators).\n"
    "\n"
    " They are mostly intended for internal use or \"advanced\" manual construction\n"
    " of generators.  In typical usage, you will probably not need to interact\n"
    " with these functions much, if at all.  As such, they are currently mostly\n"
    " undocumented.\n"
    "\n"
    " In fact, if you are using these functions a lot, file a issue on GitHub\n"
    " and let me know if there are any generator combinators that you're missing.\n"
    "\n"
).

-file("src/qcheck/shrink.gleam", 16).
-spec float_half_difference(float(), float()) -> float().
float_half_difference(X, Y) ->
    (X / 2.0) - (Y / 2.0).

-file("src/qcheck/shrink.gleam", 20).
-spec int_half_difference(integer(), integer()) -> integer().
int_half_difference(X, Y) ->
    (X div 2) - (Y div 2).

-file("src/qcheck/shrink.gleam", 24).
-spec int_shrink_step(integer(), integer()) -> gleam@yielder:step(integer(), integer()).
int_shrink_step(X, Current_shrink) ->
    case X =:= Current_shrink of
        true ->
            done;

        false ->
            Half_difference = int_half_difference(X, Current_shrink),
            case Half_difference =:= 0 of
                true ->
                    {next, Current_shrink, X};

                false ->
                    {next, Current_shrink, Current_shrink + Half_difference}
            end
    end.

-file("src/qcheck/shrink.gleam", 45).
-spec float_shrink_step(float(), float()) -> gleam@yielder:step(float(), float()).
float_shrink_step(X, Current_shrink) ->
    case X =:= Current_shrink of
        true ->
            done;

        false ->
            Half_difference = float_half_difference(X, Current_shrink),
            case Half_difference =:= +0.0 of
                true ->
                    {next, Current_shrink, X};

                false ->
                    {next, Current_shrink, Current_shrink + Half_difference}
            end
    end.

-file("src/qcheck/shrink.gleam", 66).
-spec int_towards(integer()) -> fun((integer()) -> gleam@yielder:yielder(integer())).
int_towards(Destination) ->
    fun(X) ->
        gleam@yielder:unfold(
            Destination,
            fun(Current_shrink) -> int_shrink_step(X, Current_shrink) end
        )
    end.

-file("src/qcheck/shrink.gleam", 74).
-spec float_towards(float()) -> fun((float()) -> gleam@yielder:yielder(float())).
float_towards(Destination) ->
    fun(X) ->
        _pipe = gleam@yielder:unfold(
            Destination,
            fun(Current_shrink) -> float_shrink_step(X, Current_shrink) end
        ),
        gleam@yielder:take(_pipe, 15)
    end.

-file("src/qcheck/shrink.gleam", 87).
?DOC(
    " The `atomic` shrinker treats types as atomic, and never attempts to produce\n"
    " smaller values.\n"
).
-spec atomic() -> fun((NVJ) -> gleam@yielder:yielder(NVJ)).
atomic() ->
    fun(_) -> gleam@yielder:empty() end.
