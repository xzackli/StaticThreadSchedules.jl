module StaticThreadSchedules

import Base.Threads: threadid, threading_run, nthreads, _threadsfor
export @threads


function _threadsfor(iter, lbody, schedule, cost_model)
    lidx = iter.args[1]         # index
    range = iter.args[2]

    quote
        local threadsfor_fun
        let range = $(esc(range)), cost_model = $(esc(cost_model))

        # compute the normalization of the cost
        per_thread_cost = 0.0
        for i in range
            per_thread_cost += Float64(cost_model(i))
        end
        per_thread_cost /= nthreads()

        let this_cost = per_thread_cost
            function threadsfor_fun(onethread=false)
                r = range # Load into local variable
                model = cost_model

                # divide loop iterations among threads
                if onethread
                    tid = 1
                    f = firstindex(r)
                    l = lastindex(r)
                else
                    tid = threadid()

                    # cumulative cost start and end, for this thread
                    first_cost = (tid - 1) * this_cost
                    last_cost = first_cost + this_cost

                    # compute this thread's iterations
                    f = firstindex(r)
                    cumulative_cost = 0.0
                    for i = r
                        cumulative_cost += Float64(cost_model(i))
                        if cumulative_cost > first_cost
                            f = i
                            break  # stop iterating when we pass the first cost we want
                        end
                    end
                    l = f
                    for i = f:lastindex(r)
                        cumulative_cost += Float64(cost_model(i))
                        if cumulative_cost > last_cost
                            l = i
                            break  # stop iterating when we pass the last cost we want
                        end
                    end
                end

                # run this thread's iterations
                for i = f:l
                    local $(esc(lidx)) = @inbounds r[i]
                    $(esc(lbody))
                end
            end
        end
        end
        if threadid() != 1 || ccall(:jl_in_threaded_region, Cint, ()) != 0
            $(if schedule === :static
              :(error("`@threads :static` can only be used from thread 1 and not nested"))
              else
              # only use threads when called from thread 1, outside @threads
              :(Base.invokelatest(threadsfor_fun, true))
              end)
        else
            threading_run(threadsfor_fun)
        end
        nothing
    end
end

"""
    StaticThreadSchedules.@threads [schedule] [optional scaling] for ... end

A macro to parallelize a `for` loop to run with multiple threads. Splits the iteration
space among multiple tasks and runs those tasks on threads according to a scheduling
policy.
A barrier is placed at the end of the loop which waits for all tasks to finish
execution.

The `schedule` argument can be used to request a particular scheduling policy.
If one specifies `:static` and a cost function, then the work will be split such that the cost
is approximately equal per thread. Specifying `:static` is an error
if used from inside another `@threads` loop or from a thread other than 1.

The default schedule (used when no `schedule` argument is present) is subject to change.

!!! compat "Julia 1.5"
    The `schedule` argument is available as of Julia 1.5.
"""
macro threads(args...)
    na = length(args)
    if na == 3
        sched, cost_model, ex = args
        if sched isa QuoteNode
            sched = sched.value
        elseif sched isa Symbol
            # for now only allow quoted symbols
            sched = nothing
        end
        if sched !== :static
            throw(ArgumentError("unsupported schedule argument in @threads"))
        end
        return _threadsfor(ex.args[1], ex.args[2], sched, cost_model)
    elseif na == 2
        sched, ex = args
        if sched isa QuoteNode
            sched = sched.value
        elseif sched isa Symbol
            # for now only allow quoted symbols
            sched = nothing
        end
        if sched !== :static
            throw(ArgumentError("unsupported schedule argument in @threads"))
        end
    elseif na == 1
        sched = :default
        ex = args[1]
    else
        throw(ArgumentError("wrong number of arguments in @threads"))
    end
    if !(isa(ex, Expr) && ex.head === :for)
        throw(ArgumentError("@threads requires a `for` loop expression"))
    end
    if !(ex.args[1] isa Expr && ex.args[1].head === :(=))
        throw(ArgumentError("nested outer loops are not currently supported by @threads"))
    end
    return _threadsfor(ex.args[1], ex.args[2], sched)
end


end
