Authorization Apocalypse!
=========================

A Ruby on Rails library modified from [RESTful_ACL](http://github.com/mdarby/restful_acl/tree/master).

The primary differences between AA and RESTful_ACL besides the charming name are as follows:

1. Access control conditions can be defined in external files called "keymasters" (see How To Use: Models) .
2. Expectations can be set for multiple nested parents.

This library relies on both models and their associated RESTful controllers in the Rails convention. 

How To Use: Controllers
-----------------------

To use Authorization Apocalypse!, you need to include the library in your controller and call the has_permission? method in a before filter. Be aware that AA currently makes the assumption that controllers and models share their base names, that is, the Gatekeeper infers the name of the model to interrogate by the name of the controller.

  class StayPuftsController < ApplicationController
    include AuthorizationApocalypse::Gatekeeper
    before_filter :has_permission?
  end

How To Use: Models
------------------

There are 2 ways to add access control via Authorization Apocalypse! to your models: Basic and Super Awesome. For both methods you will include the library like so

    class StayPuft < ActiveRecord::Base
      include AuthorizationApocalypse::Keymaster
      logical_parents :gozer, :ray
    end

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

There is however an unobtrusive method of defining access control on models. The library looks for a folder called "keymasters" in /app and tries to find a file in the convention _model\_name_keymaster.rb

So to use the Super Awesome method of permission definition, do the following:

1. Create the folder RAILS_ROOT/app/keymasters
2. Create a file in with the convention _model\_name_keymaster.rb

The keymaster file is loaded as a module, so the format is a little different than naked methods.

    module StayPuftKeymaster

      module ClassMethods  
        def indexable_by?(user, parents = nil)
        end

        def creatable_by?(user, parent = nil)
        end
      end

      def readable_by?(user, parents = nil)
      end

      def updatable_by?(user, parent = nil)
      end

      def deletable_by?(user, parent = nil)
      end
      
    end
    
The Basic and Super Awesome methods of access control may be used together and in any combination. If AA methods are defined in both the model and a keymaster file, the keymaster file will overwrite the model's methods.