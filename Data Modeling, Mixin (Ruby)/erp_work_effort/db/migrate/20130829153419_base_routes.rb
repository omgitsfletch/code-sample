class BaseRoutes < ActiveRecord::Migration
  def up
    # transportation_routes
    unless table_exists?(:transportation_routes)
      create_table :transportation_routes do |t|
        
		    t.string 	:internal_identifier   
        t.string  :description
      	t.string  :comments

        #connection to external system
		    t.string 	:external_identifier
		    t.string 	:external_id_source
            
        t.timestamps
      end
    end 
    
    # transportation_route_segments
    unless table_exists?(:transportation_route_segments)
      create_table :transportation_route_segments do |t|
        
		    t.string 	  :internal_identifier   
        t.string    :description
      	t.string    :comments

        #connection to external system
		    t.string 	  :external_identifier
		    t.string 	  :external_id_source
		    
		    t.integer   :sequence
		    t.datetime  :estimated_start
		    t.datetime  :estmated_arrival
		    t.datetime  :actual_start
		    t.datetime  :actual_arrival
		    t.integer   :start_mileage
		    t.integer   :end_milage
		    t.integer   :fuel_used
		    
        #foreign keys
        t.integer :transportation_route_id
        t.integer :from_transportation_route_stop_id
        t.integer :to_transportation_route_stop_id            
            
        t.timestamps
      end
    end  
    
    # transportation_route_stops
    unless table_exists?(:transportation_route_stops)
      create_table :transportation_route_stops do |t|
        
		    t.string 	:internal_identifier   
        t.string  :description
      	
        t.integer :postal_address_id
        t.string  :geoloc
        t.integer :sequence

        #connection to external system
		    t.string 	:external_identifier
		    t.string 	:external_id_source
		    
        #foreign keys
        t.integer :transportation_route_id
            
        t.timestamps
      end
    end

    # associated_transportation_routes
    unless table_exists?(:associated_transportation_routes)
      create_table :associated_transportation_routes do |t|
        #foreign keys
        t.integer     :transportation_route_id

        #polymorphic columns
        t.integer  :associated_record_id
        t.string   :associated_record_type
      end
      add_index :associated_transportation_routes, [:associated_record_id, :associated_record_type], :name => "associated_route_record_id_type_idx"
      add_index :associated_transportation_routes, :transportation_route_id, :name => "associated_route_transportation_route_id_idx"
    end
  end

  def down
    [:transportation_routes, :transportation_route_segments, :transportation_route_stops, :associated_transportation_routes].each do |tbl|
      if table_exists?(tbl)
        drop_table tbl
      end
    end
  end
end