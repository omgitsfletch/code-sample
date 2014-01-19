class TransportationRouteStop < ActiveRecord::Base
  attr_protected :created_at, :updated_at

  belongs_to :route, :class_name => "TransportationRoute", :foreign_key => "transportation_route_id"

end