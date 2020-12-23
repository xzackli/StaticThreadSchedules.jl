using StaticThreadSchedules
import ThreadPools: @qthreads

f(x) = sleep(x^2/1e6)

function default_behavior()
    @threads :static for i in 1:200
        f(i)
    end
end

function this_package()
    @threads :static (i->i^2) for i in 1:200
        f(i)
    end
end

function threadpools()
    @qthreads for i in 1:200
        f(i)
    end
end

##
@time default_behavior()
@time this_package()
@time threadpools()
