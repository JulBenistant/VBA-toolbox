---
title: "Model inversion in 4 steps"
---
* Will be replaced with the ToC, excluding the "Contents" header
{:toc}

This page summarizes the steps required for performing a model inversion with the core VB routines of the toolbox. In brief:

- one **needs** to define evolution and observation functions, as well as creating the `dim` matlab structure.
- one **can** provide further information about the model and/or its inversion (e.g. priors).

> **TIP:** Many demonstration scripts are provided with the toolbox (e.g., see this [fast demo]({{ site.baseurl }}/wiki/Fast-demo-Q-learning-model)).

# Step 1: Defining observation/evolution functions

Generative models are defined in terms of **evolution and observation functions**. One may have to write these evolution/observation functions, in compliance with the following I/O:

```matlab
[ z ] = function_name( x_t,P,u_t,in )
```

- `x_t` : the vector of hidden states at time `t`
- `P` : the vector of parameters (evolution parameters for the evolution function, observation parameters for the observation function)
- `u_t` : the input (experimenter control variable) at time `t`.
- `in` : may contain any extra relevant information
- `z`: the predicted state (evolution function) or data (observation function).
The definition of hidden states, parameters and inputs, as well as their role in the model, are given [here]({{ site.baseurl }}/wiki/Structure-of-VBA's-generative-model).

# Step 2 : Setting model inversion options

The VBA model inversion requires the user to specify some additional information:

- **model dimensions** : `dim`
  - `n` : number of hidden states
  - `p` : output (data) dimension, ie. number of obervations per time sample
  - `n_theta` : number of evolution parameters
  - `n_phi` : number of observation parameters
  - `n_t` : number of time samples
For example, setting:

```matlab
dim.n = 1
dim.n_theta = 2
dim.n_phi = 3
```
tells VBA that there are 1 hidden state, 2 evolution parameters and 3 observation parameters.

> **TIP:** other dimensions (`dim.p` and `dim.n_t`) are optional.

- Other **options** (NB: all these can be left unspecified; cf. default values)
Dealing with categorical (binary) data?

```matlab
options.binomial = 1
```
Want to get rid of annoying graphical output figures?

```matlab
options.DisplayWin = 0
```
When dealing with missing data, fill in `options.isYout`, which is a vector of same size as the data matrix `y`, whose entries are 1 if the corresponding sample is to be left out. For example:
```matlab
options.isYout = zeros(size(y))
options.isYout(1,1) = 1
```
forces VBA to ignore the first time sample of the first dimension of `y`.

> **TIP:** advanced users may use these optional arguments to control the inversion (see [this page]({{ site.baseurl }}/wiki/Controlling-the-inversion-using-VBA-options) for an exhaustive list of options).

# Step 3 : Defining priors

In addition to the evolution and observation functions, specifying the generative model requires the definition of **prior probability distributions** over model unknown variables. These are summarized by sufficient statistics (e.g., mean and variance), which are stored as a matlab structure that is itself added to the 'options' structure:

- **Observation parameters**
  - `priors.muPhi`
  - `priors.SigmaPhi`
- **Evolution parameters** (only for dynamical systems)
  - `priors.muTheta`
  - `priors.SigmaTheta`
- **Initial conditions** (only for dynamical systems)
  - `priors.muX0`
  - `priors.SigmaX0`
- **Measurement noise precision** (only for continuous data)
  - `priors.a_sigma`
  - `priors.b_sigma`
- **State noise precision** (only for dynamical systems)
  - `priors.a_alpha`
  - `priors.b_alpha`

For example, setting:

```matlab
priors.muPhi = zeros(dim.n_phi,1)
priors.SigmaPhi = eye(dim.n_phi)
```
effectively defines a N(0,I) i.i.d. (zero mean, unit variance) normal density on observation parameters.

Note that when dealing with deterministic models, one has to specify the following prior for the state noise precision:

```matlab
priors.a_alpha = Inf
priors.b_alpha = 0
```

> **TIP:** one then fills in the `priors` field of the `options` structure, as follows:
>
>```matlab
options.priors = priors
```
If left unspecified, this field is filled in with defaults (typically, i.i.d. zero-mean and unit variance Gaussian densities).

# Step 4 : Inverting the model

Having completed steps 1 to 3, one simply calls the main **VB model inversion** routine, namely `VBA_NLStateSpaceModel.m`, as follows:

```matlab
[posterior,out] = VBA_NLStateSpaceModel(y,u,f_fname,g_fname,dim,options)
```
Its input arguments are:
- the data `y`
- the input `u` (can be left empty)
- the name/handle of the observation function g
- the name/handle of the evolution function f (empty for static models)
- `dim` : the dimensions of the model variables
- `options` (can be left empty)

Its output arguments are:
- `posterior`: a matlab structure that has the same format as the `priors` above (i.e. stores the first- and second-order moments of the posterior densities of all unknown variables in the model)
- `out`: a matlab structure that summarizes some diagnostics of the model VBA inversion. NB: the (lower bound to) the model evidence is stored in `out.F`.