#
# Streetcast class
# 
# This class runs a single forecast for n number of years and y simulations each year.
# 
# It uses standard deterioration schedules for various types of streets and projects
# how much a segment will deteriorate in a given year. It also selects segments for
# preventive maintenance and full reconstruction given a budget and allocation between
# the two repair types.
# 
# At the end of each year, the simulation returns an array of the ending PCIs and summary results
#
# At the end of the forecast, it returns all conditions and all summary data
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

# gem install descriptive_statistics
require 'descriptive-statistics' # 1.3.6
require "#{File.dirname(__FILE__)}/scenario"



class Streetcast
	attr_accessor :segments, :scenario

	def initialize(segments=[], scenario=nil) 
		@segments = segments
		@scenario = scenario
	end
	

	
	##################################################
	##### 
	##### ITEMS RELATED TO RUNNING THE SIMULATION
	#####
	##################################################
	# this method kicks off the process, having received the needed data and assumptions upon initialization
	def run
		summary = []
		conditions = []
		
		@scenario.years_to_simulate.times do |year|
			c, s = run_year(year+1)
			conditions << c 
			summary << s 
		end	
		
		return conditions, summary
	end
	
	
	# runs a single year in the forecast and returns summary results
	# todo: return these results as a hash instead of an array
	def run_year(year)
	
		# run preventive maintenance
		remaining_budget, segs_prevented, preventive_cost = run_preventive_maintenance(year)
		
		# run rehab, reallocating any unspent preventive dollars 
		segs_rehabbed, rehab_cost = run_rehabilitation_projects(year, remaining_budget)

		
		# stores length of segs in each category
		quality_by_length = Segment.qualities 
		
		# stores num of segs in each category
		quality_by_count = Segment.qualities 
		
		# now step through each segment and run the deteriorate method
		# this will update the conditions, accounting for any rehab and preventive
		# work to be done
		# go through each segment and get summary data 
		
		# hash to hold the new condition data
		conditions = {}
		
		@segments.each do |seg|
			seg.deteriorate # deteriorate this segment
			
			conditions[seg.segid] = seg.conditions.last

			quality_by_length[seg.quality(year)] += seg.length # add the length to the hash
			quality_by_count[seg.quality(year)] += 1 # add 1 to the category
		end
		
		# get the current repair cost
		crc = current_repair_cost()
		
		# create a new variable to calculate mean, stdev, etc
		condition_values = DescriptiveStatistics.new(conditions.values)

		
		total_budget = @scenario.preventive_budgets[year-1] + @scenario.rehab_budgets[year-1]
		total_spent = preventive_cost + rehab_cost
		
		# create the summary array, we'll add some to it later
		summary = [year, segs_prevented, @scenario.preventive_budgets[year-1], preventive_cost, segs_rehabbed, @scenario.rehab_budgets[year-1], rehab_cost, condition_values.mean, condition_values.standard_deviation, total_budget, total_spent, crc]
				
		# get percentages for each quality category 
		count_percents = [] # holds an ordered array of percent count of each category
# 		Segment.ordered_qualities.each do |k|
		Segment.qualities.keys.each do |k|
			
			# get the number of segs in each category
			count = quality_by_count[k]
			percent = count.to_f / @segments.count.to_f * 100
			summary << percent.round(2)
			
		end
		
		return conditions, summary
	end
	
	
	
	
	# returns the current repair cost calculation, which includes:
	#		rehab cost for all segments < 50 +
	# 	preventive cost for all segments 75 to 85
	#
	# CRC is intended to evaluate the cost of all possible repairs in a given year
	def current_repair_cost
		@segments.inject(0) {|total ,segment| 
			if segment.preventive_eligible?
				total += segment.preventive_cost
			elsif segment.rehab_eligible?
				total += segment.rehab_cost
			else
				total 
			end
		}
	end
	
	# quickly get the segments eligible for preventive maintenance
	def eligible_preventives
		@segments.select { |segment| segment.preventive_eligible? }
	end
	
	# quickly get the segments eligible for rehab
	def eligible_rehabs
		@segments.select { |segment| segment.rehab_eligible? }
	end
	
	##################################################
	##### 
	##### ITEMS RELATED TO SIMULATING MAINTENANCE PROJECTS
	#####
	##################################################
	
	# runs preventive maintenance for a given year 
	# returns remaining budget, # of segs prevented, and total cost
	def run_preventive_maintenance(year)
		# get all segments eligible for preventive maintenance
		# todo: sort by condition value ascending
		if @scenario.preventive_selection_method == :sort
			prev_eligible = eligible_preventives().sort { |x, y| x.conditions.last <=> y.conditions.last }
		else 
			prev_eligible = eligible_preventives().shuffle
		end
				
		# calculate the available budget
		budget = @scenario.preventive_budgets[year-1]

		# vars for keeping running tallies
		segs_prevented = 0
		preventive_cost = 0
		
		# cycle through each eligible segment
		prev_eligible.each do |seg|
			
			# if we can't afford to do this project, move on
			if budget < seg.preventive_cost
				next
			end
			
			# perform maintenance
			seg.perform_preventive_maintenance
			segs_prevented += 1
			
			# expense this project
			budget -= seg.preventive_cost
			preventive_cost += seg.preventive_cost
		end
		
		return budget, segs_prevented, preventive_cost
	end
	
	# runs rehabilitation projects for a given year 
	# returns segs rehabbed and total cost
	def run_rehabilitation_projects(year, leftover_budget)
			
		budget = @scenario.rehab_budgets[year-1] + leftover_budget
		
		if @scenario.rehab_selection_method == :sort
			rehab_eligible = eligible_rehabs().sort { |x, y| x.conditions.last <=> y.conditions.last }
		else
			rehab_eligible = eligible_rehabs().shuffle 
		end

		
		segs_rehabbed = 0
		rehab_cost = 0
		rehab_eligible.each do |seg|
		
			if budget < seg.rehab_cost
				next
			end
			
			budget -= seg.rehab_cost
			rehab_cost += seg.rehab_cost
			
			seg.perform_rehab
			segs_rehabbed += 1
		end
		
		return segs_rehabbed, rehab_cost
	end	
	
	##################################################
	##### 
	##### ITEMS RELATED TO DATA RETURNED FROM THE SIMULATION
	#####
	##################################################
	# this provides convenient access to the ordered keys returned by each simulation
	# useful for printing results to a csv file
	# todo: find a better way to do this 
	def self.summary_keys 
		return ['year','prevented','p_bud','p_cost','rehabbed','r_bud','r_cost','average pci','stdev','total_budget','total_spent','current repair cost','un','p','f','a','g','vg']
	end
end