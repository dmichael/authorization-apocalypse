=begin

  One half of the AuthorizationApocalypse
  
  Include this module into any model who might be asked the following questions by the Gatekeeper
  Should you employ the Keymaster, you must implement these methods in your model.
  
  Sincerely,
  Gozer

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

=end

module AuthorizationApocalypse

  module Keymaster
  
    def self.included(base)
      base.extend(ClassMethods, ClassAndInstanceMethods)
      base.send(:include, InstanceMethods, ClassAndInstanceMethods)
  
      # Try to include modules in a keymasters folder
      
      keymaster      = "#{base.to_s.downcase}_keymaster"
      keymaster_file = File.join(RAILS_ROOT, 'app','keymasters', keymaster + ".rb")
      
      if File.exists?(keymaster_file)
        require keymaster_file 
        
        if Object.const_defined?(keymaster.classify)
          keymaster = keymaster.classify.constantize
          base.extend(keymaster::ClassMethods)
          base.send(:include, keymaster)
        else
          RAILS_DEFAULT_LOGGER.error "[AuthorizationApocalypse!] Could not include #{base}Keymaster"
        end
      end
      
      # Should this be here?
      
      base.class_eval do  
        named_scope :readable_by, lambda { |*args| 
          raise "named_scope readable_by(user) must be overridden"
          return {} if args.nil? || args.first.nil?
          user = (args.first.is_a?(User))? args.first : User.find(args.first)
          {
            :include => [:user], 
            :conditions => ["#{table_name}.user_id = ?", user.id ]
          } 
        }
      end
    end
  
    module ClassMethods
      attr_accessor :parents
  
      def logical_parents(*models)
        self.parents = models
        # include Keymaster::InstanceMethods
      end
  
      #----------
      # Interface: This is very un-Ruby ...
      #----------
      
      # This method checks permissions for the :index action
      def indexable_by?(user, parent = nil)
        raise "#{self}.indexable_by?(user, parent = nil) must be overridden"
      end
  
      # This method checks permissions for the :create and :new action
      def creatable_by?(user, parent = nil)
        raise "#{self}.creatable_by?(user, parent = nil) must be overridden"
      end
    end
    # ClassMethods
  
    module InstanceMethods
      private
      
      def parents
        # a little reference back to the class form the instances
        self.class.parents
      end
      
      #----------
      # Interface: This is very un-Ruby ...
      #----------
      
      # This method checks permissions for the :show action
      def readable_by?(user, parent = nil)
        raise "#{self.class}#readable_by?(user, parent = nil) must be overridden"
      end
  
      # This method checks permissions for the :update and :edit action
      def updatable_by?(user, parent = nil)
        raise "#{self.class}#updatable_by?(user, parent = nil) must be overridden"
      end
  
      # This method checks permissions for the :destroy action
      def deletable_by?(user, parent = nil)
        raise "#{self.class}#deletable_by?(user, parent = nil) must be overridden"
      end
    end
    # InstanceMethods
    
    module ClassAndInstanceMethods
      def has_parent?(model = nil)
        return !parents.nil? if model.nil?
        return parents.include?(model)
      end
      
      # this method should be accessible from both instances and classes
      def parents_readable_by?(user, parents)
        return false if parents.blank?
        parents = [parents] if !parents.is_a?(Array)
        parents.find_all{ |parent| parent.readable_by?(user) }.size > 0
      end
    end
    
  end
end
