struct Gradient{T<:Real}
    x::T
    y::T
    z::T

    function Gradient(x, y, z)

        args = promote(x, y, z)
        T = typeof(args[1])
        new{T}(args...)

    end
end

Base.show(io::IO, grad::Gradient) = print(io, "[", grad.x, ", ", grad.y, ", ", grad.z, "]")
Base.show(io::IO, ::MIME"text/plain", grad::Gradient{T}) where {T} =
    print(io, "Gradient{$T}:\n Gx = ", grad.x, " G/cm\n Gy = ", grad.y, " G/cm\n Gz = ", grad.z, " G/cm")

function gradient_frequency(grad::Gradient, pos::Position)

    return GAMBAR * (grad.x * pos.x + grad.y * pos.y + grad.z * pos.z) # Hz

end

abstract type AbstractSpoiling end

struct GradientSpoiling{T<:Real} <: AbstractSpoiling
    gradient::Gradient{T}
end

GradientSpoiling(x, y, z) = GradientSpoiling(Gradient(x, y, z))

struct RFSpoiling{T<:Real} <: AbstractSpoiling
    Δθ::T
end

struct RFandGradientSpoiling{T1<:Real,T2<:Real} <: AbstractSpoiling
    gradient::GradientSpoiling{T1}
    rf::RFSpoiling{T2}
end

RFandGradientSpoiling(grad::Gradient, rf::RFSpoiling) = RFandGradientSpoiling(GradientSpoiling(grad), rf)
RFandGradientSpoiling(grad::NTuple{3,Real}, rf::RFSpoiling) = RFandGradientSpoiling(GradientSpoiling(grad...), rf)
RFandGradientSpoiling(gx, gy, gz, rf::RFSpoiling) = RFandGradientSpoiling(GradientSpoiling(gx, gy, gz), rf)
RFandGradientSpoiling(grad::Union{<:GradientSpoiling,<:Gradient,<:NTuple{3,Real}}, Δθ) = RFandGradientSpoiling(grad, RFSpoiling(Δθ))
RFandGradientSpoiling(rf::Union{<:RFSpoiling,<:Real}, grad::Union{<:GradientSpoiling,<:Gradient,<:NTuple{3,Real}}) = RFandGradientSpoiling(grad, rf)
RFandGradientSpoiling(rf::RFSpoiling, gx, gy, gz) = RFandGradientSpoiling(gx, gy, gz, rf)

spoiler_gradient(s::GradientSpoiling) = s.gradient
spoiler_gradient(s::RFandGradientSpoiling) = spoiler_gradient(s.gradient)
rfspoiling_increment(s::RFSpoiling) = s.Δθ
rfspoiling_increment(s::RFandGradientSpoiling) = rfspoiling_increment(s.rf)

"""
    spoil(spin)

Simulate ideal spoiling (i.e., setting the transverse component of the spin's
magnetization to 0).

# Arguments
- `spin::AbstractSpin`: Spin to spoil

# Return
- `S::Matrix`: Matrix that describes ideal spoiling

# Examples
```jldoctest
julia> spin = Spin([1, 0.4, 5], 1, 1000, 100, 0)
Spin([1.0, 0.4, 5.0], 1.0, 1000.0, 100.0, 0.0, [0.0, 0.0, 0.0])

julia> S = spoil(spin); S * spin.M
3-element Array{Float64,1}:
 0.0
 0.0
 5.0
```
"""
spoil(spin::Spin) = [0 0 0; 0 0 0; 0 0 1]
spoil(spin::SpinMC) = kron(Diagonal(ones(Bool, spin.N)), [0 0 0; 0 0 0; 0 0 1])

"""
    spoil!(spin)

Apply ideal spoiling to the given spin.
"""
function spoil!(spin::Spin)

    spin.M[1:2] .= 0
    return nothing

end

function spoil!(spin::SpinMC)

    spin.M[1:3:end] .= 0
    spin.M[2:3:end] .= 0
    return nothing

end