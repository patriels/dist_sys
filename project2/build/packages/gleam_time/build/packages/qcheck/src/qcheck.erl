-module(qcheck).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([seed/1, random_seed/0, with_seed/2, generator/2, generate/3, generate_tree/2, return/1, constant/1, parameter/1, map/2, bind/2, then/2, apply/2, map2/3, map3/4, map4/5, map5/6, map6/7, tuple2/2, tuple3/3, tuple4/4, tuple5/5, tuple6/6, from_generators/2, from_weighted_generators/2, sized_from/2, option_from/1, nil/0, bool/0, fixed_size_bit_array_from/2, generic_bit_array/2, fixed_size_byte_aligned_bit_array_from/2, generic_byte_aligned_bit_array/2, small_non_negative_int/0, small_strictly_positive_int/0, fixed_length_list_from/2, generic_list/2, list_from/1, generic_dict/3, generic_set/2, generic_utf8_bit_array/2, bounded_int/2, uniform_int/0, bit_array/0, non_empty_bit_array/0, fixed_size_bit_array/1, byte_aligned_bit_array/0, non_empty_byte_aligned_bit_array/0, bounded_float/2, fixed_size_byte_aligned_bit_array/1, with_test_count/2, default_config/0, with_max_retries/2, config/3, float/0, string/0, codepoint/0, uniform_codepoint/0, fixed_length_string_from/2, generic_string/2, non_empty_string/0, string_from/1, non_empty_string_from/1, utf8_bit_array/0, non_empty_utf8_bit_array/0, fixed_size_utf8_bit_array/1, fixed_size_utf8_bit_array_from/2, run/3, given/2, bounded_codepoint/2, uppercase_ascii_codepoint/0, lowercase_ascii_codepoint/0, ascii_digit_codepoint/0, alphabetic_ascii_codepoint/0, alphanumeric_ascii_codepoint/0, uniform_printable_ascii_codepoint/0, printable_ascii_codepoint/0, codepoint_from_ints/2, codepoint_from_strings/2, ascii_whitespace_codepoint/0]).
-export_type([run_property_result/0, config/0, generator/1, generate_option/0, value_with_size/0, test_error/1, 'try'/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " QuickCheck-inspired property-based testing with integrated shrinking\n"
    "\n"
    "\n"
    " ## Overview\n"
    "\n"
    " Rather than specifying test cases manually, you describe the invariants\n"
    " that values of a given type must satisfy (\"properties\"). Then, generators\n"
    " generate lots of values (test cases) on which the properties are checked.\n"
    " Finally, if a value is found for which a given property does not hold, that\n"
    " value is \"shrunk\" in order to find an nice, informative counter-example\n"
    " that is presented to you.\n"
    "\n"
    " This module has functions for running and configuring property tests as\n"
    " well as generating random values (with shrinking) to drive those tests.\n"
    "\n"
    " For full usage examples, see the project README.\n"
    "\n"
    " ## API\n"
    "\n"
    " ### Running Tests\n"
    "\n"
    " - [given](#given)\n"
    " - [run](#run)\n"
    "\n"
    " ### Configuring and Seeding\n"
    "\n"
    " - The [Config](#Config) type\n"
    " - [config](#config)\n"
    " - [default_config](#default_config)\n"
    " - [with_seed](#with_seed)\n"
    " - [with_test_count](#with_test_count)\n"
    " - [with_max_retries](#with_max_retries)\n"
    "\n"
    " - The [Seed](#Seed) type\n"
    " - [seed](#seed)\n"
    " - [random_seed](#random_seed)\n"
    "\n"
    " ### Low-Level Construction\n"
    "\n"
    " - The [Generator](#Generator) type\n"
    " - [generator](#generator)\n"
    "\n"
    " ### Combinators and Other Utilities\n"
    "\n"
    " - [return](#return) (and [constant](#constant))\n"
    " - [bind](#bind) (and [then](#then))\n"
    " - [apply](#apply)\n"
    " - [parameter](#parameter)\n"
    " - [map](#map)\n"
    " - [map2](#map2)\n"
    " - [map3](#map3)\n"
    " - [map4](#map4)\n"
    " - [map5](#map5)\n"
    " - [map6](#map6)\n"
    " - [from_generators](#from_generators)\n"
    " - [from_weighted_generators](#from_weighted_generators)\n"
    " - [sized_from](#sized_from)\n"
    "\n"
    " ### Generator Categories\n"
    "\n"
    " There are a few different \"categories\" of generator.\n"
    "\n"
    " - Some types have generators named after the type.\n"
    "   - These give a distribution of values that is a reasonable default for test generation.\n"
    "   - E.g., `string`, `float`, `bit_array`.\n"
    " - Generic generators\n"
    "   - These are fully specified, or \"generic\", and you must provide generators for values and sizes.\n"
    "   - E.g., `generic_string`, `generic_list`.\n"
    " - Fixed size/length generators\n"
    "   - These take a size or length parameter as appropriate for the type, and generate values of that size (when possible).\n"
    "   - These generators use the default value generator.\n"
    "   - E.g., `fixed_length_string`, `fixed_length_list`\n"
    " - Non-empty generators\n"
    "   - These generate collections with length or size of at least one\n"
    "   - E.g., `non_empty_string`, `non_empty_bit_array`\n"
    " - From other generators\n"
    "   - The `_from` suffix means that another generator is used to generate values\n"
    "   - E.g., `string_from`, `list_from`\n"
    " - Mixing and matching\n"
    "   - Some generators mix and match the above categories\n"
    "   - E.g., `fixed_length_list_from`, `non_empty_string_from`\n"
    "\n"
    " ### Numeric Generators\n"
    "\n"
    " #### Ints\n"
    "\n"
    " - [uniform_int](#uniform_int)\n"
    " - [bounded_int](#bounded_int)\n"
    " - [small_non_negative_int](#small_non_negative_int)\n"
    " - [small_strictly_positive_int](#small_strictly_positive_int)\n"
    "\n"
    " #### Floats\n"
    "\n"
    " - [float](#float)\n"
    " - [bounded_float](#bounded_float)\n"
    "\n"
    " ### Codepoint and String Generators\n"
    "\n"
    " The main purpose of codepoint generators is to use them to generate\n"
    " strings.\n"
    "\n"
    " #### Codepoints\n"
    "\n"
    " - [codepoint](#codepoint)\n"
    " - [uniform_codepoint](#uniform_codepoint)\n"
    " - [bounded_codepoint](#bounded_codepoint)\n"
    " - [codepoint_from_ints](#codepoint_from_ints)\n"
    " - [codepoint_from_strings](#codepoint_from_strings)\n"
    "\n"
    " ##### ASCII Codepoints\n"
    "\n"
    " - [uppercase_ascii_codepoint](#uppercase_ascii_codepoint)\n"
    " - [lowercase_ascii_codepoint](#lowercase_ascii_codepoint)\n"
    " - [ascii_digit_codepoint](#ascii_digit_codepoint)\n"
    " - [alphabetic_ascii_codepoint](#alphabetic_ascii_codepoint)\n"
    " - [alphanumeric_ascii_codepoint](#alphanumeric_ascii_codepoint)\n"
    " - [printable_ascii_codepoint](#printable_ascii_codepoint)\n"
    " - [ascii_whitespace_codepoint](#ascii_whitespace_codepoint)\n"
    " - [uniform_printable_ascii_codepoint](#uniform_printable_ascii_codepoint)\n"
    "\n"
    " #### Strings\n"
    "\n"
    " String generators are built from codepoint generators.\n"
    "\n"
    " - [string](#string)\n"
    " - [string_from](#string_from)\n"
    " - [non_empty_string](#non_empty_string)\n"
    " - [non_empty_string_from](#non_empty_string_from)\n"
    " - [generic_string](#generic_string)\n"
    " - [fixed_length_string_from](#fixed_length_string_from)\n"
    "\n"
    " ### Bit Array Generators\n"
    "\n"
    " Bit array values come from integers, and handle sizes and shrinking in a\n"
    " reasonable way given that values in the bit array are connected to the\n"
    " size of the bit array in certain situations.\n"
    "\n"
    " These functions will generate bit arrays that cause runtime crashes when\n"
    " targeting JavaScript.\n"
    "\n"
    " - [bit_array](#bit_array)\n"
    " - [non_empty_bit_array](#non_empty_bit_array)\n"
    " - [fixed_size_bit_array](#fixed_size_bit_array)\n"
    " - [fixed_size_bit_array_from](#fixed_size_bit_array_from)\n"
    " - [generic_bit_array](#generic_bit_array)\n"
    "\n"
    " #### Byte-aligned bit arrays\n"
    "\n"
    " Byte-aligned bit arrays always have a size that is a multiple of 8.\n"
    "\n"
    " These bit arrays work on the JavaScript target.\n"
    "\n"
    " - [byte_aligned_bit_array](#byte_aligned_bit_array)\n"
    " - [non_empty_byte_aligned_bit_array](#non_empty_byte_aligned_bit_array)\n"
    " - [fixed_size_byte_aligned_bit_array](#fixed_size_byte_aligned_bit_array)\n"
    " - [fixed_size_byte_aligned_bit_array_from](#fixed_size_byte_aligned_bit_array_from)\n"
    " - [generic_byte_aligned_bit_array](#generic_byte_aligned_bit_array)\n"
    "\n"
    " #### UTF-8 Encoded Bit Arrays\n"
    "\n"
    " Bit arrays where the values are always valid utf-8 encoded bytes.\n"
    "\n"
    " These bit arrays work on the JavaScript target.\n"
    "\n"
    " - [utf8_bit_array](#utf8_bit_array)\n"
    " - [non_empty_utf8_bit_array](#non_empty_utf8_bit_array)\n"
    " - [fixed_size_utf8_bit_array](#fixed_size_utf8_bit_array)\n"
    " - [fixed_size_utf8_bit_array_from](#fixed_size_utf8_bit_array_from)\n"
    " - [generic_utf8_bit_array](#generic_utf8_bit_array)\n"
    "\n"
    " ### Collection Generators\n"
    "\n"
    " #### Lists\n"
    "\n"
    " - [list_from](#list_from)\n"
    " - [fixed_length_list_from](#fixed_length_list_from)\n"
    " - [generic_list](#generic_list)\n"
    "\n"
    " #### Dictionaries\n"
    "\n"
    " - [generic_dict](#generic_dict)\n"
    "\n"
    " #### Sets\n"
    "\n"
    " - [generic_set](#generic_set)\n"
    "\n"
    " #### Tuples\n"
    "\n"
    " - [tuple2](#tuple2)\n"
    " - [tuple3](#tuple3)\n"
    " - [tuple4](#tuple4)\n"
    " - [tuple5](#tuple5)\n"
    " - [tuple6](#tuple6)\n"
    "\n"
    " ### Other Generators\n"
    "\n"
    " - [bool](#bool)\n"
    " - [nil](#nil)\n"
    " - [option_from](#option_from)\n"
    "\n"
    " ### Debug Generators\n"
    "\n"
    " These functions aren't meant to be used directly in your tests.  They are\n"
    " provided to help debug or investigate what values and shrinks that a\n"
    " generator produces.\n"
    "\n"
    " - [generate](#generate)\n"
    " - [generate_tree](#generate_tree)\n"
    "\n"
    " ## Notes\n"
    "\n"
    " The exact distributions of individual generators are considered an\n"
    " implementation detail, and may change without a major version update.\n"
    " For example, if the `option` generator currently produced `None`\n"
    " approximately 25% of the time, but that distribution was changed to produce\n"
    " `None` 50% of the time instead, that would _not_ be considered a breaking\n"
    " change.\n"
    "\n"
).

-type run_property_result() :: run_property_ok | run_property_fail.

-opaque config() :: {config, integer(), integer(), qcheck@random:seed()}.

-type generator(OCC) :: {generator,
        fun((qcheck@random:seed()) -> {qcheck@tree:tree(OCC),
            qcheck@random:seed()})}.

-type generate_option() :: generate_none | generate_some.

-type value_with_size() :: {value_with_size, integer(), integer()}.

-type test_error(OCD) :: {test_error, OCD, OCD, integer(), binary()}.

-type 'try'(OCE) :: {no_panic, OCE} | {panic, exception:exception()}.

-file("src/qcheck.gleam", 407).
-spec do_filter_map(
    gleam@yielder:yielder(OCY),
    fun((OCY) -> gleam@option:option(ODA))
) -> gleam@yielder:step(ODA, gleam@yielder:yielder(OCY)).
do_filter_map(It, F) ->
    case gleam@yielder:step(It) of
        done ->
            done;

        {next, X, It@1} ->
            case F(X) of
                none ->
                    do_filter_map(It@1, F);

                {some, Y} ->
                    {next, Y, It@1}
            end
    end.

-file("src/qcheck.gleam", 400).
-spec filter_map(
    gleam@yielder:yielder(OCT),
    fun((OCT) -> gleam@option:option(OCV))
) -> gleam@yielder:yielder(OCV).
filter_map(It, F) ->
    gleam@yielder:unfold(It, fun(_capture) -> do_filter_map(_capture, F) end).

-file("src/qcheck.gleam", 445).
?DOC(
    " Create a new seed from a provided integer.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `n`: Integer to create the seed from\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A `Seed` value that can be used to configure deterministic test generation\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let config = default_config() |> with_seed(seed(124))\n"
    " ```\n"
).
-spec seed(integer()) -> qcheck@random:seed().
seed(N) ->
    qcheck@random:seed(N).

-file("src/qcheck.gleam", 461).
?DOC(
    " Create a new randomly-generated seed.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A `Seed` value that can be used to configure non-deterministic test generation\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let config = config(test_count: 10_000, max_retries: 1, seed: random_seed())\n"
    " ```\n"
).
-spec random_seed() -> qcheck@random:seed().
random_seed() ->
    qcheck@random:random_seed().

-file("src/qcheck.gleam", 599).
?DOC(
    " Set the random seed for reproducible test case generation.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `config`: The current configuration\n"
    " - `seed`: Seed value for random number generation\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A new `Config` with the specified random seed\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let config = default_config() |> with_seed(seed(124))\n"
    " ```\n"
).
-spec with_seed(config(), qcheck@random:seed()) -> config().
with_seed(Config, Seed) ->
    _record = Config,
    {config, erlang:element(2, _record), erlang:element(3, _record), Seed}.

-file("src/qcheck.gleam", 631).
?DOC(
    " Create a new generator from a random generator and a shrink tree function.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `random_generator`: Produces random values of type `a`\n"
    " - `tree`: Function that creates a shrink tree for generated values\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A new `Generator(a)` that combines random generation and shrinking\n"
    "\n"
    " ### Notes\n"
    "\n"
    " This is a low-level function for building custom generators. Prefer using\n"
    " built-in generators or combinators like `map`, `bind`, etc.\n"
).
-spec generator(
    qcheck@random:generator(ODF),
    fun((ODF) -> qcheck@tree:tree(ODF))
) -> generator(ODF).
generator(Random_generator, Tree) ->
    {generator,
        fun(Seed) ->
            {Generated_value, Next_seed} = qcheck@random:step(
                Random_generator,
                Seed
            ),
            {Tree(Generated_value), Next_seed}
        end}.

-file("src/qcheck.gleam", 666).
-spec do_gen(
    generator(ODM),
    integer(),
    qcheck@random:seed(),
    list(ODM),
    integer()
) -> {list(ODM), qcheck@random:seed()}.
do_gen(Generator, Number_to_generate, Seed, Acc, K) ->
    case K >= Number_to_generate of
        true ->
            {Acc, Seed};

        false ->
            {generator, Generate} = Generator,
            {Tree, Seed@1} = Generate(Seed),
            {tree, Value, _} = Tree,
            do_gen(Generator, Number_to_generate, Seed@1, [Value | Acc], K + 1)
    end.

-file("src/qcheck.gleam", 658).
?DOC(
    " Generate a fixed number of random values from a generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: The generator to use for creating values\n"
    " - `number_to_generate`: Number of values to generate\n"
    " - `seed`: Random seed for value generation\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A list of generated values, without their associated shrinks\n"
    "\n"
    " ### Notes\n"
    "\n"
    " Primarily useful for debugging generator behavior\n"
).
-spec generate(generator(ODJ), integer(), qcheck@random:seed()) -> {list(ODJ),
    qcheck@random:seed()}.
generate(Generator, Number_to_generate, Seed) ->
    do_gen(Generator, Number_to_generate, Seed, [], 0).

-file("src/qcheck.gleam", 699).
?DOC(
    " Generate a single value and its shrink tree from a generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: The generator to use for creating the value\n"
    " - `seed`: Random seed for value generation\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A tuple containing the generated value's shrink tree and the next seed\n"
    "\n"
    " ### Notes\n"
    "\n"
    " Primarily useful for debugging generator behavior\n"
).
-spec generate_tree(generator(ODQ), qcheck@random:seed()) -> {qcheck@tree:tree(ODQ),
    qcheck@random:seed()}.
generate_tree(Generator, Seed) ->
    {generator, Generate} = Generator,
    Generate(Seed).

-file("src/qcheck.gleam", 724).
?DOC(
    " Create a generator that always returns the same value and does not shrink.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `a`: The value to be consistently generated\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A `Generator` that produces the same input for all test cases\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " use string <- given(return(\"Gleam\"))\n"
    " string == \"Gleam\"\n"
    " ```\n"
).
-spec return(ODT) -> generator(ODT).
return(A) ->
    {generator, fun(Seed) -> {qcheck@tree:return(A), Seed} end}.

-file("src/qcheck.gleam", 749).
?DOC(
    " Create a generator that always returns the same value and does not shrink.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `a`: The value to be consistently generated\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A `Generator` that produces the same input for all test cases\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " use string <- given(constant(\"Gleam\"))\n"
    " string == \"Gleam\"\n"
    " ```\n"
    "\n"
    " ### Notes\n"
    "\n"
    " This function is an alias for `return`.\n"
).
-spec constant(ODV) -> generator(ODV).
constant(A) ->
    return(A).

-file("src/qcheck.gleam", 778).
?DOC(
    " Support for constructing curried functions for the applicative style of\n"
    " generator composition.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " type Box {\n"
    "   Box(x: Int, y: Int, w: Int, h: Int)\n"
    " }\n"
    "\n"
    " fn box_generator() {\n"
    "   return({\n"
    "     use x <- parameter\n"
    "     use y <- parameter\n"
    "     use w <- parameter\n"
    "     use h <- parameter\n"
    "     Box(x:, y:, w:, h:)\n"
    "   })\n"
    "   |> apply(bounded_int(-100, 100))\n"
    "   |> apply(bounded_int(-100, 100))\n"
    "   |> apply(bounded_int(1, 100))\n"
    "   |> apply(bounded_int(1, 100))\n"
    " }\n"
    " ```\n"
).
-spec parameter(fun((ODX) -> ODY)) -> fun((ODX) -> ODY).
parameter(F) ->
    F.

-file("src/qcheck.gleam", 809).
?DOC(
    " Transform a generator by applying a function to each generated value.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: The original generator to transform\n"
    " - `f`: Function to apply to each generated value\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A new generator that produces values transformed by `f`, with shrinking\n"
    " behavior derived from the original generator\n"
    "\n"
    " ### Examples\n"
    "\n"
    " ```\n"
    " let even_number_generator = map(uniform_int(), fn(n) { 2 * n })\n"
    " ```\n"
    "\n"
    " With `use`:\n"
    "\n"
    " ```\n"
    " let even_number_generator = {\n"
    "   use n <- map(uniform_int())\n"
    "   2 * n\n"
    " }\n"
    " ```\n"
).
-spec map(generator(ODZ), fun((ODZ) -> OEB)) -> generator(OEB).
map(Generator, F) ->
    {generator, Generate} = Generator,
    {generator,
        fun(Seed) ->
            {Tree, Seed@1} = Generate(Seed),
            Tree@1 = qcheck@tree:map(Tree, F),
            {Tree@1, Seed@1}
        end}.

-file("src/qcheck.gleam", 894).
?DOC(
    " Transform a generator by applying a function that returns another\n"
    " generator to each generated value.\n"
    "\n"
    " Unlike `map`, this allows for a dependency on the resulting generator and\n"
    " the original generated values.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: A generator that creates a value of type `a`\n"
    " - `f`: A function that takes a value of type `a` and returns a generator\n"
    "     of type `b`\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that first generates a value of type `a`, then uses that value\n"
    " to generate a value of type `b`\n"
    "\n"
    " ### Examples\n"
    "\n"
    " Say you wanted to generate a valid date in string form, like `\"2025-01-30\"`.\n"
    " In order to generate a valid day, you need both the month (some months have\n"
    " 31 days, other have fewer) and also the year (since the year affects the max\n"
    " days in February). So, before you can generate a valid day, you must first\n"
    " generate a year and a month. You could imagine a set of functions like this:\n"
    "\n"
    " ```\n"
    " fn date_generator() -> Generator(String) {\n"
    "   use #(year, month) <- bind(tuple2(year_generator(), month_generator()))\n"
    "   use day <- map(day_generator(year:, month:))\n"
    "\n"
    "   int.to_string(year)\n"
    "   <> \"-\"\n"
    "   <> int.to_string(month)\n"
    "   <> \"-\"\n"
    "   <> int.to_string(day)\n"
    " }\n"
    "\n"
    " // Note how the day generator depends on the value of `year` and `month`.\n"
    " fn day_generator(year year, month month) -> Generator(Int) {\n"
    "   todo\n"
    " }\n"
    "\n"
    " fn year_generator() -> Generator(Int) {\n"
    "   todo\n"
    " }\n"
    "\n"
    " fn month_generator() -> Generator(Int) {\n"
    "   todo\n"
    " }\n"
    " ```\n"
    "\n"
    " Another situation in which you would need `bind` is if you needed to\n"
    " generate departure and arrival times. We will say a pair of departure and\n"
    " arrival times is valid if the departure time is before the arrival time.\n"
    " That means we cannot generate an arrival time without first generating a\n"
    " departure time. Here is how that might look:\n"
    "\n"
    " ```\n"
    " fn departure_and_arrival_generator() {\n"
    "   use departure_time <- bind(departure_time_generator())\n"
    "   use arrival_time <- map(arrival_time_generator(departure_time))\n"
    "   #(departure_time, arrival_time)\n"
    " }\n"
    "\n"
    " fn departure_time_generator() {\n"
    "   todo\n"
    " }\n"
    "\n"
    " fn arrival_time_generator(departure_time) {\n"
    "   todo\n"
    " }\n"
    " ```\n"
).
-spec bind(generator(OED), fun((OED) -> generator(OEF))) -> generator(OEF).
bind(Generator, F) ->
    {generator, Generate} = Generator,
    {generator,
        fun(Seed) ->
            {Tree, Seed@1} = Generate(Seed),
            Tree@2 = qcheck@tree:bind(
                Tree,
                fun(X) ->
                    {generator, Generate@1} = F(X),
                    {Tree@1, _} = Generate@1(Seed@1),
                    Tree@1
                end
            ),
            {Tree@2, Seed@1}
        end}.

-file("src/qcheck.gleam", 986).
?DOC(
    " Transform a generator by applying a function that returns another\n"
    " generator to each generated value.\n"
    "\n"
    " Unlike `map`, this allows for a dependency on the resulting generator and\n"
    " the original generated values.\n"
    "\n"
    " (`then` is an alias for `bind`.)\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: A generator that creates a value of type `a`\n"
    " - `f`: A function that takes a value of type `a` and returns a generator\n"
    "     of type `b`\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that first generates a value of type `a`, then uses that value\n"
    " to generate a value of type `b`\n"
    "\n"
    " ### Examples\n"
    "\n"
    " Say you wanted to generate a valid date in string form, like `\"2025-01-30\"`.\n"
    " In order to generate a valid day, you need both the month (some months have\n"
    " 31 days, other have fewer) and also the year (since the year affects the max\n"
    " days in February). So, before you can generate a valid day, you must first\n"
    " generate a year and a month. You could imagine a set of functions like this:\n"
    "\n"
    " ```\n"
    " fn date_generator() -> Generator(String) {\n"
    "   use #(year, month) <- then(tuple2(year_generator(), month_generator()))\n"
    "   use day <- map(day_generator(year:, month:))\n"
    "\n"
    "   int.to_string(year)\n"
    "   <> \"-\"\n"
    "   <> int.to_string(month)\n"
    "   <> \"-\"\n"
    "   <> int.to_string(day)\n"
    " }\n"
    "\n"
    " // Note how the day generator depends on the value of `year` and `month`.\n"
    " fn day_generator(year year, month month) -> Generator(Int) {\n"
    "   todo\n"
    " }\n"
    "\n"
    " fn year_generator() -> Generator(Int) {\n"
    "   todo\n"
    " }\n"
    "\n"
    " fn month_generator() -> Generator(Int) {\n"
    "   todo\n"
    " }\n"
    " ```\n"
    "\n"
    " Another situation in which you would need `then` is if you needed to\n"
    " generate departure and arrival times. We will say a pair of departure and\n"
    " arrival times is valid if the departure time is before the arrival time.\n"
    " That means we cannot generate an arrival time without first generating a\n"
    " departure time. Here is how that might look:\n"
    "\n"
    " ```\n"
    " fn departure_and_arrival_generator() {\n"
    "   use departure_time <- then(departure_time_generator())\n"
    "   use arrival_time <- map(arrival_time_generator(departure_time))\n"
    "   #(departure_time, arrival_time)\n"
    " }\n"
    "\n"
    " fn departure_time_generator() {\n"
    "   todo\n"
    " }\n"
    "\n"
    " fn arrival_time_generator(departure_time) {\n"
    "   todo\n"
    " }\n"
    " ```\n"
).
-spec then(generator(OEI), fun((OEI) -> generator(OEK))) -> generator(OEK).
then(Generator, F) ->
    bind(Generator, F).

-file("src/qcheck.gleam", 1014).
?DOC(
    " Support for constructing generators in an applicative style.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " type Box {\n"
    "   Box(x: Int, y: Int, w: Int, h: Int)\n"
    " }\n"
    "\n"
    " fn box_generator() {\n"
    "   return({\n"
    "     use x <- parameter\n"
    "     use y <- parameter\n"
    "     use w <- parameter\n"
    "     use h <- parameter\n"
    "     Box(x:, y:, w:, h:)\n"
    "   })\n"
    "   |> apply(bounded_int(-100, 100))\n"
    "   |> apply(bounded_int(-100, 100))\n"
    "   |> apply(bounded_int(1, 100))\n"
    "   |> apply(bounded_int(1, 100))\n"
    " }\n"
    " ```\n"
).
-spec apply(generator(fun((OEN) -> OEO)), generator(OEN)) -> generator(OEO).
apply(F, X) ->
    {generator, F@1} = F,
    {generator, X@1} = X,
    {generator,
        fun(Seed) ->
            {Y_of_x, Seed@1} = X@1(Seed),
            {Y_of_f, Seed@2} = F@1(Seed@1),
            Tree = qcheck@tree:apply(Y_of_f, Y_of_x),
            {Tree, Seed@2}
        end}.

-file("src/qcheck.gleam", 1047).
?DOC(
    " Transform two generators by applying a function to their generated values.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `g1`: First generator to provide input\n"
    " - `g2`: Second generator to provide input\n"
    " - `f`: Function to apply to generated values from `g1` and `g2`\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A new generator that produces values by applying `f` to values from `g1`\n"
    " and `g2`\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " use year, month <- map2(bounded_int(0, 9999), bounded_int(1, 12))\n"
    " int.to_string(year) <> \"-\" <> int.to_string(month)\n"
    " ```\n"
).
-spec map2(generator(OES), generator(OEU), fun((OES, OEU) -> OEW)) -> generator(OEW).
map2(G1, G2, F) ->
    _pipe = return(
        begin
            parameter(fun(X1) -> parameter(fun(X2) -> F(X1, X2) end) end)
        end
    ),
    _pipe@1 = apply(_pipe, G1),
    apply(_pipe@1, G2).

-file("src/qcheck.gleam", 1065).
?DOC(
    " Transform three generators by applying a function to their generated values.\n"
    "\n"
    " See docs for [`map2`](#map2).\n"
).
-spec map3(
    generator(OEY),
    generator(OFA),
    generator(OFC),
    fun((OEY, OFA, OFC) -> OFE)
) -> generator(OFE).
map3(G1, G2, G3, F) ->
    _pipe = return(
        begin
            parameter(
                fun(X1) ->
                    parameter(
                        fun(X2) -> parameter(fun(X3) -> F(X1, X2, X3) end) end
                    )
                end
            )
        end
    ),
    _pipe@1 = apply(_pipe, G1),
    _pipe@2 = apply(_pipe@1, G2),
    apply(_pipe@2, G3).

-file("src/qcheck.gleam", 1086).
?DOC(
    " Transform four generators by applying a function to their generated values.\n"
    "\n"
    " See docs for [`map2`](#map2).\n"
).
-spec map4(
    generator(OFG),
    generator(OFI),
    generator(OFK),
    generator(OFM),
    fun((OFG, OFI, OFK, OFM) -> OFO)
) -> generator(OFO).
map4(G1, G2, G3, G4, F) ->
    _pipe = return(
        begin
            parameter(
                fun(X1) ->
                    parameter(
                        fun(X2) ->
                            parameter(
                                fun(X3) ->
                                    parameter(fun(X4) -> F(X1, X2, X3, X4) end)
                                end
                            )
                        end
                    )
                end
            )
        end
    ),
    _pipe@1 = apply(_pipe, G1),
    _pipe@2 = apply(_pipe@1, G2),
    _pipe@3 = apply(_pipe@2, G3),
    apply(_pipe@3, G4).

-file("src/qcheck.gleam", 1110).
?DOC(
    " Transform five generators by applying a function to their generated values.\n"
    "\n"
    " See docs for [`map2`](#map2).\n"
).
-spec map5(
    generator(OFQ),
    generator(OFS),
    generator(OFU),
    generator(OFW),
    generator(OFY),
    fun((OFQ, OFS, OFU, OFW, OFY) -> OGA)
) -> generator(OGA).
map5(G1, G2, G3, G4, G5, F) ->
    _pipe = return(
        begin
            parameter(
                fun(X1) ->
                    parameter(
                        fun(X2) ->
                            parameter(
                                fun(X3) ->
                                    parameter(
                                        fun(X4) ->
                                            parameter(
                                                fun(X5) ->
                                                    F(X1, X2, X3, X4, X5)
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ),
    _pipe@1 = apply(_pipe, G1),
    _pipe@2 = apply(_pipe@1, G2),
    _pipe@3 = apply(_pipe@2, G3),
    _pipe@4 = apply(_pipe@3, G4),
    apply(_pipe@4, G5).

-file("src/qcheck.gleam", 1137).
?DOC(
    " Transform six generators by applying a function to their generated values.\n"
    "\n"
    " See docs for [`map2`](#map2).\n"
).
-spec map6(
    generator(OGC),
    generator(OGE),
    generator(OGG),
    generator(OGI),
    generator(OGK),
    generator(OGM),
    fun((OGC, OGE, OGG, OGI, OGK, OGM) -> OGO)
) -> generator(OGO).
map6(G1, G2, G3, G4, G5, G6, F) ->
    _pipe = return(
        begin
            parameter(
                fun(X1) ->
                    parameter(
                        fun(X2) ->
                            parameter(
                                fun(X3) ->
                                    parameter(
                                        fun(X4) ->
                                            parameter(
                                                fun(X5) ->
                                                    parameter(
                                                        fun(X6) ->
                                                            F(
                                                                X1,
                                                                X2,
                                                                X3,
                                                                X4,
                                                                X5,
                                                                X6
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ),
    _pipe@1 = apply(_pipe, G1),
    _pipe@2 = apply(_pipe@1, G2),
    _pipe@3 = apply(_pipe@2, G3),
    _pipe@4 = apply(_pipe@3, G4),
    _pipe@5 = apply(_pipe@4, G5),
    apply(_pipe@5, G6).

-file("src/qcheck.gleam", 1181).
?DOC(
    " Generate a tuple of two values using the provided generators.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `g1`: Generator for the first tuple element\n"
    " - `g2`: Generator for the second tuple element\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces a tuple of two values, one from each input\n"
    " generator\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let point_generator = tuple2(float(), float())\n"
    " ```\n"
).
-spec tuple2(generator(OGQ), generator(OGS)) -> generator({OGQ, OGS}).
tuple2(G1, G2) ->
    map2(G1, G2, fun(X1, X2) -> {X1, X2} end).

-file("src/qcheck.gleam", 1190).
?DOC(
    " Generate a tuple of three values using the provided generators.\n"
    "\n"
    " See docs for [`tuple2`](#tuple2).\n"
).
-spec tuple3(generator(OGV), generator(OGX), generator(OGZ)) -> generator({OGV,
    OGX,
    OGZ}).
tuple3(G1, G2, G3) ->
    map3(G1, G2, G3, fun(X1, X2, X3) -> {X1, X2, X3} end).

-file("src/qcheck.gleam", 1203).
?DOC(
    " Generate a tuple of four values using the provided generators.\n"
    "\n"
    " See docs for [`tuple2`](#tuple2).\n"
).
-spec tuple4(generator(OHC), generator(OHE), generator(OHG), generator(OHI)) -> generator({OHC,
    OHE,
    OHG,
    OHI}).
tuple4(G1, G2, G3, G4) ->
    map4(G1, G2, G3, G4, fun(X1, X2, X3, X4) -> {X1, X2, X3, X4} end).

-file("src/qcheck.gleam", 1217).
?DOC(
    " Generate a tuple of five values using the provided generators.\n"
    "\n"
    " See docs for [`tuple2`](#tuple2).\n"
).
-spec tuple5(
    generator(OHL),
    generator(OHN),
    generator(OHP),
    generator(OHR),
    generator(OHT)
) -> generator({OHL, OHN, OHP, OHR, OHT}).
tuple5(G1, G2, G3, G4, G5) ->
    map5(
        G1,
        G2,
        G3,
        G4,
        G5,
        fun(X1, X2, X3, X4, X5) -> {X1, X2, X3, X4, X5} end
    ).

-file("src/qcheck.gleam", 1232).
?DOC(
    " Generate a tuple of six values using the provided generators.\n"
    "\n"
    " See docs for [`tuple2`](#tuple2).\n"
).
-spec tuple6(
    generator(OHW),
    generator(OHY),
    generator(OIA),
    generator(OIC),
    generator(OIE),
    generator(OIG)
) -> generator({OHW, OHY, OIA, OIC, OIE, OIG}).
tuple6(G1, G2, G3, G4, G5, G6) ->
    map6(
        G1,
        G2,
        G3,
        G4,
        G5,
        G6,
        fun(X1, X2, X3, X4, X5, X6) -> {X1, X2, X3, X4, X5, X6} end
    ).

-file("src/qcheck.gleam", 1271).
?DOC(
    " Choose a generator from a list of generators, then generate a value from\n"
    " the selected generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: Initial generator to include in the choice\n"
    " - `generators`: Additional generators to choose from\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that selects and uses one of the provided generators\n"
    "\n"
    " ### Notes\n"
    "\n"
    " - Will always produce values since at least one generator is required\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " fn mostly_ascii_characters_generator() {\n"
    "   from_generators(uppercase_ascii_codepoint(), [\n"
    "     lowercase_ascii_codepoint(),\n"
    "     uniform_codepoint(),\n"
    "   ])\n"
    " }\n"
    " ```\n"
).
-spec from_generators(generator(OIJ), list(generator(OIJ))) -> generator(OIJ).
from_generators(Generator, Generators) ->
    {generator,
        fun(Seed) ->
            {{generator, Generator@1}, Seed@1} = begin
                _pipe = qcheck@random:uniform(Generator, Generators),
                qcheck@random:step(_pipe, Seed)
            end,
            Generator@1(Seed@1)
        end}.

-file("src/qcheck.gleam", 1306).
?DOC(
    " Choose a generator from a list of weighted generators, then generate a\n"
    " value from the selected generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: Initial weighted generator (weight and generator)\n"
    " - `generators`: Additional weighted generators\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that selects and generates values based on the provided\n"
    " weights\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " from_weighted_generators(#(26, uppercase_ascii_codepoint()), [\n"
    "   #(26, lowercase_ascii_codepoint()),\n"
    "   #(10, ascii_digit_codepoint()),\n"
    " ])\n"
    " ```\n"
).
-spec from_weighted_generators(
    {integer(), generator(OIO)},
    list({integer(), generator(OIO)})
) -> generator(OIO).
from_weighted_generators(Generator, Generators) ->
    {generator,
        fun(Seed) ->
            {{generator, Generator@1}, Seed@1} = begin
                _pipe = qcheck@random:weighted(Generator, Generators),
                qcheck@random:step(_pipe, Seed)
            end,
            Generator@1(Seed@1)
        end}.

-file("src/qcheck.gleam", 1351).
?DOC(
    " Creates a generator by first generating a size using the provided\n"
    " `size_generator`, then passing that size to the `sized_generator` to\n"
    " produce a value.\n"
    "\n"
    " Shrinks on the size first, then on the generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `sized_generator`: A generator function that takes a size and produces a\n"
    "     value\n"
    " - `size_generator`: A generator for creating the size input\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that first produces a size, then uses that size to generate a\n"
    " value\n"
    "\n"
    " ### Example\n"
    "\n"
    " Create a bit arrays whose bit size is from 10 to 20.\n"
    "\n"
    " ```\n"
    " fixed_size_bit_array() |> sized_from(bounded_int(10, 20))\n"
    " ```\n"
).
-spec sized_from(fun((integer()) -> generator(OIT)), generator(integer())) -> generator(OIT).
sized_from(Sized_generator, Size_generator) ->
    _pipe = Size_generator,
    bind(_pipe, Sized_generator).

-file("src/qcheck.gleam", 2328).
-spec generate_option() -> qcheck@random:generator(generate_option()).
generate_option() ->
    qcheck@random:weighted({15, generate_none}, [{85, generate_some}]).

-file("src/qcheck.gleam", 2349).
?DOC(
    " Create a generator for `Option` values.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: Generator for the inner value type\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces `Option` values, shrinking towards `None` first,\n"
    " then towards the shrinks of the input generator\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " option_from(string())\n"
    " ```\n"
).
-spec option_from(generator(OLR)) -> generator(gleam@option:option(OLR)).
option_from(Generator) ->
    {generator, Generate} = Generator,
    {generator,
        fun(Seed) ->
            {Generate_option, Seed@1} = qcheck@random:step(
                generate_option(),
                Seed
            ),
            case Generate_option of
                generate_none ->
                    {qcheck@tree:return(none), Seed@1};

                generate_some ->
                    {Tree, Seed@2} = Generate(Seed@1),
                    {qcheck@tree:option(Tree), Seed@2}
            end
        end}.

-file("src/qcheck.gleam", 2372).
?DOC(
    " Generate a constant `Nil` value.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A `Generator` that always returns `Nil` and does not shrink\n"
).
-spec nil() -> generator(nil).
nil() ->
    {generator, fun(Seed) -> {qcheck@tree:return(nil), Seed} end}.

-file("src/qcheck.gleam", 2382).
?DOC(
    " Generate boolean values.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that generates boolean values and shrinks towards `False`\n"
).
-spec bool() -> generator(boolean()).
bool() ->
    {generator,
        fun(Seed) ->
            {Bool, Seed@1} = begin
                _pipe = qcheck@random:choose(true, false),
                qcheck@random:step(_pipe, Seed)
            end,
            Tree = case Bool of
                true ->
                    {tree,
                        true,
                        gleam@yielder:once(
                            fun() -> qcheck@tree:return(false) end
                        )};

                false ->
                    qcheck@tree:return(false)
            end,
            {Tree, Seed@1}
        end}.

-file("src/qcheck.gleam", 2457).
-spec value_with_size_list_to_bit_array(list(value_with_size())) -> bitstring().
value_with_size_list_to_bit_array(Value_with_size_list) ->
    gleam@list:fold(
        Value_with_size_list,
        <<>>,
        fun(Acc, _use1) ->
            {value_with_size, Int, Size} = _use1,
            <<Int:(lists:max([(Size), 0])), Acc/bitstring>>
        end
    ).

-file("src/qcheck.gleam", 2464).
-spec do_gen_bit_array(
    generator(integer()),
    qcheck@random:seed(),
    bitstring(),
    list(qcheck@tree:tree(value_with_size())),
    integer()
) -> {bitstring(),
    list(qcheck@tree:tree(value_with_size())),
    qcheck@random:seed()}.
do_gen_bit_array(Value_generator, Seed, Acc, Value_with_size_trees, K) ->
    {generator, Generate} = Value_generator,
    {Int_tree, Seed@1} = Generate(Seed),
    case K of
        K@1 when K@1 =< 0 ->
            {Acc, Value_with_size_trees, Seed@1};

        K@2 when K@2 =< 8 ->
            Value_with_size_tree = qcheck@tree:map(
                Int_tree,
                fun(Int) -> {value_with_size, Int, K@2} end
            ),
            {tree, {value_with_size, Root, _}, _} = Value_with_size_tree,
            do_gen_bit_array(
                Value_generator,
                Seed@1,
                <<Root:(lists:max([(K@2), 0])), Acc/bitstring>>,
                [Value_with_size_tree | Value_with_size_trees],
                0
            );

        K@3 ->
            Value_with_size_tree@1 = qcheck@tree:map(
                Int_tree,
                fun(Int@1) -> {value_with_size, Int@1, 8} end
            ),
            {tree, {value_with_size, Root@1, _}, _} = Value_with_size_tree@1,
            do_gen_bit_array(
                Value_generator,
                Seed@1,
                <<Root@1, Acc/bitstring>>,
                [Value_with_size_tree@1 | Value_with_size_trees],
                K@3 - 8
            )
    end.

-file("src/qcheck.gleam", 2430).
?DOC(
    " Generate fixed-size bit arrays where elements are generated\n"
    " using the provided integer generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `value_generator`: Generators bit array values\n"
    " - `bit_size`: Number of bits in the generated bit array\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator of fixed-size bit arrays\n"
    "\n"
    " ### Notes\n"
    "\n"
    " Shrinks on values, not on size\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " fixed_size_bit_array_from(bounded_int(0, 255), 64)\n"
    " ```\n"
    "\n"
    " ### Warning\n"
    "\n"
    " This function will generate bit arrays that cause runtime crashes when\n"
    " targeting JavaScript unless the bit size is a multiple of 8.\n"
).
-spec fixed_size_bit_array_from(generator(integer()), integer()) -> generator(bitstring()).
fixed_size_bit_array_from(Value_generator, Bit_size) ->
    {generator,
        fun(Seed) ->
            {Generated_bit_array, Int_trees, Seed@1} = do_gen_bit_array(
                Value_generator,
                Seed,
                <<>>,
                [],
                Bit_size
            ),
            Shrink = fun() ->
                Int_list_tree = begin
                    _pipe = Int_trees,
                    _pipe@1 = lists:reverse(_pipe),
                    qcheck@tree:sequence_trees(_pipe@1)
                end,
                {tree, _, Children} = qcheck@tree:map(
                    Int_list_tree,
                    fun value_with_size_list_to_bit_array/1
                ),
                Children
            end,
            Tree = {tree, Generated_bit_array, Shrink()},
            {Tree, Seed@1}
        end}.

-file("src/qcheck.gleam", 2532).
?DOC(
    " Generate bit arrays with configurable values and bit sizes.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `values_from`: Generator for bit array contents\n"
    " - `bit_size_from`: Generator for bit array size\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A bit array generator\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let generator = generic_bit_array(\n"
    "   value_generator: bounded_int(0, 255),\n"
    "   bit_size_generator: bounded_int(32, 64)\n"
    " )\n"
    " ```\n"
    "\n"
    " ### Warning\n"
    "\n"
    " This function will generate bit arrays that cause runtime crashes when\n"
    " targeting JavaScript.\n"
).
-spec generic_bit_array(generator(integer()), generator(integer())) -> generator(bitstring()).
generic_bit_array(Value_generator, Bit_size_generator) ->
    _pipe = Bit_size_generator,
    bind(
        _pipe,
        fun(_capture) ->
            fixed_size_bit_array_from(Value_generator, _capture)
        end
    ).

-file("src/qcheck.gleam", 2762).
?DOC(
    " Generate byte-aligned bit arrays of the given number of bytes from the\n"
    " given value generator\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `value_generator`: Generates the values of the bit array\n"
    " - `num_bytes`: Number of bytes for the generated bit array\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces bit arrays with the specified number of bytes\n"
    " according to the given value generator\n"
    "\n"
    " ### Example\n"
    "\n"
    " Generate 4-byte bit arrays:\n"
    "\n"
    " ```\n"
    " fixed_size_byte_aligned_bit_array(bounded_int(0, 255), 16)\n"
    " ```\n"
).
-spec fixed_size_byte_aligned_bit_array_from(generator(integer()), integer()) -> generator(bitstring()).
fixed_size_byte_aligned_bit_array_from(Value_generator, Byte_size) ->
    Bit_size = Byte_size * 8,
    fixed_size_bit_array_from(Value_generator, Bit_size).

-file("src/qcheck.gleam", 2782).
?DOC(
    " Generate byte-aligned bit arrays according to the given value generator\n"
    " and byte size generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `value_generator`: Generates the values of the bit array\n"
    " - `byte_size_generator`: Generates the number of bytes of the bit array\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A byte-aligned bit array generator\n"
).
-spec generic_byte_aligned_bit_array(generator(integer()), generator(integer())) -> generator(bitstring()).
generic_byte_aligned_bit_array(Value_generator, Byte_size_generator) ->
    bind(
        Byte_size_generator,
        fun(Byte_size) ->
            fixed_size_byte_aligned_bit_array_from(Value_generator, Byte_size)
        end
    ).

-file("src/qcheck.gleam", 2809).
-spec new_test_error(ONG, ONG, integer(), binary()) -> test_error(ONG).
new_test_error(Orig, Shrunk, Steps, Error_msg) ->
    {test_error, Orig, Shrunk, Steps, Error_msg}.

-file("src/qcheck.gleam", 2839).
-spec fail(binary()) -> any().
fail(Test_error_display) ->
    qcheck_ffi:fail(Test_error_display).

-file("src/qcheck.gleam", 2871).
-spec 'try'(fun(() -> ONO)) -> 'try'(ONO).
'try'(F) ->
    case exception_ffi:rescue(fun() -> F() end) of
        {ok, Y} ->
            {no_panic, Y};

        {error, Exn} ->
            {panic, Exn}
    end.

-file("src/qcheck.gleam", 346).
-spec do_run_property(fun((OCO) -> nil), OCO, integer(), integer()) -> run_property_result().
do_run_property(Property, Value, Max_retries, I) ->
    case I < Max_retries of
        true ->
            case 'try'(fun() -> Property(Value) end) of
                {no_panic, nil} ->
                    do_run_property(Property, Value, Max_retries, I + 1);

                {panic, _} ->
                    run_property_fail
            end;

        false ->
            run_property_ok
    end.

-file("src/qcheck.gleam", 338).
-spec run_property(fun((OCN) -> nil), OCN, integer()) -> run_property_result().
run_property(Property, Value, Max_retries) ->
    do_run_property(Property, Value, Max_retries, 0).

-file("src/qcheck.gleam", 371).
-spec do_shrink(qcheck@tree:tree(OCR), fun((OCR) -> nil), integer(), integer()) -> {OCR,
    integer()}.
do_shrink(Tree, Property, Run_property_max_retries, Shrink_count) ->
    {tree, Original_failing_value, Shrinks} = Tree,
    Result = begin
        _pipe = Shrinks,
        _pipe@1 = filter_map(
            _pipe,
            fun(Tree@1) ->
                {tree, Value, _} = Tree@1,
                case run_property(Property, Value, Run_property_max_retries) of
                    run_property_ok ->
                        none;

                    run_property_fail ->
                        {some, Tree@1}
                end
            end
        ),
        gleam@yielder:first(_pipe@1)
    end,
    case Result of
        {error, nil} ->
            {Original_failing_value, Shrink_count};

        {ok, Next_tree} ->
            do_shrink(
                Next_tree,
                Property,
                Run_property_max_retries,
                Shrink_count + 1
            )
    end.

-file("src/qcheck.gleam", 363).
-spec shrink(qcheck@tree:tree(OCP), fun((OCP) -> nil), integer()) -> {OCP,
    integer()}.
shrink(Tree, Property, Run_property_max_retries) ->
    do_shrink(Tree, Property, Run_property_max_retries, 0).

-file("src/qcheck.gleam", 1375).
?DOC(
    " Generate small non-negative integers, well-suited for modeling sized\n"
    " elements like lists or strings.\n"
    "\n"
    " Shrinks towards `0`.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator for small, non-negative integers\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " generic_string(bounded_codepoint(0, 255), small_non_negative_int())\n"
    " ```\n"
).
-spec small_non_negative_int() -> generator(integer()).
small_non_negative_int() ->
    generator(
        begin
            _pipe = qcheck@random:int(0, 100),
            qcheck@random:then(_pipe, fun(X) -> case X < 75 of
                        true ->
                            qcheck@random:int(0, 10);

                        false ->
                            qcheck@random:int(0, 100)
                    end end)
        end,
        fun(N) -> qcheck@tree:new(N, qcheck@shrink:int_towards(0)) end
    ).

-file("src/qcheck.gleam", 1403).
?DOC(
    " Generate small, strictly positive integers, well-suited for modeling sized\n"
    " elements like lists or strings.\n"
    "\n"
    " Shrinks towards `0`.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator for small, strictly positive integers\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " generic_string(bounded_codepoint(0, 255), small_strictly_positive_int())\n"
    " ```\n"
).
-spec small_strictly_positive_int() -> generator(integer()).
small_strictly_positive_int() ->
    _pipe = small_non_negative_int(),
    map(_pipe, fun(_capture) -> gleam@int:add(_capture, 1) end).

-file("src/qcheck.gleam", 2880).
-spec list_cons(ONQ, list(ONQ)) -> list(ONQ).
list_cons(X, Xs) ->
    [X | Xs].

-file("src/qcheck.gleam", 2128).
-spec generic_list_loop(
    integer(),
    qcheck@tree:tree(list(OKK)),
    generator(OKK),
    qcheck@random:seed()
) -> {qcheck@tree:tree(list(OKK)), qcheck@random:seed()}.
generic_list_loop(N, Acc, Element_generator, Seed) ->
    case N =< 0 of
        true ->
            {Acc, Seed};

        false ->
            {generator, Generate} = Element_generator,
            {Tree, Seed@1} = Generate(Seed),
            generic_list_loop(
                N - 1,
                qcheck@tree:map2(Tree, Acc, fun list_cons/2),
                Element_generator,
                Seed@1
            )
    end.

-file("src/qcheck.gleam", 2205).
?DOC(
    " Generate fixed-length lists with elements from the given generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `element_generator`: Generates list elements\n"
    " - `length`: The length of the generated lists\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces fixed-length lists with elements from the given\n"
    " generator.\n"
    "\n"
    " ### Shrinking\n"
    "\n"
    " Shrinks first on list length, then on list elements, ensuring shrunk lists\n"
    " remain within length generator's range.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " fixed_length_list_from(string(), 5)\n"
    " ```\n"
).
-spec fixed_length_list_from(generator(OKV), integer()) -> generator(list(OKV)).
fixed_length_list_from(Element_generator, Length) ->
    {generator,
        fun(Seed) ->
            generic_list_loop(
                Length,
                qcheck@tree:return([]),
                Element_generator,
                Seed
            )
        end}.

-file("src/qcheck.gleam", 2174).
?DOC(
    " Generate lists with elements from one generator and lengths from another.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `elements_from`: Generates list elements\n"
    " - `length_from`: Generates list lengths\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces lists with:\n"
    " - Elements from `elements_from`\n"
    " - Lengths from `length_from`\n"
    "\n"
    " ### Shrinking\n"
    "\n"
    " Shrinks first on list length, then on list elements, ensuring shrunk lists\n"
    " remain within length generator's range.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " generic_list(string(), small_non_negative_int())\n"
    " ```\n"
).
-spec generic_list(generator(OKQ), generator(integer())) -> generator(list(OKQ)).
generic_list(Element_generator, Length_generator) ->
    bind(
        Length_generator,
        fun(Length) -> fixed_length_list_from(Element_generator, Length) end
    ).

-file("src/qcheck.gleam", 2234).
?DOC(
    " Generate lists with elements from the given generator and the default\n"
    " length generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `element_generator`: Generates list elements\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces lists with elements from the given generator\n"
    "\n"
    " ### Shrinking\n"
    "\n"
    " Shrinks first on list length, then on list elements.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " list_from(string())\n"
    " ```\n"
).
-spec list_from(generator(OKZ)) -> generator(list(OKZ)).
list_from(Element_generator) ->
    generic_list(Element_generator, small_non_negative_int()).

-file("src/qcheck.gleam", 2269).
?DOC(
    " Generates dictionaries with keys from a key generator, values from a value\n"
    " generator, and sizes from a size generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `keys_from`: Generator for dictionary keys\n"
    " - `values_from`: Generator for dictionary values\n"
    " - `size_from`: Generator for dictionary size\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces dictionaries\n"
    "\n"
    " ### Notes\n"
    "\n"
    " - The actual size may be less than the generated size due to potential key\n"
    "   duplicates\n"
    " - Shrinks on size first, then on individual elements\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " generic_dict(\n"
    "   key_generator: uniform_int(),\n"
    "   value_generator: string(),\n"
    "   size_generator: small_strictly_positive_int()\n"
    " )\n"
    " ```\n"
).
-spec generic_dict(generator(OLD), generator(OLF), generator(integer())) -> generator(gleam@dict:dict(OLD, OLF)).
generic_dict(Key_generator, Value_generator, Size_generator) ->
    map(
        generic_list(tuple2(Key_generator, Value_generator), Size_generator),
        fun(Association_list) -> maps:from_list(Association_list) end
    ).

-file("src/qcheck.gleam", 2310).
?DOC(
    " Generates sets with values from an element generator, and sizes from a size\n"
    " generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `elements_from`: Generator for set elements\n"
    " - `size_from`: Generator for set size\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces sets\n"
    "\n"
    " ### Notes\n"
    "\n"
    " - The actual size may be less than the generated size due to potential\n"
    "   duplicates\n"
    " - Shrinks on size first, then on individual elements\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " generic_set(\n"
    "   value_generator: string(),\n"
    "   size_generator: small_strictly_positive_int()\n"
    " )\n"
    " ```\n"
).
-spec generic_set(generator(OLL), generator(integer())) -> generator(gleam@set:set(OLL)).
generic_set(Element_generator, Size_generator) ->
    map(
        generic_list(Element_generator, Size_generator),
        fun(Elements) -> gleam@set:from_list(Elements) end
    ).

-file("src/qcheck.gleam", 2684).
?DOC(
    " Generate bit arrays of UTF-8 encoded bytes with configurable values\n"
    " and number of codepoints.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `codepoints_from`: Generates the codepoint values of the resulting\n"
    "     bit arrays\n"
    " - `codepoint_size_from`: Generates sizes in number of codepoints represented\n"
    "     by the resulting bit arrays\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator of bit arrays of valid UTF-8 encoded bytes\n"
).
-spec generic_utf8_bit_array(generator(integer()), generator(integer())) -> generator(generator(list(integer()))).
generic_utf8_bit_array(Codepoint_generator, Num_codepoints_generator) ->
    map(
        Num_codepoints_generator,
        fun(Length) -> fixed_length_list_from(Codepoint_generator, Length) end
    ).

-file("src/qcheck.gleam", 2885).
-spec pick_origin_within_range(integer(), integer(), integer()) -> integer().
pick_origin_within_range(Low, High, Goal) ->
    case Low > Goal of
        true ->
            Low;

        false ->
            case High < Goal of
                true ->
                    High;

                false ->
                    Goal
            end
    end.

-file("src/qcheck.gleam", 1431).
?DOC(
    " Generate integers uniformly distributed between `from` and `to`, inclusive.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `from`: Lower bound of the range (inclusive)\n"
    " - `to`: Upper bound of the range (inclusive)\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator producing integers within the specified range.\n"
    "\n"
    " ### Behavior\n"
    "\n"
    " - Shrinks towards `0`, but won't shrink outside of the range `[from, to]`\n"
    " - Automatically orders parameters if `from` > `to`\n"
    "\n"
    " ### Example\n"
    "\n"
    " Generate integers between -10 and 10.\n"
    "\n"
    " ```\n"
    " bounded_int(-10, 10)\n"
    " ```\n"
).
-spec bounded_int(integer(), integer()) -> generator(integer()).
bounded_int(Low, High) ->
    {Low@1, High@1} = case Low =< High of
        true ->
            {Low, High};

        false ->
            {High, Low}
    end,
    generator(
        qcheck@random:int(Low@1, High@1),
        fun(N) ->
            Origin = pick_origin_within_range(Low@1, High@1, 0),
            qcheck@tree:new(N, qcheck@shrink:int_towards(Origin))
        end
    ).

-file("src/qcheck.gleam", 1445).
-spec bounded_int_with_shrink_target(integer(), integer(), integer()) -> generator(integer()).
bounded_int_with_shrink_target(Low, High, Shrink_target) ->
    {Low@1, High@1} = case Low =< High of
        true ->
            {Low, High};

        false ->
            {High, Low}
    end,
    generator(
        qcheck@random:int(Low@1, High@1),
        fun(N) ->
            Origin = pick_origin_within_range(Low@1, High@1, Shrink_target),
            qcheck@tree:new(N, qcheck@shrink:int_towards(Origin))
        end
    ).

-file("src/qcheck.gleam", 1482).
?DOC(
    " Generate uniformly distributed integers across a large range.\n"
    "\n"
    " ### Details\n"
    "\n"
    " - Shrinks generated values towards `0`\n"
    " - Not likely to hit interesting or corner cases\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator of integers with uniform distribution\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let positive_int_generator = {\n"
    "   use n <- map(uniform_int())\n"
    "   int.absolute_value(n)\n"
    " }\n"
    " ```\n"
).
-spec uniform_int() -> generator(integer()).
uniform_int() ->
    bounded_int(-2147483648, 2147483647).

-file("src/qcheck.gleam", 2399).
-spec unsigned_byte() -> generator(integer()).
unsigned_byte() ->
    bounded_int(0, 255).

-file("src/qcheck.gleam", 2546).
?DOC(
    " Generate bit arrays.\n"
    "\n"
    " ### Warning\n"
    "\n"
    " This function will generate bit arrays that cause runtime crashes when\n"
    " targeting JavaScript.\n"
).
-spec bit_array() -> generator(bitstring()).
bit_array() ->
    generic_bit_array(unsigned_byte(), small_non_negative_int()).

-file("src/qcheck.gleam", 2564).
?DOC(
    " Generate non-empty bit arrays.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator of non-empty bit arrays\n"
    "\n"
    " ### Warning\n"
    "\n"
    " This function will generate bit arrays that cause runtime crashes when\n"
    " targeting JavaScript.\n"
).
-spec non_empty_bit_array() -> generator(bitstring()).
non_empty_bit_array() ->
    generic_bit_array(unsigned_byte(), small_strictly_positive_int()).

-file("src/qcheck.gleam", 2578).
?DOC(
    " Generate fixed-size bit arrays.\n"
    "\n"
    " ### Warning\n"
    "\n"
    " This function will generate bit arrays that cause runtime crashes when\n"
    " targeting JavaScript.\n"
).
-spec fixed_size_bit_array(integer()) -> generator(bitstring()).
fixed_size_bit_array(Size) ->
    fixed_size_bit_array_from(unsigned_byte(), Size).

-file("src/qcheck.gleam", 2792).
?DOC(" Generate a number from the sequence `[0, 8, 16, ..., 128]`.\n").
-spec byte_aligned_bit_size_generator(integer()) -> generator(integer()).
byte_aligned_bit_size_generator(Min) ->
    map(
        bounded_int(Min, 16),
        fun(Num_bytes) ->
            Num_bits = 8 * Num_bytes,
            Num_bits
        end
    ).

-file("src/qcheck.gleam", 2702).
?DOC(" Generate byte-aligned bit arrays.\n").
-spec byte_aligned_bit_array() -> generator(bitstring()).
byte_aligned_bit_array() ->
    generic_bit_array(unsigned_byte(), byte_aligned_bit_size_generator(0)).

-file("src/qcheck.gleam", 2711).
?DOC(" Generate non-empty byte-aligned bit arrays.\n").
-spec non_empty_byte_aligned_bit_array() -> generator(bitstring()).
non_empty_byte_aligned_bit_array() ->
    generic_bit_array(unsigned_byte(), byte_aligned_bit_size_generator(1)).

-file("src/qcheck.gleam", 2897).
-spec pick_origin_within_range_float(float(), float(), float()) -> float().
pick_origin_within_range_float(Low, High, Goal) ->
    case Low > Goal of
        true ->
            Low;

        false ->
            case High < Goal of
                true ->
                    High;

                false ->
                    Goal
            end
    end.

-file("src/qcheck.gleam", 1546).
?DOC(
    " Generate floats uniformly distributed between `from` and `to`, inclusive.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `from`: Lower bound of the range (inclusive)\n"
    " - `to`: Upper bound of the range (inclusive)\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator producing floats within the specified range.\n"
    "\n"
    " ### Behavior\n"
    "\n"
    " - Shrinks towards `0`, but won't shrink outside of the range `[from, to]`\n"
    " - Automatically orders parameters if `from` > `to`\n"
    "\n"
    " ### Example\n"
    "\n"
    " Generate floats between -10 and 10.\n"
    "\n"
    " ```\n"
    " bounded_float(-10, 10)\n"
    " ```\n"
).
-spec bounded_float(float(), float()) -> generator(float()).
bounded_float(Low, High) ->
    {Low@1, High@1} = case Low =< High of
        true ->
            {Low, High};

        false ->
            {High, Low}
    end,
    generator(
        qcheck@random:float(Low@1, High@1),
        fun(N) ->
            Origin = pick_origin_within_range_float(Low@1, High@1, +0.0),
            qcheck@tree:new(N, qcheck@shrink:float_towards(Origin))
        end
    ).

-file("src/qcheck.gleam", 2952).
?DOC(
    " Return the first codepoint of a given string, or if the string is empty return the codepoint for `a`.\n"
    " Return the codepoint representation of the character.\n"
    "\n"
    " If the given character is a multicodepoint grapheme cluster, only returns\n"
    " the first codepoint in the cluster.\n"
    "\n"
    " If `n <= 0` return `0`, else return `n`.\n"
).
-spec ensure_positive_or_zero(integer()) -> integer().
ensure_positive_or_zero(N) ->
    case gleam@int:compare(N, 0) of
        gt ->
            N;

        eq ->
            N;

        lt ->
            0
    end.

-file("src/qcheck.gleam", 2736).
?DOC(
    " Generate byte-aligned bit arrays of the given number of bytes\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `num_bytes`: Number of bytes for the generated bit array\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces bit arrays with the specified number of bytes\n"
    "\n"
    " ### Example\n"
    "\n"
    " Generate 4-byte bit arrays:\n"
    "\n"
    " ```\n"
    " fixed_size_byte_aligned_bit_array(4)\n"
    " ```\n"
).
-spec fixed_size_byte_aligned_bit_array(integer()) -> generator(bitstring()).
fixed_size_byte_aligned_bit_array(Num_bytes) ->
    Num_bits = ensure_positive_or_zero(Num_bytes) * 8,
    fixed_size_bit_array(Num_bits).

-file("src/qcheck.gleam", 546).
?DOC(
    " Set the number of test cases to run in a property test.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `config`: The current configuration\n"
    " - `test_count`: Number of test cases to generate.  If `test_count <= 0`,\n"
    "     uses the default test count.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A new `Config` with the specified test count\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let config = default_config() |> with_test_count(10_000)\n"
    " ```\n"
).
-spec with_test_count(config(), integer()) -> config().
with_test_count(Config, Test_count) ->
    Test_count@1 = case Test_count =< 0 of
        true ->
            1000;

        false ->
            Test_count
    end,
    _record = Config,
    {config,
        Test_count@1,
        erlang:element(3, _record),
        erlang:element(4, _record)}.

-file("src/qcheck.gleam", 489).
?DOC(
    " Create a default configuration for property-based testing.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " - A `Config` with default settings for test count, max retries, and seed\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let config = default_config()\n"
    " ```\n"
).
-spec default_config() -> config().
default_config() ->
    {config, 1000, 1, random_seed()}.

-file("src/qcheck.gleam", 573).
?DOC(
    " Set the maximum number of retries for a property test.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `config`: The current configuration\n"
    " - `max_retries`: Maximum number of retries allowed.  If `max_retries < 0`,\n"
    "     uses the default max retries.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A new `Config` with the specified maximum retries\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let config = default_config() |> with_max_retries(100)\n"
    " ```\n"
).
-spec with_max_retries(config(), integer()) -> config().
with_max_retries(Config, Max_retries) ->
    Max_retries@1 = case Max_retries < 0 of
        true ->
            1;

        false ->
            Max_retries
    end,
    _record = Config,
    {config,
        erlang:element(2, _record),
        Max_retries@1,
        erlang:element(4, _record)}.

-file("src/qcheck.gleam", 516).
?DOC(
    " Create a new `Config` with specified test count, max retries, and seed.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `test_count`: Number of test cases to generate\n"
    " - `max_retries`: Maximum retries to test a shrunk input candidate.\n"
    "      Values > 1 can be useful for testing non-deterministic code.\n"
    " - `seed`: Random seed for deterministic test generation\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A `Config` with the provided settings, using defaults for any invalid arguments\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let config = config(test_count: 10_000, max_retries: 1, seed: seed(47))\n"
    " ```\n"
).
-spec config(integer(), integer(), qcheck@random:seed()) -> config().
config(Test_count, Max_retries, Seed) ->
    _pipe = default_config(),
    _pipe@1 = with_test_count(_pipe, Test_count),
    _pipe@2 = with_max_retries(_pipe@1, Max_retries),
    with_seed(_pipe@2, Seed).

-file("src/qcheck.gleam", 1507).
?DOC(
    " Generate floats with a bias towards smaller values.\n"
    "\n"
    " Shrinks towards `0.0`.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces floating-point numbers\n"
).
-spec float() -> generator(float()).
float() ->
    {generator,
        fun(Seed) ->
            {X, Seed@1} = begin
                _pipe = qcheck@random:float(+0.0, 15.0),
                qcheck@random:step(_pipe, Seed)
            end,
            {Y, Seed@2} = begin
                _pipe@1 = qcheck@random:choose(1.0, -1.0),
                qcheck@random:step(_pipe@1, Seed@1)
            end,
            {Z, Seed@3} = begin
                _pipe@2 = qcheck@random:choose(1.0, -1.0),
                qcheck@random:step(_pipe@2, Seed@2)
            end,
            Generated_value = (exp(X) * Y) * Z,
            Tree = qcheck@tree:new(
                Generated_value,
                qcheck@shrink:float_towards(+0.0)
            ),
            {Tree, Seed@3}
        end}.

-file("src/qcheck.gleam", 1490).
-spec exp(float()) -> float().
exp(X) ->
    _assert_subject = gleam@float:power(2.71828, X),
    {ok, Result} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"qcheck"/utf8>>,
                        function => <<"exp"/utf8>>,
                        line => 1495})
    end,
    Result.

-file("src/qcheck.gleam", 1645).
-spec utf_codepoint_exn(integer()) -> integer().
utf_codepoint_exn(Int) ->
    case gleam@string:utf_codepoint(Int) of
        {ok, Cp} ->
            Cp;

        {error, nil} ->
            erlang:error(#{gleam_error => panic,
                    message => (<<"ERROR utf_codepoint_exn: "/utf8,
                        (erlang:integer_to_binary(Int))/binary>>),
                    module => <<"qcheck"/utf8>>,
                    function => <<"utf_codepoint_exn"/utf8>>,
                    line => 1648})
    end.

-file("src/qcheck.gleam", 2072).
?DOC(
    " Generate strings with the default codepoint and length generators.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " use string <- given(string())\n"
    " string.length(string) == string.length(string <> \"!\") + 1\n"
    " ```\n"
).
-spec string() -> generator(binary()).
string() ->
    bind(
        small_non_negative_int(),
        fun(Length) -> fixed_length_string_from(codepoint(), Length) end
    ).

-file("src/qcheck.gleam", 1787).
?DOC(
    " Generate Unicode codepoints with a decent distribution that is good for\n"
    " generating genreal strings.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces Unicode codepoints\n"
    "\n"
    " ### Example\n"
    "\n"
    " The decent default string generator could be writen something like this:\n"
    "\n"
    " ```\n"
    " generic_string(codepoint(), small_non_negative_int())\n"
    " ```\n"
).
-spec codepoint() -> generator(integer()).
codepoint() ->
    from_weighted_generators(
        {30, uppercase_ascii_codepoint()},
        [{30, lowercase_ascii_codepoint()},
            {10, ascii_digit_codepoint()},
            {15, uniform_printable_ascii_codepoint()},
            {15, uniform_codepoint()}]
    ).

-file("src/qcheck.gleam", 1630).
?DOC(
    " Generate Unicode codepoints.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that creates Unicode codepoints across the valid range\n"
    "\n"
    " ### Notes\n"
    "\n"
    " - Generates codepoints from U+0000 to U+10FFFF\n"
    " - Uses ASCII lowercase 'a' as a shrink target\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " string_from(uniform_codepoint())\n"
    " ```\n"
).
-spec uniform_codepoint() -> generator(integer()).
uniform_codepoint() ->
    map(
        bounded_int_with_shrink_target(16#0000, 16#10FFFF, 97),
        fun(Int) -> case Int of
                N when (0 =< N) andalso (N =< 16#D7FF) ->
                    utf_codepoint_exn(N);

                N@1 when (16#E000 =< N@1) andalso (N@1 =< 16#10FFFF) ->
                    utf_codepoint_exn(N@1);

                _ ->
                    utf_codepoint_exn(97)
            end end
    ).

-file("src/qcheck.gleam", 1891).
?DOC(
    " Return the codepoint representation of the character.\n"
    "\n"
    " If the given character is a multicodepoint grapheme cluster, only returns\n"
    " the first codepoint in the cluster.\n"
).
-spec char_to_int(binary()) -> integer().
char_to_int(Char) ->
    case gleam@string:to_utf_codepoints(Char) of
        [] ->
            97;

        [Codepoint | _] ->
            gleam_stdlib:identity(Codepoint)
    end.

-file("src/qcheck.gleam", 1931).
-spec do_gen_string(
    integer(),
    integer(),
    list(integer()),
    generator(integer()),
    list(qcheck@tree:tree(integer())),
    qcheck@random:seed()
) -> {binary(), list(qcheck@tree:tree(integer())), qcheck@random:seed()}.
do_gen_string(Target_length, I, Acc, Codepoint_gen, Codepoint_trees_rev, Seed) ->
    {generator, Gen_codepoint_tree} = Codepoint_gen,
    {Codepoint_tree, Seed@1} = Gen_codepoint_tree(Seed),
    case I >= Target_length of
        true ->
            Generated_string = begin
                _pipe = lists:reverse(Acc),
                gleam_stdlib:utf_codepoint_list_to_string(_pipe)
            end,
            case string:length(Generated_string) < Target_length of
                true ->
                    {tree, Root, _} = Codepoint_tree,
                    do_gen_string(
                        Target_length,
                        I + 1,
                        [Root | Acc],
                        Codepoint_gen,
                        [Codepoint_tree | Codepoint_trees_rev],
                        Seed@1
                    );

                false ->
                    {Generated_string, Codepoint_trees_rev, Seed@1}
            end;

        false ->
            {tree, Root@1, _} = Codepoint_tree,
            do_gen_string(
                Target_length,
                I + 1,
                [Root@1 | Acc],
                Codepoint_gen,
                [Codepoint_tree | Codepoint_trees_rev],
                Seed@1
            )
    end.

-file("src/qcheck.gleam", 2009).
?DOC(
    " Generate a fixed-length string from the given codepoint generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: A generator for codepoints\n"
    " - `length`: Number of graphemes in the generated string\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces strings with the specified number of graphemes\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " fixed_length_string_from(codepoint(), 5)\n"
    " ```\n"
).
-spec fixed_length_string_from(generator(integer()), integer()) -> generator(binary()).
fixed_length_string_from(Generator, Length) ->
    {generator,
        fun(Seed) ->
            {Generated_string, Reversed_codepoint_trees, Seed@1} = do_gen_string(
                Length,
                0,
                [],
                Generator,
                [],
                Seed
            ),
            Shrink = fun() ->
                Codepoint_list_tree = begin
                    _pipe = lists:reverse(Reversed_codepoint_trees),
                    qcheck@tree:sequence_trees(_pipe)
                end,
                {tree, _, Children} = begin
                    _pipe@1 = Codepoint_list_tree,
                    qcheck@tree:map(
                        _pipe@1,
                        fun(Char_list) ->
                            gleam_stdlib:utf_codepoint_list_to_string(Char_list)
                        end
                    )
                end,
                Children
            end,
            Tree = {tree, Generated_string, Shrink()},
            {Tree, Seed@1}
        end}.

-file("src/qcheck.gleam", 2055).
?DOC(
    " Generate a string from the given codepoint generator and the given length\n"
    " generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `codepoint_generator`: A generator for codepoints\n"
    " - `length_generator`: A generator to determine number of graphemes in the\n"
    "      generated strings\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A string generator\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " generic_string(ascii_digit_codepoint(), bounded_int(8, 15))\n"
    " ```\n"
).
-spec generic_string(generator(integer()), generator(integer())) -> generator(binary()).
generic_string(Codepoint_generator, Length_generator) ->
    bind(
        Length_generator,
        fun(Length) -> fixed_length_string_from(Codepoint_generator, Length) end
    ).

-file("src/qcheck.gleam", 2086).
?DOC(
    " Generate non-empty strings with the default codepoint and length generators.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " use string <- given(string())\n"
    " string.length(string) > 0\n"
    " ```\n"
).
-spec non_empty_string() -> generator(binary()).
non_empty_string() ->
    bind(
        small_strictly_positive_int(),
        fun(Length) -> fixed_length_string_from(codepoint(), Length) end
    ).

-file("src/qcheck.gleam", 2101).
?DOC(
    " Generate strings with the given codepoint generator and default length\n"
    " generator.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " string_from(ascii_digit_codepoint())\n"
    " ```\n"
).
-spec string_from(generator(integer())) -> generator(binary()).
string_from(Codepoint_generator) ->
    bind(
        small_non_negative_int(),
        fun(Length) -> fixed_length_string_from(Codepoint_generator, Length) end
    ).

-file("src/qcheck.gleam", 2118).
?DOC(
    " Generate non-empty strings with the given codepoint generator and default\n"
    " length generator.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " non_empty_string_from(alphanumeric_ascii_codepoint())\n"
    " ```\n"
).
-spec non_empty_string_from(generator(integer())) -> generator(binary()).
non_empty_string_from(Codepoint_generator) ->
    bind(
        small_strictly_positive_int(),
        fun(Length) -> fixed_length_string_from(Codepoint_generator, Length) end
    ).

-file("src/qcheck.gleam", 2628).
-spec utf_codepoint_list(integer(), integer()) -> generator(list(integer())).
utf_codepoint_list(Min_length, Max_length) ->
    generic_list(uniform_codepoint(), bounded_int(Min_length, Max_length)).

-file("src/qcheck.gleam", 2692).
-spec bit_array_from_codepoints(list(integer())) -> bitstring().
bit_array_from_codepoints(Codepoints) ->
    _pipe = Codepoints,
    _pipe@1 = gleam_stdlib:utf_codepoint_list_to_string(_pipe),
    gleam_stdlib:identity(_pipe@1).

-file("src/qcheck.gleam", 2586).
?DOC(" Generate bit arrays of valid UTF-8 bytes.\n").
-spec utf8_bit_array() -> generator(bitstring()).
utf8_bit_array() ->
    bind(
        small_strictly_positive_int(),
        fun(Max_length) ->
            map(
                utf_codepoint_list(0, Max_length),
                fun(Codepoints) -> bit_array_from_codepoints(Codepoints) end
            )
        end
    ).

-file("src/qcheck.gleam", 2595).
?DOC(" Generate non-empty bit arrays of valid UTF-8 bytes.\n").
-spec non_empty_utf8_bit_array() -> generator(bitstring()).
non_empty_utf8_bit_array() ->
    bind(
        small_strictly_positive_int(),
        fun(Max_length) ->
            map(
                utf_codepoint_list(1, Max_length),
                fun(Codepoints) -> bit_array_from_codepoints(Codepoints) end
            )
        end
    ).

-file("src/qcheck.gleam", 2620).
?DOC(
    " Generate a fixed-sized bit array of valid UTF-8 encoded bytes with the\n"
    " given number of codepoints.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `num_codepoints`: The number of Unicode codepoints represented by the\n"
    " generated bit arrays\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces of fixed-sized bit arrays of UTF-8 encoded bytes\n"
    "\n"
    " ### Details\n"
    "\n"
    " - The size is determined by the number of Unicode codepoints, not bytes or\n"
    "   bits.\n"
    " - If a negative number is provided, it is converted to zero.\n"
).
-spec fixed_size_utf8_bit_array(integer()) -> generator(bitstring()).
fixed_size_utf8_bit_array(Num_codepoints) ->
    Num_codepoints@1 = ensure_positive_or_zero(Num_codepoints),
    map(
        utf_codepoint_list(Num_codepoints@1, Num_codepoints@1),
        fun(Codepoints) -> bit_array_from_codepoints(Codepoints) end
    ).

-file("src/qcheck.gleam", 2658).
?DOC(
    " Generate a fixed-sized bit array of valid UTF-8 encoded bytes with the\n"
    " given number of codepoints and values generated from the given codepoint\n"
    " generator.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `codepoint_generator`: Generates the values\n"
    " - `num_codepoints`: The number of Unicode codepoints represented by the\n"
    " generated bit arrays\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces of fixed-sized bit arrays of UTF-8 encoded bytes\n"
    "\n"
    " ### Details\n"
    "\n"
    " - The size is determined by the number of Unicode codepoints, not bytes or\n"
    "   bits.\n"
    " - If a negative number is provided, it is converted to zero.\n"
).
-spec fixed_size_utf8_bit_array_from(generator(integer()), integer()) -> generator(bitstring()).
fixed_size_utf8_bit_array_from(Codepoint_generator, Num_codepoints) ->
    map(
        fixed_length_list_from(Codepoint_generator, Num_codepoints),
        fun(Codepoints) -> bit_array_from_codepoints(Codepoints) end
    ).

-file("src/qcheck.gleam", 2823).
-spec test_error_to_string(test_error(any())) -> binary().
test_error_to_string(Test_error) ->
    <<<<<<<<<<<<<<<<"TestError[original_value: "/utf8,
                                    (gleam@string:inspect(
                                        erlang:element(2, Test_error)
                                    ))/binary>>/binary,
                                "; shrunk_value: "/utf8>>/binary,
                            (gleam@string:inspect(erlang:element(3, Test_error)))/binary>>/binary,
                        "; shrink_steps: "/utf8>>/binary,
                    (gleam@string:inspect(erlang:element(4, Test_error)))/binary>>/binary,
                "; error: "/utf8>>/binary,
            (erlang:element(5, Test_error))/binary>>/binary,
        ";]"/utf8>>.

-file("src/qcheck.gleam", 2843).
-spec failwith(ONM, ONM, integer(), binary()) -> any().
failwith(Original_value, Shrunk_value, Shrink_steps, Error_msg) ->
    _pipe = new_test_error(
        Original_value,
        Shrunk_value,
        Shrink_steps,
        Error_msg
    ),
    _pipe@1 = test_error_to_string(_pipe),
    fail(_pipe@1).

-file("src/qcheck.gleam", 298).
-spec do_run(config(), generator(OCL), fun((OCL) -> nil), integer()) -> nil.
do_run(Config, Generator, Property, I) ->
    case I >= erlang:element(2, Config) of
        true ->
            nil;

        false ->
            {generator, Generate} = Generator,
            {Tree, Seed} = Generate(erlang:element(4, Config)),
            {tree, Value, _} = Tree,
            case 'try'(fun() -> Property(Value) end) of
                {no_panic, nil} ->
                    do_run(
                        begin
                            _pipe = Config,
                            with_seed(_pipe, Seed)
                        end,
                        Generator,
                        Property,
                        I + 1
                    );

                {panic, Exn} ->
                    {Shrunk_value, Shrink_steps} = shrink(
                        Tree,
                        Property,
                        erlang:element(3, Config)
                    ),
                    failwith(
                        Value,
                        Shrunk_value,
                        Shrink_steps,
                        gleam@string:inspect(Exn)
                    )
            end
    end.

-file("src/qcheck.gleam", 273).
?DOC(
    " Test a property against generated test cases using the provided\n"
    " configuration.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `config`: Settings for test execution\n"
    " - `generator`: Creates test inputs\n"
    " - `property`: The property to verify\n"
    "\n"
    " ### Returns\n"
    "\n"
    " - `Nil` if all test cases pass (the property returns `Nil`)\n"
    " - Panics if any test case fails (the property panics)\n"
).
-spec run(config(), generator(OCH), fun((OCH) -> nil)) -> nil.
run(Config, Generator, Property) ->
    do_run(Config, Generator, Property, 0).

-file("src/qcheck.gleam", 294).
?DOC(
    " Test a property against generated test cases using the default\n"
    " configuration.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `generator`: Creates test inputs\n"
    " - `property`: The property to verify\n"
    "\n"
    " ### Returns\n"
    "\n"
    " - `Nil` if all test cases pass (the property returns `Nil`)\n"
    " - Panics if any test case fails (the property panics)\n"
).
-spec given(generator(OCJ), fun((OCJ) -> nil)) -> nil.
given(Generator, Property) ->
    run(default_config(), Generator, Property).

-file("src/qcheck.gleam", 2928).
?DOC(
    " Convert and int to a single character string.\n"
    "\n"
    " If the given int does not\n"
    " represent a valid codepoint, returns try to convert `default` into a valid\n"
    " codepoint.\n"
    "\n"
    " If that too doesn't work, then just return `\"a\"` -- but you should ensure\n"
    " that `default` will be a valid codepoint or you may mess up the expected\n"
    " shrinking behavior.\n"
    "\n"
    " Convert an int to a codepoint.\n"
    "\n"
    " If the given int does not\n"
    " represent a valid codepoint, returns try to convert `default` into a valid\n"
    " codepoint.\n"
    "\n"
    " If that too doesn't work, then just return `\"a\"` -- but you should ensure\n"
    " that `default` will be a valid codepoint or you may mess up the expected\n"
    " shrinking behavior.\n"
).
-spec int_to_codepoint(integer(), integer()) -> integer().
int_to_codepoint(N, Default) ->
    case gleam@string:utf_codepoint(N) of
        {ok, Cp} ->
            Cp;

        {error, nil} ->
            case gleam@string:utf_codepoint(Default) of
                {ok, Cp@1} ->
                    Cp@1;

                {error, nil} ->
                    _assert_subject = gleam@string:utf_codepoint(97),
                    {ok, Cp@2} = case _assert_subject of
                        {ok, _} -> _assert_subject;
                        _assert_fail ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        value => _assert_fail,
                                        module => <<"qcheck"/utf8>>,
                                        function => <<"int_to_codepoint"/utf8>>,
                                        line => 2937})
                    end,
                    Cp@2
            end
    end.

-file("src/qcheck.gleam", 1586).
?DOC(
    " Generate Unicode codepoints uniformly distributed within a specified\n"
    " range.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `from`: Minimum codepoint value (inclusive)\n"
    " - `to`: Maximum codepoint value (inclusive)\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces Unicode codepoints within the specified range.\n"
    "\n"
    " ### Notes\n"
    "\n"
    " - If the range is invalid, it will be automatically adjusted to a valid\n"
    "   range\n"
    " - Shrinks towards an origin codepoint (typically lowercase 'a')\n"
    " - Mainly used for string generation\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let cyrillic_character = bounded_codepoint(from: 0x0400, to: 0x04FF)\n"
    " ```\n"
).
-spec bounded_codepoint(integer(), integer()) -> generator(integer()).
bounded_codepoint(Low, High) ->
    {Low@1, High@1} = case Low =< High of
        true ->
            {Low, High};

        false ->
            {High, Low}
    end,
    Low@2 = gleam@int:clamp(Low@1, 0, 16#10FFFF),
    High@2 = gleam@int:clamp(High@1, 0, 16#10FFFF),
    Origin = pick_origin_within_range(Low@2, High@2, 97),
    Shrink = qcheck@shrink:int_towards(Origin),
    {generator,
        fun(Seed) ->
            {N, Seed@1} = begin
                _pipe = qcheck@random:int(Low@2, High@2),
                qcheck@random:step(_pipe, Seed)
            end,
            Tree = begin
                _pipe@1 = qcheck@tree:new(N, Shrink),
                qcheck@tree:map(
                    _pipe@1,
                    fun(_capture) -> int_to_codepoint(_capture, Origin) end
                )
            end,
            {Tree, Seed@1}
        end}.

-file("src/qcheck.gleam", 1664).
?DOC(
    " Generate uppercase ASCII letters.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces uppercase letters from `A` to `Z` as codepoints\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " string_from(uppercase_ascii_codepoint())\n"
    " ```\n"
).
-spec uppercase_ascii_codepoint() -> generator(integer()).
uppercase_ascii_codepoint() ->
    bounded_codepoint(65, 90).

-file("src/qcheck.gleam", 1680).
?DOC(
    " Generate lowercase ASCII letters.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces lowercase letters from `a` to `z` as codepoints\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " string_from(lowercase_ascii_codepoint())\n"
    " ```\n"
).
-spec lowercase_ascii_codepoint() -> generator(integer()).
lowercase_ascii_codepoint() ->
    bounded_codepoint(97, 122).

-file("src/qcheck.gleam", 1696).
?DOC(
    " Generate ASCII digits as codepoints.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces ASCII digits from `0` to `9` as codepoints\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " string_from(ascii_digit_codepoint())\n"
    " ```\n"
).
-spec ascii_digit_codepoint() -> generator(integer()).
ascii_digit_codepoint() ->
    bounded_codepoint(48, 57).

-file("src/qcheck.gleam", 1712).
?DOC(
    " Generate alphabetic ASCII characters.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces alphabetic ASCII characters as codepoints\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " string_from(alphabetic_ascii_codepoint())\n"
    " ```\n"
).
-spec alphabetic_ascii_codepoint() -> generator(integer()).
alphabetic_ascii_codepoint() ->
    from_generators(uppercase_ascii_codepoint(), [lowercase_ascii_codepoint()]).

-file("src/qcheck.gleam", 1728).
?DOC(
    " Generate alphanumeric ASCII characters.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces alphanumeric ASCII characters as codepoints\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " string_from(alphanumeric_ascii_codepoint())\n"
    " ```\n"
).
-spec alphanumeric_ascii_codepoint() -> generator(integer()).
alphanumeric_ascii_codepoint() ->
    from_weighted_generators(
        {26, uppercase_ascii_codepoint()},
        [{26, lowercase_ascii_codepoint()}, {10, ascii_digit_codepoint()}]
    ).

-file("src/qcheck.gleam", 1747).
?DOC(
    " Uniformly generate printable ASCII characters.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces printable ASCII characters as codepoints\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " string_from(uniform_printable_ascii_codepoint())\n"
    " ```\n"
).
-spec uniform_printable_ascii_codepoint() -> generator(integer()).
uniform_printable_ascii_codepoint() ->
    bounded_codepoint(32, 126).

-file("src/qcheck.gleam", 1764).
?DOC(
    " Generate printable ASCII characters with a bias towards alphanumeric\n"
    " characters.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces printable ASCII characters as codepoints\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " string_from(printable_ascii_codepoint())\n"
    " ```\n"
).
-spec printable_ascii_codepoint() -> generator(integer()).
printable_ascii_codepoint() ->
    from_weighted_generators(
        {381, uppercase_ascii_codepoint()},
        [{381, lowercase_ascii_codepoint()},
            {147, ascii_digit_codepoint()},
            {91, uniform_printable_ascii_codepoint()}]
    ).

-file("src/qcheck.gleam", 1833).
?DOC(
    " Generate a codepoint from a list of codepoints represented as integers.\n"
    "\n"
    " Splitting up the arguments in this way ensures some value is always\n"
    " generated by preventing you from passing in an empty list.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `first`: First codepoint to choose from\n"
    " - `rest`: Additional codepoints to choose from\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A `Generator` that produces codepoints from the provided values\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let ascii_whitespace_generator = codepoint_from_ints(\n"
    "   // Horizontal tab\n"
    "   9,\n"
    "   [\n"
    "     // Line feed\n"
    "     10,\n"
    "     // Vertical tab\n"
    "     11,\n"
    "     // Form feed\n"
    "     12,\n"
    "     // Carriage return\n"
    "     13,\n"
    "     // Space\n"
    "     32,\n"
    "   ],\n"
    " )\n"
    " ```\n"
).
-spec codepoint_from_ints(integer(), list(integer())) -> generator(integer()).
codepoint_from_ints(First, Rest) ->
    Hd = First,
    Tl = Rest,
    Shrink_target = gleam@list:fold(Tl, Hd, fun gleam@int:min/2),
    {generator,
        fun(Seed) ->
            {N, Seed@1} = begin
                _pipe = qcheck@random:uniform(Hd, Tl),
                qcheck@random:step(_pipe, Seed)
            end,
            Tree = begin
                _pipe@1 = qcheck@tree:new(
                    N,
                    qcheck@shrink:int_towards(Shrink_target)
                ),
                qcheck@tree:map(
                    _pipe@1,
                    fun(_capture) ->
                        int_to_codepoint(_capture, Shrink_target)
                    end
                )
            end,
            {Tree, Seed@1}
        end}.

-file("src/qcheck.gleam", 1876).
?DOC(
    " Generate a codepoint from a list of strings.\n"
    "\n"
    " ### Arguments\n"
    "\n"
    " - `first`: First character to choose from\n"
    " - `rest`: Additional characters to choose from\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A `Generator` that produces codepoints from the provided values\n"
    "\n"
    " ### Notes\n"
    "\n"
    " - Splitting up the arguments in this way ensures some value is always\n"
    "   generated by preventing you from passing in an empty list.\n"
    " - Only the first codepoint is taken from each of the provided strings\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let quadrant_generator = codepoint_from_strings(\"▙\", [\"▛\", \"▜\", \"▟\"])\n"
    " ```\n"
).
-spec codepoint_from_strings(binary(), list(binary())) -> generator(integer()).
codepoint_from_strings(First, Rest) ->
    Head = char_to_int(First),
    Tail = gleam@list:map(Rest, fun char_to_int/1),
    codepoint_from_ints(Head, Tail).

-file("src/qcheck.gleam", 1910).
?DOC(
    " Generate ASCII whitespace as codepoints.\n"
    "\n"
    " ### Returns\n"
    "\n"
    " A generator that produces ASCII whitespace as codepoints\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```\n"
    " let whitespace_generator = string_from(ascii_whitespace_codepoint())\n"
    " ```\n"
).
-spec ascii_whitespace_codepoint() -> generator(integer()).
ascii_whitespace_codepoint() ->
    codepoint_from_ints(9, [10, 11, 12, 13, 32]).
