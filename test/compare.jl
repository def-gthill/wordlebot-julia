using Printf

using Wordlebot
using FilePathsBase; using FilePathsBase: /

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
