module Wordlebot

include("Wordlist.jl")

import ArgParse
import Base.Iterators
import Random

import .Wordlist

export Player, Turn, GuessRanker
export guess!, play!
export meanturns, meanturns_better, meaninfo, cluefor, cluefor_text

const CLUE_CHARS = "_?\$"

function main()
    parsed_args = parse_args()
    all_words = parsed_args["all"]
    randomize = parsed_args["randomize"]

    guesses, targets = Wordlist.load()
    if !all_words
        guesses = targets
    end

    player = GuessRanker(meanturns_better, guesses, targets, randomize)

    guess_number = 1
    clue = nothing
    while clue != "\$\$\$\$\$"
        println("Guess $guess_number")
        best_guess = guess!(player, clue)
        if isempty(best_guess)
            println("I don't get it!")
            return
        else
            message = if length(player.remaining_targets) == 1
                "I know this is the answer!"
            else
                "$(length(player.remaining_targets)) words remaining"
            end
            println("$best_guess ($message)")
            clue = readline(keep = false)
            while !(length(clue) == 5 && Set(clue) ⊆ Set(CLUE_CHARS))
                println("Invalid clue; must have five characters, all _, ?, or \$")
                clue = readline(keep = false)
            end
            guess_number += 1
        end
    end
    
    println("Yay!")
end

function parse_args()
    s = ArgParse.ArgParseSettings()

    ArgParse.@add_arg_table! s begin
        "--all"
            help = "allow all valid guesses"
            action = :store_true
        "--randomize"
            help = "choose randomly from amongst the best guesses"
            action = :store_true
    end

    ArgParse.parse_args(s)
end

abstract type Player end

function guess!(player::Player, clue::Union{String, Nothing})::AbstractString
    ""
end

function play!(player::Player, target::AbstractString)::Vector{Turn}
    clue = nothing
    result = Vector{Turn}()
    while !(clue == "\$\$\$\$\$" || clue == "")
        guess = guess!(player, clue)
        clue = isempty(guess) ? "" : cluefor_text(guess, target)
        push!(result, Turn(guess, clue))
    end
    result
end

struct Turn
    guess::AbstractString
    clue::String
end

mutable struct GuessRanker <: Player
    strategy::Function
    allowed_guesses::Vector{<:AbstractString}
    allowed_targets::Vector{<:AbstractString}
    randomize::Bool
    last_guess::Union{AbstractString, Nothing}
    remaining_targets::Vector{<:AbstractString}
    function GuessRanker(strategy, allowed_guesses, allowed_targets, randomize = false)
        new(strategy, allowed_guesses, allowed_targets, randomize, nothing, allowed_targets)
    end
end

function guess!(player::GuessRanker, clue::Union{String, Nothing})::AbstractString
    if player.last_guess !== nothing
        player.remaining_targets = filter(
            word -> fitsclue_text(player.last_guess, word, clue),
            player.remaining_targets,
        )
    end
    if isempty(player.remaining_targets)
        return ""
    end
    best_guess_list = best_guesses(
        player.strategy, player.allowed_guesses, player.remaining_targets
    )
    best_guess_with_score = first(best_guess_list)
    if player.randomize
        decent_guesses = collect(
            Iterators.takewhile(best_guess_list) do g
                g.score - best_guess_with_score.score < 0.05
            end
        )
        best_guess_with_score = first(Random.shuffle(decent_guesses))
    end
    player.last_guess = best_guess_with_score.guess
end

function best_guesses(
    strategy::Function,
    guesses::Vector{<:AbstractString},
    targets::Vector{<:AbstractString},
)::Vector{Guess}
    result = [Guess(guess, strategy(guess, targets)) for guess in guesses]
    sort(result, by = guess -> (guess.score, guess.guess))
end

struct Guess
    guess::AbstractString
    score::Float64
end

function meanturns_better(
    guess::AbstractString,
    targets::Vector{<:AbstractString},
    future_info::Real = 3.0,
)::Float64
    counts = Dict{Vector{Int8}, Int16}()
    for target in targets
        if guess != target
            clue = cluefor(guess, target)
            counts[clue] = get(counts, clue, 0) + 1
        end
    end
    n = length(targets)
    turns = 1
    if n > 1
        total = sum(values(counts)) do c
            c * max(
                1 + (log(n) - log(n / c)) / future_info,
                (2 * c - 1) / c,
            )
        end
        turns *= total / sum(values(counts))
    end
    if guess in targets
        turns *= (n - 1) / n
    end
    turns
end

function meanturns(
    guess::AbstractString,
    targets::Vector{<:AbstractString},
    future_info::Real = 3.0,
)::Float64
    n = length(targets)
    if guess in targets
        result = (n - 1) / n
        if length(targets) > 1
            result *= (1 + (log(n) - meaninfo(guess, targets)) / future_info)
        end
        result
    else
        (1 + (log(n) - meaninfo(guess, targets)) / future_info)
    end
end

function meaninfo(guess::AbstractString, targets::Vector{<:AbstractString})::Float64
    counts = Dict{Vector{Int8}, Int16}()
    for target in targets
        if guess != target
            clue = cluefor(guess, target)
            counts[clue] = get(counts, clue, 0) + 1
        end
    end
    n = length(targets)
    sum(c -> c * log(n / c), values(counts)) / sum(values(counts))
end

function cluefor(guess::AbstractString, target::AbstractString)::Vector{Int8}
    result = zeros(Int8, length(target))
    unmatched_indices = BitSet(keys(target))
    mark_strong_matches!(result, guess, target, unmatched_indices)
    mark_weak_matches!(result, guess, target, unmatched_indices)
    result
end

function mark_strong_matches!(result, guess, target, unmatched_indices)
    for (i, char) in pairs(guess)
        if char == target[i]
            result[i] = 2
            delete!(unmatched_indices, i)
        end
    end
end

function mark_weak_matches!(result, guess, target, unmatched_indices)
    for (i, char) in pairs(guess)
        if result[i] > 0 continue end
        matching_index = first_or_zero(unmatched_indices) do j
            char == target[j]
        end
        if matching_index > 0
            result[i] = 1
            delete!(unmatched_indices, matching_index)
        end
    end
end

function first_or_zero(f, c)
    for elem in c
        if f(elem)
            return elem
        end
    end
    0
end

function fitsclue_text(
    guess::AbstractString, target::AbstractString, clue::AbstractString
)::Bool
    cluefor_text(guess, target) == clue
end

function cluefor_text(guess::AbstractString, target::AbstractString)::String
    clue_chars = map(cluefor(guess, target)) do i
        CLUE_CHARS[i + 1]
    end
    String(clue_chars)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end # module
