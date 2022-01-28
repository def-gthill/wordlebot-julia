module Wordlist

using FilePathsBase; using FilePathsBase: /
using EzXML

export load

const url = "www.powerlanguage.co.uk/wordle"
const datapath = p"data"
const indexpath = datapath / "index.html"
const scriptpath = datapath / "script.js"
const guesspath = datapath / "guesses.txt"
const targetpath = datapath / "targets.txt"

function load()
    if !exists(guesspath) || !exists(targetpath)
        mkpath(datapath)
        download(url, string(indexpath))
        script = find_script(indexpath)
        download("$url/$script", string(scriptpath))
        guesses, targets = find_words(scriptpath)
        dump_words(guesses, guesspath)
        dump_words(targets, targetpath)
    end
    guesses = load_words(guesspath)
    targets = load_words(targetpath)
    (guesses=guesses, targets=targets)
end

function find_script(path)
    doc = readhtml(string(path))
    findfirst("//script[contains(@src,'main')]", doc)["src"]
end

function find_words(path)
    pattern = r"\"[a-z]{5}\"(,\"[a-z]{5}\")+"
    open(path, "r") do f
        matches = eachmatch(pattern, read(f, String))
        lists = map(m -> split_words(m.match), matches)
        sort!(lists, by=length, rev=true)
        guesses=[lists[1]; lists[2]]
        targets=lists[2]
        (guesses=guesses, targets=targets)
    end
end

function split_words(word_string)
    map(word -> string(strip(word, '"')), split(word_string, ","))
end

function dump_words(words, path)
    open(path, "w") do f
        for word in words
            println(f, word)
        end
    end
end

load_words(path) = sort(collect(eachline(string(path))))

end #module
