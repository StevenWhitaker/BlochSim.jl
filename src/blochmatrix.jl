abstract type AbstractBlochMatrix{T<:Real} end

mutable struct BlochMatrix{T<:Real} <: AbstractBlochMatrix{T}
    a11::T
    a21::T
    a31::T
    a12::T
    a22::T
    a32::T
    a13::T
    a23::T
    a33::T
end

BlochMatrix(a...) = BlochMatrix(promote(a...)...)
BlochMatrix{T}() where {T} = BlochMatrix(zero(T), zero(T), zero(T), zero(T),
                                    zero(T), zero(T), zero(T), zero(T), zero(T))
BlochMatrix() = BlochMatrix{Float64}()

Base.eltype(::BlochMatrix{T}) where {T} = T

function Base.fill!(A::BlochMatrix, v)

    A.a11 = v
    A.a21 = v
    A.a31 = v
    A.a12 = v
    A.a22 = v
    A.a32 = v
    A.a13 = v
    A.a23 = v
    A.a33 = v
    return nothing

end

function Base.copyto!(dst::BlochMatrix, src::BlochMatrix)

    dst.a11 = src.a11
    dst.a21 = src.a21
    dst.a31 = src.a31
    dst.a12 = src.a12
    dst.a22 = src.a22
    dst.a32 = src.a32
    dst.a13 = src.a13
    dst.a23 = src.a23
    dst.a33 = src.a33
    return nothing

end

function Base.Matrix(A::BlochMatrix{T}) where {T}

    mat = Matrix{T}(undef, 3, 3)
    mat[1,1] = A.a11
    mat[2,1] = A.a21
    mat[3,1] = A.a31
    mat[1,2] = A.a12
    mat[2,2] = A.a22
    mat[3,2] = A.a32
    mat[1,3] = A.a13
    mat[2,3] = A.a23
    mat[3,3] = A.a33

    return mat

end

mutable struct BlochDynamicsMatrix{T<:Real} <: AbstractBlochMatrix{T}
    R1::T
    R2::T
    Δω::T
end

BlochDynamicsMatrix{T}() where {T} = BlochDynamicsMatrix(zero(T), zero(T), zero(T))
BlochDynamicsMatrix() = BlochDynamicsMatrix{Float64}()
BlochDynamicsMatrix(R1, R2, Δω) = BlochDynamicsMatrix(promote(R1, R2, Δω)...)

Base.convert(::Type{BlochDynamicsMatrix{T}}, A::BlochDynamicsMatrix) where {T} =
    BlochDynamicsMatrix(T(A.R1), T(A.R2), T(A.Δω))
Base.convert(::Type{BlochDynamicsMatrix{T}}, A::BlochDynamicsMatrix{T}) where {T} = A

function Base.Matrix(A::BlochDynamicsMatrix{T}) where {T}

    mat = Matrix{T}(undef, 3, 3)
    mat[1,1] = A.R2
    mat[2,1] = -A.Δω
    mat[3,1] = zero(T)
    mat[1,2] = A.Δω
    mat[2,2] = A.R2
    mat[3,2] = zero(T)
    mat[1,3] = zero(T)
    mat[2,3] = zero(T)
    mat[3,3] = A.R1

    return mat

end

mutable struct FreePrecessionMatrix{T<:Real} <: AbstractBlochMatrix{T}
    E1::T
    E2cosθ::T
    E2sinθ::T
end

FreePrecessionMatrix{T}() where {T} = FreePrecessionMatrix(zero(T), zero(T), zero(T))
FreePrecessionMatrix() = FreePrecessionMatrix{Float64}()
FreePrecessionMatrix(E1, E2cosθ, E2sinθ) = FreePrecessionMatrix(promote(E1, E2cosθ, E2sinθ)...)

function Base.Matrix(A::FreePrecessionMatrix{T}) where {T}

    mat = Matrix{T}(undef, 3, 3)
    mat[1,1] = A.E2cosθ
    mat[2,1] = -A.E2sinθ
    mat[3,1] = zero(T)
    mat[1,2] = A.E2sinθ
    mat[2,2] = A.E2cosθ
    mat[3,2] = zero(T)
    mat[1,3] = zero(T)
    mat[2,3] = zero(T)
    mat[3,3] = A.E1

    return mat

end

mutable struct ExchangeDynamicsMatrix{T<:Real} <: AbstractBlochMatrix{T}
    r::T
end

ExchangeDynamicsMatrix{T}() where {T} = ExchangeDynamicsMatrix(zero(T))
ExchangeDynamicsMatrix() = ExchangeDynamicsMatrix{Float64}()

Base.convert(::Type{ExchangeDynamicsMatrix{T}}, A::ExchangeDynamicsMatrix) where {T} =
    ExchangeDynamicsMatrix(T(A.r))
Base.convert(::Type{ExchangeDynamicsMatrix{T}}, A::ExchangeDynamicsMatrix{T}) where {T} = A

function Base.Matrix(A::ExchangeDynamicsMatrix{T}) where {T}

    mat = Matrix{T}(undef, 3, 3)
    mat[1,1] = A.r
    mat[2,1] = zero(T)
    mat[3,1] = zero(T)
    mat[1,2] = zero(T)
    mat[2,2] = A.r
    mat[3,2] = zero(T)
    mat[1,3] = zero(T)
    mat[2,3] = zero(T)
    mat[3,3] = A.r

    return mat

end

abstract type AbstractBlochMcConnellMatrix{T<:Real,N} end

mutable struct BlochMcConnellDynamicsMatrix{T<:Real,N,M} <: AbstractBlochMcConnellMatrix{T,N}
    A::NTuple{N,BlochDynamicsMatrix{T}}
    E::NTuple{M,ExchangeDynamicsMatrix{T}}

    function BlochMcConnellDynamicsMatrix(
        A::NTuple{N,BlochDynamicsMatrix{T}},
        E::NTuple{M,ExchangeDynamicsMatrix{S}}
    ) where {M,N,S,T}

        M == N * (N - 1) || error("exchange rates must be defined for each pair of compartments")
        Tnew = promote_type(T, S)
        A = convert.(BlochDynamicsMatrix{Tnew}, A)
        E = convert.(ExchangeDynamicsMatrix{Tnew}, E)
        new{Tnew,N,M}(A, E)

    end
end

function BlochMcConnellDynamicsMatrix{T}(N) where {T}

    A = ntuple(i -> BlochDynamicsMatrix{T}(), N)
    E = ntuple(i -> ExchangeDynamicsMatrix{T}(), N * (N - 1))
    BlochMcConnellDynamicsMatrix(A, E)

end

BlochMcConnellDynamicsMatrix(N) = BlochMcConnellDynamicsMatrix{Float64}(N)

# N = 3
#   [2,1]: (1-1)*3-1+2+(2<1) = 0-1+2+0 = 1 ✓
#   [3,1]: (1-1)*3-1+3+(3<1) = 0-1+3+0 = 2 ✓
#   [1,2]: (2-1)*3-2+1+(1<2) = 3-2+1+1 = 3 ✓
#   [3,2]: (2-1)*3-2+3+(3<2) = 3-2+3+0 = 4 ✓
#   [1,3]: (3-1)*3-3+1+(1<3) = 6-3+1+1 = 5 ✓
#   [2,3]: (3-1)*3-3+2+(2<3) = 6-3+2+1 = 6 ✓
function getblock(A::BlochMcConnellDynamicsMatrix{T,N,M}, i, j) where {T,N,M}

    return i == j ? A.A[i] : A.E[(j-1)*N-j+i+(i<j)]

end

function Base.Matrix(A::BlochMcConnellDynamicsMatrix{T,N,M}) where {T,N,M}

    mat = Matrix{T}(undef, 3N, 3N)
    index = 0
    for j = 1:N, i = 1:N

        if i == j

            mat[3i-2,3j-2] = A.A[i].R2
            mat[3i-1,3j-2] = -A.A[i].Δω
            mat[3i  ,3j-2] = zero(T)
            mat[3i-2,3j-1] = A.A[i].Δω
            mat[3i-1,3j-1] = A.A[i].R2
            mat[3i  ,3j-1] = zero(T)
            mat[3i-2,3j]   = zero(T)
            mat[3i-1,3j]   = zero(T)
            mat[3i  ,3j]   = A.A[i].R1

        else

            index += 1
            mat[3i-2,3j-2] = A.E[index].r
            mat[3i-1,3j-2] = zero(T)
            mat[3i  ,3j-2] = zero(T)
            mat[3i-2,3j-1] = zero(T)
            mat[3i-1,3j-1] = A.E[index].r
            mat[3i  ,3j-1] = zero(T)
            mat[3i-2,3j]   = zero(T)
            mat[3i-1,3j]   = zero(T)
            mat[3i  ,3j]   = A.E[index].r

        end

    end

    return mat

end

struct BlochMcConnellMatrix{T<:Real,N} <: AbstractBlochMcConnellMatrix{T,N}
    A::NTuple{N,NTuple{N,BlochMatrix{T}}}
end

function BlochMcConnellMatrix{T}(N) where {T}

    A = ntuple(i -> ntuple(i -> BlochMatrix{T}(), N), N)
    BlochMcConnellMatrix(A)

end

BlochMcConnellMatrix(N) = BlochMcConnellMatrix{Float64}(N)

getblock(A::BlochMcConnellMatrix, i, j) = A.A[i][j]

function Base.fill!(A::BlochMcConnellMatrix{T,N}, v) where {T,N}

    for i = 1:N, j = 1:N
        fill!(getblock(A, i, j), v)
    end

end

function Base.copyto!(dst::BlochMcConnellMatrix{T,N}, src::BlochMcConnellMatrix{S,N}) where {S,T,N}

    for j = 1:N, i = 1:N
        db = getblock(dst, i, j)
        sb = getblock(src, i, j)
        db.a11 = sb.a11
        db.a21 = sb.a21
        db.a31 = sb.a31
        db.a12 = sb.a12
        db.a22 = sb.a22
        db.a32 = sb.a32
        db.a13 = sb.a13
        db.a23 = sb.a23
        db.a33 = sb.a33
    end

end

function Base.copyto!(dst::BlochMcConnellMatrix{T,N}, src::AbstractMatrix) where {T,N}

    for j = 1:N, i = 1:N
        b = getblock(dst, i, j)
        b.a11 = src[3i-2,3j-2]
        b.a21 = src[3i-1,3j-2]
        b.a31 = src[3i  ,3j-2]
        b.a12 = src[3i-2,3j-1]
        b.a22 = src[3i-1,3j-1]
        b.a32 = src[3i  ,3j-1]
        b.a13 = src[3i-2,3j]
        b.a23 = src[3i-1,3j]
        b.a33 = src[3i  ,3j]
    end

end

function Base.Matrix(A::BlochMcConnellMatrix{T,N}) where {T,N}

    mat = Matrix{T}(undef, 3N, 3N)
    for j = 1:N, i = 1:N

        b = getblock(A, i, j)
        mat[3i-2,3j-2] = b.a11
        mat[3i-1,3j-2] = b.a21
        mat[3i  ,3j-2] = b.a31
        mat[3i-2,3j-1] = b.a12
        mat[3i-1,3j-1] = b.a22
        mat[3i  ,3j-1] = b.a32
        mat[3i-2,3j]   = b.a13
        mat[3i-1,3j]   = b.a23
        mat[3i  ,3j]   = b.a33

    end

    return mat

end

struct ExcitationMatrix{T<:Real}
    A::BlochMatrix{T}
end

ExcitationMatrix{T}() where {T} = ExcitationMatrix(BlochMatrix{T}())
ExcitationMatrix() = ExcitationMatrix(BlochMatrix())

struct IdealSpoilingMatrix end
const idealspoiling = IdealSpoilingMatrix()

Base.:+(M1::Magnetization, M2::Magnetization) = Magnetization(M1.x + M2.x, M1.y + M2.y, M1.z + M2.z)
Base.:/(M::Magnetization, a) = Magnetization(M.x / a, M.y / a, M.z / a)

function add!(M1::Magnetization, M2::Magnetization)

    M1.x += M2.x
    M1.y += M2.y
    M1.z += M2.z
    return nothing

end

function add!(M1::Magnetization, M2::AbstractVector)

    M1.x += M2[1]
    M1.y += M2[2]
    M1.z += M2[3]
    return nothing

end

function add!(C::AbstractVector, M1::Magnetization, M2::Magnetization)

    C[1] = M1.x + M2.x
    C[2] = M1.y + M2.y
    C[3] = M1.z + M2.z
    return nothing

end

function add!(M1::MagnetizationMC{T1,N}, M2::MagnetizationMC{T2,N}) where {T1,T2,N}

    for i = 1:N
        add!(M1[i], M2[i])
    end

end

function add!(M1::MagnetizationMC{T,N}, M2::AbstractVector) where {T,N}

    for i = 1:N
        add!(M1[i], view(M2, 3i-2:3i))
    end

end

function add!(C::AbstractVector, M1::MagnetizationMC{T,N}, M2::MagnetizationMC{S,N}) where {S,T,N}

    for i = 1:N
        add!(view(C, 3i-2:3i), M1[i], M2[i])
    end

end

function Base.:*(A::AbstractMatrix, M::Magnetization)

    Mx = A[1,1] * M.x + A[1,2] * M.y + A[1,3] * M.z
    My = A[2,1] * M.x + A[2,2] * M.y + A[2,3] * M.z
    Mz = A[3,1] * M.x + A[3,2] * M.y + A[3,3] * M.z
    return Magnetization(Mx, My, Mz)

end

Base.:*(A::AbstractMatrix, M::MagnetizationMC{T,N}) where {T,N} = MagnetizationMC(ntuple(N) do i
    Mtmp = view(A, 3i-2:3i, 1:3) * M[1]
    for j = 2:N
        add!(Mtmp, view(A, 3i-2:3i, 3j-2:3j) * M[j])
    end
    Mtmp
end...)

function Base.:*(A::BlochMatrix, M::Magnetization)

    return Magnetization(
        A.a11 * M.x + A.a12 * M.y + A.a13 * M.z,
        A.a21 * M.x + A.a22 * M.y + A.a23 * M.z,
        A.a31 * M.x + A.a32 * M.y + A.a33 * M.z
    )

end

Base.:*(A::ExcitationMatrix, M::Magnetization) = A.A * M

Base.:*(::IdealSpoilingMatrix, M::Magnetization{T}) where {T} = Magnetization(zero(T), zero(T), M.z)

function Base.:*(A::BlochMatrix, B::FreePrecessionMatrix)

    return BlochMatrix(
        A.a11 * B.E2cosθ - A.a12 * B.E2sinθ,
        A.a21 * B.E2cosθ - A.a22 * B.E2sinθ,
        A.a31 * B.E2cosθ - A.a32 * B.E2sinθ,
        A.a11 * B.E2sinθ + A.a12 * B.E2cosθ,
        A.a21 * B.E2sinθ + A.a22 * B.E2cosθ,
        A.a31 * B.E2sinθ + A.a32 * B.E2cosθ,
        A.a13 * B.E1,
        A.a23 * B.E1,
        A.a33 * B.E1
    )

end

function Base.:*(A::BlochMatrix, ::IdealSpoilingMatrix)

    T = eltype(A)
    return BlochMatrix(zero(T), zero(T), zero(T), zero(T), zero(T), zero(T), A.a13, A.a23, A.a33)

end

Base.:*(A::ExcitationMatrix, ::IdealSpoilingMatrix) = A.A * idealspoiling

function Base.:-(::UniformScaling, B::BlochMatrix)

    T = eltype(B)
    return BlochMatrix(
        one(T) - B.a11,
        -B.a21,
        -B.a31,
        -B.a12,
        one(T) - B.a22,
        -B.a32,
        -B.a13,
        -B.a23,
        one(T) - B.a33
    )

end

Base.:\(A::BlochMatrix, M::Magnetization) = Magnetization((Matrix(A) \ Vector(M))...)

# M2 = A * M1
function LinearAlgebra.mul!(M2::Magnetization, A::AbstractMatrix, M1::Magnetization)

    M2.x = A[1,1] * M1.x + A[1,2] * M1.y + A[1,3] * M1.z
    M2.y = A[2,1] * M1.x + A[2,2] * M1.y + A[2,3] * M1.z
    M2.z = A[3,1] * M1.x + A[3,2] * M1.y + A[3,3] * M1.z
    return nothing

end

# M2 = A * M1 + M2
function muladd!(M2::Magnetization, A::AbstractMatrix, M1::Magnetization)

    M2.x += A[1,1] * M1.x + A[1,2] * M1.y + A[1,3] * M1.z
    M2.y += A[2,1] * M1.x + A[2,2] * M1.y + A[2,3] * M1.z
    M2.z += A[3,1] * M1.x + A[3,2] * M1.y + A[3,3] * M1.z
    return nothing

end

# M2 = A * M1
function LinearAlgebra.mul!(M2::MagnetizationMC{T,N}, A::AbstractMatrix, M1::MagnetizationMC{S,N}) where {S,T,N}

    for i = 1:N
        M = M2[i]
        mul!(M, view(A, 3i-2:3i, 1:3), M1[1])
        for j = 2:N
            muladd!(M, view(A, 3i-2:3i, 3j-2:3j), M1[j])
        end
    end
    return nothing

end

# M2 = A * M1 + M2
function muladd!(M2::MagnetizationMC{T,N}, A::AbstractMatrix, M1::MagnetizationMC{S,N}) where {S,T,N}

    for i = 1:N
        M = M2[i]
        for j = 1:N
            muladd!(M, view(A, 3i-2:3i, 3j-2:3j), M1[j])
        end
    end
    return nothing

end

function LinearAlgebra.mul!(M2::Magnetization, A::BlochMatrix, M1::Magnetization)

    M2.x = A.a11 * M1.x + A.a12 * M1.y + A.a13 * M1.z
    M2.y = A.a21 * M1.x + A.a22 * M1.y + A.a23 * M1.z
    M2.z = A.a31 * M1.x + A.a32 * M1.y + A.a33 * M1.z
    return nothing

end

function LinearAlgebra.mul!(M2::Magnetization, A::FreePrecessionMatrix, M1::Magnetization)

    M2.x = A.E2cosθ * M1.x + A.E2sinθ * M1.y
    M2.y = A.E2cosθ * M1.y - A.E2sinθ * M1.x
    M2.z = A.E1 * M1.z
    return nothing

end

function LinearAlgebra.mul!(M2::Magnetization, A::ExcitationMatrix, M1::Magnetization)

    mul!(M2, A.A, M1)

end

function LinearAlgebra.mul!(M2::Vector, A::BlochMatrix, M1::Magnetization)

    M2[1] = A.a11 * M1.x + A.a12 * M1.y + A.a13 * M1.z
    M2[2] = A.a21 * M1.x + A.a22 * M1.y + A.a23 * M1.z
    M2[3] = A.a31 * M1.x + A.a32 * M1.y + A.a33 * M1.z
    return nothing

end

function LinearAlgebra.mul!(M2::Vector, A::ExcitationMatrix, M1::Magnetization)

    mul!(M2, A.A, M1)

end

function LinearAlgebra.mul!(M2::MagnetizationMC{T1,N}, A::BlochMcConnellMatrix{T2,N}, M1::MagnetizationMC{T3,N}) where {T1,T2,T3,N}

    for i = 1:N
        M = M2[i]
        mul!(M, getblock(A, i, 1), M1[1])
        for j = 2:N
            muladd!(M, getblock(A, i, j), M1[j])
        end
    end

end

function LinearAlgebra.mul!(M2::MagnetizationMC{T,N}, A::ExcitationMatrix, M1::MagnetizationMC{S,N}) where {S,T,N}

    for i = 1:N
        mul!(M2[i], A, M1[i])
    end

end

function LinearAlgebra.mul!(M::Magnetization{T}, ::IdealSpoilingMatrix) where {T}

    M.x = zero(T)
    M.y = zero(T)
    return nothing

end

function LinearAlgebra.mul!(M::MagnetizationMC{T,N}, ::IdealSpoilingMatrix) where {T,N}

    for i = 1:N
        mul!(M[i], idealspoiling)
    end

end

function LinearAlgebra.mul!(M2::Magnetization{T}, ::IdealSpoilingMatrix, M1::Magnetization) where {T}

    M2.x = zero(T)
    M2.y = zero(T)
    M2.z = M1.z
    return nothing

end

function LinearAlgebra.mul!(M2::MagnetizationMC{T,N}, ::IdealSpoilingMatrix, M1::MagnetizationMC{S,N}) where {S,T,N}

    for i = 1:N
        mul!(M2[i], idealspoiling, M1[i])
    end

end

function muladd!(M2::Magnetization, A::BlochMatrix, M1::Magnetization)

    M2.x += A.a11 * M1.x + A.a12 * M1.y + A.a13 * M1.z
    M2.y += A.a21 * M1.x + A.a22 * M1.y + A.a23 * M1.z
    M2.z += A.a31 * M1.x + A.a32 * M1.y + A.a33 * M1.z
    return nothing

end

function muladd!(M2::Magnetization, A::FreePrecessionMatrix, M1::Magnetization)

    M2.x += A.E2cosθ * M1.x + A.E2sinθ * M1.y
    M2.y += A.E2cosθ * M1.y - A.E2sinθ * M1.x
    M2.z += A.E1 * M1.z
    return nothing

end

function muladd!(M2::MagnetizationMC{T1,N}, A::BlochMcConnellMatrix{T2,N}, M1::MagnetizationMC{T3,N}) where {T1,T2,T3,N}

    for i = 1:N
        M = M2[i]
        for j = 1:N
            muladd!(M, getblock(A, i, j), M1[j])
        end
    end

end

# A = A * t
function LinearAlgebra.mul!(A::BlochDynamicsMatrix, t::Real)

    A.R1 *= t
    A.R2 *= t
    A.Δω *= t
    return nothing

end

function LinearAlgebra.mul!(E::ExchangeDynamicsMatrix, t::Real)

    E.r *= t
    return nothing

end

function LinearAlgebra.mul!(A::BlochMcConnellDynamicsMatrix, t::Real)

    for A in A.A
        mul!(A, t)
    end
    for E in A.E
        mul!(E, t)
    end

end

# C = A * t
function LinearAlgebra.mul!(C::BlochMatrix, A::BlochMatrix, t::Real)

    C.a11 = A.a11 * t
    C.a21 = A.a21 * t
    C.a31 = A.a31 * t
    C.a12 = A.a12 * t
    C.a22 = A.a22 * t
    C.a32 = A.a32 * t
    C.a13 = A.a13 * t
    C.a23 = A.a23 * t
    C.a33 = A.a33 * t
    return nothing

end

function LinearAlgebra.mul!(C::BlochMcConnellMatrix{T,N}, A::BlochMcConnellMatrix{S,N}, t::Real) where {S,T,N}

    for i = 1:N, j = 1:N
        mul!(getblock(C, i, j), getblock(A, i, j), t)
    end

end

# C = A * t + C
function muladd!(C::BlochMatrix, A::BlochMatrix, t::Real)

    C.a11 += A.a11 * t
    C.a21 += A.a21 * t
    C.a31 += A.a31 * t
    C.a12 += A.a12 * t
    C.a22 += A.a22 * t
    C.a32 += A.a32 * t
    C.a13 += A.a13 * t
    C.a23 += A.a23 * t
    C.a33 += A.a33 * t
    return nothing

end

function muladd!(C::BlochMcConnellMatrix{T,N}, A::BlochMcConnellMatrix{S,N}, t::Real) where {S,T,N}

    for i = 1:N, j = 1:N
        muladd!(getblock(C, i, j), getblock(A, i, j), t)
    end

end

# C = I * t + C
function muladd!(C::BlochMatrix, ::UniformScaling, t::Real)

    C.a11 += t
    C.a22 += t
    C.a33 += t
    return nothing

end

function muladd!(C::BlochMcConnellMatrix{T,N}, I::UniformScaling, t::Real) where {T,N}

    for i = 1:N
        muladd!(getblock(C, i, i), I, t)
    end

end

# C = A * B
function LinearAlgebra.mul!(C::BlochMatrix, A::BlochMatrix, B::BlochMatrix)

    C.a11 = A.a11 * B.a11 + A.a12 * B.a21 + A.a13 * B.a31
    C.a21 = A.a21 * B.a11 + A.a22 * B.a21 + A.a23 * B.a31
    C.a31 = A.a31 * B.a11 + A.a32 * B.a21 + A.a33 * B.a31
    C.a12 = A.a11 * B.a12 + A.a12 * B.a22 + A.a13 * B.a32
    C.a22 = A.a21 * B.a12 + A.a22 * B.a22 + A.a23 * B.a32
    C.a32 = A.a31 * B.a12 + A.a32 * B.a22 + A.a33 * B.a32
    C.a13 = A.a11 * B.a13 + A.a12 * B.a23 + A.a13 * B.a33
    C.a23 = A.a21 * B.a13 + A.a22 * B.a23 + A.a23 * B.a33
    C.a33 = A.a31 * B.a13 + A.a32 * B.a23 + A.a33 * B.a33
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix, A::BlochDynamicsMatrix, B::BlochMatrix)

    C.a11 = A.R2 * B.a11 + A.Δω * B.a21
    C.a21 = A.R2 * B.a21 - A.Δω * B.a11
    C.a31 = A.R1 * B.a31
    C.a12 = A.R2 * B.a12 + A.Δω * B.a22
    C.a22 = A.R2 * B.a22 - A.Δω * B.a12
    C.a32 = A.R1 * B.a32
    C.a13 = A.R2 * B.a13 + A.Δω * B.a23
    C.a23 = A.R2 * B.a23 - A.Δω * B.a13
    C.a33 = A.R1 * B.a33
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix, A::ExchangeDynamicsMatrix, B::BlochMatrix)

    C.a11 = A.r * B.a11
    C.a21 = A.r * B.a21
    C.a31 = A.r * B.a31
    C.a12 = A.r * B.a12
    C.a22 = A.r * B.a22
    C.a32 = A.r * B.a32
    C.a13 = A.r * B.a13
    C.a23 = A.r * B.a23
    C.a33 = A.r * B.a33
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix{T}, A::BlochDynamicsMatrix, B::BlochDynamicsMatrix) where {T}

    C.a11 = A.R2 * B.R2 - A.Δω * B.Δω
    C.a21 = -A.Δω * B.R2 - A.R2 * B.Δω
    C.a31 = zero(T)
    C.a12 = -C.a21
    C.a22 = C.a11
    C.a32 = zero(T)
    C.a13 = zero(T)
    C.a23 = zero(T)
    C.a33 = A.R1 * B.R1
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix{T}, A::ExchangeDynamicsMatrix, B::ExchangeDynamicsMatrix) where {T}

    C.a11 = A.r * B.r
    C.a21 = zero(T)
    C.a31 = zero(T)
    C.a12 = zero(T)
    C.a22 = A.r * B.r
    C.a32 = zero(T)
    C.a13 = zero(T)
    C.a23 = zero(T)
    C.a33 = A.r * B.r
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix{T}, A::BlochDynamicsMatrix, B::ExchangeDynamicsMatrix) where {T}

    C.a11 = A.R2 * B.r
    C.a21 = -A.Δω * B.r
    C.a31 = zero(T)
    C.a12 = A.Δω * B.r
    C.a22 = A.R2 * B.r
    C.a32 = zero(T)
    C.a13 = zero(T)
    C.a23 = zero(T)
    C.a33 = A.R1 * B.r
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix, A::ExchangeDynamicsMatrix, B::BlochDynamicsMatrix)

    mul!(C, B, A)

end

function LinearAlgebra.mul!(C::BlochMatrix, A::ExcitationMatrix, B::BlochMatrix)

    mul!(C, A.A, B)

end

function LinearAlgebra.mul!(C::BlochMatrix, A::ExcitationMatrix, B::FreePrecessionMatrix)

    mul!(C, A.A, B)

end

function LinearAlgebra.mul!(C::BlochMatrix, A::BlochMatrix, B::FreePrecessionMatrix)

    C.a11 = A.a11 * B.E2cosθ - A.a12 * B.E2sinθ
    C.a21 = A.a21 * B.E2cosθ - A.a22 * B.E2sinθ
    C.a31 = A.a31 * B.E2cosθ - A.a32 * B.E2sinθ
    C.a12 = A.a11 * B.E2sinθ + A.a12 * B.E2cosθ
    C.a22 = A.a21 * B.E2sinθ + A.a22 * B.E2cosθ
    C.a32 = A.a31 * B.E2sinθ + A.a32 * B.E2cosθ
    C.a13 = A.a13 * B.E1
    C.a23 = A.a23 * B.E1
    C.a33 = A.a33 * B.E1
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix, A::FreePrecessionMatrix, B::BlochMatrix)

    C.a11 = A.E2cosθ * B.a11 + A.E2sinθ * B.a21
    C.a21 = A.E2cosθ * B.a21 - A.E2sinθ * B.a11
    C.a31 = A.E1 * B.a31
    C.a12 = A.E2cosθ * B.a12 + A.E2sinθ * B.a22
    C.a22 = A.E2cosθ * B.a22 - A.E2sinθ * B.a12
    C.a32 = A.E1 * B.a32
    C.a13 = A.E2cosθ * B.a13 + A.E2sinθ * B.a23
    C.a23 = A.E2cosθ * B.a23 - A.E2sinθ * B.a13
    C.a33 = A.E1 * B.a33
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix{T}, A::FreePrecessionMatrix, B::FreePrecessionMatrix) where {T}

    C.a11 = A.E2cosθ * B.E2cosθ - A.E2sinθ * B.E2sinθ
    C.a12 = A.E2cosθ * B.E2sinθ + A.E2sinθ * B.E2cosθ
    C.a13 = zero(T)
    C.a21 = -C.a12
    C.a22 = C.a11
    C.a23 = zero(T)
    C.a31 = zero(T)
    C.a32 = zero(T)
    C.a33 = A.E1 * B.E1
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix{T}, ::IdealSpoilingMatrix, B::BlochMatrix) where {T}

    C.a11 = zero(T)
    C.a21 = zero(T)
    C.a31 = B.a31
    C.a12 = zero(T)
    C.a22 = zero(T)
    C.a32 = B.a32
    C.a13 = zero(T)
    C.a23 = zero(T)
    C.a33 = B.a33
    return nothing

end

function LinearAlgebra.mul!(C::BlochMatrix{T}, ::IdealSpoilingMatrix, B::FreePrecessionMatrix) where {T}

    C.a11 = zero(T)
    C.a21 = zero(T)
    C.a31 = zero(T)
    C.a12 = zero(T)
    C.a22 = zero(T)
    C.a32 = zero(T)
    C.a13 = zero(T)
    C.a23 = zero(T)
    C.a33 = B.E1
    return nothing

end

function LinearAlgebra.mul!(
    C::BlochMcConnellMatrix{T1,N},
    A::ExcitationMatrix,
    B::BlochMcConnellMatrix{T2,N}
) where {T1,T2,N}

    for j = 1:N, i = 1:N
        mul!(getblock(C, i, j), A.A, getblock(B, i, j))
    end

end

function LinearAlgebra.mul!(
    C::BlochMcConnellMatrix{T1,N},
    ::IdealSpoilingMatrix,
    B::BlochMcConnellMatrix{T2,N}
) where {T1,T2,N}

    for j = 1:N, i = 1:N
        mul!(getblock(C, i, j), idealspoiling, getblock(B, i, j))
    end

end

function LinearAlgebra.mul!(
    C::AbstractBlochMcConnellMatrix{T1,N},
    A::AbstractBlochMcConnellMatrix{T2,N},
    B::AbstractBlochMcConnellMatrix{T3,N}
) where {T1,T2,T3,N}

    for j = 1:N, i = 1:N
        mul!(getblock(C, i, j), getblock(A, i, 1), getblock(B, 1, j))
        for k = 2:N
            muladd!(getblock(C, i, j), getblock(A, i, k), getblock(B, k, j))
        end
    end

end

# C = A * B + C
function muladd!(C::BlochMatrix, A::BlochMatrix, B::BlochMatrix)

    C.a11 += A.a11 * B.a11 + A.a12 * B.a21 + A.a13 * B.a31
    C.a21 += A.a21 * B.a11 + A.a22 * B.a21 + A.a23 * B.a31
    C.a31 += A.a31 * B.a11 + A.a32 * B.a21 + A.a33 * B.a31
    C.a12 += A.a11 * B.a12 + A.a12 * B.a22 + A.a13 * B.a32
    C.a22 += A.a21 * B.a12 + A.a22 * B.a22 + A.a23 * B.a32
    C.a32 += A.a31 * B.a12 + A.a32 * B.a22 + A.a33 * B.a32
    C.a13 += A.a11 * B.a13 + A.a12 * B.a23 + A.a13 * B.a33
    C.a23 += A.a21 * B.a13 + A.a22 * B.a23 + A.a23 * B.a33
    C.a33 += A.a31 * B.a13 + A.a32 * B.a23 + A.a33 * B.a33
    return nothing

end

function muladd!(C::BlochMatrix, A::BlochDynamicsMatrix, B::BlochMatrix)

    C.a11 += A.R2 * B.a11 + A.Δω * B.a21
    C.a21 += A.R2 * B.a21 - A.Δω * B.a11
    C.a31 += A.R1 * B.a31
    C.a12 += A.R2 * B.a12 + A.Δω * B.a22
    C.a22 += A.R2 * B.a22 - A.Δω * B.a12
    C.a32 += A.R1 * B.a32
    C.a13 += A.R2 * B.a13 + A.Δω * B.a23
    C.a23 += A.R2 * B.a23 - A.Δω * B.a13
    C.a33 += A.R1 * B.a33
    return nothing

end

function muladd!(C::BlochMatrix, A::ExchangeDynamicsMatrix, B::BlochMatrix)

    C.a11 += A.r * B.a11
    C.a21 += A.r * B.a21
    C.a31 += A.r * B.a31
    C.a12 += A.r * B.a12
    C.a22 += A.r * B.a22
    C.a32 += A.r * B.a32
    C.a13 += A.r * B.a13
    C.a23 += A.r * B.a23
    C.a33 += A.r * B.a33
    return nothing

end

function muladd!(C::BlochMatrix, A::BlochDynamicsMatrix, B::BlochDynamicsMatrix)

    C.a11 += A.R2 * B.R2 - A.Δω * B.Δω
    C.a21 -= A.Δω * B.R2 + A.R2 * B.Δω
    C.a12 += A.R2 * B.Δω + A.Δω * B.R2
    C.a22 += A.R2 * B.R2 - A.Δω * B.Δω
    C.a33 += A.R1 * B.R1
    return nothing

end

function muladd!(C::BlochMatrix, A::ExchangeDynamicsMatrix, B::ExchangeDynamicsMatrix)

    C.a11 += A.r * B.r
    C.a22 += A.r * B.r
    C.a33 += A.r * B.r
    return nothing

end

function muladd!(C::BlochMatrix, A::BlochDynamicsMatrix, B::ExchangeDynamicsMatrix)

    C.a11 += A.R2 * B.r
    C.a21 -= A.Δω * B.r
    C.a12 += A.Δω * B.r
    C.a22 += A.R2 * B.r
    C.a33 += A.R1 * B.r
    return nothing

end

function muladd!(C::BlochMatrix, A::ExchangeDynamicsMatrix, B::BlochDynamicsMatrix)

    muladd!(C, B, A)

end

# C = A - B
function subtract!(C::AbstractMatrix{T}, ::UniformScaling, B::BlochMatrix) where {T}

    C[1,1] = one(T) - B.a11
    C[2,1] = -B.a21
    C[3,1] = -B.a31
    C[1,2] = -B.a12
    C[2,2] = one(T) - B.a22
    C[3,2] = -B.a32
    C[1,3] = -B.a13
    C[2,3] = -B.a23
    C[3,3] = one(T) - B.a33
    return nothing

end

function subtract!(C::AbstractMatrix, A::BlochMcConnellMatrix{T,N}, B::BlochMcConnellMatrix{S,N}) where {S,T,N}

    for j = 1:N, i = 1:N
        Ab = getblock(A, i, j)
        Bb = getblock(B, i, j)
        C[3i-2,3j-2] = Ab.a11 - Bb.a11
        C[3i-1,3j-2] = Ab.a21 - Bb.a21
        C[3i  ,3j-2] = Ab.a31 - Bb.a31
        C[3i-2,3j-1] = Ab.a12 - Bb.a12
        C[3i-1,3j-1] = Ab.a22 - Bb.a22
        C[3i  ,3j-1] = Ab.a32 - Bb.a32
        C[3i-2,3j]   = Ab.a13 - Bb.a13
        C[3i-1,3j]   = Ab.a23 - Bb.a23
        C[3i  ,3j]   = Ab.a33 - Bb.a33
    end

end

function subtract!(C::AbstractMatrix{T}, A::UniformScaling, B::BlochMcConnellMatrix{S,N}) where {S,T,N}

    for j = 1:N, i = 1:N
        b = getblock(B, i, j)
        if i == j
            C[3i-2,3j-2] = one(T) - b.a11
            C[3i-1,3j-2] = -b.a21
            C[3i  ,3j-2] = -b.a31
            C[3i-2,3j-1] = -b.a12
            C[3i-1,3j-1] = one(T) - b.a22
            C[3i  ,3j-1] = -b.a32
            C[3i-2,3j]   = -b.a13
            C[3i-1,3j]   = -b.a23
            C[3i  ,3j]   = one(T) - b.a33
        else
            C[3i-2,3j-2] = -b.a11
            C[3i-1,3j-2] = -b.a21
            C[3i  ,3j-2] = -b.a31
            C[3i-2,3j-1] = -b.a12
            C[3i-1,3j-1] = -b.a22
            C[3i  ,3j-1] = -b.a32
            C[3i-2,3j]   = -b.a13
            C[3i-1,3j]   = -b.a23
            C[3i  ,3j]   = -b.a33
        end
    end

end

# C = A + B
function add!(C::AbstractMatrix, A::BlochMcConnellMatrix{T,N}, B::BlochMcConnellMatrix{S,N}) where {S,T,N}

    for j = 1:N, i = 1:N
        Ab = getblock(A, i, j)
        Bb = getblock(B, i, j)
        C[3i-2,3j-2] = Ab.a11 + Bb.a11
        C[3i-1,3j-2] = Ab.a21 + Bb.a21
        C[3i  ,3j-2] = Ab.a31 + Bb.a31
        C[3i-2,3j-1] = Ab.a12 + Bb.a12
        C[3i-1,3j-1] = Ab.a22 + Bb.a22
        C[3i  ,3j-1] = Ab.a32 + Bb.a32
        C[3i-2,3j]   = Ab.a13 + Bb.a13
        C[3i-1,3j]   = Ab.a23 + Bb.a23
        C[3i  ,3j]   = Ab.a33 + Bb.a33
    end

end

# M2 = -A * M1
function subtractmul!(
    M2::Magnetization,
    ::Nothing,
    A::BlochMatrix,
    M1::Magnetization
)

    M2.x = -A.a11 * M1.x - A.a12 * M1.y - A.a13 * M1.z
    M2.y = -A.a21 * M1.x - A.a22 * M1.y - A.a23 * M1.z
    M2.z = -A.a31 * M1.x - A.a32 * M1.y - A.a33 * M1.z
    return nothing

end

# M2 = (I - A) * M1
function subtractmul!(
    M2::Magnetization,
    ::UniformScaling,
    A::BlochMatrix,
    M1::Magnetization
)

    M2.x =  (1 - A.a11) * M1.x - A.a12 * M1.y - A.a13 * M1.z
    M2.y = -A.a21 * M1.x + (1 - A.a22) * M1.y - A.a23 * M1.z
    M2.z = -A.a31 * M1.x - A.a32 * M1.y + (1 - A.a33) * M1.z
    return nothing

end

function subtractmul!(
    M2::MagnetizationMC{T1,N},
    I::UniformScaling,
    A::BlochMcConnellMatrix{T2,N},
    M1::MagnetizationMC{T3,N}
) where {T1,T2,T3,N}

    for i = 1:N
        M = M2[i]
        if i == 1
            subtractmul!(M, I, getblock(A, i, 1), M1[1])
        else
            subtractmul!(M, nothing, getblock(A, i, 1), M1[1])
        end
        for j = 2:N
            if j == i
                subtractmuladd!(M, I, getblock(A, i, j), M1[j])
            else
                subtractmuladd!(M, nothing, getblock(A, i, j), M1[j])
            end
        end
    end

end

# M2 = -A * M1 + M2
function subtractmuladd!(
    M2::Magnetization,
    ::Nothing,
    A::BlochMatrix,
    M1::Magnetization
)

    M2.x -= A.a11 * M1.x + A.a12 * M1.y + A.a13 * M1.z
    M2.y -= A.a21 * M1.x + A.a22 * M1.y + A.a23 * M1.z
    M2.z -= A.a31 * M1.x + A.a32 * M1.y + A.a33 * M1.z
    return nothing

end

# M2 = (I - A) * M1 + M2
function subtractmuladd!(
    M2::Magnetization,
    ::UniformScaling,
    A::BlochMatrix,
    M1::Magnetization
)

    M2.x +=  (1 - A.a11) * M1.x - A.a12 * M1.y - A.a13 * M1.z
    M2.y += -A.a21 * M1.x + (1 - A.a22) * M1.y - A.a23 * M1.z
    M2.z += -A.a31 * M1.x - A.a32 * M1.y + (1 - A.a33) * M1.z
    return nothing

end

# Vector 1-norm
function absolutesum(A::BlochDynamicsMatrix)

    return 2 * abs(A.R2) + 2 * abs(A.Δω) + abs(A.R1)

end

function absolutesum(E::ExchangeDynamicsMatrix)

    return 3 * abs(E.r)

end

function absolutesum(A::BlochMcConnellDynamicsMatrix{T,N,M}) where {T,N,M}

    result = absolutesum(A.A[1])
    for i = 2:N
        result += absolutesum(A.A[i])
    end
    for E in A.E
        result += absolutesum(E)
    end
    return result

end
