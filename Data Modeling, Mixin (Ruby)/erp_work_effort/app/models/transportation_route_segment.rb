class TransportationRouteSegment < ActiveRecord::Base
  attr_protected :created_at, :updated_at

  belongs_to :route, :class_name => "TransportationRoute", :foreign_key => "transportation_route_id"

  belongs_to :from_stop, :class_name => "TransportationRouteStop", :foreign_key => "from_transportation_route_stop_id"
  belongs_to :to_stop, :class_name => "TransportationRouteStop", :foreign_key => "to_transportation_route_stop_id"

end