using StaticThreadSchedules

v = zeros(12)
# suppose this operation scales like log(i)
@threads :static (i->i^2) for i in 1:12
    v[i] = Threads.threadid()
end
print(v)
