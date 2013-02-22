#
# Street Simulation Model
# 
# This file runs a series of street deterioration simulations and prints the
# results to a CSV file for further analysis.
# 
# @ Version:	0.1
# @ Copyright:	Weatherford OMB, 2013
# @ Created:	January 23, 2013
#
# LICENSE: This software is licensed under the Creative Commons Attribution-NonCommercial license.
# You are free to use, modify, and distribute this software, except for commercial use. The City
# of Weatherford makes no claims to the completeness or accuracy of this software, and assumes
# no liability for your use of it.
#

require "#{File.dirname(__FILE__)}/scenario"
require "#{File.dirname(__FILE__)}/streetcast"
require "#{File.dirname(__FILE__)}/segment"

require "#{File.dirname(__FILE__)}/importexport"
include ImportExport



# configuration options for saving the results to a CSV file
SAVE_CONDITIONS_TO_CSV = false
SAVE_SUMMARY_TO_CSV = true



# Create the scenario
# examples:
# scenario = Scenario.baseline() for the baseline scenario
#
# or 
# 
# scenario = Scenario.new
# scenario.configure do |s|
# 	// change assumptions
# end

# optionally, you can call a predefined scenario when running the sim from the command line
# for example:
# > ruby run_sim.rb baseline
# will run the baseline scenario

# uncomment the next line to print the names of predefined scenarios
# puts Scenario.predefined_scenarios

# if there were no arguments given, the following code will be used to create the scenario
if ARGV.length == 0
	
	# change anything below to customize the scenario you'd like to simulate
	# in this example, we'll start with "scenario1" and make a few changes to it 

	scenario = Scenario.scenario1()
	scenario.configure do |s|
		# configure the scenario here
		
		s.interations = 1
		s.years_to_simulate = 5
	end

########################################################
########################################################
# 
#
# Nothing below this point needs to be adjusted
# in order to run the simulation
# 
#
########################################################
########################################################

	FILENAME = 'custom scenario'
else 
	
	predefined = Scenario.predefined_scenarios
	if predefined.index( ARGV[0] )
		scenario = Scenario.send ARGV[0]
	
	else 
		scenario = Scenario.scenario1
		puts "!! error !!", "Unable to find a scenario named '#{ARGV[0].to_sym}', using scenario1 instead",""
	end
	
	FILENAME = scenario.predefined_scenario
end


# print the scenario description
scenario.describe
puts "-"*20

abort
# conditions[] holds the condition data for each segment for each year for each simulation
conditions = []

# summmary[] holds the summary results for each year for each simulation
summary = []

puts "Beginning simulations..."
scenario.interations.times do |sim|
	streetcast = Streetcast.new( ImportExport.import_segments(), scenario )

	c, s = streetcast.run
	conditions << c 
	summary << s

	puts "Completed iteration #{sim}"
end
puts "Completed all iterations!","-"*20


if SAVE_SUMMARY_TO_CSV
	headers = Streetcast.summary_keys
	headers.unshift('simulation')
	
	ImportExport.export_summary(FILENAME, summary, headers)
	puts "Saved summary CSV file"
end

if SAVE_CONDITIONS_TO_CSV
	ImportExport.export_conditions(FILENAME, conditions)
	puts "Saved conditions CSV file"
end

puts "StreetCast completed","-"*20