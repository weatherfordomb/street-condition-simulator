#
# Segment class
# 
# This class represents a street segment of a given area, type, classification, and initial condition
# 
# It keeps track when preventive maintenance is done, and also estimates condition after reconstruction.
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

# constants which hold variables that are not generally considered scenario assumptions
PREVENTIVE_CUTOFF_RANGE = 70.0..80.0
PREVENTIVE_HOLD_RANGE = 4..8
REHAB_CUTOFF_RANGE = 0.0..50.0
PREVENTIVE_COST_SQYD = 3
REHAB_COST_SQYD = 8

class Segment
	attr_accessor :segid, :length, :width, :area_sqyd, :surface_type, :street_class
	attr_accessor :years_remaining_on_preventive_hold
	
	# holds a temporary condition value based on rehab taking place
	attr_reader :post_rehab_condition 
	
	# array holding condition values for each year (0 = initial)
	attr_accessor :conditions 
	
	
	def initialize(segmentid, initial_condition, length, width, type, street_class)
		@segid = segmentid
		@length = length
		@width = width
		@area_sqyd = ( (@width * @length) / 9 ).round
		@surface_type = type
		@street_class = street_class
		
		@years_remaining_on_preventive_hold = 0
		@post_rehab_condition = 0
		
		@conditions = []
		@conditions << initial_condition
	end
	
	
	def describe(full=false)
		puts "Segment Details for #{@segid}"
		if full
			puts "Dimensions: #{@length}' x #{@width}'"
			puts "Type: #{@surface_type}; Classification: #{@street_class}"
		end
		
		puts "Most recent condition data: #{@conditions.last} for year #{@conditions.length - 1}"
		
		if @years_remaining_on_preventive_hold > 0
			puts "Preventive hold in place for #{@years_remaining_on_preventive_hold} more year(s)"
		end
	end
		

	
	##################################################
	##### 
	##### PREVENTIVE RELATED
	#####
	##################################################
	def preventive_cost
		@area_sqyd * PREVENTIVE_COST_SQYD
	end
	
	# determines if this segment is eligible for preventive maintenance
	# if the current condition is >= the cutoff, and there is no hold
	# on the deterioration, return true
	def preventive_eligible?
		# we need to know what the condition is at the end of the previous year
		pci = @conditions.last
		
		# if the PCI is outside the than the cutoff, or we are still arresting deterioration, it's not eligible
		if pci >= PREVENTIVE_CUTOFF_RANGE.first and pci <= PREVENTIVE_CUTOFF_RANGE.last and @years_remaining_on_preventive_hold == 0
			return true
		else
			return false
		end
	end
	
	# performing preventive maintenance arrests deterioration generally for 3-5 years
	# pick a random number in that interval 
	def perform_preventive_maintenance
		@years_remaining_on_preventive_hold = rand(PREVENTIVE_HOLD_RANGE.last - PREVENTIVE_HOLD_RANGE.first) + PREVENTIVE_HOLD_RANGE.first 
		
	end
	
	##################################################
	##### 
	##### REHAB RELATED
	#####
	##################################################
	def rehab_cost
		@area_sqyd * REHAB_COST_SQYD
	end
	
	# determines if this segment is eligible for rehabilitation
	# if the current condition is within the cutoff range, return true
	def rehab_eligible?
		pci = @conditions.last 
		pci >= REHAB_CUTOFF_RANGE.first and pci <= REHAB_CUTOFF_RANGE.last
	end
	
	# estimate a post rehab condition 
	# rehabbing the street gets us a new condition between 95-99
	def perform_rehab
		@post_rehab_condition = 99 - rand(4)
	end
	
	
	##################################################
	##### 
	##### CONDITION RELATED
	#####
	##################################################
	
	# used to project normal deterioration over the next five years if left untouched
	def condition_five_years_from_year(year)
		condition = @conditions.last
		5.times do |i|
			condition -= deduct_slope_for_pci(condition)
		end
		return condition
	end
	
	# cause the segment to experience a year's deterioration
	def deteriorate
		# get the last condition value
		current_pci = @conditions.last
		
		# if a road has been preventively maintained, we slow deterioration
		# and decrement by only .5 points on the condition value until the 
		# hold is removed
		if @years_remaining_on_preventive_hold > 0
			@conditions << current_pci - 0.5
			@years_remaining_on_preventive_hold -= 1
			
		# if there is no hold, calculate the deduction slope
		else
			slope = deduct_slope_for_pci(current_pci)
			
			# condition has a lower limit of 0
			if current_pci - slope < 0
				@conditions << 0
			
			else 
				# if we have rehabbed in this year of the sim, the post_rehabbed_condition is > 0
				# use that value, and only assume 6 months of deterioration, since rehab will 
				# occur at some point during the summer months 
				if @post_rehab_condition > 0
					@conditions << @post_rehab_condition - (slope/2)
					
					# reset the post_rehabbed_condition value to 0
					@post_rehab_condition = 0
					
				# if we have not rehabbed, and there is no hold, assume a full year's deterioration
				else 
					@conditions << current_pci - slope
				end
			end
		
		end
		
	end
	
	
	# calculate the deterioration slope of a segment for a given year based on the condition value
	# 
	# these slope values are based on standard deterioration slopes, but are merely snapshots
	# at various points on the line. they are estimates.
	#
	# different materials (asphalt or concrete) and classifications (arterial, etc.) have
	# different deterioration schedules
	def deduct_slope_for_pci(pci) 
		slope = 0
		
		# calculate the deduct slope based on the previous PCi
		if @surface_type == 'AC'
			# these are all asphalt concrete roads
			if @street_class == 'ART'
				if pci > 85
					slope = 1.5
				elsif pci > 65
					slope = 3.33
				elsif pci > 40
					slope = 2.78
				else
					slope = 1.67
				end
			
			elsif @street_class == 'COL'
				if pci > 85
					slope = 1.15
				elsif pci > 65
					slope = 2.5
				elsif pci > 40
					slope = 2.27
				else
					slope = 1.25
				end
			
			else
				if pci > 85
					slope = 0.94
				elsif pci > 65
					slope = 2.22
				elsif pci > 40
					slope = 1.92
				else
					slope = 1.15
				end
			end
		
		else
			# these are all PCC roads
			if @street_class == 'ART'
				if pci > 85
					slope = 0.83
				elsif pci > 65
					slope = 2.22
				elsif pci > 40
					slope = 1.47
				else
					slope = 1.07
				end
			
			elsif @street_class == 'COL'
				if pci > 85
					slope = 0.75
				elsif pci > 65
					slope = 1.82
				elsif pci > 40
					slope = 1.39
				else
					slope = 0.97
				end
			
			else
				if pci > 85
					slope = 0.68
				elsif pci > 65
					slope = 1.54
				elsif pci > 40
					slope = 1.04
				else
					slope = 0.86
				end
			end #
		end # end if surface type
		
		slope
	end

	
	# an easy way to create a hash for the streetcast to save this information
	def self.qualities
		Hash["unacceptable"=>0,"poor"=>0,"acceptable"=>0,"fair"=>0,"good"=>0,"very good"=>0]
	end
	
	# the condition categories in order
	def self.ordered_qualities
		return ["unacceptable","poor","acceptable","fair","good","very good"]
	end
	
	# this method gives a string equivalent for the condition category
	def quality(year)
		pci = @conditions[year]
		if pci > 90
			"very good"
		elsif pci >= 75
			"good"
		elsif pci >= 65
			"fair"
		elsif pci >= 55
			"acceptable"
		elsif pci >= 40
			"poor"
		else
			"unacceptable"
		end
	end

end