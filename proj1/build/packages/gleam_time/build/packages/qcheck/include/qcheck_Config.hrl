-record(config, {
    test_count :: integer(),
    max_retries :: integer(),
    seed :: qcheck@random:seed()
}).
