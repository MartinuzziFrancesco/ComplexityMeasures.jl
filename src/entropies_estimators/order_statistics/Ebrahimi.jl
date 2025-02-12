export Ebrahimi

"""
    Ebrahimi <: DiffEntropyEst
    Ebrahimi(; m::Int = 1, base = 2)

The `Ebrahimi` estimator computes the [`Shannon`](@ref) [`entropy`](@ref) (in the given
`base`) of a timeseries using the method from Ebrahimi (1994)[^Ebrahimi1994].

The `Ebrahimi` estimator belongs to a class of differential entropy estimators based
on [order statistics](https://en.wikipedia.org/wiki/Order_statistic). It only works for
*timeseries* input.

## Description

Assume we have samples ``\\bar{X} = \\{x_1, x_2, \\ldots, x_N \\}`` from a
continuous random variable ``X \\in \\mathbb{R}`` with support ``\\mathcal{X}`` and
density function``f : \\mathbb{R} \\to \\mathbb{R}``. `Ebrahimi` estimates the
[Shannon](@ref) differential entropy

```math
H(X) = \\int_{\\mathcal{X}} f(x) \\log f(x) dx = \\mathbb{E}[-\\log(f(X))].
```

However, instead of estimating the above integral directly, it makes use of the equivalent
integral, where ``F`` is the distribution function for ``X``,

```math
H(X) = \\int_0^1 \\log \\left(\\dfrac{d}{dp}F^{-1}(p) \\right) dp
```

This integral is approximated by first computing the
[order statistics](https://en.wikipedia.org/wiki/Order_statistic) of ``\\bar{X}``
(the input timeseries), i.e. ``x_{(1)} \\leq x_{(2)} \\leq \\cdots \\leq x_{(n)}``.
The `Ebrahimi` [`Shannon`](@ref) differential entropy estimate is then

```math
\\hat{H}_{E}(\\bar{X}, m) =
\\dfrac{1}{n} \\sum_{i = 1}^n \\log
\\left[ \\dfrac{n}{c_i m} (\\bar{X}_{(i+m)} - \\bar{X}_{(i-m)}) \\right],
```

where

```math
c_i =
\\begin{cases}
    1 + \\frac{i - 1}{m}, & 1 \\geq i \\geq m \\\\
    2,                    & m + 1 \\geq i \\geq n - m \\\\
    1 + \\frac{n - i}{m} & n - m + 1 \\geq i \\geq n
\\end{cases}.
```

[^Ebrahimi1994]:
    Ebrahimi, N., Pflughoeft, K., & Soofi, E. S. (1994). Two measures of sample entropy.
    Statistics & Probability Letters, 20(3), 225-234.

See also: [`entropy`](@ref), [`Correa`](@ref), [`AlizadehArghami`](@ref),
[`Vasicek`](@ref), [`DifferentialEntropyEstimator`](@ref).
"""
@Base.kwdef struct Ebrahimi{I<:Integer, B} <: DiffEntropyEst
    m::I = 1
    base::B = 2
end

function ebrahimi_scaling_factor(i, m, n)
    if 1 ≤ i ≤ m
        return 1 + (i - 1) / m
    elseif m + 1 ≤ i ≤ n - m
        return 2
    else n - m + 1 ≤ i ≤ n
        return 1 + (n - i) / m
    end
end

function entropy(est::Ebrahimi, x::AbstractVector{<:Real})
    (; m) = est
    n = length(x)
    m < floor(Int, n / 2) || throw(ArgumentError("Need m < length(x)/2."))

    ex = sort(x)
    HVₘₙ = 0.0
    for i = 1:n
        cᵢ = ebrahimi_scaling_factor(i, m, n)
        f = n / (cᵢ * m)
        dnext = ith_order_statistic(ex, i + m, n)
        dprev = ith_order_statistic(ex, i - m, n)
        HVₘₙ += log(f * (dnext - dprev))
    end

    # The estimated entropy has "unit" [nats]
    h = HVₘₙ / n
    return convert_logunit(h, ℯ, est.base)
end
