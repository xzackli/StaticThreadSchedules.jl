using StaticThreadSchedules
import ThreadPools: @qthreads

function f(n)
    s = 0.0
    for i in 1:2n
        for j in 1:2n
            s += Float64(exp(-i*j))
        end
    end
end

function default_behavior()
    @threads :static for i in 1:600
        f(i)
    end
end

function this_package()
    @threads :static (i->i^2) for i in 1:600
        f(i)
    end
end

function threadpools()
    @qthreads for i in 1:600
        f(i)
    end
end

##
using BenchmarkTools
@btime default_behavior()
@btime this_package()
@btime threadpools()
