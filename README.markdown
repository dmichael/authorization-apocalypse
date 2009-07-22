Authorization Apocalypse!
=========================

A Ruby on Rails library modified from [RESTful_ACL](http://github.com/mdarby/restful_acl/tree/master).

The primary differences between AA and RESTful_ACL besides the charming name are as follows 
* Access control conditions can be defined in external files called "keymasters" (see How To Use: Models) .
* Expectations can be set for multiple nested parents.

This library relies on both models and their associated RESTful controllers in the Rails convention. 

How To Use: Models
------------------

### Basic

The basic way to set authorization permissions for a model and objects created from the model is to 1) declare the expected parents and 2) define the following methods within the model's file

* self.indexable_by?
* self.creatable_by?
* readable_by?
* updatable_by?
* deletable_by?

Here is an example:

    class StayPuft < ActiveRecord::Base
      # Set up some expectations. Order is maintained.
      logical_parents :gozer, :ray
      
      # This method checks permissions for the :index action
      def self.indexable_by?(user, parents = [])
      end

      # This method checks permissions for the :create and :new action
      def self.creatable_by?(user, parents = [])
      end
      
      # This method checks permissions for the :index action
      def readable_by?(user, parents = [])
      end

      # This method checks permissions for the :update and :edit action
      def updatable_by?(user, parents = [])
      end

      # This method checks permissions for the :destroy action
      def deletable_by?(user, parents = [])
      end
    end
    
### Super Awesome