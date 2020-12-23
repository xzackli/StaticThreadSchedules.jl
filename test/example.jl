using StaticThreadSchedules

v = zeros(12)
# suppose this operation scales like i^2
@threads :static (i->i^2) for i in 1:12
    v[i] = Threads.threadid()
end
print(v)
