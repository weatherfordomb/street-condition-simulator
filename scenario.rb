#
# Street Simulation Model
# Scenarios.rb
# 
# This class is provided to the Streetcast object for running scenarios
# It also provides predefined scenarios if you want to use them
# 
# @ Version:	0.1
# @ Copyright:	Weatherford OMB, 2013
# @ Created:	February 22, 2013
#
# LICENSE: This software is licensed under the Creative Commons Attribution-NonCommercial license.
# You are free to use, modify, and distribute this software, except for commercial use. The City
# of Weatherford makes no claims to the completeness or accuracy of this software, and assumes
# no liability for your use of it.
#


class Scenario
	attr_accessor :iterations, :years_to_simulate
	attr_accessor :preventive_selection_method, :rehab_selection_method
	attr_accessor :preventive_budgets, :rehab_budgets
	attr_accessor :predefined_scenario
	
	# designated intializer, sets a few default values 
	def initialize()
		@iterations = 20
		@years_to_simulate = 20
		@preventive_selection_method = :sort
		@rehab_selection_method = :shuffle

		@preventive_budgets = []
		@rehab_budgets = []
		
		@predefined_scenario = nil
	end
	

	
	# returns a block used for quickly setting up the scenario
	def configure
		yield self
		self
	end

	
	def describe
		puts "<Scenario>","#{@years_to_simulate} year(s) in legth, #{@iterations} iteration(s)"
		if @predefined_scenario
			puts "Using predefined scenario '#{@predefined_scenario}'"
		else 
			puts "Using custom budget scenario"
		end
		
	end

	##################################################################
	##################################################################
	#
	#
	# BEGIN PREDEFINED SCENARIOS
	#
	# IMPORTANT!!!
	# If you add a new predefined scenario, make sure to add the
	# class method name to the array in self.predefined_scenarios()
	# 
	##################################################################
	##################################################################
	
	# todo: make this automated
	def self.predefined_scenarios()
		[
			'baseline',
			'scenario1','scenario2','scenario3','scenario4','scenario5',
			'scenario6','scenario7','scenario8',
			'scenario9'
		]
	end

	# zero funding scenario
	def self.baseline
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Baseline'
			
			s.years_to_simulate.times do |i|
				s.preventive_budgets << 0
				s.rehab_budgets << 0
			end
		end
		scenario
	end

	# current funding scenario
	def self.scenario1 
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Scenario 1'
			
			s.years_to_simulate.times do |i|
				s.preventive_budgets << 50000
				s.rehab_budgets << 400000
			end
		end
		scenario
	end

	# slight increase for rehab
	def self.scenario2
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Scenario 2'
			
			s.years_to_simulate.times do |i|
				s.preventive_budgets << 50000
				s.rehab_budgets << 450000
			end
		end
		scenario
	end

	# slight increase for preventive
	def self.scenario3
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Scenario 3'
			
			s.years_to_simulate.times do |i|
				s.preventive_budgets << 100000
				s.rehab_budgets << 400000
			end
		end
		scenario
	end

	# slightly larger increase for rehab
	def self.scenario4
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Scenario 4'
			
			s.years_to_simulate.times do |i|
				s.preventive_budgets << 50000
				s.rehab_budgets << 500000
			end
		end
		scenario
	end

	# slightly larger increase for preventive
	def self.scenario5
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Scenario 5'
			
			s.years_to_simulate.times do |i|
				s.preventive_budgets << 150000
				s.rehab_budgets << 400000
			end
		end
		scenario
	end
	
	# add 25k to rehab every 2 years
	def self.scenario6
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Scenario 6'
			
			s.preventive_budgets << 50000
			
			10.times do |i|
				2.times do |t|
					s.rehab_budgets << 400000 + (25000 * i)
				end
			end
		end
		scenario
	end
	
	# add 50k to the budget every 5 years and allocate it 75% to rehab, 25% to preventive
	def self.scenario7
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Scenario 7'
			
			4.times do |i|
				5.times do |t|
					s.preventive_budgets << 50000 + (12500 * i)
					s.rehab_budgets << 400000 + (37500 * i)
				end
			end
		end
		scenario
	end
	
	# add 25k to the rehab budget every year after year 10
	def self.scenario8
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Scenario 8'
			
			s.preventive_budgets << 150000
			
			10.times do |i|
				s.rehab_budgets << 500000
			end
			10.times do |i|
				s.rehab_budgets << 500000 + (25000 * i)
			end
		end
		scenario
	end
	
	
	# use COS to set budgets
	def self.scenario9
		scenario = Scenario.new 
		scenario.configure do |s|
			s.predefined_scenario = 'Scenario 9'
			
			s.years_to_simulate = 80
			
			spread = 125000
			midpoint = 900000
			s.years_to_simulate.times do |i|
				rehab = ( (spread * Math.cos( i.to_f / Math::PI ) ) + midpoint).round
				s.rehab_budgets << rehab
				s.preventive_budgets << 1125000 - rehab
			end

		end
		scenario
	end
	
end