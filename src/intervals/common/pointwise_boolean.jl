# This file is part of the IntervalArithmetic.jl package; MIT licensed

#=  This file contains functions not specified in the IEEE Std 1788-2015,
    extending real boolean operations to intervals.

    This is different from what is described in sections 9.5 of the
    IEEE Std 1788-2015 (Boolean functions of intervals), since we deal here
    with what is needed for drop in replacement of Float by intervals,
    and not what is reasonnable to do with intervals in a separate execution
    environment.

    Essentially, julia is better at composability that what the standard
    ever expected from a programming language so we have some extra problems
    to solve.
=#

# TODO Need help for the names x_x
# TODO Fetch the tests from NumberInterval.jl for the ternary politic
# TODO More globally, test the file
# TODO Add a :ternary_with_warning politic for the default?
"""
    PointwisePolitic{P}

Define which politic we use to extend pointwise comparison of 

Valid value for the politic identifier `P` are
    - `:binary_consistent` : A pointwise boolean operation `B` is interpreted
        as `B(X::Interval) = all(B(x) for x in X)`.
        This is self-consistent, but breaks the usual rules for negation.
        For example with this politic, `iszero((-1..3)) == false` and
        `(!iszero)((-1..3)) == false`.
        This *silently* breaks any code relying on such operation conditional
        statements.
    - `:boolean_intervals` : A pointwise boolean operation `B` return the set
        of all outcomes `B(X) = {B(x) | x ∈ X}`.
        This is safe, erroring whenever an invterval is used in a conditional
        statement.
    - `:ternary_logic` (default) : With this politics we use the same logic as for
        `:boolean_intervals`, with the following substitutions to get
        normal `Bool` whenever possible:
            - `{true}` -> `true`
            - `{false}` -> `false`
            - `{true, false}` -> `missing`
        This only causes error in conditional statements when hitting `missing`
        and it is safe.
"""
struct PointwisePolitic{P} end

const BinaryConsistent = PointwisePolitic{:binary_consistent}
const BooleanIntervals = PointwisePolitic{:boolean_intervals}
const TernaryLogic = PointwisePolitic{:ternary_logic}

bool_operations = [
    :(==), :(!=), :<, :(<=), :>, :(>=)
]

## Ternary logic

function ==(::TernaryLogic, x::Interval, y::Interval)
    isthin(x) && isthin(y) && x.lo == y.lo && return true
    return missing
end

function <(::TernaryLogic, x::Interval, y::Interval)
    strictprecedes(x, y) && return true
    precedes(y, x) && return false
    return missing
end

function <=(::TernaryLogic, x::Interval, y::Interval)
    precedes(x, y) && return true
    strictprecedes(y, x) && return false
    return missing
end

# TODO We got a warning in VSCode there
!=(::TernaryLogic, x::Interval, y::Interval) = !==(TernaryLogic, x, y)
>(::TernaryLogic, x::Interval, y::Interval) = !<(TernaryLogic, x, y)
>=(::TernaryLogic, x::Interval, y::Interval) = !<=(TernaryLogic, x, y)


## Boolean Intervals

struct BooleanInterval
    has_true::Bool
    has_false::Bool
end

function BooleanInterval(args...)
    has_true = (true in args)
    has_false = (false in args)
    return BooleanInterval(has_true, has_false)
end

for op in bool_operations
    @eval function $op(::BooleanIntervals, x::Interval, y::Interval)
        ternary_res = $op(TernaryLogic, x, y)
        ismissing(ternary_res) && return BooleanInterval(true, false)
        return BooleanInterval(ternary_res)
    end
end


## Binary consistent

for op in bool_operations
    @eval function $op(::BinaryConsistent, x::Interval, y::Interval)
        ternary_res = $op(TernaryLogic, x, y)
        ismissing(ternary_res) && return false
        return BooleanInterval(ternary_res)
    end
end


## Default behaviors

pointwise_politic() = TernaryLogic()

for op in bool_operations
    @eval $op(x::Interval, y::Interval) = $op(pointwise_politic(), x, y)
end