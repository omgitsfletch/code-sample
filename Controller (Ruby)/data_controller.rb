module ServiceLayer
  class DataController < ServiceLayer::BaseController

    # is this driver's current shipment still assigned to him?
    def validate_in_transit_shipment
       begin
        render :json => { :success => true, :valid_shipment => is_valid_shipment?(params[:user_id], params[:shipment_item_id]) }
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        render :json => { :success => false, :message => e.message }
      end
    end

    # TODO: Also return has_order_in_transit and update mobile app to use it
    def get_next_shipment_id
      begin
        pending = TrackedStatusType.find_by_internal_identifier('pending')
        order = ShipmentItem.assigned_driver(params[:user_id]).
                            joins(:status_applications).
                            where("status_applications.thru_date IS NULL AND status_applications.tracked_status_type_id = ?", pending.id).
                            order('shipment_items.est_start_at asc').first

        render :json => { :success => true, :order_id => order.id }
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        render :json => { :success => false, :message => e.message }
      end
    end
    
    def shipments
      begin
        # Get shipment items for the carrier organization of the passed user ID, and only ones assigned to drivers
        orders = ShipmentItem.assigned_driver(params[:user_id]).order('shipment_items.est_start_at asc')
        render :json => { :success => true, :orders => orders.collect { |shipment_item| shipment_item.to_data_hash } }
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        render :json => { :success => false, :message => e.message }
      end
    end

    def location_elements
      render :json => { :success => true, :locations => PartyGeoloc.all.collect{|geoloc| geoloc.to_data_hash} }
    end

    def vehicles
      unless params[:user_id].nil?
        vehicles = Vehicle.assigned_driver(params[:user_id])

        render :json => { :success => true, :vehicles =>  vehicles.collect { |vehicle| vehicle.to_data_hash } }
      else
        render :json => { :success => false, :message => 'Must pass user ID to get valid list of available trucks.' }
      end
    end

    def confirm_order_shipments
      begin
        raise 'Invalid Shipment' unless is_valid_shipment?(params[:user_id], params[:order_id])
        order_shipments = JSON.parse(params[:data])
        order_shipments.each do |order_shipment_id, checked|
          OrderShipment.find(order_shipment_id).current_status = params[:new_status] if checked
        end

        render :json => {:success => true }
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        render :json => { :success => false, :message => e.message }
      end
    end

    def proceed_to_next_step
      begin
        raise 'Invalid Shipment' unless is_assigned_shipment?(params[:user_id], params[:order_id])

        shipment_item = ShipmentItem.find(params[:order_id])

        # If we are starting a delivery, set the current truck
        if shipment_item.current_status == 'pending'
          shipment_item.assign_vehicle(params[:vehicle_id])
        end

        shipment_item.next_step
        
        if shipment_item.current_status == 'complete'
          # If we are finishing carrying something, unassign the vehicle
          shipment_item.unassign_vehicle

          # Hook point for ending assignment of driver to role for now
          driver_role_type = RoleType.find_by_internal_identifier('driver')
          shipment_item.end_role(driver_role_type)
        end

        render :json => { :success => true, :order => shipment_item.to_data_hash }
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        render :json => { :success => false, :message => e.message }
      end
    end

    def proceed_to_step
      begin
        raise "Must define an end status to advance ShipmentItem to." if params[:step].blank?
        raise 'Invalid Shipment' unless is_assigned_shipment?(params[:user_id], params[:order_id])

        shipment_item = ShipmentItem.find(params[:order_id])

        # If we are starting a delivery, set the current truck
        if shipment_item.current_status == 'pending'
          shipment_item.assign_vehicle(params[:vehicle_id])
        end

        while shipment_item.current_status != params[:step]
          old_status = shipment_item.current_status
          shipment_item.next_step
          new_status = shipment_item.current_status

          if (old_status == new_status)
            raise "Reached end of status chain without hitting goal. Either the defined stop point was invalid or some other error occurred."
          end
        end
        
        if shipment_item.current_status == 'complete'
          # If we are finishing carrying something, unassign the vehicle
          shipment_item.unassign_vehicle

          # Hook point for ending assignment of driver to role for now
          driver_role_type = RoleType.find_by_internal_identifier('driver')
          shipment_item.end_role(driver_role_type)
        end

        render :json => { :success => true, :order => shipment_item.to_data_hash }
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        render :json => { :success => false, :message => e.message }
      end
    end

    def save_note
      begin
        raise 'Invalid Shipment' unless is_valid_shipment?(params[:user_id], params[:order_id])
        order = ShipmentItem.find(params[:order_id])
        user = User.find(params[:user_id])
        note_type_iid = params[:note_type_iid]

        order.current_status_application.create_or_update_note_by_type(note_type_iid, params[:note_content], user)

        render :json => { :success => true, :note => order.current_status_application.get_note_by_type(note_type_iid).to_data_hash }
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
        render :json => { :success => false, :message => e.message } 
      end
    end

    def save_location_element
      unless params[:driver_id].nil?
        driver = User.find(params[:driver_id])
        party_id = driver.party.id

        data_point = PartyGeoloc.new
        data_point.party_id         = party_id
        data_point.window_start_at  = params[:window_start_at]
        data_point.window_end_at    = params[:window_end_at]
        data_point.lat              = params[:lat]
        data_point.lng              = params[:lng]
        data_point.save

        render :json => { :success => true, :data => data_point.to_data_hash }
      else
        render :json => { :success => false, :message => 'Invalid input params. Could not save location data.' }
      end
    end

  protected
    def is_assigned_shipment?(user_id, shipment_item_id)
      ShipmentItem.select('shipment_items.id').assigned_driver(user_id).collect{|si| si.id}.include?(shipment_item_id.to_i)
    end

    def is_valid_shipment?(user_id, shipment_item_id)
      ShipmentItem.select('shipment_items.id').assigned_driver(user_id).in_transit.collect{|si| si.id}.include?(shipment_item_id.to_i)
    end

  end #OrdersController
end #FuelBuddyService