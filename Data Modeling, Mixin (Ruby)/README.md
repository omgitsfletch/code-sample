## Models : Transportation Routes & Mixin : ActsAsRoutable ##

#### File Details ####

*Created* : c. September 2013  
*Original Location* : [```/work_effort```](https://github.com/portablemind/compass_agile_enterprise/tree/master/erp_work_effort)  
*Original Commit* : [Compass AE GitHub](https://github.com/portablemind/compass_agile_enterprise/commit/8228c4f5ff77c6330c677d1ec018474cb575d494)


#### File Description ####

This Ruby mixin was written during my time at TrueNorth Technology. The company had an open source ERP application, [Compass Agile Enterprise](https://github.com/portablemind/compass_agile_enterprise), with a lot of separate modules that added functionality. One of the things I was tasked with doing was designing the preliminary version of a new feature for keeping track of routes during the transportation of goods. The end goal was eventual integration with GPS tracking, and being given a set of shipments at different locations, determining the ideal way to transport said goods, keeping in mind delivery schedules and historical routing data.

Using some of the previous plugins created in Compass AE as a guide, this is my first Ruby mixin, ActsAsRoutable. The most challenging part was handling the model associations. To give some background: another developer on the team, [Russell](https://github.com/russ1985/), had developed a plugin called [has_many_polymorphic](https://github.com/russ1985/has_many_polymorphic). It allowed for two-way polymorphic associations; the example he used was a polymorphic class Animal, with many sub-types: Bears, Birds, Monkeys. You could also have a class Zoo. A Zoo could have many animals, accessed via Zoo.first.animals, but each animal type could also reverse the association i.e. Bear.last.zoos. The only drawback to Russell's creation was that the polymorphic association had to pre-defined; in other words, you had to know your sub-types in advance and "hard-code" them. You couldn't take his example and dynamically add another subtype class Lions during operation. While this may seem contrived and unnecessary, in the context of our intended usage (being able to use mixins to add functionality on the fly), it was an important hump to overcome.

What follows is my creation. When ActsAsRoutable is included on a model, it creates a bunch of associations on the fly to allow the two-way polymorphic relationship between TransportationRoutes and the models using that mixin. This required taking Russ's version, and figuring out how to do class_exec, etc., to dynamically create the same necessary associations. The end result allows you to do something like route.associated_records and see the objects of different class types linked to a particular route, or do <some_object>.routes to see all the routes linked to that particular object instance.
