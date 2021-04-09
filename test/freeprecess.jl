function freeprecess1()

    t = 100
    spin = Spin(1, 1000, 100, 1.25)
    (A1, B1) = freeprecess(spin, t)
    A2 = FreePrecessionMatrix()
    B2 = Magnetization(0.0, 0.0, 0.0)
    freeprecess!(A2, B2, spin, t)
    return A1 == Matrix(A2) && B1 == Vector(B2)

end

function freeprecess2()

    t = 20
    spin = SpinMC(1, (0.7, 0.2, 0.1), (1000, 400, 1000), (100, 20, 0.01), (0, 15, 0), (100, 100, 25, Inf, Inf, Inf))
    (A1, B1) = freeprecess(spin, t)
    A2 = similar(A1)
    B2 = zero(B1)
    freeprecess!(A2, B2, spin, t)
    return A1 == A2 && B1 == B2

end

function freeprecess3()

    t = 20
    M0 = 1
    (fa, fb) = (0.5, 0.5)
    (T1a, T2a, Δfa) = (1000, 100, 0)
    (T1b, T2b, Δfb) = (400, 20, 15)
    spina = Spin(fa * M0, T1a, T2a, Δfa)
    spinb = Spin(fb * M0, T1b, T2b, Δfb)
    spinmc = SpinMC(M0, (fa, fb), (T1a, T1b), (T2a, T2b), (Δfa, Δfb), (Inf, Inf))
    Aa = FreePrecessionMatrix()
    Ba = Magnetization(0.0, 0.0, 0.0)
    Ab = FreePrecessionMatrix()
    Bb = Magnetization(0.0, 0.0, 0.0)
    Amc = Array{Float64}(undef, 6, 6)
    Bmc = MagnetizationMC(Magnetization(0.0, 0.0, 0.0), Magnetization(0.0, 0.0, 0.0))
    freeprecess!(Aa, Ba, spina, t)
    freeprecess!(Ab, Bb, spinb, t)
    freeprecess!(Amc, Bmc, spinmc, t)
    return Amc ≈ [Matrix(Aa) zeros(3, 3); zeros(3, 3) Matrix(Ab)] && Bmc ≈ MagnetizationMC(Ba, Bb)

end

function freeprecess4()

    t = 100
    grad = Gradient(0, 0, 1)
    spin = Spin(1, 1000, 100, 1.25, Position(0, 0, 1))
    (A1, B1) = freeprecess(spin, t, [grad.x, grad.y, grad.z])
    A2 = FreePrecessionMatrix()
    B2 = Magnetization(0.0, 0.0, 0.0)
    freeprecess!(A2, B2, spin, t, grad)
    return A1 == Matrix(A2) && B1 == Vector(B2)

end

function freeprecess5()

    t = 20
    grad = Gradient(0, 0, 1)
    spin = SpinMC(1, (0.8, 0.2), (1000, 400), (100, 20), (0, 15), (100, 25), Position(0, 0, 1))
    (A1, B1) = freeprecess(spin, t, [grad.x, grad.y, grad.z])
    A2 = similar(A1)
    B2 = zero(B1)
    freeprecess!(A2, B2, spin, t, grad)
    return A1 ≈ A2 && B1 == B2

end

@testset "Free Precession" begin

    @test freeprecess1()
    @test freeprecess2()
    @test freeprecess3()
    @test freeprecess4()
    @test freeprecess5()

end