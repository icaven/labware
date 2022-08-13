
difference_tolerance = 0.1;
barb_height = 5.5;
inner_post_height = 4;
air_channel_radius = 2.64 / 2;
air_hose_fitting_tolerance = 0.2;
air_hose_outer_radius = (5+air_hose_fitting_tolerance)/2;
air_hose_channel_wall_thickness = 1;
post_radius = 7.8/2;
inner_post_radius = 4.1 / 2;
nozzle_standoff_height = 2;     // The height above the tri-nozzle plaform
nozzle_height = barb_height + inner_post_height + nozzle_standoff_height;
rounding_radius = 2;
gopro_mount_height = 15;
suction_tri_nozzle_height = gopro_mount_height;
air_hose_insert_height = max(5, suction_tri_nozzle_height/2 - air_channel_radius);

suction_cup_lip_radius = 14.8 / 2;

circumcircle_radius = 75/2;
radius_vertical_air_channel_centers = 0.75 * circumcircle_radius - suction_cup_lip_radius;


$fn = 100;

module threaded_stem(length, screwsize) {
    screwpitch = screwsize / 6;

    fn = 100;
    render(10)
        translate([0, 0, length / 2]) {
            linear_extrude(height = length, center = true, convexity = 10, twist = - 360 * length / screwpitch, $fn = fn
            )
                translate([screwsize * 0.1 / 2, 0, 0])
                    circle(r = screwsize * 0.9 / 2, $fn = fn);
        }
}

module threaded_nozzle() {
    $fn = 100;
    threaded_height = 3.75;
    hex_post_circumcircle_radius = 7.8/2;
    hex_post_height = 5;
    transition_height = 1.5;

    nozzle_height = barb_height + inner_post_height + transition_height + hex_post_height + threaded_height;
    translate([0, 0, nozzle_height])
        rotate([180, 0, 0])
            difference() {
                union() {

                    translate([0, 0, inner_post_height + transition_height + hex_post_height + threaded_height +
                        barb_height])
                        rotate([180, 0, 0])
                            cylinder(h = barb_height, r1 = 4.35 / 2, r2 = 5.25 / 2);
                    translate([0, 0, transition_height + hex_post_height + threaded_height])
                        cylinder(h = inner_post_height, r = inner_post_radius);
                    translate([0, 0, transition_height + hex_post_height + threaded_height])
                        rotate([180, 0, 0])
                            cylinder(h = transition_height, r1 = 4.1 / 2, r2 = 7. / 2);
                    translate([0, 0, threaded_height])
                        cylinder(h = hex_post_height, r = hex_post_circumcircle_radius, $fn = 6);
                    threaded_stem(threaded_height, 4.7);
                }
                cylinder(h = nozzle_height * 3, r = air_channel_radius, center = true);
            }

}

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

module internal_air_channels()
{
    horizontal_channel_axis_height = air_hose_insert_height + air_hose_outer_radius - air_channel_radius;
    union()
        {
            // The central hole that the air hose fits into
            cylinder(h = air_hose_insert_height, r = air_hose_outer_radius);
            translate([0, 0, air_hose_insert_height])
                sphere(r = air_hose_outer_radius);

            // Make the channels from the nozzles into the body of the tri_nozzle base
            translate([0, 0, horizontal_channel_axis_height]) {
                
                // Horizontal air channels from the central hole to the vertical channels
                for (angle = [0: 360 / 3: 360]) {
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
                for (angle = [0: 360 / 3: 360]) {
                    union()
                        {
                            translate([cos(angle) * radius_vertical_air_channel_centers, 
                                      sin(angle) * radius_vertical_air_channel_centers,
                                      0])
                                cylinder(h = 2 * rounding_radius + suction_tri_nozzle_height -
                                    horizontal_channel_axis_height + difference_tolerance,
                                r = air_channel_radius);

                        }
                }


            }
        }
}

// From: https://github.com/keeeal/n-dof

module _profile(l, r, b) {
    difference() {
        union() {
            circle(r);
            translate([0, -r]) square([l+r, 2*r]);
        }
        circle(b);
    }
}

module gopro_female(length=1, base=false) {
    translate([0, 0,-7.85]) linear_extrude(3.1) _profile(length, 7.5, 2.7);
    translate([0, 0,-1.55]) linear_extrude(3.1) _profile(length, 7.5, 2.7);
    translate([0, 0, 4.75]) linear_extrude(3.1) _profile(length, 7.5, 2.7);
    translate([0, 0, 7.85]) difference() {
        cylinder(1.8, 7.5, 6);
        rotate([0, 0, 30]) cylinder(2, r=4.9, $fn=6);
    }
    if (base) {
        translate([length, 7.5, 0]) rotate([90, 0, 0])
        linear_extrude(15) difference() {
            translate([7.2, 0]) square([2.6, 18.9], true);
            translate([5.9, -9.45]) circle(1.6);
            translate([5.9, -3.15]) circle(1.6);
            translate([5.9,  3.15]) circle(1.6);
            translate([5.9,  9.45]) circle(1.6);
        }
    }
}

module gopro_male(length=1, base=false) {
    translate([0, 0,-4.55]) linear_extrude(2.8) _profile(length, 7.5, 2.7);
    translate([0, 0, 1.75]) linear_extrude(2.8) _profile(length, 7.5, 2.7);
    if (base) {
        translate([length, 7.5, 0]) rotate([90, 0, 0])
        linear_extrude(15) difference() {
            translate([7.125, 0]) square([2.75, 12.6], true);
            translate([5.75, -6.3]) circle(1.75);
            translate([5.75, -0]) circle(1.75);
            translate([5.75,  6.3]) circle(1.75);
        }
    }
}


module suction_tri_nozzle()
{
    distance_of_mount_from_body = rounding_radius + 1;
    difference() {
        translate([0, 0, rounding_radius])
            minkowski() {
                linear_extrude(height = suction_tri_nozzle_height-2*rounding_radius, center = false)
                    circle(r = circumcircle_radius, $fn = 3);
                sphere(r = rounding_radius);
            }
        internal_air_channels();
    }
    
    translate([0, 0, suction_tri_nozzle_height])
    for (angle = [0: 360/3: 360]){
        translate([cos(angle) * radius_vertical_air_channel_centers, sin(angle)*radius_vertical_air_channel_centers, 0])
            nozzle();
    }
    
    translate([-(7+distance_of_mount_from_body+circumcircle_radius/2), 0, suction_tri_nozzle_height/2])
    rotate([90, 0, 0])
    gopro_male(distance_of_mount_from_body, false);
}

//translate([0,0,barb_height + inner_post_height])
//rotate([180, 0, 0])
//nozzle();
//intersection(){
//    translate([0, 0, -suction_tri_nozzle_height*2])
//    cube([circumcircle_radius, circumcircle_radius, nozzle_height+(suction_tri_nozzle_height + rounding_radius)*4]);
//    suction_tri_nozzle();
//}
//internal_air_channels();

suction_tri_nozzle();

