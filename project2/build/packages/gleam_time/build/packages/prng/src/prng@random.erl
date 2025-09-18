-module(prng@random).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([step/2, sample/2, to_yielder/2, to_random_yielder/1, random_sample/1, int/2, float/2, constant/1, fixed_size_list/2, then/2, list/1, map/2, weighted/2, try_weighted/1, map2/3, pair/2, uniform/2, try_uniform/1, choose/2, map3/4, map4/5, map5/6, fixed_size_string/1, string/0, bit_array/0, set/1, fixed_size_set/2, dict/2, fixed_size_dict/3]).
-export_type([generator/1]).

-opaque generator(GIJ) :: {generator,
        fun((prng@seed:seed()) -> {GIJ, prng@seed:seed()})}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 154).
-spec step(generator(GIK), prng@seed:seed()) -> {GIK, prng@seed:seed()}.
step(Generator, Seed) ->
    (erlang:element(2, Generator))(Seed).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 164).
-spec sample(generator(GIM), prng@seed:seed()) -> GIM.
sample(Generator, Seed) ->
    erlang:element(1, step(Generator, Seed)).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 224).
-spec to_yielder(generator(GIT), prng@seed:seed()) -> gleam@yielder:yielder(GIT).
to_yielder(Generator, Seed) ->
    gleam@yielder:unfold(
        Seed,
        fun(Seed@1) ->
            {Value, New_seed} = step(Generator, Seed@1),
            {next, Value, New_seed}
        end
    ).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 210).
-spec to_random_yielder(generator(GIQ)) -> gleam@yielder:yielder(GIQ).
to_random_yielder(Generator) ->
    to_yielder(Generator, prng@seed:random()).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 191).
-spec random_sample(generator(GIO)) -> GIO.
random_sample(Generator) ->
    _assert_subject = gleam@yielder:first(to_random_yielder(Generator)),
    {ok, Result} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"prng/random"/utf8>>,
                        function => <<"random_sample"/utf8>>,
                        line => 196})
    end,
    Result.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 264).
-spec sort_ascending(GIX, GIX, fun((GIX, GIX) -> gleam@order:order())) -> {GIX,
    GIX}.
sort_ascending(One, Other, Compare) ->
    case Compare(One, Other) of
        lt ->
            {One, Other};

        eq ->
            {One, Other};

        gt ->
            {Other, One}
    end.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 258).
-spec int(integer(), integer()) -> generator(integer()).
int(From, To) ->
    {generator,
        fun(Seed) ->
            {Low, High} = sort_ascending(From, To, fun gleam@int:compare/2),
            prng_ffi:random_int(Seed, Low, High)
        end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 283).
-spec float(float(), float()) -> generator(float()).
float(From, To) ->
    {generator,
        fun(Seed) ->
            {Low, High} = sort_ascending(From, To, fun gleam@float:compare/2),
            prng_ffi:random_float(Seed, Low, High)
        end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 305).
-spec constant(GIZ) -> generator(GIZ).
constant(Value) ->
    {generator, fun(Seed) -> {Value, Seed} end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 465).
-spec get_by_weight({float(), GJR}, list({float(), GJR}), float()) -> GJR.
get_by_weight(First, Others, Countdown) ->
    {Weight, Value} = First,
    case Others of
        [] ->
            Value;

        [Second | Rest] ->
            Positive_weight = gleam@float:absolute_value(Weight),
            case gleam@float:compare(Countdown, Positive_weight) of
                lt ->
                    Value;

                eq ->
                    Value;

                gt ->
                    get_by_weight(Second, Rest, Countdown - Positive_weight)
            end
    end.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 552).
-spec do_fixed_size_list(list(GKE), prng@seed:seed(), generator(GKE), integer()) -> {list(GKE),
    prng@seed:seed()}.
do_fixed_size_list(Acc, Seed, Generator, Length) ->
    case Length =< 0 of
        true ->
            {Acc, Seed};

        false ->
            {Value, Seed@1} = step(Generator, Seed),
            do_fixed_size_list([Value | Acc], Seed@1, Generator, Length - 1)
    end.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 544).
-spec fixed_size_list(generator(GKA), integer()) -> generator(list(GKA)).
fixed_size_list(Generator, Length) ->
    {generator,
        fun(Seed) -> do_fixed_size_list([], Seed, Generator, Length) end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 746).
-spec then(generator(GLT), fun((GLT) -> generator(GLV))) -> generator(GLV).
then(Generator, Generator_from) ->
    {generator,
        fun(Seed) ->
            {Value, Seed@1} = step(Generator, Seed),
            _pipe = Generator_from(Value),
            step(_pipe, Seed@1)
        end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 573).
-spec list(generator(GKI)) -> generator(list(GKI)).
list(Generator) ->
    then(int(0, 32), fun(Size) -> fixed_size_list(Generator, Size) end).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 773).
-spec map(generator(GLY), fun((GLY) -> GMA)) -> generator(GMA).
map(Generator, Fun) ->
    {generator,
        fun(Seed) ->
            {Value, Seed@1} = step(Generator, Seed),
            {Fun(Value), Seed@1}
        end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 420).
-spec weighted({float(), GJJ}, list({float(), GJJ})) -> generator(GJJ).
weighted(First, Others) ->
    Normalise = fun(Pair) ->
        gleam@float:absolute_value(gleam@pair:first(Pair))
    end,
    Total = Normalise(First) + gleam@float:sum(
        gleam@list:map(Others, Normalise)
    ),
    map(
        float(+0.0, Total),
        fun(_capture) -> get_by_weight(First, Others, _capture) end
    ).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 458).
-spec try_weighted(list({float(), GJM})) -> {ok, generator(GJM)} | {error, nil}.
try_weighted(Options) ->
    case Options of
        [First | Rest] ->
            {ok, weighted(First, Rest)};

        [] ->
            {error, nil}
    end.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 817).
-spec map2(generator(GMC), generator(GME), fun((GMC, GME) -> GMG)) -> generator(GMG).
map2(One, Other, Fun) ->
    {generator,
        fun(Seed) ->
            {A, Seed@1} = step(One, Seed),
            {B, Seed@2} = step(Other, Seed@1),
            {Fun(A, B), Seed@2}
        end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 525).
-spec pair(generator(GJV), generator(GJX)) -> generator({GJV, GJX}).
pair(One, Other) ->
    map2(One, Other, fun gleam@pair:new/2).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 342).
-spec uniform(GJB, list(GJB)) -> generator(GJB).
uniform(First, Others) ->
    weighted(
        {1.0, First},
        gleam@list:map(
            Others,
            fun(_capture) -> gleam@pair:new(1.0, _capture) end
        )
    ).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 378).
-spec try_uniform(list(GJE)) -> {ok, generator(GJE)} | {error, nil}.
try_uniform(Options) ->
    case Options of
        [First | Rest] ->
            {ok, uniform(First, Rest)};

        [] ->
            {error, nil}
    end.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 505).
-spec choose(GJT, GJT) -> generator(GJT).
choose(One, Other) ->
    uniform(One, [Other]).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 861).
-spec map3(
    generator(GMI),
    generator(GMK),
    generator(GMM),
    fun((GMI, GMK, GMM) -> GMO)
) -> generator(GMO).
map3(One, Two, Three, Fun) ->
    {generator,
        fun(Seed) ->
            {A, Seed@1} = step(One, Seed),
            {B, Seed@2} = step(Two, Seed@1),
            {C, Seed@3} = step(Three, Seed@2),
            {Fun(A, B, C), Seed@3}
        end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 878).
-spec map4(
    generator(GMQ),
    generator(GMS),
    generator(GMU),
    generator(GMW),
    fun((GMQ, GMS, GMU, GMW) -> GMY)
) -> generator(GMY).
map4(One, Two, Three, Four, Fun) ->
    {generator,
        fun(Seed) ->
            {A, Seed@1} = step(One, Seed),
            {B, Seed@2} = step(Two, Seed@1),
            {C, Seed@3} = step(Three, Seed@2),
            {D, Seed@4} = step(Four, Seed@3),
            {Fun(A, B, C, D), Seed@4}
        end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 900).
-spec map5(
    generator(GNA),
    generator(GNC),
    generator(GNE),
    generator(GNG),
    generator(GNI),
    fun((GNA, GNC, GNE, GNG, GNI) -> GNK)
) -> generator(GNK).
map5(One, Two, Three, Four, Five, Fun) ->
    {generator,
        fun(Seed) ->
            {A, Seed@1} = step(One, Seed),
            {B, Seed@2} = step(Two, Seed@1),
            {C, Seed@3} = step(Three, Seed@2),
            {D, Seed@4} = step(Four, Seed@3),
            {E, Seed@5} = step(Five, Seed@4),
            {Fun(A, B, C, D, E), Seed@5}
        end}.

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 937).
-spec fixed_size_string(integer()) -> generator(binary()).
fixed_size_string(Size) ->
    _pipe = fixed_size_list(utf_codepoint_in_range(0, 1023), Size),
    map(_pipe, fun gleam_stdlib:utf_codepoint_list_to_string/1).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 925).
-spec string() -> generator(binary()).
string() ->
    then(int(0, 32), fun(Size) -> fixed_size_string(Size) end).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 706).
-spec bit_array() -> generator(bitstring()).
bit_array() ->
    map(string(), fun gleam_stdlib:identity/1).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 948).
-spec utf_codepoint_in_range(integer(), integer()) -> generator(integer()).
utf_codepoint_in_range(Lower, Upper) ->
    then(
        int(Lower, Upper),
        fun(Raw_codepoint) -> case gleam@string:utf_codepoint(Raw_codepoint) of
                {ok, Codepoint} ->
                    constant(Codepoint);

                {error, _} ->
                    utf_codepoint_in_range(Lower, Upper)
            end end
    ).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 699).
-spec set(generator(GLO)) -> generator(gleam@set:set(GLO)).
set(Generator) ->
    then(int(0, 32), fun(Size) -> fixed_size_set(Generator, Size) end).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 651).
-spec fixed_size_set(generator(GLF), integer()) -> generator(gleam@set:set(GLF)).
fixed_size_set(Generator, Size) ->
    _pipe = gleam@int:max(Size, 0),
    do_fixed_size_set(Generator, _pipe, 0, 0, gleam@set:new()).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 659).
-spec do_fixed_size_set(
    generator(GLJ),
    integer(),
    integer(),
    integer(),
    gleam@set:set(GLJ)
) -> generator(gleam@set:set(GLJ)).
do_fixed_size_set(Generator, Size, Unique_items, Consecutive_attempts, Acc) ->
    Has_required_size = Unique_items =:= Size,
    gleam@bool:guard(
        Has_required_size,
        constant(Acc),
        fun() ->
            Has_reached_maximum_attempts = Consecutive_attempts >= 10,
            gleam@bool:guard(
                Has_reached_maximum_attempts,
                constant(Acc),
                fun() ->
                    then(
                        Generator,
                        fun(Item) -> case gleam@set:contains(Acc, Item) of
                                true ->
                                    _pipe = (Consecutive_attempts + 1),
                                    do_fixed_size_set(
                                        Generator,
                                        Size,
                                        Unique_items,
                                        _pipe,
                                        Acc
                                    );

                                false ->
                                    _pipe@1 = gleam@set:insert(Acc, Item),
                                    do_fixed_size_set(
                                        Generator,
                                        Size,
                                        Unique_items + 1,
                                        0,
                                        _pipe@1
                                    )
                            end end
                    )
                end
            )
        end
    ).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 639).
-spec dict(generator(any()), generator(any())) -> generator(gleam@dict:dict(any(), any())).
dict(Keys, Values) ->
    then(int(0, 32), fun(Size) -> fixed_size_dict(Keys, Values, Size) end).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 588).
-spec fixed_size_dict(generator(GKM), generator(GKO), integer()) -> generator(gleam@dict:dict(GKM, GKO)).
fixed_size_dict(Keys, Values, Size) ->
    _pipe = gleam@int:max(Size, 0),
    do_fixed_size_dict(Keys, Values, _pipe, 0, 0, maps:new()).

-file("/Users/giacomocavalieri/Documents/progetti/prng/src/prng/random.gleam", 597).
-spec do_fixed_size_dict(
    generator(GKR),
    generator(GKT),
    integer(),
    integer(),
    integer(),
    gleam@dict:dict(GKR, GKT)
) -> generator(gleam@dict:dict(GKR, GKT)).
do_fixed_size_dict(Keys, Values, Size, Unique_keys, Consecutive_attempts, Acc) ->
    Has_required_size = Unique_keys =:= Size,
    gleam@bool:guard(
        Has_required_size,
        constant(Acc),
        fun() ->
            Has_reached_maximum_attempts = Consecutive_attempts >= 10,
            gleam@bool:guard(
                Has_reached_maximum_attempts,
                constant(Acc),
                fun() ->
                    then(Keys, fun(Key) -> case gleam@dict:has_key(Acc, Key) of
                                true ->
                                    _pipe = (Consecutive_attempts + 1),
                                    do_fixed_size_dict(
                                        Keys,
                                        Values,
                                        Size,
                                        Unique_keys,
                                        _pipe,
                                        Acc
                                    );

                                false ->
                                    then(
                                        Values,
                                        fun(Value) ->
                                            _pipe@1 = gleam@dict:insert(
                                                Acc,
                                                Key,
                                                Value
                                            ),
                                            do_fixed_size_dict(
                                                Keys,
                                                Values,
                                                Size,
                                                Unique_keys + 1,
                                                0,
                                                _pipe@1
                                            )
                                        end
                                    )
                            end end)
                end
            )
        end
    ).
