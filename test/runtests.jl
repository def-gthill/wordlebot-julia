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
