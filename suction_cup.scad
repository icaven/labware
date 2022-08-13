/*
    A suction cup for the multi-nozzle platform.  This should be printed with a flexible material such as TPU.
 */

barb_height = 5.5;
inner_post_height = 2.9;
inner_post_radius = 4.1 / 2;

suction_cup_bellow_bottom_height = 5;
suction_cup_bellow_top_height = 2.5;
suction_cup_lip_height = 2.5;
suction_cup_base_radius = 9 / 2;
suction_cup_wall_thickness = 1.5;
suction_cup_bellow_min_radius = 11.25 / 2;
suction_cup_bellow_max_radius = 17 / 2;
suction_cup_lip_radius = 14.8 / 2;
suction_cup_lip_wall_thickness = 0.5;
difference_tolerance = 0.1;
suction_cup_total_height = suction_cup_lip_height + suction_cup_bellow_top_height + suction_cup_bellow_bottom_height +
    barb_height + inner_post_height;
suction_cup_mold_wall_thickness = 1.5;
mold_height = suction_cup_total_height + suction_cup_mold_wall_thickness * 2;

resolution = 100;
$fn = resolution;


// The exterior surface of the suction cup
module suction_cup_surface() {
    union() {
        translate([0, 0, suction_cup_bellow_top_height + suction_cup_bellow_bottom_height + barb_height +
            inner_post_height - difference_tolerance])
            cylinder(h = suction_cup_lip_height + difference_tolerance*2, r1 = suction_cup_bellow_min_radius, 
            r2 = suction_cup_lip_radius);
        translate([0, 0, suction_cup_bellow_bottom_height + barb_height + inner_post_height])
            cylinder(h = suction_cup_bellow_top_height, r1 = suction_cup_bellow_max_radius, r2 =
            suction_cup_bellow_min_radius);
        translate([0, 0, barb_height + inner_post_height])
            cylinder(h = suction_cup_bellow_bottom_height, r1 = suction_cup_base_radius, r2 =
            suction_cup_bellow_max_radius);
        cylinder(h = barb_height + inner_post_height, r = suction_cup_base_radius);
    }
}


// The interior void of the cup
module suction_cup_inner_space() {
    union() {
        translate([0, 0, suction_cup_bellow_top_height + suction_cup_bellow_bottom_height + barb_height +
            inner_post_height - difference_tolerance])
            cylinder(h = suction_cup_lip_height + difference_tolerance * 2, r1 = suction_cup_bellow_min_radius -
                suction_cup_wall_thickness, r2 = suction_cup_lip_radius -
                suction_cup_lip_wall_thickness);
        translate([0, 0, suction_cup_bellow_bottom_height + barb_height + inner_post_height + difference_tolerance])
            cylinder(h = suction_cup_bellow_top_height + 2 * difference_tolerance, r1 = suction_cup_bellow_max_radius -
                suction_cup_wall_thickness,
            r2 = suction_cup_bellow_min_radius - suction_cup_wall_thickness);
        translate([0, 0, barb_height + inner_post_height])
            cylinder(h = suction_cup_bellow_bottom_height + difference_tolerance, r1 = suction_cup_base_radius -
                suction_cup_wall_thickness,
            r2 = suction_cup_bellow_max_radius - suction_cup_wall_thickness);
        translate([0, 0, -difference_tolerance])
            cylinder(h = barb_height + inner_post_height + 2 * difference_tolerance,
            r = inner_post_radius);
    }
}


// Make the part
module suction_cup() {

    difference() {
        suction_cup_surface();
        suction_cup_inner_space();
    }
}

suction_cup();
