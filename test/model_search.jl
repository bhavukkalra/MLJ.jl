module TestModelSearch

# using Revise
using Test
using MLJ

pca = info("PCA", pkg="MultivariateStats")
cnst = info("ConstantRegressor", pkg="MLJ")

@test_throws ArgumentError MLJ.info("Julia")

@test info(ConstantRegressor) == cnst
@test info(Standardizer()) == info("Standardizer", pkg="MLJ")

@testset "localmodels" begin
    tree = info("DecisionTreeRegressor")
    @test cnst in localmodels(modl=TestModelSearch)
    @test !(tree in localmodels(modl=TestModelSearch))
    import MLJModels
    import DecisionTree
    import MLJModels.DecisionTree_.DecisionTreeRegressor
    @test tree in localmodels(modl=TestModelSearch)
end

@testset "models() and localmodels" begin
    t(model) = model.is_pure_julia
    mods = models(t)
    @test pca in mods
    @test cnst in mods
    @test !(info("SVC") in mods)
    mods = localmodels(t, modl=TestModelSearch)
    @test cnst in mods
    @test !(pca in mods)
    u(model) = !(model.is_supervised)
    @test pca in models(u, t)
    @test !(cnst in models(u, t))
end

end
true
