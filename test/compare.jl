using Printf

using Wordlebot
using FilePathsBase; using FilePathsBase: /

function awfulbot(guess, targets)
    if guess in targets
        if length(targets) == 1
            0
        else
            counts = Dict{Vector{Int8}, Int16}()
            for target in targets
                if guess != target
                    clue = cluefor(guess, target)
                    counts[clue] = get(counts, clue, 0) + 1
                end
            end
            1 - maximum(values(counts)) / length(targets)
        end
    else
        1
    end
end

const strategies = [
    (
        "mean_info",
        "Initial strategy (mean info)",
        (g, t) -> GuessRanker(meanturns, g, t),
    ),
    (
        "avoid_small",
        "Avoid small groups",
        (g, t) -> GuessRanker(meanturns_better, g, t),
    ),
    (
        "avoid_small_random",
        "Avoid small groups, randomized",
        (g, t) -> GuessRanker(meanturns_better, g, t, true),
    ),
    (
        "baseline",
        "Guess a random word that fits all the clues",
        (g, t) -> GuessRanker((g_, t_) -> g_ in t_ ? 0 : 1, g, t, true)
    ),
    (
        "awful",
        "Choose the least informative word that fits all the clues",
        (g, t) -> GuessRanker(awfulbot, g, t)
    )
]

const resultspath = p"test/results"

function main()
    _, targets = Wordlebot.Wordlist.load()
    test_targets = test_sample(targets, 100)
    guesses = targets
    println("Comparing strategies")

    for (i, (fname, description, strategy)) in enumerate(strategies)
        path = resultspath / "$(string(i; pad=2))_$fname.txt"
        println(description, ":")
        if exists(path)
            string(path) |> readlines |> first |> println
        else
            total_guesses = 0
            all_turns = Vector{String}()
            for target in test_targets
                player = strategy(guesses, targets)
                turns = play!(player, target)
                println(turns)
                push!(all_turns, string(turns))
                total_guesses += length(turns)
            end
            average_guesses = total_guesses / length(test_targets)
            score_summary = @sprintf "Average guesses: %.2f" average_guesses
            println(score_summary)
            mkpath(parent(path))
            open(path, "w") do f
                println(f, score_summary)
                for turn in all_turns
                    println(f, turn)
                end
            end
        end
    end
end

function test_sample(targets::Vector{<:AbstractString}, size::Integer)
    n = length(targets)
    targets[1:cld(n, size):n]
end


function Base.show(io::IO, x::Vector{Turn})
    print(io, length(x), ": ")
    join(io, map(turn -> "$(turn.guess) ($(turn.clue))", x), " > ")
end

main()
