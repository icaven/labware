/*
Tapered tube holder for benchtop

2022-07-28      Ian Caven   - Modified tapered tube holder for the benchtop

*/

// Set to true to make a test print of the tube support
test_print_for_tapered_tube_support = false;
// When making a test print of the tube support, this is height used
default_support_print_height = 5;


// The number of supporting segments (must be even for a symmetric result)
number_taper_tube_support_spokes = 12;

// The tapered tube bottom support
taper_angle = 54.2;   // degrees from the center axis
// The clearance height is the amount needed to ensure that the tube bottom doesn't make contact with the base of the centrifuge holder
tube_bottom_clearance_height = 2;

// The constrained design parameters, these are determined by the centrifuge and sample tube
// The tube is tapered, slightly smaller at the bottom
// The diameter is measured just above the taper
tube_diameter = 33;
tolerance_around_tube = 0.5;    // The space around the sample tube when inserted
tube_opening_radius = tube_diameter / 2;
min_tapered_section_diameter = 7;

min_wall_thickness = 1.75;   // Dependent on the filament size?
wall_thickness= min_wall_thickness*1;   // The thickness of the plastic walls (except for the lip which is half)
difference_overlap = 0.1;   // A small overlap used when differencing objects
tube_cylinder_support_thickness = wall_thickness;

tapered_insert_outer_radius = tube_opening_radius - wall_thickness-tolerance_around_tube;
taper_support_height = tan(taper_angle) * tapered_insert_outer_radius;
truncated_taper_height = taper_support_height-tan(taper_angle) * min_tapered_section_diameter/2;
construction_truncated_taper_height = truncated_taper_height - difference_overlap + tube_bottom_clearance_height;
extra_base_width = construction_truncated_taper_height / cos(45);
extra_tube_support_height = 15;

// Rendering and printing parameters - probably don't need to change
resolution = 100; // Set to a higher value for smoother curves, lower for faster rendering
$fn=resolution;

module tapered_section()
{
    $fn=resolution;

    // Offset the taper so that the truncated portion
    // of the taper is below ground (which will be removed via intersection later)
    intersection()
    {
        translate([0, 0, truncated_taper_height])
        rotate([180, 0, 0])
        cylinder(taper_support_height, r1=tapered_insert_outer_radius, r2=0);
        
        cylinder(taper_support_height, r=tapered_insert_outer_radius);

    }
}

module tapered_section_shell()
{
   $fn=resolution;
   shell_radius = tapered_insert_outer_radius + wall_thickness;
    shell_height = tan(taper_angle) * shell_radius - difference_overlap;
    truncated_shell_height = shell_height-tan(taper_angle) * (min_tapered_section_diameter/2 + wall_thickness);

    difference()
    {
        intersection() 
        {
            translate([0, 0, truncated_shell_height])
            rotate([180, 0, 0])
                cylinder(shell_height, r1=shell_radius, r2=0);
            cylinder(shell_height, r=shell_radius);
        }
        tapered_section();
    }

}

module hollow_cylinder()
{
   $fn=resolution;

    // The hollow cylinder around the spokes
    difference()
    {
       cylinder(h=construction_truncated_taper_height, r1=extra_base_width+tapered_insert_outer_radius+wall_thickness, 
                r2=tapered_insert_outer_radius+wall_thickness, center=false);
       translate([0, 0, -difference_overlap])
        cylinder(h=construction_truncated_taper_height+difference_overlap*2, 
                 r1=extra_base_width+tapered_insert_outer_radius, r2=tapered_insert_outer_radius, center=false);
    }
}



module spokes()
{
   $fn=resolution;
    union()
    {
      // Make the supporting spokes for the tapered tube
     translate([0, 0, taper_support_height/2-tube_bottom_clearance_height*2])
     for (angle = [ 0 : 180/(number_taper_tube_support_spokes/2): 180 ])
        rotate([0, 0, angle]) 
            cube([tube_cylinder_support_thickness, 
                  (extra_base_width+tapered_insert_outer_radius + difference_overlap) * 2 + wall_thickness/2, 
                  construction_truncated_taper_height+tube_bottom_clearance_height*2], 
            center = true);
    }
}

module tapered_support()
{
   intersection() {
        cylinder(h = construction_truncated_taper_height, r1 = extra_base_width + tapered_insert_outer_radius +
            wall_thickness,
        r2 = tapered_insert_outer_radius + wall_thickness, center = false);
    
        union() {
            // The hollow cylinder around the spokes
            hollow_cylinder();
    
            // The hollow cone that holds the tube
            translate([0, 0, tube_bottom_clearance_height])
                tapered_section_shell();
    
            difference()
                {
                    spokes();
    
                    // Subtract the tapered section to make room for it
                    translate([0, 0, tube_bottom_clearance_height])
                        tapered_section();
    
                }
    
        }
    }
}

// Module that makes the supporting insert for a tapered tube
module benchtop_tapered_tube_support()
{
    $fn=resolution;
    support_cylinder_radius = (taper_support_height - truncated_taper_height)  / tan(taper_angle);
    // Use a gradual slope on the base so that if the part warps after printing, it doesn't bulge at the bottom
    // Use a sphere to carve away the small amount gradually
    base_sphere_radius = 24*(extra_base_width+tapered_insert_outer_radius);
    
    translate([0, 0, construction_truncated_taper_height-difference_overlap])
    difference() {
        cylinder(h=extra_tube_support_height, 
                 r=tapered_insert_outer_radius+wall_thickness, center=false);
        translate([0, 0, -difference_overlap])
        cylinder(h=extra_tube_support_height+2*difference_overlap, 
                 r=tapered_insert_outer_radius, center=false);

    }

    difference(){
        intersection()
        {
            cylinder(h=construction_truncated_taper_height, r=extra_base_width+tapered_insert_outer_radius+wall_thickness+difference_overlap, center=false);
    
            difference()
            {
                union()
                {
                    tapered_support();
                    
                    // Make a hollow tube for the pointed end of the taper to fit into
                    difference()
                    {
                        cylinder(h=tube_bottom_clearance_height, r=support_cylinder_radius+wall_thickness, center=false);
                        cylinder(h=tube_bottom_clearance_height+difference_overlap, r=support_cylinder_radius, center=false);
                    }
                }
               // Remove the spokes from the bottom opening
               translate([0, 0, 0])
                cylinder((tube_bottom_clearance_height+difference_overlap)*2, r=support_cylinder_radius, center=true);
            }
    
        }
    
        translate([0, 0, -base_sphere_radius+0.85])
            sphere(r=base_sphere_radius, $fn=resolution*2);
       
    }
 
}

if (test_print_for_tapered_tube_support){
    intersection()
    {
        support_print_height = test_print_for_tapered_tube_support ? default_support_print_height + tube_bottom_clearance_height: construction_truncated_taper_height;
        translate([0, 0, 29])
         cylinder(support_print_height, r=extra_base_width+tapered_insert_outer_radius+wall_thickness+difference_overlap, center=false, $fn=resolution);
        
        benchtop_tapered_tube_support();
    }
}
else
{
    rotate([180, 0, 0])
        benchtop_tapered_tube_support();
}
 
