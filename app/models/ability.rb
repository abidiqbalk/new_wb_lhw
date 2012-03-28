class Ability
	include CanCan::Ability
	 
	def initialize(user)
		user ||= User.new # guest user
		
		if user.role? "Super Administrator"
			can :manage, :all
			cannot :manage, Role, :name => "Super Administrator"
			cannot :view, User do |other_user|
				other_user.role? "Super Administrator" and other_user!=user
			end
			cannot :disable_users, User do |other_user|
				other_user==user
			end
		end

		if user.role? "User Administrator"
			can :manage, User 
			cannot :disable_users, User
			can :manage, Role
			cannot :manage, Role, :name => "Super Administrator"
			cannot [:view], User do |other_user|
				other_user.role? "Super Administrator"
			end
		end	
		
		if user.role? "Province Manager"
			can :view_compliance_reports, District
			can :view_school_reports, :all
		end	
		
		if user.role? "District Manager"
			can :view_compliance_reports, District, :id => user.district_ids
			can :view_school_reports, District, :id => user.district_ids
		end	
		
	end
end
