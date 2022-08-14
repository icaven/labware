/*
    A multi-nozzle platform connected to a single port that may be connected to a vacuum pump.
    The nozzle platform has a fitting that allows it to be connected to a Go-Pro compatible arm.
    
    2022-08-13      Ian Caven
    
 */

// Include for the gopro compatible fitting
use <third_party/n-dof/lib/gopro.scad>

/* [Parameters of the barb for the nozzle] */
barb_height = 5.5;
inner_post_height = 4;
air_channel_radius = 2.64 / 2;
air_hose_fitting_tolerance = 0.2;
air_hose_outer_radius = (5+air_hose_fitting_tolerance)/2;
air_hose_channel_wall_thickness = 1;
post_radius = 7.8/2;
inner_post_radius = 4.1 / 2;

/* [Multi-nozzle platform parameters] */
// The number of nozzles (minimum 3)
number_nozzles = 3;
// The height above the nozzle plaform
nozzle_standoff_height = 2;
nozzle_height = barb_height + inner_post_height + nozzle_standoff_height;
// The radius of the smooth edges
rounding_radius = 2;
// The default value is determined by the gopro connector height (minimum 15)
multi_nozzle_height = 15;
connector_fitting_height = multi_nozzle_height;
air_hose_insert_height = max(5, multi_nozzle_height/2 - air_channel_radius);

suction_cup_lip_radius = 14.8 / 2;

// The size of the smallest object to be picked up
smallest_object_diameter = 75;
circumradius = smallest_object_diameter/2;
apothem = circumradius * cos(180/number_nozzles);
radius_vertical_air_channel_centers = 0.75 * circumradius - suction_cup_lip_radius;

// The number of sides of a circle
resolution = 100;
$fn = resolution;

// Module to construct a barbed nozzle
module nozzle() {
    $fn = 100;
    difference() {
        union() {
            translate([0, 0, inner_post_height + nozzle_standoff_height])
                cylinder(h = barb_height, r1 = 5.25 / 2, r2 = 4.35 / 2);
            
            // The inner post between the barb and the standoff
            translate([0, 0, nozzle_standoff_height])
                cylinder(h = inner_post_height, r = inner_post_radius);
            
            // The nozzle standoff
            cylinder(h = nozzle_standoff_height, r = post_radius);
        }
        cylinder(h = nozzle_height * 3, r = air_channel_radius, center = true);
    }

}

// The internal air channels are modelled by this module
module internal_air_channels()
{
    // A small amount to use when using difference so that the preview will appear correct
    difference_tolerance = 0.1;

    horizontal_channel_axis_height = air_hose_insert_height + air_hose_outer_radius - air_channel_radius;
    union()
        {
            // The central hole that the air hose fits into
            cylinder(h = air_hose_insert_height, r = air_hose_outer_radius);
            translate([0, 0, air_hose_insert_height])
                sphere(r = air_hose_outer_radius);

            // Make the channels from the nozzles into the body of the multi-nozzle base
            translate([0, 0, horizontal_channel_axis_height]) {
                
                // Horizontal air channels from the central hole to the vertical channels
                for (angle = [0: 360 / number_nozzles: 360]) {
                    translate([cos(angle) * radius_vertical_air_channel_centers, 
                               sin(angle) * radius_vertical_air_channel_centers,
                               0])
                        union()
                            {
                                rotate([90, 0, angle - 90])
                                    cylinder(h = radius_vertical_air_channel_centers, r = air_channel_radius);
                                sphere(r = air_channel_radius);
                            }
                }
                // Vertical air channels from the horizontal channels to the nozzles
                for (angle = [0: 360 / number_nozzles: 360]) {
                    union()
                        {
                            translate([cos(angle) * radius_vertical_air_channel_centers, 
                                      sin(angle) * radius_vertical_air_channel_centers,
                                      0])
                                cylinder(h = 2 * rounding_radius + multi_nozzle_height -
                                    horizontal_channel_axis_height + difference_tolerance,
                                r = air_channel_radius);

                        }
                }


            }
        }
}

// Assemble the parts of the multi-nozzle 
module multinozzle()
{
    distance_of_mount_from_body = rounding_radius + 1;
    connector_fitting_length = 15;  // Determined by the gopro connector dimension

    rotate([0, 0, number_nozzles % 2 == 0 ? 180/number_nozzles : 0]) {
        // Create the body with the internal air channels
        difference() {
            translate([0, 0, rounding_radius])
                minkowski() {
                    linear_extrude(height = multi_nozzle_height-2*rounding_radius, center = false)
                        circle(r = circumradius, $fn = number_nozzles);
                    sphere(r = rounding_radius);
                }
            internal_air_channels();
        }
        
        // Add the nozzles
        translate([0, 0, multi_nozzle_height])
        for (angle = [0: 360/number_nozzles: 360]){
            translate([cos(angle) * radius_vertical_air_channel_centers, sin(angle)*radius_vertical_air_channel_centers, 0])
                nozzle();
        }
    }

    // Add the connector fitting
    translate([- (connector_fitting_length / 2 + distance_of_mount_from_body + apothem), 0, multi_nozzle_height / 2])
        rotate([90, 0, 0])
            gopro_male(distance_of_mount_from_body, false);
    
}

multinozzle();

// For development - show the individual nozzle
/*
translate([0, 0, barb_height + inner_post_height])
    rotate([180, 0, 0])
        nozzle();
*/

// For development - show a cut away view of the air channel and a nozzle
/*
intersection(){
    translate([0, 0, - multi_nozzle_height * 2])
        rotate([0, 0, number_nozzles % 2 == 0 ? 180 / number_nozzles : 0])
            cube([circumradius, circumradius, nozzle_height + (multi_nozzle_height + rounding_radius) * 4]);
    multinozzle();
}
*/

// For development - show the internal air channels
//internal_air_channels();


