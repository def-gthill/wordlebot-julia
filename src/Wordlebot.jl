module Wordlebot

include("Wordlist.jl")

import .Wordlist

export cluefor, cluefor_text

const CLUE_CHARS = "_?\$"

function main()
    guesses, targets = Wordlist.load()
    println(length(guesses))
    println(length(targets))
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
        matching_index = first_or_nothing(unmatched_indices) do j
            char == target[j]
        end
        if matching_index !== nothing
            result[i] = 1
            delete!(unmatched_indices, matching_index)
        end
    end
end

function first_or_nothing(f, c)
    for elem in c
        if f(elem)
            return elem
        end
    end
end

function cluefor_text(guess::AbstractString, target::AbstractString)::String
    clue_chars = map(cluefor(guess, target)) do i
        CLUE_CHARS[i + 1]
    end
    String(clue_chars)
end

main()

end # module
