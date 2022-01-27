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
