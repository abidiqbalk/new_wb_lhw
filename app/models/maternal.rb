
require 'open-uri'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE #otherwise it messes up looking for SSL certificate
=begin
Wraps data-collection functionality for maternals.

#Schema Information
    Table name: phone_entries
	id                           :integer(4)      not null, primary key
	type                         :string(255)
	meta_instance_id             :string(41)
	meta_model_version           :string(10)
	meta_ui_version              :string(10)
	meta_submission_date         :timestamp
	meta_is_complete             :string(4)
	meta_date_marked_as_complete :timestamp
	device_id                    :string(15)
	subscriber_id                :string(15)
	sim_id                       :string(20)
	start_time                   :timestamp
	end_time                     :timestamp
	location_x                   :decimal(14, 10) not null
	location_y                   :decimal(14, 10) not null
	location_z                   :decimal(14, 10) not null
	location_accuracy            :decimal(14, 10)
	created_at                   :datetime        not null
	updated_at                   :datetime        not null
	photo_file_name              :string(255)
	photo_content_type           :string(255)
	photo_file_size              :integer(4)
	photo_updated_at             :datetime
	photo_url                    :string(255)
=end
class Maternal < PhoneEntry

	has_one :detail, :class_name => "MaternalDetail"	# so all phone-entries have a common interface
	acts_as_gmappable :lat => 'location_y', :lng => 'location_x', :process_geocoding => false

=begin
Imports records from google fusion tables via [fusion table gem](https://github.com/troy/fusion-tables). 
Also fetches corresponding phone-entry image from app-spot and saves it via [paperclip](https://github.com/thoughtbot/paperclip)
@note This method is called periodically from the scheduler
=end
	def self.import_data
		puts  "Importing maternal on #{Time.now}"
		ft = GData::Client::FusionTables.new 
		ft.clientlogin(Yetting.fusion_account,Yetting.fusion_password)		
		ft.set_api_key(Yetting.api_key)


		#maternal_google_table = ft.show_tables[11]
		#puts maternal_google_table.inspect
		#for table in ft.show_tables
		#puts table.name
		#end



		maternal_google_table = ft.show_tables[ft.show_tables.index{|x|x.name=="Monitoring - Maternal"}]

		last_record = self.order("meta_submission_date").last
		
		if last_record.nil?
			puts  "nil record case got run"
			new_records = maternal_google_table.select "*", "ORDER BY '*meta-submission-date*' ASC"
		else
			#we have to assign to because .slice must be the only string method to return the deleted string for some dumb reason...
			last_record = self.order("meta_submission_date").last
			search_after = last_record.meta_submission_date.in_time_zone('UTC').strftime("%m/%d/%Y %H:%M:%S")
			search_after.slice!(" UTC")
			puts  "search after: " + search_after.to_s
			new_records = maternal_google_table.select "*", "WHERE '*meta-submission-date*' >= '#{search_after}' and '*meta-instance-id*' NOT EQUAL TO '#{last_record.meta_instance_id}' ORDER BY '*meta-submission-date*' ASC"
		end

		fields = maternal_google_table.describe
		success_count = 0
		fail_location = 0 
		fail_sim = 0
		duplicate_fail = 0
		records_to_insert=50
		puts  "records caught:" + new_records.count.to_s
		#tried using describe to auto-do it but too much hassle. easier to do it explicitly
		for record in new_records 			
			begin
				location = record["location".to_sym]
				unless location.nil?
					locations = location["geometry"]["coordinates"]
				end

				if record["simid".downcase.to_sym].blank?
					fail_sim = fail_sim + 1
				end
				
				unless record["simid".downcase.to_sym].blank?
					new_maternal = self.new(
						:meta_instance_id=>record[fields[0][:name].downcase.to_sym],
						:meta_model_version=>record[fields[1][:name].downcase.to_sym],			
						:meta_ui_version=>record[fields[2][:name].downcase.to_sym],			
						:meta_submission_date=>DateTime.strptime(record[fields[3][:name].downcase.to_sym],'%m/%d/%Y %H:%M:%S.%L'),			
						:meta_is_complete=>record[fields[4][:name].downcase.to_sym]	,		
						:meta_date_marked_as_complete=>DateTime.strptime(record[fields[5][:name].downcase.to_sym],'%m/%d/%Y %H:%M:%S.%L'),			
						:device_id=>record[fields[6][:name].downcase.to_sym],			
						:subscriber_id=>record[fields[7][:name].downcase.to_sym],			
						:sim_id=>record[fields[8][:name].downcase.to_sym],			
						:start_time=>record[fields[9][:name].downcase.to_sym].tr("T"," "),			
						:end_time=>record[fields[10][:name].downcase.to_sym].tr("T"," "),			
						:photo_url=>record["photo".to_sym],						
						:location_x=>locations[0],			
						:location_y=>locations[1],
						:location_accuracy=>record["location:Accuracy".downcase.to_sym]			
					)
					new_maternal.build_detail(
						:lhw_code=> record[fields[11][:name].downcase.to_sym],
						:name=> record[fields[12][:name].downcase.to_sym],
						:expected_date=>record[fields[13][:name].downcase.to_sym].present? ? DateTime.strptime(record[fields[13][:name].downcase.to_sym], "%m/%d/%Y ").to_date : nil,
						:iron_intake=> record[fields[14][:name].downcase.to_sym],
						:tt_vaccination_count=> record[fields[15][:name].downcase.to_sym],
						:tt_vaccination_date1=>record[fields[16][:name].downcase.to_sym].present? ? DateTime.strptime(record[fields[16][:name].downcase.to_sym], "%m/%d/%Y ").to_date : nil,
						:tt_vaccination_date2=>record[fields[17][:name].downcase.to_sym].present? ? DateTime.strptime(record[fields[17][:name].downcase.to_sym], "%m/%d/%Y ").to_date : nil,
						:anc_count=> record[fields[18][:name].downcase.to_sym],
						:anc_date1=>record[fields[19][:name].downcase.to_sym].present? ? DateTime.strptime(record[fields[19][:name].downcase.to_sym], "%m/%d/%Y ").to_date : nil,
						:anc_date2=>record[fields[20][:name].downcase.to_sym].present? ? DateTime.strptime(record[fields[20][:name].downcase.to_sym], "%m/%d/%Y ").to_date : nil,
						:anc_date3=>record[fields[21][:name].downcase.to_sym].present? ? DateTime.strptime(record[fields[21][:name].downcase.to_sym], "%m/%d/%Y ").to_date : nil,
						:anc_date4=>record[fields[22][:name].downcase.to_sym].present? ? DateTime.strptime(record[fields[22][:name].downcase.to_sym], "%m/%d/%Y ").to_date : nil
								
					)
	
					new_maternal.save!
					unless new_maternal.photo_url.nil?
						new_maternal.update_attribute(:photo,open(new_maternal.photo_url))
					end
				
					success_count = success_count + 1
				end
			rescue ActiveRecord::RecordNotUnique # we check for duplicates by defining a unique index on device_id and end_time and let the db handle it
				duplicate_fail = duplicate_fail + 1
				puts  "Duplicate record found. Not inserting."
			end				
		end
		puts  "location_fail: " + fail_location.to_s
		puts  "sim_fail: " + fail_sim.to_s
		puts  "duplicate_fail: " + duplicate_fail.to_s
		puts  "Imported " +  success_count.to_s + " of " + new_records.count.to_s + " maternal records."
	end
	
=begin
Attaches calculated statistics such as averages and totals to a collection of objects implementing the Reportable Module.
@param [Array of Objects implementing Reportable Module] collection these objects will have the statistics attached to them. 
@param [Array of Objects holding the statistics] maternal_records these objects contain the necessary statistics that will be attached. 
@return [Array of Objects implementing Reportable Module] the collection object with attached statistics 
=end
	def self.build_statistics(maternal_records,collection)
		for unit in maternal_records
			instance = collection.find { |instance| instance.name == unit.name }
			#attr_accessor_with_default is deprecated :S
			instance.maternal_count_total = unit.maternal_count_total_c.to_i
			instance.average_monthly_consumption_total = unit.average_monthly_consumption_total_c.to_i
			instance.students_grade4_total = unit.students_grade4_total_c.to_i
			instance.students_grade5_total = unit.students_grade5_total_c.to_i
			instance.teachers_present_total = unit.teachers_present_total_c.to_i
			instance.tasks_identified_total = unit.tasks_identified_total_c.to_i
			instance.average_monthly_consumption_average = unit.average_monthly_consumption_average_c.to_f.round(1)
			instance.students_grade4_average = unit.students_grade4_average_c.to_f.round(1)
			instance.students_grade5_average = unit.students_grade5_average_c.to_f.round(1)
			instance.teachers_present_average = unit.teachers_present_average_c.to_f.round(1)
			instance.tasks_identified_average = unit.tasks_identified_average_c.to_f.round(1)
		end
		return collection
	end

=begin
Builds Indicators associated with activity for a report
@param [Array of statistics] averages a Hash containing statistics (monthly and for a defined time-period) to be used for reporting overall statistics. 
@return [Array of Indicator Objects] An array of indicators associated with the report or activity
=end
	def self.indicators2
		a=Indicator2.new(:hook => "lhw_code", :indicator_type => "code", :indicator_activity=>self)
		b=Indicator2.new(:hook => "name", :indicator_type => "code", :indicator_activity=>self)
		c=Indicator2.new(:hook => "expected_date", :indicator_type => "date", :indicator_activity=>self)
		d=Indicator2.new(:hook => "iron_intake", :indicator_type => "boolean", :indicator_activity=>self)
		e=Indicator2.new(:hook => "tt_vaccination_count", :indicator_activity=>self)
		f=Indicator2.new(:hook => "tt_vaccination_date1", :indicator_type => "date", :indicator_activity=>self)
		g=Indicator2.new(:hook => "tt_vaccination_date2", :indicator_type => "date", :indicator_activity=>self)
		h=Indicator2.new(:hook => "anc_count", :indicator_activity=>self)
		i=Indicator2.new(:hook => "anc_date1", :indicator_type => "date", :indicator_activity=>self)
		j=Indicator2.new(:hook => "anc_date2", :indicator_type => "date", :indicator_activity=>self)
		k=Indicator2.new(:hook => "anc_date3", :indicator_type => "date", :indicator_activity=>self)
		l=Indicator2.new(:hook => "anc_date4", :indicator_type => "date", :indicator_activity=>self)		
		return [a,b,c,d,e,f,g,h,i,j,k,l]
	end
end

