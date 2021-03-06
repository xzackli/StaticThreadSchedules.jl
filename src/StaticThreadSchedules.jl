module StaticThreadSchedules

import Base.Threads: threadid, threading_run, nthreads, _threadsfor
export @threads


function _threadsfor(iter, lbody, schedule, cost_model)
    lidx = iter.args[1]         # index
    range = iter.args[2]

    quote
        local threadsfor_fun
        # compute the normalization of the cost
        per_thread_cost = 0.0
        for i in $(esc(range))
            per_thread_cost += Float64($(esc(cost_model))(i))
        end
        per_thread_cost = per_thread_cost / nthreads() + 10eps()
        # @show per_thread_cost
        chunk_indices = zeros(Int, nthreads()+1)
        current_chunk = 1
        chunk_indices[1] = 1
        accumulated_cost = 0.0
        for i in $(esc(range))
            # @show i, accumulated_cost
            accumulated_cost += Float64($(esc(cost_model))(i))
            if accumulated_cost > per_thread_cost
                accumulated_cost -= per_thread_cost
                current_chunk += 1
                chunk_indices[current_chunk] = i
            end
        end
        chunk_indices[end] = lastindex($(esc(range))) + 1
        # @show chunk_indices

        let range = $(esc(range)), chunks_ = chunk_indices
            function threadsfor_fun(onethread=false)
                r = range # Load into local variable
                chunks = chunks_
                tid = threadid()

                f = chunks[tid]
                l = chunks[tid+1]-1

                # run this thread's iterations
                for i = f:l
                    local $(esc(lidx)) = @inbounds r[i]
                    $(esc(lbody))
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
