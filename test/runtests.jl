using Test
using Wordlebot

@testset "cluefor" begin
    @test cluefor_text("looks", "panic") == "_____"

    @test cluefor_text("tries", "panic") == "__?__"
    @test cluefor_text("scrap", "craps") == "?????"

    @test cluefor_text("remit", "panic") == "___\$_"
    @test cluefor_text("trips", "tries") == "\$\$\$_\$"

    @test cluefor_text("strip", "panic") == "___\$?"
    @test cluefor_text("canid", "panic") == "?\$\$\$_"

    @test cluefor_text("petty", "tangy") == "__?_\$"
    @test cluefor_text("petty", "tenet") == "_\$??_"

    @test cluefor_text("petty", "litre") == "_?\$__"
    @test cluefor_text("litre", "petty") == "__\$_?"

    @test cluefor_text("petty", "total") == "__\$?_"
    @test cluefor_text("total", "petty") == "?_\$__"
    @test cluefor_text("petty", "taste") == "_??\$_"
    @test cluefor_text("taste", "petty") == "?__\$?"

    @test cluefor("looks", "panic") == zeros(Int8, 5)
    @test cluefor("scrap", "craps") == ones(Int8, 5)
end

const example_targets = ["tiles", "times", "panic"]
const info_21 = (2 * log(3 / 2) + log(3)) / 3

@testset "meaninfo" begin
    @test meaninfo("tires", example_targets) == info_21
    @test meaninfo("looks", example_targets) == log(3)
    @test meaninfo("panic", example_targets) == log(3 / 2)
    @test meaninfo("tiles", example_targets) == log(3)
end

@testset "meanturns" begin
    @test meanturns("panic", ["panic"]) == 0
    @test meanturns("looks", ["panic"]) == 1
    @test meanturns("tiles", example_targets) == 2 / 3
    @test meanturns("looks", example_targets) == 1
    @test meanturns("panic", example_targets, 3.0) == 2 / 3 * (1 + log(2) / 3)
    @test meanturns("tires", example_targets, 3.0) == 1 + (log(3) - info_21) / 3
end

@testset "meanturns_better" begin
    @test meanturns_better("panic", ["panic"]) == 0
    @test meanturns_better("looks", ["panic"]) == 1
    @test meanturns_better("tiles", example_targets) == 2 / 3
    @test meanturns_better("looks", example_targets) == 1
    @test meanturns_better("panic", example_targets) == (2 / 3) * (3 / 2)
    @test meanturns_better("tires", example_targets) == (2 / 3) * (3 / 2) + 1 / 3
end

const dummy_words = [
    "tangy",
    "solar",
    "proxy",
]

mutable struct DummyPlayer <: Player
    index::Int8
end

DummyPlayer() = DummyPlayer(1)

function Wordlebot.guess!(player::DummyPlayer, clue::Union{String, Nothing})::AbstractString
    cur_index = player.index
    player.index += 1
    get(dummy_words, cur_index, "")
end

@testset "play!" begin
    @test play!(DummyPlayer(), "tangy") == [Turn("tangy", "\$\$\$\$\$")]
    @test play!(DummyPlayer(), "proxy") == [
        Turn("tangy", "____\$"),
        Turn("solar", "_?__?"),
        Turn("proxy", "\$\$\$\$\$"),
    ]
    @test play!(DummyPlayer(), "perky") == [
        Turn("tangy", "____\$"),
        Turn("solar", "____?"),
        Turn("proxy", "\$?__\$"),
        Turn("", ""),
    ]
end
