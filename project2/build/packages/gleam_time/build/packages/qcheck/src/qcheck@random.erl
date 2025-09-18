-module(qcheck@random).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([seed/1, random_seed/0, step/2, int/2, float/2, float_weighted/2, weighted/2, uniform/2, choose/2, bind/2, then/2, map/2, to_random_yielder/1, to_yielder/2, random_sample/1, sample/2, constant/1]).
-export_type([seed/0, generator/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Random\n"
    "\n"
    " The random module provides basic random value generators that can be used\n"
    " to define Generators.\n"
    "\n"
    " They are mostly inteded for internal use or \"advanced\" manual construction\n"
    " of generators.  In typical usage, you will probably not need to interact\n"
    " with these functions much, if at all.  As such, they are currently mostly\n"
    " undocumented.\n"
    "\n"
).

-opaque seed() :: {seed, prng@seed:seed()}.

-opaque generator(NRD) :: {generator, prng@random:generator(NRD)}.

-file("src/qcheck/random.gleam", 40).
?DOC(
    " `seed(n) creates a new seed from the given integer, `n`.\n"
    "\n"
    " ### Example\n"
    "\n"
    " Use a specific seed for the `Config`.\n"
    "\n"
    " ```\n"
    " let config =\n"
    "   qcheck.default_config()\n"
    "   |> qcheck.with_seed(qcheck.seed(124))\n"
    " ```\n"
).
-spec seed(integer()) -> seed().
seed(N) ->
    _pipe = prng_ffi:new_seed(N),
    {seed, _pipe}.

-file("src/qcheck/random.gleam", 57).
?DOC(
    " `random_seed()` creates a new randomly-generated seed.  You can use it when\n"
    " you don't care about having specifically reproducible results.\n"
    "\n"
    " ### Example\n"
    "\n"
    " Use a random seed for the `Config`.\n"
    "\n"
    " ```\n"
    " let config =\n"
    "   qcheck.default_config()\n"
    "   |> qcheck.with_seed(qcheck.random_seed())\n"
    " ```\n"
).
-spec random_seed() -> seed().
random_seed() ->
    _pipe = prng@seed:random(),
    {seed, _pipe}.

-file("src/qcheck/random.gleam", 73).
-spec step(generator(NRE), seed()) -> {NRE, seed()}.
step(Generator, Seed) ->
    {A, Seed@1} = prng@random:step(
        erlang:element(2, Generator),
        erlang:element(2, Seed)
    ),
    {A, {seed, Seed@1}}.

-file("src/qcheck/random.gleam", 78).
-spec int(integer(), integer()) -> generator(integer()).
int(From, To) ->
    _pipe = prng@random:int(From, To),
    {generator, _pipe}.

-file("src/qcheck/random.gleam", 82).
-spec float(float(), float()) -> generator(float()).
float(From, To) ->
    _pipe = prng@random:float(From, To),
    {generator, _pipe}.

-file("src/qcheck/random.gleam", 90).
?DOC(
    " Like `weighted` but uses `Floats` to specify the weights.\n"
    "\n"
    " Generally you should prefer `weighted` as it is faster.\n"
).
-spec float_weighted({float(), NRI}, list({float(), NRI})) -> generator(NRI).
float_weighted(First, Others) ->
    _pipe = prng@random:weighted(First, Others),
    {generator, _pipe}.

-file("src/qcheck/random.gleam", 113).
-spec get_by_weight({integer(), NRT}, list({integer(), NRT}), integer()) -> NRT.
get_by_weight(First, Others, Countdown) ->
    {Weight, Value} = First,
    case Others of
        [] ->
            Value;

        [Second | Rest] ->
            Positive_weight = gleam@int:absolute_value(Weight),
            case gleam@int:compare(Countdown, Positive_weight) of
                lt ->
                    Value;

                gt ->
                    get_by_weight(Second, Rest, Countdown - Positive_weight);

                eq ->
                    get_by_weight(Second, Rest, Countdown - Positive_weight)
            end
    end.

-file("src/qcheck/random.gleam", 97).
-spec weighted({integer(), NRL}, list({integer(), NRL})) -> generator(NRL).
weighted(First, Others) ->
    Normalise = fun(Pair) ->
        gleam@int:absolute_value(gleam@pair:first(Pair))
    end,
    Total = Normalise(First) + gleam@int:sum(gleam@list:map(Others, Normalise)),
    _pipe = prng@random:map(
        prng@random:int(0, Total - 1),
        fun(_capture) -> get_by_weight(First, Others, _capture) end
    ),
    {generator, _pipe}.

-file("src/qcheck/random.gleam", 105).
-spec uniform(NRO, list(NRO)) -> generator(NRO).
uniform(First, Others) ->
    weighted(
        {1, First},
        gleam@list:map(Others, fun(_capture) -> gleam@pair:new(1, _capture) end)
    ).

-file("src/qcheck/random.gleam", 109).
-spec choose(NRR, NRR) -> generator(NRR).
choose(One, Other) ->
    uniform(One, [Other]).

-file("src/qcheck/random.gleam", 127).
-spec bind(generator(NRV), fun((NRV) -> generator(NRX))) -> generator(NRX).
bind(Generator, F) ->
    _pipe = prng@random:then(
        erlang:element(2, Generator),
        fun(A) ->
            Generator@1 = F(A),
            erlang:element(2, Generator@1)
        end
    ),
    {generator, _pipe}.

-file("src/qcheck/random.gleam", 139).
?DOC(" `then` is an alias for `bind`.\n").
-spec then(generator(NSA), fun((NSA) -> generator(NSC))) -> generator(NSC).
then(Generator, F) ->
    bind(Generator, F).

-file("src/qcheck/random.gleam", 143).
-spec map(generator(NSF), fun((NSF) -> NSH)) -> generator(NSH).
map(Generator, Fun) ->
    _pipe = prng@random:map(erlang:element(2, Generator), Fun),
    {generator, _pipe}.

-file("src/qcheck/random.gleam", 147).
-spec to_random_yielder(generator(NSJ)) -> gleam@yielder:yielder(NSJ).
to_random_yielder(Generator) ->
    prng@random:to_random_yielder(erlang:element(2, Generator)).

-file("src/qcheck/random.gleam", 151).
-spec to_yielder(generator(NSM), seed()) -> gleam@yielder:yielder(NSM).
to_yielder(Generator, Seed) ->
    prng@random:to_yielder(
        erlang:element(2, Generator),
        erlang:element(2, Seed)
    ).

-file("src/qcheck/random.gleam", 155).
-spec random_sample(generator(NSP)) -> NSP.
random_sample(Generator) ->
    prng@random:random_sample(erlang:element(2, Generator)).

-file("src/qcheck/random.gleam", 159).
-spec sample(generator(NSR), seed()) -> NSR.
sample(Generator, Seed) ->
    prng@random:sample(erlang:element(2, Generator), erlang:element(2, Seed)).

-file("src/qcheck/random.gleam", 163).
-spec constant(NST) -> generator(NST).
constant(Value) ->
    _pipe = prng@random:constant(Value),
    {generator, _pipe}.
