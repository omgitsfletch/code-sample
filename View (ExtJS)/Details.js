Ext.define('DriverBuddy.view.orders.Details', {
    extend: 'Ext.Panel',
    xtype: 'fuelbuddy-view-orders-details',
    order: null,
    orderTpl: new Ext.XTemplate(
        '<div class="order_details">',
            '<h3>Order#: {internalId}</h3>',
            '<div>Status: {statusDescription}</div>',
            '<div>Order Date: {windowStartAt:date("n/j/y H:i")} - {windowEndAt:date("n/j/y H:i")}</div>',
            '<h3>Pickup Address</h3>',
            '<tpl if="dispatchFromCurrentLocation !== true">',
                '<div>{shipFromAddress1} {shipFromAddress2}</div>',
                '<div>{shipFromCity}, {shipFromState} {shipFromPostalCode} {shipFromCountry}</div>',
            '</tpl>',
            '<tpl if="dispatchFromCurrentLocation === true">',
                '<div>N/A</div>',
            '</tpl>',
            '<h3>Delivery Address</h3>',
            '<div>{shipToAddress1} {shipToAddress2}</div>',
            '<div>{shipToCity}, {shipToState} {shipToPostalCode} {shipToCountry}</div>',
            '<h3>Products</h3>',
            '<tpl for="orderItems">',
                '<div>{productDescription}: {quantity} {unit}(s)</div>',
            '</tpl>',
        '</div>'
    ),
    config: {
        html: "test",
        styleHtmlContent: true,
        layout: 'fit',
        items: [
            {
                xtype: 'toolbar',
                docked: 'bottom',
                items: [
                    { xtype: 'spacer' },
                    {
                        xtype: 'button',
                        itemId: 'nextStepBtn',
                        text: '',
                        handler: function(button) {
                            var details = button.up('fuelbuddy-view-orders-details');
                            details.goToNextStep();
                        }
                    },
                    {
                        xtype: 'button',
                        itemId: 'mapBtn',
                        text: 'Map',
                        handler: function (button) {
                            var order = button.up('fuelbuddy-view-orders-details').order.getData();
                            button.up('fuelbuddy-view-orders-main').showMap();
                        }
                    },
                    { xtype: 'spacer' }
                ]
            }
        ]
    },

    loadOrder: function (order, index) {
        this.order = order;
        this.setHtml(this.orderTpl.apply(order.getData()));

        // Show/hide next step button and change text as necessary
        this.changeNextStepButton(order.get('status'), order);
    },

    changeNextStepButton: function(status, order) {
        var nextStepBtn = this.down('#nextStepBtn');
        nextStepBtn.hide(); // hide by default

        if (status != 'pending'){
            nextStepBtn.show();
        }else{
            userStore = Ext.getStore('UserStore');
            user = userStore.first();
            // make ajax call to see if they are allowed to start this.order
            Ext.Ajax.request({
                url: DriverBuddy.Configuration.host_url + '/service_layer/data/get_next_shipment_id',
                params: {user_id: user.data.internalId},
                method: 'POST',
                success: function(response) {
                    data = Ext.JSON.decode(response.responseText);

                    if (data.success) {
                        if (data.order_id == order.data.internalId){
                            if (!Ext.getStore('fuelbuddy-view-orders-list-store').has_order_in_transit){
                                nextStepBtn.show();
                            }
                        }
                    } else {
                        Ext.Msg.alert('Error', data.message);
                    }
                },
                failure: function() {
                    Ext.Msg.alert('Error', 'Communication error on get_next_shipment_id');
                }
            });             
        }

        switch (status) {
            case 'pending':
                buttonText = 'Start Delivery';
                break;
            case 'in_transit_pickup':
                buttonText = 'Confirm Pickup';
                break;
            case 'pickup_confirmed':
                buttonText = 'Pickup Order';
                break;
            case 'in_transit_drop_off':
                buttonText = 'Confirm Delivery';
                break;
            case 'drop_off_confirmed':
                buttonText = 'Deliver Order';
                break;
            case 'drop_off_complete':
                buttonText = 'Confirm & Close';
                break;
            case 'complete':
                buttonText = 'Complete';
                nextStepBtn.hide();
                break;
        }

        nextStepBtn.setText(buttonText);
    },

    goToNextStep: function () {
        var details = this,
            main = this.up('fuelbuddy-view-orders-main'),
            pickup = this.up('fuelbuddy-view-orders-main').down('fuelbuddy-view-orders-pickup-main'),
            delivery = this.up('fuelbuddy-view-orders-main').down('fuelbuddy-view-orders-delivery-main'),
            orderStore = this.up('fuelbuddy-view-orders-main').down('fuelbuddy-view-orders-list').getStore(),
            selectedVehicleStore = Ext.getStore('SelectedVehicleStore'),
            currentStatus = this.order.get('status'),
            backBtn = this.up('fuelbuddy-view-orders-main').down('#backBtn'),
            user = Ext.getStore('UserStore').first();

        vehicle = selectedVehicleStore.first();

        if (Ext.Array.contains(['in_transit_pickup', 'pickup_confirmed'], details.order.get('status'))) {
            /* Pass order to pickup card layout. This transition between orders cards & pickup cards will
               always re-pass the order in question, and the pickup side will run its own logic to determine
               how it will used */
            pickup.order = details.order;

            main.setActiveItem('fuelbuddy-view-orders-pickup-main');
        } else if (Ext.Array.contains(['in_transit_drop_off', 'drop_off_confirmed'], details.order.get('status'))) {
            /* Pass order to delivery card layout. This transition between orders cards & delivery cards will
               always re-pass the order in question, and the delivery side will run its own logic to determine
               how it will used */
            delivery.order = details.order;

            main.setActiveItem('fuelbuddy-view-orders-delivery-main');
        } else {
            // Since we are dispatching from current location, and starting the order, we skip the pickup steps and proceed directly to "delivery"
            if (details.order.get('dispatchFromCurrentLocation') && currentStatus == 'pending') {
                Ext.Msg.show({
                    title: 'Confirm',
                    message: 'Are you sure you want to start this delivery?',
                    cls: 'large',
                    buttons: Ext.MessageBox.YESNO,
                    fn: function (buttonId) {
                        if (buttonId == 'yes' || buttonId == 'ok') {
                            details.setMasked({
                                xtype: 'loadmask',
                                message: 'Continuing order...'
                            });

                            Ext.Ajax.request({
                                method: 'POST',
                                url: DriverBuddy.Configuration.host_url + '/fuel_buddy_service/orders/proceed_to_step',
                                params: {
                                    order_id: details.order.get('internalId'),
                                    vehicle_id: vehicle.data.id,
                                    step: 'in_transit_drop_off',
                                    user_id: user.get('internalId')
                                },
                                success: function (response) {
                                    details.setMasked(false);
                                    responseObj = Ext.JSON.decode(response.responseText);
                                    if (responseObj.success) {
                                        // Order advanced to next step, reload the store
                                        orderStore.load({
                                            callback: function() {
                                                // Load the same record again
                                                details.order = orderStore.findRecord('internalId', details.order.get('internalId'));
                                                details.setHtml(details.orderTpl.apply(details.order.getData()));

                                                // Update the button text and hide if necessary
                                                details.changeNextStepButton(details.order.get('status'));

                                                if (currentStatus == 'pending') {
                                                    details.up('fuelbuddy-view-orders-main').showMap();
                                                }
                                            },
                                            scope: this
                                        });
                                    }
                                    else {
                                        if (responseObj.message == 'Invalid Shipment'){
                                            DriverBuddy.app.unassignedProceedToNextOrder(details.order.get('internalId'));
                                        }else{
                                            Ext.Msg.alert('Error', responseObj.message);
                                        }
                                    }
                                },
                                failure: function () {
                                    details.setMasked(false);
                                    Ext.Msg.alert('Error', 'Could not continue order.');
                                }
                            });
                        }
                    }
                });
            // Normal advancement, go to immediate next step
            } else {
                switch (currentStatus) {
                    case 'pending':
                        boxText = 'start this delivery';
                        break;
                    case 'drop_off_complete':
                        boxText = 'complete and close this order';
                        break;
                }

                // Button click here simply advances to next step, AJAX call time
                Ext.Msg.show({
                    title: 'Confirm',
                    message: 'Are you sure you want to ' + boxText + '?',
                    cls: 'large',
                    buttons: Ext.MessageBox.YESNO,
                    fn: function (buttonId) {
                        if (buttonId == 'yes' || buttonId == 'ok') {
                            details.setMasked({
                                xtype: 'loadmask',
                                message: 'Continuing order...'
                            });

                            Ext.Ajax.request({
                                method: 'POST',
                                url: DriverBuddy.Configuration.host_url + '/fuel_buddy_service/orders/proceed_to_next_step',
                                params: {
                                    order_id: details.order.get('internalId'),
                                    vehicle_id: vehicle.data.id,
                                    user_id: user.get('internalId')
                                },
                                success: function (response) {
                                    details.setMasked(false);
                                    responseObj = Ext.JSON.decode(response.responseText);
                                    if (responseObj.success) {
                                        // order has been completed, clear order_in_transit
                                        if (currentStatus == 'drop_off_complete'){
                                            orders_list_store = Ext.getStore('fuelbuddy-view-orders-list-store');
                                            orders_list_store.has_order_in_transit = false;
                                            orders_list_store.order_in_transit = null;
                                        }
                                        // Order advanced to next step, reload the store
                                        orderStore.load({
                                            callback: function() {
                                                // Load the same record again
                                                details.order = orderStore.findRecord('internalId', details.order.get('internalId'));
                                                details.setHtml(details.orderTpl.apply(details.order.getData()));

                                                // Update the button text and hide if necessary
                                                details.changeNextStepButton(details.order.get('status'));

                                                if (currentStatus == 'pending') {
                                                    details.up('fuelbuddy-view-orders-main').showMap();
                                                }
                                            },
                                            scope: this
                                        });
                                    }
                                    else {
                                        if (responseObj.message == 'Invalid Shipment'){
                                            DriverBuddy.app.unassignedProceedToNextOrder(details.order.get('internalId'));
                                        }else{
                                            Ext.Msg.alert('Error', responseObj.message);
                                        }
                                    }
                                },
                                failure: function () {
                                    details.setMasked(false);
                                    Ext.Msg.alert('Error', 'Could not continue order.');
                                }
                            });
                        }
                    }
                });
            }
        }
    }
});