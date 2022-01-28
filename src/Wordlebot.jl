module Wordlebot

include("Wordlist.jl")

import .Wordlist

export meanturns, meaninfo, cluefor, cluefor_text

const CLUE_CHARS = "_?\$"

function main()
    guesses, targets = Wordlist.load()
    remaining_targets = targets

    guess_number = 1
    clue = nothing
    while clue != "\$\$\$\$\$"
        println("Guess $guess_number")
        if isempty(remaining_targets)
            println("I don't get it!")
            return
        else
            @time best_guess_list = best_guesses(guesses, remaining_targets)
            best_guess = first(best_guess_list)
            message = if length(remaining_targets) == 1
                "I know this is the answer!"
            else
                "$(length(remaining_targets)) words remaining"
            end
            println("$best_guess ($message)")
            clue = readline(keep = false)
            while !(length(clue) == 5 && Set(clue) ⊆ Set(CLUE_CHARS))
                println("Invalid clue; must have five characters, all _, ?, or \$")
                clue = readline(keep = false)
            end
            remaining_targets = filter(
                word -> fitsclue_text(best_guess, word, clue),
                remaining_targets,
            )
            guess_number += 1
        end
    end
    
    println("Yay!")
end

function best_guesses(
    guesses::Vector{<:AbstractString},
    targets::Vector{<:AbstractString},
)::Vector{AbstractString}
    scores = Dict(guess => meanturns(guess, targets) for guess in guesses)
    sort(guesses, by = guess -> scores[guess])
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
