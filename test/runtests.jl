using Test
using Wordlebot

@testset "cluefor" begin
    @test cluefor_text("looks", "panic") == "_____"
end
