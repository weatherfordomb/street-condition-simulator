street-condition-simulator
==========================

A Ruby-based simulation model used to forecast street deterioration at given funding levels. This project began in response to a City Council request to provide an estimate of annual street funding needs. The preliminary report can be found [here](http://weatherfordtx.gov/DocumentCenter/View/5962).

You are free to download, run, test, and/or modify the code found here. Everything falls under the Creative Commons Attribution-NonCommercial license.

## Running a Simulation
After downloading and installing the necessary rubygems (see below), you may run a simulation by running the following in the command line (assuming you have navigated to the appropriate directory):

	> ruby run_sim.rb 

You may add the name of a predefined scenario as an argument as well:

	> ruby run_sim.rb baseline

You can view the predefined scenarios in the class file scenario.rb, or by calling the predefined_scenarios() class method. If you'd like to set a custom scenario, you can do so in run_sim.rb. Any configurations you make to a custom scenario will be overwritten if you provide a predefined scenario as an argument when running the simulation.

## Changes From Original Version
The code in this repository is a refactored version of the original simulation engine. In addition to more inline documentation and comments, it includes the following changes:

* A module called ImportExport to move this code out of the "run_sim.rb" file
* A new class called Scenario which stores the assumptions given to the simulator. Previously these assumptions were stored in constants set in the "run_sim.rb" file
* Some other adjustments to take advantage of Ruby 1.9.3 (we were on 1.8.7 when we began writing this code)

We've tested the results since refactoring and (so far) they appear to be statistically similar to the original version. If you notice anything that looks or acts odd, please let us know or send a pull request so we can incorporate your changes.

## Using Ruby
We're new to Ruby so we may not have followed all of the standard conventions. Don't hold that against us.

This simulator makes use of the [Descriptive Statistics](http://rubygems.org/gems/descriptive-statistics) rubygem, which will need to be installed before running. Thanks to Julian Tescher.

## Final thoughts
Finally, the purpose of this project was two-fold: to build a simulation model that could help provide an answer to the City Council's question, and to learn some new techniques for performing such analyses. It is not designed to make recommendations on which street projects should be funded.