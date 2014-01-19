module ErpWorkEffort
  module Extensions
    module ActiveRecord
      module ActsAsRoutable

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def acts_as_routable
            extend ActsAsRoutable::SingletonMethods
            include ActsAsRoutable::InstanceMethods

            # If we knew the models that would be routable, we could use Russell's has_many_polymorphic plugin
            # to define the relationship between those models and TransportationRoutes. Since acts_as_routable
            # is used on demand, we have to mimic the behavior of the plugin, but from the opposite direction,
            # to properly form the bidirectional many-to-many relationship we want.

            inheriting_class_name = self.name

            # Add has_many_through association to the Routes table
            TransportationRoute.class_exec do
              has_many inheriting_class_name.tableize.to_sym,
                  :through => :associated_transportation_routes,
                  :source => inheriting_class_name.tableize.singularize.to_sym,
                  :conditions => ["associated_transportation_routes.associated_record_type = ?", inheriting_class_name],
                  :dependent => :destroy

              @associated_models << inheriting_class_name.tableize
            end

            # Add linking association to the polymorphic join table
            AssociatedTransportationRoute.class_exec do
              belongs_to inheriting_class_name.tableize.singularize.to_sym,
                  :class_name => inheriting_class_name,
                  :foreign_key => "associated_record_id"
            end

            # Add associations back to routes to the class using this mixin
            has_many :associated_transportation_routes, :as => "associated_record", :dependent => :destroy
            has_many :routes, :through => :associated_transportation_routes, :source => :transportation_route, :dependent => :destroy
          end
        end

        module SingletonMethods
        end

        module InstanceMethods
        end

      end #ActsAsRoutable
    end #ActiveRecord
  end #Extensions
end #ErpWorkEffort