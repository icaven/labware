threaded_height = 3.75;
barb_height = 5.5;
inner_post_height = 2.9;
inner_post_radius = 4.1 / 2;
transition_height = 1.5;
hex_post_height = 5;
hex_post_circumcircle_radius = 7.8/2;
air_channel_radius = 2.64 / 2;

mold_base_guide_sphere_radius = 2;
mold_base_guide_sphere_fitting_tolerance = 0.05;
mold_base_height = mold_base_guide_sphere_radius;  // at least mold_base_guide_sphere_radius
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
sleeve_wall_thickness = 0.75;
sleeve_sliding_tolerance = 0.1;
sleeve_inner_radius = suction_cup_bellow_max_radius + suction_cup_mold_wall_thickness + sleeve_sliding_tolerance;


$fn = 100;


module suction_cup() {
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

module suction_cup_mold_half() {
    intersection()
        {
            translate([- mold_height / 2, 0, 0])
                cube([mold_height, mold_height, mold_height]);

            union() {
                translate([0, 0, suction_cup_total_height])
                    rotate([180, 0, 0])
                        difference() {
                            translate([0, 0, 0])
                                cylinder(h = suction_cup_total_height + suction_cup_mold_wall_thickness,
                                r = suction_cup_bellow_max_radius + suction_cup_mold_wall_thickness);
                            
                            suction_cup();
                            
                        }
            }

        }
}

module suction_cup_mold_insert() {
    intersection()
        {
            difference() {
                color("red")
                translate([0, 0, suction_cup_total_height])
                rotate([180, 0, 0])
                suction_cup_inner_space();
                
                // Make the sphere pockets slightly larger to get the fit without binding
//                sphere(r=mold_base_guide_sphere_radius+mold_base_guide_sphere_fitting_tolerance);
                    for (angle = [0: 360/3: 360]) {
                        translate([0.5 * cos(angle) * suction_cup_lip_radius, 0.5 * sin(angle) * suction_cup_lip_radius,
                            0])
                            sphere(r = mold_base_guide_sphere_radius+mold_base_guide_sphere_fitting_tolerance);
                    }

            }

        }
}

module mold_base()
{
    // Make the base a force-fit into the sleeve to prevent leakage
    cylinder(h=mold_base_height, r=sleeve_inner_radius);
    
    // Use a half sphere to mate to the suction_cup_inner_space
    translate([0, 0, mold_base_height])
    for (angle = [0: 360/3: 360]){
        translate([0.5 * cos(angle) * suction_cup_lip_radius, 0.5 * sin(angle)*suction_cup_lip_radius, 0])
            sphere(r=mold_base_guide_sphere_radius);
    }

}

module mold_sleeve()
{
    color("blue")
    difference() {
        cylinder(h=mold_base_guide_sphere_radius+mold_height, 
        r=suction_cup_bellow_max_radius + suction_cup_mold_wall_thickness + sleeve_wall_thickness + sleeve_sliding_tolerance);
        translate([0, 0, -difference_tolerance])
        cylinder(h=mold_base_guide_sphere_radius+mold_height+difference_tolerance*2, 
        r=suction_cup_bellow_max_radius + suction_cup_mold_wall_thickness + sleeve_sliding_tolerance);
            
    }
    
    difference()
    {
        cylinder(h=1, r=suction_cup_bellow_max_radius * 2.5);
        cylinder(h=1, r=suction_cup_bellow_max_radius + suction_cup_mold_wall_thickness + sleeve_sliding_tolerance);
    }

}

module suction_cup_mold_parts_all_at_once()
{
    translate([0, 0, 0])
        mold_sleeve();

    translate([0, mold_height + suction_cup_bellow_max_radius * 2, 0])
        rotate([90, 0, 0])
            suction_cup_mold_half();

    translate([0, - (suction_cup_bellow_max_radius * 2), 0])
        rotate([90, 0, 0])
            suction_cup_mold_half();

    translate([suction_cup_bellow_max_radius * 3, 0, 0])
        suction_cup_mold_insert();

    translate([- suction_cup_bellow_max_radius * 3, 0, 0])
        mold_base();

}

//translate([0, 10, 0])
//text(str(suction_cup_bellow_bottom_height/2 + suction_cup_bellow_bottom_height + barb_height + inner_post_height +2), 4);

difference()
    {
suction_cup();
suction_cup_inner_space();        
    }

//translate([0, mold_height + suction_cup_bellow_max_radius * 2, 0])
//    rotate([90, 0, 0])
//        suction_cup_mold_half();

//    translate([suction_cup_bellow_max_radius * 3, 0, 0])
//        suction_cup_mold_insert();

//    translate([- suction_cup_bellow_max_radius * 3, 0, 0])
//        mold_base();

//    translate([0, 0, 0])
//        mold_sleeve();
