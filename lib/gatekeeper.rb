=begin	
	
	One half of the AuthorizationApocalypse
	
	Include this module into any Controller who might need to ask objects some questions.
	Should you employ the Gatekeeper, you must also have the Keymaster included in the associated model.
	
	Sincerely,
	Gozer
	
	PS, This will work with the SetNotationHelper (or without it if you prefer)
	
=end
	
module AuthorizationApocalypse
	
	module Gatekeeper
	  begin
		  include SetNotationHelper 
	  rescue
    end
		# module ClassMethods
			
			#----------
			# has_permission?
			#----------
			
			# This method triggers the Gatekeeper. Include it in your before_filter, after login_required
			# It is essentially called in leu of RestfulAuthenitcation's authorized? method.
			
			def has_permission?
				return true if administrator?
				
				# Load the Model based on the controller name
				klass   = self.controller_name.classify.constantize
		
				# Load the possible parent requested
				@parents = (klass.has_parent?) ? get_parents_from_request_params(klass, params) : nil
	
				# Load the resource requested
				if params[:id]
					if ["index", "destroy", "update"].include?(params[:action]) && klass.respond_to?(:in_set)
						@resource = klass.in_set(params[:id])
						@resource = @resource.first if @resource.size == 1
					else
						@resource = klass.find(params[:id])
					end
				end
	
				# Let's let the Model decide what is acceptable
				# NOTE: It is still the concrete controller's job to filter inaccessible resources (accessed via the index)!
				# This presumably happens in the with_parent named scope
				
				authorized = case params[:action]
					when "edit", "update"
						if !@resource.is_a?(Array)
							return @resource.updatable_by?(current_user, @parents) # this is 'returned' to authorized
						end
	
						verify_set_accessablility(@resource, :updatable_by?) do |unauthorized_ids|
							permission_denied(
								:status => :conflict,
								:message => "#{unauthorized_ids.to_a.join(',')}  is not available for update."
							) if unauthorized_ids.size > 0
						end
						true # if it gets past verification, authorized is true
					
					when "destroy"        
						if !@resource.is_a?(Array)
							return @resource.deletable_by?(current_user, @parents)
						end
						
						verify_set_accessablility(@resource, :deletable_by?) do |unauthorized_ids|
							permission_denied(
								:status => :conflict,
								:message => "#{unauthorized_ids.to_a.join(',')} is not available for deletion."
							) if unauthorized_ids.size > 0
						end
						true # if it gets past verification, authorized is true
				
					when "index" 				  then klass.indexable_by?(current_user, @parents)
					when "new", "create"  then klass.creatable_by?(current_user, @parents)
					when "show"           then @resource.readable_by?(current_user, @parents)
					else check_non_restful_route(current_user, klass, @resource, @parents)
				end
	
				permission_denied unless authorized
					
				#rescue NoMethodError => e
					# Misconfiguration: A RESTful_ACL specific method is missing.
					#raise_error(klass, e)
				#rescue
					# Failsafe: If any funny business is going on, log and redirect
					#routing_error
				#end
			end
	
			private
			
			#----------
			# verify_set_accessablility
			#----------
			
			# This method enforces the integrity of the incoming set.
			# That is, it looks at what was requested and compares it to what is available.
			#    
			#		verify_set_accessablility(@resource, :updatable_by?) do |unauthorized_ids|
			#			permission_denied(
			#				:status => :conflict,
			#				:message => "#{unauthorized_ids.to_a.join(',')}  is not available for update."
			#			) if unauthorized_ids.size > 0
			#		end
			
			def verify_set_accessablility(resources, keymaster_method, options = {}, &block)
				# filter out the resources by keymaster method that are NOT accessible to the user
				filtered_resources = resources.find_all{|r| r.send(keymaster_method, current_user) }
			
				requested_ids = parse_set(params[:id])
				resource_ids  = Set.new(resources.map{|s| s.id.to_s})
				filtered_ids  = Set.new(filtered_resources.map{|s| s.id.to_s})
				
				if resource_ids != requested_ids
					yield resource_ids - requested_ids
				end
				
				if (resource_ids != filtered_ids)
					yield resource_ids - filtered_ids
				end
			end
			
			#----------
			# check_non_restful_route
			#----------
	
			def check_non_restful_route(user, klass, resource, parent)
				if resource
					resource.is_readable_by(user, parent)
				elsif klass
					klass.is_indexable_by(user, parent)
				else
					# If all else fails, deny access
					false
				end
			end
	
			def routing_error
				logger.info("[Authorization Apocalypse!] Routing error by %s at %s for %s" %
				[(logged_in? ? current_user.login : 'guest'), Time.now, request.request_uri])
	
				render "/404.html", :status => 404
			end
	
			def raise_error(klass, error)
				method = get_method_from_error(error)
				message = (is_class_method?(method)) ? "#{klass}#self.#{method}" : "#{klass}##{method}"
				raise NoMethodError, "[Authorization Apocalypse!] #{message}(user, parent = nil) seems to be missing?"
			end
	
			def get_method_from_error(error)
				error.message.gsub('`', "'").split("'").at(1)
			end
	
			def is_class_method?(method)
				method =~ /(indexable|creatable)/
			end
			
			#----------
			# get_parents_from_request_params
			#----------
			
			# This method does not distinguish between
			
			def get_parents_from_request_params(klass, params = {})
				# parent_klass.find(parent_id) if has_parent?
				# Find the parent's id's from the params hash (coming from a controller presumably)
				parent_params = params.reject{ |key, value| !key.to_s.include?("_id") }
				parent_params = parent_params.reject{|key, value| value.blank? }
	
				# This little block of love loops over the found parent hashes from the params, 
				# populating a parents array (initialized to [] in inject()) and returns it to @parent_instances
	
				@parents = parent_params.inject([]) do |parents, params|
					# We only expect a single parent, but this should handles them all.			
					# inject method passes the enumerated one at a time - in this case a single key/value pair
					params = params.to_a
					key    = params[0].to_s.split("_")[0]
					value  = params[1]
										
					if klass.has_parent?(key.to_sym)
						parent_klass = key.classify.constantize.base_class
						# We have special needs here to handle sets!
						instance = (klass.respond_to? :in_set) ? parent_klass.in_set(value) : parent_klass.find(value)
						parents << instance
					else
						barn_logger :error, trace, "Parent instances for #{key.classify} were asked for, but not found in parent expectations for #{self.class}"
					end
					# we must return the parents, not the params
					parents
				end
	
				@parents.flatten!
				
				# return the parenst sorted as they were expressed in logical_parents
				# we use 1000 to place non-matchers at the back of the list.. though there should not be any!
				@parents.sort_by{|name| klass.parents.index(name) || 1000 }
				return (!@parents.blank?) ? @parents : nil
			end
			
			#def get_parent_from_request_uri(child_klass)
			#	parent_klass = child_klass.mom.to_s
			#  bits         = request.request_uri.split('/')
			#  parent_id    = bits.at(bits.index(parent_klass.pluralize) + 1)
			# 
			#  parent_klass.classify.constantize.find(parent_id)
			#end
	
			def requested_through_parents?
				(@parents.blank?) ? false : true
			end
			
			def parents_readable_by?(user)
				return false if @parents.blank?
				@parents.find_all{ |parent| parent.readable_by?(user) }.size > 0
			end
			
			def administrator?
				current_user && current_user.respond_to?("is_admin?") && current_user.is_admin?
			end
	
			#----------
			# permission_denied
			#----------
	
			def permission_denied(options = {})
				status = options[:status] || :forbidden
				url    = options[:url] || new_session_path
				
				error = if options[:message]
					{:message => options[:message], :status => status.to_s.humanize}
				else
					{:status => status.to_s.humanize}
				end
				
				logger.info("[Authorization Apocalypse!] Permission denied to %s at %s for %s" %
				[(logged_in? ? current_user.login : 'guest'), Time.now, request.request_uri])
	
				respond_to do |format|
					format.html {
						store_location
						redirect_to url
					}
					format.json {render :json => error, :status => status }
					format.js		{render :json => error, :status => status }
					format.xml 	{render :xml => error, :status => status }
				end
			end
	
		# end
	end
end