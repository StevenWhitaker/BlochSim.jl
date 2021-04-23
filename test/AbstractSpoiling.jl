function GradientSpoiling1()

    GradientSpoiling(0, 1, 0, 1)
    GradientSpoiling(0.0, 1, 0f0, 2//3)
    return true

end

function GradientSpoiling2()

    grad = Gradient(0, 0, 0)
    spoil = GradientSpoiling(grad, 3.0)
    return spoiler_gradient(spoil) === grad

end

function RFSpoiling1()

    RFSpoiling(deg2rad(117))
    return true

end

function RFSpoiling2()

    Δθ = 1
    spoil = RFSpoiling(Δθ)
    return rfspoiling_increment(spoil) == Δθ

end

function RFandGradientSpoiling1()

    RFandGradientSpoiling(GradientSpoiling(0, 0, 0, 3), RFSpoiling(deg2rad(117)))
    RFandGradientSpoiling(Gradient(0, 0, 0), 3, RFSpoiling(deg2rad(117)))
    RFandGradientSpoiling((0, 0, 0), 3, RFSpoiling(deg2rad(117)))
    RFandGradientSpoiling(0, 0, 0, 3, RFSpoiling(deg2rad(117)))
    RFandGradientSpoiling(GradientSpoiling(0, 0, 0, 3), deg2rad(117))
    RFandGradientSpoiling(Gradient(0, 0, 0), 3, deg2rad(117))
    RFandGradientSpoiling((0, 0, 0), 3, deg2rad(117))
    RFandGradientSpoiling(RFSpoiling(deg2rad(117)), GradientSpoiling(0, 0, 0, 3))
    RFandGradientSpoiling(RFSpoiling(deg2rad(117)), Gradient(0, 0, 0), 3)
    RFandGradientSpoiling(RFSpoiling(deg2rad(117)), (0, 0, 0), 3)
    RFandGradientSpoiling(RFSpoiling(deg2rad(117)), 0, 0, 0, 3)
    RFandGradientSpoiling(deg2rad(117), GradientSpoiling(0, 0, 0, 3))
    RFandGradientSpoiling(deg2rad(117), Gradient(0, 0, 0), 3)
    RFandGradientSpoiling(deg2rad(117), (0, 0, 0), 3)
    return true

end

function RFandGradientSpoiling2()

    grad = Gradient(1.0, 2.0, 1//2)
    Δθ = 2f0
    spoil = RFandGradientSpoiling(grad, 1.0, Δθ)
    return spoiler_gradient(spoil) === grad && rfspoiling_increment(spoil) == Δθ

end

@testset "AbstractSpoiling" begin

    @testset "GradientSpoiling" begin

        @test GradientSpoiling1()
        @test GradientSpoiling2()

    end

    @testset "RFSpoiling" begin

        @test RFSpoiling1()
        @test RFSpoiling2()

    end

    @testset "RFandGradientSpoiling" begin

        @test RFandGradientSpoiling1()
        @test RFandGradientSpoiling2()

    end

end
