
include <BOSL2/std.scad>
include <BOSL2/threading.scad>


rod_height = 30;
rod_diameter = 18;
cap_diameter = 19.9;
cap_height = 3.7;
nut_height = 10;
plate_ring_height = 2;
thread_pitch = 1.5;

// Don't need to change anything after this
module __end_of_customizer_variables() {}

wall_thickness = 2.5;
nut_diameter = 27;

// Create the threaded holder, upside down (the way it should be printed)
up(rod_height/2)
difference()
{
    union()
    {
        threaded_rod(d=rod_diameter, height=rod_height, pitch=thread_pitch, end_len1=cap_height*4, $fa=1, $fs=1, blunt_start=true);
        
        // The cap at the top
        down(rod_height/2-cap_height/2)
        cylinder(h=cap_height, r=cap_diameter/2, center=true, $fa=1, $fs=1);
        
        // Collar around the post
        down(rod_height/2-cap_height*3-plate_ring_height*2)
        cylinder(h=plate_ring_height, r=nut_diameter/2, center=true, $fa=1, $fs=1);
        
        // Tapered support for the collar
        down(rod_height/2-cap_height*3-plate_ring_height)
        cylinder(h=plate_ring_height, r2=nut_diameter/2, r1=rod_diameter/2-1, center=true, $fa=1, $fs=1);


    }
    cylinder(h=rod_height+2, r=rod_diameter/2-wall_thickness, center=true, $fa=1, $fs=1);
}


// Add the matching nut
right(rod_diameter*2)
up(nut_height/2)
threaded_nut(nutwidth=nut_diameter, id=rod_diameter, h=nut_height, pitch=thread_pitch, $slop=0.05, $fa=1, $fs=1);
