-module(proj1).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\proj1.gleam").
-export([main/0]).
-export_type([message_to_supervisor/0, message_to_worker/0, worker_state/0]).

-type message_to_supervisor() :: {result, integer(), boolean()}.

-type message_to_worker() :: start.

-type worker_state() :: {worker_state,
        integer(),
        integer(),
        integer(),
        gleam@erlang@process:subject(message_to_supervisor())}.

-file("src\\proj1.gleam", 73).
-spec supervisor_loop(
    gleam@erlang@process:subject(message_to_supervisor()),
    list(integer())
) -> list(integer()).
supervisor_loop(Subject, Perfect_squares) ->
    case gleam@erlang@process:'receive'(Subject, 100) of
        {ok, {result, Start, true}} ->
            Updated_list = lists:append([Start], Perfect_squares),
            supervisor_loop(Subject, Updated_list);

        {ok, {result, _, false}} ->
            supervisor_loop(Subject, Perfect_squares);

        {error, _} ->
            Perfect_squares
    end.

-file("src\\proj1.gleam", 106).
-spec sum_squares_up_to(integer()) -> integer().
sum_squares_up_to(N) ->
    ((N * (N + 1)) * ((2 * N) + 1)) div 6.

-file("src\\proj1.gleam", 110).
-spec sum_consecutive_squares(integer(), integer()) -> integer().
sum_consecutive_squares(Start, Len) ->
    End = (Start + Len) - 1,
    sum_squares_up_to(End) - sum_squares_up_to(Start - 1).

-file("src\\proj1.gleam", 115).
-spec is_perfect_square(integer()) -> boolean().
is_perfect_square(N) ->
    Sq_root = gleam@float:square_root(erlang:float(N)),
    case Sq_root of
        {ok, Sq_root@1} ->
            erlang:float(erlang:round(Sq_root@1)) =:= Sq_root@1;

        {error, _} ->
            false
    end.

-file("src\\proj1.gleam", 171).
-spec do_calculations(
    integer(),
    integer(),
    gleam@erlang@process:subject(message_to_supervisor()),
    integer()
) -> nil.
do_calculations(Start, Len, Supervisor, End) ->
    case Start > End of
        true ->
            case Start > 0 of
                true ->
                    Sum = sum_consecutive_squares(Start, Len),
                    Perfect = is_perfect_square(Sum),
                    gleam@erlang@process:send(
                        Supervisor,
                        {result, Start, Perfect}
                    ),
                    do_calculations(Start - 1, Len, Supervisor, End);

                false ->
                    nil
            end;

        false ->
            nil
    end.

-file("src\\proj1.gleam", 55).
-spec worker_handle_message(worker_state(), message_to_worker()) -> gleam@otp@actor:next(worker_state(), message_to_worker()).
worker_handle_message(State, Message) ->
    case Message of
        start ->
            do_calculations(
                erlang:element(2, State),
                erlang:element(3, State),
                erlang:element(5, State),
                erlang:element(2, State) - erlang:element(4, State)
            ),
            gleam@otp@actor:stop()
    end,
    gleam@otp@actor:continue(State).

-file("src\\proj1.gleam", 137).
-spec add_workers(
    gleam@otp@static_supervisor:builder(),
    integer(),
    integer(),
    integer(),
    gleam@erlang@process:subject(message_to_supervisor())
) -> gleam@otp@static_supervisor:builder().
add_workers(Builder, N, Len, Sub_problems, Supervisor_data) ->
    case N =< 0 of
        true ->
            Builder;

        false ->
            Initial_state = {worker_state,
                N,
                Len,
                Sub_problems,
                Supervisor_data},
            Worker@1 = case begin
                _pipe = gleam@otp@actor:new(Initial_state),
                _pipe@1 = gleam@otp@actor:on_message(
                    _pipe,
                    fun worker_handle_message/2
                ),
                gleam@otp@actor:start(_pipe@1)
            end of
                {ok, Worker} -> Worker;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"proj1"/utf8>>,
                                function => <<"add_workers"/utf8>>,
                                line => 150,
                                value => _assert_fail,
                                start => 3702,
                                'end' => 3832,
                                pattern_start => 3713,
                                pattern_end => 3723})
            end,
            Subject = erlang:element(3, Worker@1),
            gleam@erlang@process:send(Subject, start),
            Child_spec = {child_specification,
                fun() -> {ok, Worker@1} end,
                temporary,
                false,
                {worker, 5000}},
            Builder@1 = gleam@otp@static_supervisor:add(Builder, Child_spec),
            add_workers(
                Builder@1,
                N - Sub_problems,
                Len,
                Sub_problems,
                Supervisor_data
            )
    end.

-file("src\\proj1.gleam", 13).
-spec main() -> nil.
main() ->
    Args = argv:load(),
    Params = gleam@result:unwrap(gleam@list:rest(erlang:element(4, Args)), []),
    case Params =:= [] of
        true ->
            nil;

        false ->
            N = gleam@result:unwrap(
                gleam_stdlib:parse_int(
                    gleam@result:unwrap(gleam@list:first(Params), <<"0"/utf8>>)
                ),
                0
            ),
            M = gleam@result:unwrap(
                gleam_stdlib:parse_int(
                    gleam@result:unwrap(gleam@list:last(Params), <<"0"/utf8>>)
                ),
                0
            ),
            Sp = 100,
            Subject = gleam@erlang@process:new_subject(),
            Builder = begin
                _pipe = gleam@otp@static_supervisor:new(one_for_one),
                add_workers(_pipe, N, M, Sp, Subject)
            end,
            case gleam@otp@static_supervisor:start(Builder) of
                {ok, _} -> nil;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"proj1"/utf8>>,
                                function => <<"main"/utf8>>,
                                line => 35,
                                value => _assert_fail,
                                start => 1090,
                                'end' => 1151,
                                pattern_start => 1101,
                                pattern_end => 1116})
            end,
            List = supervisor_loop(Subject, []),
            List_string = begin
                _pipe@1 = gleam@list:map(List, fun erlang:integer_to_binary/1),
                gleam@string:join(_pipe@1, <<"\n"/utf8>>)
            end,
            gleam_stdlib:println(List_string)
    end.
