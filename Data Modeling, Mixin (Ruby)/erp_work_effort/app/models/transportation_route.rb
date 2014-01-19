class TransportationRoute < ActiveRecord::Base
  attr_protected :created_at, :updated_at

  #declare array to related models
  attr_accessor :associated_records_array

  # This class instance variable is needed to hold the models linked within :associated_transportation_routes
  class << self; attr_accessor :associated_models end
  @associated_models = []

  # Needed for polymorophic relationship with other models
  has_many :associated_transportation_routes, :dependent => :destroy

  has_many :segments, :class_name => "TransportationRouteSegment", :after_add => :modify_stops, :dependent => :destroy
  has_many :stops, :class_name => "TransportationRouteStop", :dependent => :destroy

  #before we save this model make sure you save all the relationships.
  before_save do |record|
    record.send("associated_records").each do |reln_record|
      #handle STI get superclass class_name if not sub class of ActiveRecord::Base
      klass_name = (reln_record.class.superclass == ActiveRecord::Base) ? reln_record.class.name : reln_record.class.superclass.name
      conditions = "associated_record_id = #{reln_record.id} and associated_record_type = '#{klass_name}'"
      exisiting_record = record.send("associated_transportation_routes").where(conditions).first

      if exisiting_record.nil?
        values_hash = {}
        values_hash["#{record.class.name.underscore}_id"] = record.id
        values_hash["associated_record_type"] = klass_name
        values_hash["associated_record_id"] = reln_record.id
        
        AssociatedTransportationRoute.create(values_hash)
      end
    end
  end

  # Gets all associated records (of any class) tied to this route
  def associated_records
    #used the declared instance variable array
    records = self.send("associated_records_array")
    records = records || []
    self.class.associated_models.each do |model|
      records = records | self.send(model.to_s)
    end
      
    #set it back to the instance variable
    self.send("associated_records_array=", records)
      
    records
  end

  # Ties a segment's from/to stops to its route, and then forces a reload of the route's stops array from its cached value
  def modify_stops(segment)
  	stops = []
  	stops << segment.from_stop << segment.to_stop

  	stops.each do |stop|
	  	unless stop.nil? or stop.route == self
	  		stop.route = self
	  		stop.save
	  	end
	  end

	  # Force reload of the stops array since it has changed
	  self.stops(true)
  end

  def test
    puts self.name
  end

end