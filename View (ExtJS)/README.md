# ExtJS View : DriverBuddy.view.orders.Details #

#### File Details ####

*Created* : September 2013  
*Original Location* : ```/public/driver_buddy/app/views/orders/Details.js```  
*Mobile App URL* : [Google Play Store](https://play.google.com/store/apps/details?id=com.driverbuddy.driverbuddymobile)  
*Demo Video* : [YouTube](https://www.youtube.com/watch?v=SvxUab6BUsM)

#### File Description ####

As implied, this is an ExtJS/Sencha Touch view file for a mobile application called [DriverBuddy](http://home.driverbuddy.com/). DriverBuddy is an application, when used in concert with a primary application server running in Ruby on Rails, that allows trucking companies to manage their drivers, trucks, inventory, shipments, and even the GPS location of each of those things at any given time.

Specifically, this is the view for the "Shipment Details" page. This page lists a bunch of data about a shipment, such as destination, and the products in the shipment, and the expected delivery date. From this page, you can go "backwards" to the main orders listing page, or "forward" to a map page. The primary functionality here though is that the user can advance this shipment to the next step in the delivery process. In some cases, that involves changing to an entirely different section of the app (to confirm the pickup/delivery of specific items, etc.), and it also requires some remote calls to ensure that the currently viewed shipment is still assigned to the logged in user (with fairly complex state management). This is because on the main Ruby application, there is a dispatch screen that allows company managers to assign/unassign/reassign shipments, and edit the details for shipments; this means additional logic is required to keep data on the mobile side constantly in sync with the backend side.
