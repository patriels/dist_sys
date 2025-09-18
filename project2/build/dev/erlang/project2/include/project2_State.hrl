-record(state, {
    val1 :: float(),
    val2 :: float(),
    val3 :: integer(),
    neighbors :: list({integer(),
        gleam@erlang@process:subject(project2:message())})
}).
