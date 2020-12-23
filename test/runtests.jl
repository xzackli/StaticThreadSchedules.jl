using StaticThreadSchedules
using Test

@show Threads.nthreads()

@testset "StaticThreadSchedules.jl" begin

    # divisible by common thread counts
    v = zeros(3 * 5 * 128)
    @threads :static (i->log(i+1)) for i in 1:length(v)
        v[i] = Threads.threadid()
    end
    @test all(v .> 0)

    # a prime number
    v = zeros(71)
    @threads :static (i->log(i+1)) for i in 1:length(v)
        v[i] = Threads.threadid()
    end
    @test all(v .> 0)


    # size 1 vector edge case
    v = zeros(1)
    @threads :static (i->log(i+1)) for i in 1:length(v)
        v[i] = Threads.threadid()
    end
    @test all(v .> 0)

    # call Base.@threads if no third arg
    v = zeros(7)
    @threads :static for i in 1:length(v)
        v[i] = Threads.threadid()
    end
    @test all(v .> 0)
    v = zeros(7)
    @threads for i in 1:length(v)
        v[i] = Threads.threadid()
    end
    @test all(v .> 0)


end
