# Introduction
This repo contains code for the Bayesian hierarchical models for peahen looking data published in [this paper](http://jeb.biologists.org/content/216/16/3035.abstract).
The data come from looking time experiments in peahens outfitted with eye trackers. Outcomes are the number of times a given peahen fixated on a given region of a peacock in a fixed amount of time. Inputs include the male and female identities, total frames of looking time, number of fixations for each location (region of interest = ROI), and relative size of each ROI.

# Files and Data
The repo contains three file types:
- `.R` files containing data in R's `dump` function format. That is, `source`ing the relevant file will load the variables.
- `.bug` files are files specifying the hierarchical models in JAGS/BUGS format. Model details are given in the paper, but the files are lightly commented, as well. Models are only tested with JAGS. Models including subject eye (which one was being tracked) as a factor include the `_eye` suffix. Models excluding female identity (treating male, and not video clip, as the sampling unit) include the `_nofem` suffix. Data files are named likewise.
- `run_peafowl_model.R` Performs model fitting and saves csv files of quantiles for variables of interest and plots of actual vs simulated data from the model.

# Dependencies and Running
- The code relies on the `rjags` and `ggplot2` packages.
- `run_peafowl_model.R` has two settable parameters, `model` and `side`, that determine which model is run and whether the data used are for the peacock as viewed from in front or behind. 

