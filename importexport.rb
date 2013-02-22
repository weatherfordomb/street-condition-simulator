#
# Street Simulation Model
# 
# This file imports condition data and returns it.
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


require 'csv'

module ImportExport

	##################################################
	##### 
	##### IMPORT THE SEGMENT DATA
	#####
	##################################################
	
	# on Jan 24, for some reason, i started encountering a weird bug where this segments array wouldn't clone right
	# if you ran 2 10 year simulations, instead of starting back at the initial PCI in year 1 of sim 2
	# it would use year 10 of sim 1 as the starting point. 
	# as much as I don't want to read from the CSV file before every single simulation, I have to do that right now
	# until I have time to figure out what's happening. This problem was not occuring with the first iteration
	# of the simulation engine.

	def import_segments
		segments = []
		
		# save the column indexes in variables so that it's more clear how we're getting data from the CSV file
		idx_segid = 0
		idx_initial_pci = 9
		idx_length = 3
		idx_width = 4
		idx_type = 6
		idx_class = 7
		
		header = true
	
		CSV.foreach("#{File.dirname(__FILE__)}/data.csv") do |row|
			if header
				header = false
				next
			end
		
			segid = row[idx_segid].to_i
			initial_pci = row[idx_initial_pci].to_f
			length = row[idx_length].to_i
			width = row[idx_width].to_i
			type = row[idx_type].to_s
			street_class = row[idx_class].to_s
			segments << Segment.new(segid, initial_pci, length, width, type, street_class)
			
		end
		
		return segments
	end
	
	##################################################
	##### 
	##### EXPORT THE CONDITION DATA
	#####
	##################################################
	
	# This saves a CSV file for the segment condition data for each year of the simulation
	def export_condtions(filename, data)
		CSV.open("results/conditions - #{filename} - #{Time.now}.csv", "w") do |csv|
			csv << ['simulation','year','segid','condition']
			
			# cycle through each simulation
			data.each_index do |sim_index| 
				
				# cycle through each year 
				data[sim_index].each_index do |year_index|
					
					# cycle through each condition 
					data[sim_index][year_index].each do |segid, condition|
					
						s = [sim_index, year_index, segid, condition]
						csv << s
		
					end # end condition
					
				end # end year 
		
			end # end simulation
		
		end # end CSV.open
	end
	
	
	# This saves a CSV file of the summary results for each year of the simulation
	def export_summary(filename, data, headers) 
		CSV.open("results/summary - #{filename} - #{Time.now}.csv", "w") do |csv|
			csv << headers
			
			# cycle through simulations
			data.each_index do |simulation|
				
				# cycle through years 
				data[simulation].each do |sum|
					s = sum
					# push the num of the simulation to the front of the array
					s.unshift(data)
					csv << s
		
				end # end years 
		
			end # end simulations
		
		end # end CSV.open
	end
	
end