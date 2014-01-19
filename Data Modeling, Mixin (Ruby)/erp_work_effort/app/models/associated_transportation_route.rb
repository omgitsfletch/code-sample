# EXAMPLE USAGE of has_many_polymorphic with AssociatedWorkEffort 
# TransportationRoute.class_eval do     
#     has_many_polymorphic :associated_records,
#                :through => :associated_transportation_routes,
#                :models => [:shipment_items, :shipments]
# end
class AssociatedTransportationRoute < ActiveRecord::Base
  belongs_to :transportation_route
  belongs_to :associated_record, :polymorphic => true
end