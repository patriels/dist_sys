-module(project2).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\project2.gleam").
-export([build_state/2, num_to_coords/2, coords_to_num/2, get_3d_neighbors/2, assign_neighbors/3, find_random_actor/2, start_workers/4, main/0, find_random_neighbor/1, get_imp3d_neighbors/2]).
-export_type([monitor/0, message/0, state/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type monitor() :: update.

-type message() :: {push_sum, float(), float()} |
    {gossip, float()} |
    {neighbor_set_up,
        list({integer(), gleam@erlang@process:subject(message())})} |
    start.

-type state() :: {state,
        float(),
        float(),
        integer(),
        list({integer(), gleam@erlang@process:subject(message())})}.

-file("src\\project2.gleam", 187).
-spec build_state(integer(), binary()) -> state().
build_state(N, Algorithm) ->
    case Algorithm of
        <<"gossip"/utf8>> ->
            {state, +0.0, 10.0, 0, []};

        <<"push-sum"/utf8>> ->
            N_float = erlang:float(N),
            {state, N_float, 1.0, 0, []};

        _ ->
            gleam_stdlib:println(<<"invalid algorithm input"/utf8>>),
            {state, +0.0, +0.0, 0, []}
    end.

-file("src\\project2.gleam", 345).
-spec num_to_coords(integer(), integer()) -> {integer(), integer(), integer()}.
num_to_coords(N, Size) ->
    X = case Size of
        0 -> 0;
        Gleam@denominator -> (N - 1) rem Gleam@denominator
    end,
    Y = case Size of
        0 -> 0;
        Gleam@denominator@2 -> (case Size of
            0 -> 0;
            Gleam@denominator@1 -> (N - 1) div Gleam@denominator@1
        end) rem Gleam@denominator@2
    end,
    Z = case (Size * Size) of
        0 -> 0;
        Gleam@denominator@3 -> N div Gleam@denominator@3
    end,
    {X, Y, Z}.

-file("src\\project2.gleam", 354).
-spec coords_to_num({integer(), integer(), integer()}, integer()) -> integer().
coords_to_num(Coords, Size) ->
    {X, Y, Z} = Coords,
    ((1 + X) + (Y * Size)) + ((Z * Size) * Size).

-file("src\\project2.gleam", 280).
-spec get_3d_neighbors(
    integer(),
    list({integer(), gleam@erlang@process:subject(message())})
) -> list({integer(), gleam@erlang@process:subject(message())}).
get_3d_neighbors(N, Actors) ->
    Num_actors = erlang:length(Actors),
    Grid_size = gleam@float:power(erlang:float(Num_actors), 1.0 / 3.0),
    Grid_int = erlang:round(gleam@result:unwrap(Grid_size, +0.0)),
    {X, Y, Z} = num_to_coords(N, Grid_int),
    Candidates = [{X - 1, Y, Z},
        {X + 1, Y, Z},
        {X, Y - 1, Z},
        {X, Y + 1, Z},
        {X, Y, Z - 1},
        {X, Y, Z + 1}],
    Neighbors = gleam@list:filter_map(
        Candidates,
        fun(X@1) ->
            {Nx, Ny, Nz} = X@1,
            case (((((Nx >= 0) andalso (Ny >= 0)) andalso (Nz >= 0)) andalso (Nx
            < Grid_int))
            andalso (Ny < Grid_int))
            andalso (Nz < Grid_int) of
                true ->
                    Num = coords_to_num(X@1, Grid_int),
                    case gleam@list:find(
                        Actors,
                        fun(X@2) -> gleam@pair:first(X@2) =:= (Num - 1) end
                    ) of
                        {ok, Actor} ->
                            {ok, Actor};

                        {error, _} ->
                            {error, nil}
                    end;

                false ->
                    {error, nil}
            end
        end
    ),
    Neighbors.

-file("src\\project2.gleam", 236).
-spec assign_neighbors(
    integer(),
    binary(),
    list({integer(), gleam@erlang@process:subject(message())})
) -> nil.
assign_neighbors(N, Topology, Actors) ->
    case N of
        0 ->
            gleam_stdlib:println(<<"full topology created"/utf8>>);

        _ ->
            Result@1 = case gleam@list:find(
                Actors,
                fun(X) -> gleam@pair:first(X) =:= N end
            ) of
                {ok, Result} -> Result;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"project2"/utf8>>,
                                function => <<"assign_neighbors"/utf8>>,
                                line => 246,
                                value => _assert_fail,
                                start => 6685,
                                'end' => 6756,
                                pattern_start => 6696,
                                pattern_end => 6706})
            end,
            Subject = gleam@pair:second(Result@1),
            case Topology of
                <<"full"/utf8>> ->
                    gleam@otp@actor:send(
                        Subject,
                        {neighbor_set_up,
                            gleam@list:filter(
                                Actors,
                                fun(X@1) -> erlang:element(1, X@1) /= N end
                            )}
                    );

                <<"3D"/utf8>> ->
                    Neighbors = get_3d_neighbors(N, Actors),
                    gleam@otp@actor:send(Subject, {neighbor_set_up, Neighbors});

                <<"line"/utf8>> ->
                    gleam@otp@actor:send(
                        Subject,
                        {neighbor_set_up,
                            gleam@list:filter(
                                Actors,
                                fun(X@2) ->
                                    (erlang:element(1, X@2) =:= (N + 1)) orelse (erlang:element(
                                        1,
                                        X@2
                                    )
                                    =:= (N - 1))
                                end
                            )}
                    );

                <<"imp3D"/utf8>> ->
                    gleam_stdlib:println(<<"imperfect 3d topology"/utf8>>);

                _ ->
                    gleam_stdlib:println(<<"invalid topology input"/utf8>>)
            end,
            assign_neighbors(N - 1, Topology, Actors)
    end.

-file("src\\project2.gleam", 360).
-spec find_random_actor(
    list({integer(), gleam@erlang@process:subject(message())}),
    integer()
) -> gleam@erlang@process:subject(message()).
find_random_actor(List, N) ->
    Rando = gleam@int:random(N) + 1,
    Result@1 = case gleam@list:find(
        List,
        fun(X) -> gleam@pair:first(X) =:= Rando end
    ) of
        {ok, Result} -> Result;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"project2"/utf8>>,
                        function => <<"find_random_actor"/utf8>>,
                        line => 365,
                        value => _assert_fail,
                        start => 9949,
                        'end' => 10022,
                        pattern_start => 9960,
                        pattern_end => 9970})
    end,
    gleam@pair:second(Result@1).

-file("src\\project2.gleam", 102).
?DOC(
    "define the start fucntion for when a worker is messaaged\n"
    " when a work receives the start meesage it starts calculations\n"
).
-spec worker_handle_message(state(), message()) -> gleam@otp@actor:next(state(), message()).
worker_handle_message(State, Message) ->
    case Message of
        {push_sum, Sum, Weight} ->
            Curr_sum = erlang:element(2, State) + Sum,
            Halved_sum = Curr_sum / 2.0,
            Curr_weight = erlang:element(3, State) + Weight,
            Halved_weight = Curr_weight / 2.0,
            Subject = find_random_actor(
                erlang:element(5, State),
                erlang:length(erlang:element(5, State))
            ),
            gleam@otp@actor:send(Subject, {push_sum, Halved_sum, Halved_weight}),
            Prev_ratio = case erlang:element(3, State) of
                +0.0 -> +0.0;
                -0.0 -> -0.0;
                Gleam@denominator -> erlang:element(2, State) / Gleam@denominator
            end,
            Curr_ratio = case Halved_weight of
                +0.0 -> +0.0;
                -0.0 -> -0.0;
                Gleam@denominator@1 -> Halved_sum / Gleam@denominator@1
            end,
            Num_repeats = case gleam@float:absolute_value(
                Prev_ratio - Curr_ratio
            )
            =< 1.0e-10 of
                true ->
                    erlang:element(4, State) + 1;

                false ->
                    0
            end,
            case Num_repeats =:= 3 of
                true ->
                    gleam@otp@actor:stop();

                false ->
                    New_state = {state,
                        Halved_sum,
                        Halved_weight,
                        Num_repeats,
                        erlang:element(5, State)},
                    gleam@otp@actor:continue(New_state)
            end;

        {gossip, Rumor} ->
            case erlang:element(3, State) > +0.0 of
                true ->
                    New_count = gleam@float:subtract(
                        erlang:element(3, State),
                        1.0
                    ),
                    Neighbor = find_random_actor(
                        erlang:element(5, State),
                        erlang:length(erlang:element(5, State))
                    ),
                    gleam@otp@actor:send(Neighbor, {gossip, Rumor}),
                    New_state@1 = {state,
                        Rumor,
                        New_count,
                        0,
                        erlang:element(5, State)},
                    gleam@otp@actor:continue(New_state@1);

                false ->
                    gleam_stdlib:println(
                        <<"I will no longer hear the rumor"/utf8>>
                    ),
                    gleam@otp@actor:stop()
            end,
            gleam@otp@actor:stop();

        {neighbor_set_up, Neighbors} ->
            New_state@2 = {state,
                erlang:element(2, State),
                erlang:element(3, State),
                0,
                Neighbors},
            gleam@otp@actor:continue(New_state@2);

        start ->
            Halved_sum@1 = erlang:element(2, State) / 2.0,
            Halved_weight@1 = erlang:element(3, State) / 2.0,
            Subject@1 = find_random_actor(
                erlang:element(5, State),
                erlang:length(erlang:element(5, State))
            ),
            gleam@otp@actor:send(
                Subject@1,
                {push_sum, Halved_sum@1, Halved_weight@1}
            ),
            New_state@3 = {state,
                Halved_sum@1,
                Halved_weight@1,
                0,
                erlang:element(5, State)},
            gleam@otp@actor:continue(New_state@3)
    end.

-file("src\\project2.gleam", 206).
-spec start_workers(
    integer(),
    binary(),
    binary(),
    list({integer(), gleam@erlang@process:subject(message())})
) -> list({integer(), gleam@erlang@process:subject(message())}).
start_workers(N, Topology, Algorithm, Workers) ->
    case N > 0 of
        true ->
            Initial_state = build_state(N, Algorithm),
            Actor@1 = case begin
                _pipe = gleam@otp@actor:new(Initial_state),
                _pipe@1 = gleam@otp@actor:on_message(
                    _pipe,
                    fun worker_handle_message/2
                ),
                gleam@otp@actor:start(_pipe@1)
            end of
                {ok, Actor} -> Actor;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"project2"/utf8>>,
                                function => <<"start_workers"/utf8>>,
                                line => 217,
                                value => _assert_fail,
                                start => 5906,
                                'end' => 6058,
                                pattern_start => 5917,
                                pattern_end => 5926})
            end,
            New_workers = lists:append(
                Workers,
                [{N, erlang:element(3, Actor@1)}]
            ),
            start_workers(N - 1, Topology, Algorithm, New_workers);

        false ->
            assign_neighbors(erlang:length(Workers), Topology, Workers),
            Workers
    end.

-file("src\\project2.gleam", 13).
-spec main() -> nil.
main() ->
    Time_start = gleam@time@timestamp:system_time(),
    Args@1 = case gleam@list:rest(erlang:element(4, argv:load())) of
        {ok, Args} -> Args;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"project2"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 15,
                        value => _assert_fail,
                        start => 310,
                        'end' => 364,
                        pattern_start => 321,
                        pattern_end => 329})
    end,
    Len = erlang:length(Args@1),
    case Len of
        3 ->
            echo(<<"we have args"/utf8>>, nil, 19),
            Num_string@1 = case gleam@list:first(Args@1) of
                {ok, Num_string} -> Num_string;
                _assert_fail@1 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"project2"/utf8>>,
                                function => <<"main"/utf8>>,
                                line => 21,
                                value => _assert_fail@1,
                                start => 500,
                                'end' => 544,
                                pattern_start => 511,
                                pattern_end => 525})
            end,
            N@1 = case gleam_stdlib:parse_int(Num_string@1) of
                {ok, N} -> N;
                _assert_fail@2 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"project2"/utf8>>,
                                function => <<"main"/utf8>>,
                                line => 22,
                                value => _assert_fail@2,
                                start => 551,
                                'end' => 591,
                                pattern_start => 562,
                                pattern_end => 567})
            end,
            Args@3 = case gleam@list:rest(Args@1) of
                {ok, Args@2} -> Args@2;
                _assert_fail@3 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"project2"/utf8>>,
                                function => <<"main"/utf8>>,
                                line => 24,
                                value => _assert_fail@3,
                                start => 644,
                                'end' => 681,
                                pattern_start => 655,
                                pattern_end => 663})
            end,
            Topology@1 = case gleam@list:first(Args@3) of
                {ok, Topology} -> Topology;
                _assert_fail@4 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"project2"/utf8>>,
                                function => <<"main"/utf8>>,
                                line => 25,
                                value => _assert_fail@4,
                                start => 688,
                                'end' => 730,
                                pattern_start => 699,
                                pattern_end => 711})
            end,
            Args@5 = case gleam@list:rest(Args@3) of
                {ok, Args@4} -> Args@4;
                _assert_fail@5 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"project2"/utf8>>,
                                function => <<"main"/utf8>>,
                                line => 27,
                                value => _assert_fail@5,
                                start => 784,
                                'end' => 821,
                                pattern_start => 795,
                                pattern_end => 803})
            end,
            Algorithm@1 = case gleam@list:first(Args@5) of
                {ok, Algorithm} -> Algorithm;
                _assert_fail@6 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"project2"/utf8>>,
                                function => <<"main"/utf8>>,
                                line => 28,
                                value => _assert_fail@6,
                                start => 828,
                                'end' => 871,
                                pattern_start => 839,
                                pattern_end => 852})
            end,
            Empty_actors = [],
            Actors = start_workers(N@1, Topology@1, Algorithm@1, Empty_actors),
            Random_actor = find_random_actor(Actors, erlang:length(Actors)),
            case Algorithm@1 of
                <<"gossip"/utf8>> ->
                    gleam@otp@actor:send(Random_actor, {gossip, 8.0});

                <<"push-sum"/utf8>> ->
                    gleam@otp@actor:send(Random_actor, start);

                _ ->
                    gleam_stdlib:println(<<"Invalid algorithm"/utf8>>)
            end;

        _ ->
            nil
    end,
    Time_end = gleam@time@timestamp:system_time(),
    Duration = gleam@time@timestamp:difference(Time_start, Time_end),
    Time = gleam@time@duration:to_seconds(Duration),
    gleam_stdlib:println(gleam_stdlib:float_to_string(Time)).

-file("src\\project2.gleam", 369).
-spec find_random_neighbor(
    list({integer(), gleam@erlang@process:subject(message())})
) -> {integer(), gleam@erlang@process:subject(message())}.
find_random_neighbor(List) ->
    Num_actors = erlang:length(List),
    Rando = gleam@int:random(Num_actors),
    Result@1 = case gleam@list:find(
        List,
        fun(X) -> gleam@pair:first(X) =:= Rando end
    ) of
        {ok, Result} -> Result;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"project2"/utf8>>,
                        function => <<"find_random_neighbor"/utf8>>,
                        line => 374,
                        value => _assert_fail,
                        start => 10233,
                        'end' => 10306,
                        pattern_start => 10244,
                        pattern_end => 10254})
    end,
    Result@1.

-file("src\\project2.gleam", 327).
-spec get_imp3d_neighbors(
    integer(),
    list({integer(), gleam@erlang@process:subject(message())})
) -> list({integer(), gleam@erlang@process:subject(message())}).
get_imp3d_neighbors(N, Actors) ->
    Reg_neighbors = get_3d_neighbors(N, Actors),
    Others = gleam@list:filter(
        Actors,
        fun(Actor) -> not gleam@list:contains(Reg_neighbors, Actor) end
    ),
    Rando = find_random_neighbor(Others),
    lists:append(Reg_neighbors, [Rando]).

-define(is_lowercase_char(X),
    (X > 96 andalso X < 123)).

-define(is_underscore_char(X),
    (X == 95)).

-define(is_digit_char(X),
    (X > 47 andalso X < 58)).

-define(is_ascii_character(X),
    (erlang:is_integer(X) andalso X >= 32 andalso X =< 126)).

-define(could_be_record(Tuple),
    erlang:is_tuple(Tuple) andalso
        erlang:is_atom(erlang:element(1, Tuple)) andalso
        erlang:element(1, Tuple) =/= false andalso
        erlang:element(1, Tuple) =/= true andalso
        erlang:element(1, Tuple) =/= nil
).
-define(is_atom_char(C),
    (?is_lowercase_char(C) orelse
        ?is_underscore_char(C) orelse
        ?is_digit_char(C))
).

-define(grey, "\e[90m").
-define(reset_color, "\e[39m").

echo(Value, Message, Line) ->
    StringLine = erlang:integer_to_list(Line),
    StringValue = echo@inspect(Value),
    StringMessage =
        case Message of
            nil -> "";
            M -> [" ", M]
        end,

    io:put_chars(
      standard_error,
      [
        ?grey, ?FILEPATH, $:, StringLine, ?reset_color, StringMessage, $\n,
        StringValue, $\n
      ]
    ),
    Value.

echo@inspect(Value) ->
    case Value of
        nil -> "Nil";
        true -> "True";
        false -> "False";
        Int when erlang:is_integer(Int) -> erlang:integer_to_list(Int);
        Float when erlang:is_float(Float) -> io_lib_format:fwrite_g(Float);
        Binary when erlang:is_binary(Binary) -> inspect@binary(Binary);
        Bits when erlang:is_bitstring(Bits) -> inspect@bit_array(Bits);
        Atom when erlang:is_atom(Atom) -> inspect@atom(Atom);
        List when erlang:is_list(List) -> inspect@list(List);
        Map when erlang:is_map(Map) -> inspect@map(Map);
        Record when ?could_be_record(Record) -> inspect@record(Record);
        Tuple when erlang:is_tuple(Tuple) -> inspect@tuple(Tuple);
        Function when erlang:is_function(Function) -> inspect@function(Function);
        Any -> ["//erl(", io_lib:format("~p", [Any]), ")"]
    end.

inspect@bit_array(Bits) ->
    Pieces = inspect@bit_array_pieces(Bits, []),
    Inner = lists:join(", ", lists:reverse(Pieces)),
    ["<<", Inner, ">>"].

inspect@bit_array_pieces(Bits, Acc) ->
    case Bits of
        <<>> ->
            Acc;
        <<Byte, Rest/bitstring>> ->
            inspect@bit_array_pieces(Rest, [erlang:integer_to_binary(Byte) | Acc]);
        _ ->
            Size = erlang:bit_size(Bits),
            <<RemainingBits:Size>> = Bits,
            SizeString = [":size(", erlang:integer_to_binary(Size), ")"],
            Piece = [erlang:integer_to_binary(RemainingBits), SizeString],
            [Piece | Acc]
    end.

inspect@binary(Binary) ->
    case inspect@maybe_utf8_string(Binary, <<>>) of
        {ok, InspectedUtf8String} ->
            InspectedUtf8String;
        {error, not_a_utf8_string} ->
            Segments = [erlang:integer_to_list(X) || <<X>> <= Binary],
            ["<<", lists:join(", ", Segments), ">>"]
    end.

inspect@atom(Atom) ->
    Binary = erlang:atom_to_binary(Atom),
    case inspect@maybe_gleam_atom(Binary, none, <<>>) of
        {ok, Inspected} -> Inspected;
        {error, _} -> ["atom.create_from_string(\"", Binary, "\")"]
    end.

inspect@list(List) ->
    case inspect@list_loop(List, true) of
        {charlist, _} -> ["charlist.from_string(\"", erlang:list_to_binary(List), "\")"];
        {proper, Elements} -> ["[", Elements, "]"];
        {improper, Elements} -> ["//erl([", Elements, "])"]
    end.

inspect@map(Map) ->
    Fields = [
        [<<"#(">>, echo@inspect(Key), <<", ">>, echo@inspect(Value), <<")">>]
        || {Key, Value} <- maps:to_list(Map)
    ],
    ["dict.from_list([", lists:join(", ", Fields), "])"].

inspect@record(Record) ->
    [Atom | ArgsList] = Tuple = erlang:tuple_to_list(Record),
    case inspect@maybe_gleam_atom(Atom, none, <<>>) of
        {ok, Tag} ->
            Args = lists:join(", ", lists:map(fun echo@inspect/1, ArgsList)),
            [Tag, "(", Args, ")"];
        _ ->
            inspect@tuple(Tuple)
    end.

inspect@tuple(Tuple) when erlang:is_tuple(Tuple) ->
    inspect@tuple(erlang:tuple_to_list(Tuple));
inspect@tuple(Tuple) ->
    Elements = lists:map(fun echo@inspect/1, Tuple),
    ["#(", lists:join(", ", Elements), ")"].

inspect@function(Function) ->
    {arity, Arity} = erlang:fun_info(Function, arity),
    ArgsAsciiCodes = lists:seq($a, $a + Arity - 1),
    Args = lists:join(", ", lists:map(fun(Arg) -> <<Arg>> end, ArgsAsciiCodes)),
    ["//fn(", Args, ") { ... }"].

inspect@maybe_utf8_string(Binary, Acc) ->
    case Binary of
        <<>> ->
            {ok, <<$", Acc/binary, $">>};
        <<First/utf8, Rest/binary>> ->
            Escaped = inspect@escape_grapheme(First),
            inspect@maybe_utf8_string(Rest, <<Acc/binary, Escaped/binary>>);
        _ ->
            {error, not_a_utf8_string}
    end.

inspect@escape_grapheme(Char) ->
    case Char of
        $" -> <<$\\, $">>;
        $\\ -> <<$\\, $\\>>;
        $\r -> <<$\\, $r>>;
        $\n -> <<$\\, $n>>;
        $\t -> <<$\\, $t>>;
        $\f -> <<$\\, $f>>;
        X when X > 126, X < 160 -> inspect@convert_to_u(X);
        X when X < 32 -> inspect@convert_to_u(X);
        Other -> <<Other/utf8>>
    end.

inspect@convert_to_u(Code) ->
    erlang:list_to_binary(io_lib:format("\\u{~4.16.0B}", [Code])).

inspect@list_loop(List, Ascii) ->
    case List of
        [] ->
            {proper, []};
        [First] when Ascii andalso ?is_ascii_character(First) ->
            {charlist, nil};
        [First] ->
            {proper, [echo@inspect(First)]};
        [First | Rest] when erlang:is_list(Rest) ->
            StillAscii = Ascii andalso ?is_ascii_character(First),
            {Kind, Inspected} = inspect@list_loop(Rest, StillAscii),
            {Kind, [echo@inspect(First), ", " | Inspected]};
        [First | ImproperRest] ->
            {improper, [echo@inspect(First), " | ", echo@inspect(ImproperRest)]}
    end.

inspect@maybe_gleam_atom(Atom, PrevChar, Acc) when erlang:is_atom(Atom) ->
    Binary = erlang:atom_to_binary(Atom),
    inspect@maybe_gleam_atom(Binary, PrevChar, Acc);
inspect@maybe_gleam_atom(Atom, PrevChar, Acc) ->
    case {Atom, PrevChar} of
        {<<>>, none} ->
            {error, nil};
        {<<First, _/binary>>, none} when ?is_digit_char(First) ->
            {error, nil};
        {<<"_", _/binary>>, none} ->
            {error, nil};
        {<<"_">>, _} ->
            {error, nil};
        {<<"_", _/binary>>, $_} ->
            {error, nil};
        {<<First, _/binary>>, _} when not ?is_atom_char(First) ->
            {error, nil};
        {<<First, Rest/binary>>, none} ->
            inspect@maybe_gleam_atom(Rest, First, <<Acc/binary, (inspect@uppercase(First))>>);
        {<<"_", Rest/binary>>, _} ->
            inspect@maybe_gleam_atom(Rest, $_, Acc);
        {<<First, Rest/binary>>, $_} ->
            inspect@maybe_gleam_atom(Rest, First, <<Acc/binary, (inspect@uppercase(First))>>);
        {<<First, Rest/binary>>, _} ->
            inspect@maybe_gleam_atom(Rest, First, <<Acc/binary, First>>);
        {<<>>, _} ->
            {ok, Acc};
        _ ->
            erlang:throw({gleam_error, echo, Atom, PrevChar, Acc})
    end.

inspect@uppercase(X) -> X - 32.

