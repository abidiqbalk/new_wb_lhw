Lhw::Application.routes.draw do

	devise_for :users,  :controllers => { :registrations => "users/registrations" }	#match 'compliance' => 'compliances#districts'
	
	resources :users do
		member do
			post 'disable_account'
			post 'enable_account'
			get 'compliance_report'
			post 'compliance_report'
			get 'indicators_report'
			post 'indicators_report'      
		end
	end
	
	resources :phone_entries do
		member do
			get 'audio_attachment'
		end
	end

	resources :health_facilities do
		member do
			get  'indicators_report'
			post 'indicators_report'
		end
	end

	
	resources :districts do # remember folks if you miss the s in resources, great things happen like params being appended with . instead of /
		member do
			get  :compliance_report
			post :compliance_report
			get  :indicators_report
			post :indicators_report
			get  :indicators_report_by_people
			post :indicators_report_by_people
		  get  :compliance_table
      get  :monitoring_compliance_table
      get  :reporting_compliance_table
      post :compliance_table
      post :filter_for_compliance_table
    end
	end

	resources :provinces do # remember folks if you miss the s in resources, great things happen like params being appended with . instead of /
		member do
			get 'compliance_report'
			post 'compliance_report'
			get 'indicators_report'
			post 'indicators_report'
		end
	end

	
  # The priority is based upon order of creation:
  # first created -> highest priority.
  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'districts#monitoring_compliance_table', :id => 'layyah'
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  #match ':controller(/:action(/:id))(.:format)'
end
