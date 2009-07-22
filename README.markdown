Authorization Apocalypse!
=========================

A Ruby on Rails library modified from [RESTful_ACL](http://github.com/mdarby/restful_acl/tree/master).

How To Use: Models
----------

    class StayPuft < ActiveRecord::Base
    	# Set up some expectations. Order is maintained.
    	logical_parents :gozer, :ray
	
    	# This method checks permissions for the :index action
    	def readable_by?(user, parents = [])
    	end

    	# This method checks permissions for the :update and :edit action
    	def updatable_by?(user, parents = [])
    	end

    	# This method checks permissions for the :destroy action
    	def deletable_by?(user, parents = [])
    	end

    	# This method checks permissions for the :index action
    	def indexable_by?(user, parents = [])
    	end

    	# This method checks permissions for the :create and :new action
    	def creatable_by?(user, parents = [])
    	end
    end