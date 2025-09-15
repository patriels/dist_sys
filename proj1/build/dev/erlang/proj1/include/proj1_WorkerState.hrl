-record(worker_state, {
    start :: integer(),
    len :: integer(),
    sub_problems :: integer(),
    supervisor_data :: gleam@erlang@process:subject(proj1:message_to_supervisor())
}).
