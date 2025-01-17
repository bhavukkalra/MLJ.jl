```@meta
EditURL = "<unknown>/../../../../MLJ/examples/lightning_tour/lightning_tour.jl"
```

# Lightning tour of MLJ

*For a more elementary introduction to MLJ, see [Getting
Started](https://alan-turing-institute.github.io/MLJ.jl/dev/getting_started/).*

**Note.** Be sure this file has not been separated from the
accompanying Project.toml and Manifest.toml files, which should not
should be altered unless you know what you are doing. Using them,
the following code block instantiates a julia environment with a tested
bundle of packages known to work with the rest of the script:

````@example lightning_tour
using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
````

Assuming Julia 1.7

In MLJ a *model* is just a container for hyper-parameters, and that's
all. Here we will apply several kinds of model composition before
binding the resulting "meta-model" to data in a *machine* for
evaluation, using cross-validation.

Loading and instantiating a gradient tree-boosting model:

````@example lightning_tour
using MLJ
MLJ.color_off()

Booster = @load EvoTreeRegressor # loads code defining a model type
booster = Booster(max_depth=2)   # specify hyper-parameter at construction
````

````@example lightning_tour
booster.nrounds=50               # or mutate post facto
booster
````

This model is an example of an iterative model. As is stands, the
number of iterations `nrounds` is fixed.

### Composition 1: Wrapping the model to make it "self-iterating"

Let's create a new model that automatically learns the number of iterations,
using the `NumberSinceBest(3)` criterion, as applied to an
out-of-sample `l1` loss:

````@example lightning_tour
using MLJIteration
iterated_booster = IteratedModel(model=booster,
                                 resampling=Holdout(fraction_train=0.8),
                                 controls=[Step(2), NumberSinceBest(3), NumberLimit(300)],
                                 measure=l1,
                                 retrain=true)
````

### Composition 2: Preprocess the input features

Combining the model with categorical feature encoding:

````@example lightning_tour
pipe = ContinuousEncoder |> iterated_booster
````

### Composition 3: Wrapping the model to make it "self-tuning"

First, we define a hyper-parameter range for optimization of a
(nested) hyper-parameter:

````@example lightning_tour
max_depth_range = range(pipe,
                        :(deterministic_iterated_model.model.max_depth),
                        lower = 1,
                        upper = 10)
````

Now we can wrap the pipeline model in an optimization strategy to make
it "self-tuning":

````@example lightning_tour
self_tuning_pipe = TunedModel(model=pipe,
                              tuning=RandomSearch(),
                              ranges = max_depth_range,
                              resampling=CV(nfolds=3, rng=456),
                              measure=l1,
                              acceleration=CPUThreads(),
                              n=50)
````

### Binding to data and evaluating performance

Loading a selection of features and labels from the Ames
House Price dataset:

````@example lightning_tour
X, y = @load_reduced_ames;
nothing #hide
````

Binding the "self-tuning" pipeline model to data in a *machine* (which
will additionally store *learned* parameters):

````@example lightning_tour
mach = machine(self_tuning_pipe, X, y)
````

Evaluating the "self-tuning" pipeline model's performance using 5-fold
cross-validation (implies multiple layers of nested resampling):

````@example lightning_tour
evaluate!(mach,
          measures=[l1, l2],
          resampling=CV(nfolds=5, rng=123),
          acceleration=CPUThreads())
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

