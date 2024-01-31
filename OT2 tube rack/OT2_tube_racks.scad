/*
    Redesigned tube rack and plates for OpenTrons 2.
    See: https://shop.opentrons.com/4-in-1-tube-rack-set/
    Dimensions from: https://opentrons-landing-img.s3.amazonaws.com/labware/Opentrons_Tube_Rack_White_Paper.pdf
    
    BSD 2-Clause License

    Copyright (c) 2024, Ian Cavén
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    
*/

/*
    Download and install BOSL2 from https://github.com/BelfrySCAD/BOSL2
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

// Part to generate
part_name = "1.5 ml and caps plate"; // ["50 ml plate", "15 ml plate", "15 and 50 ml plate", "1.5 ml and caps plate", "stand"]

// The height of letters off the top of the plate
letter_height = 0.5;

// Letter size - vertical ascent of the letters from the baseline
letter_size = 3.;

// Assembled view - not for printing
show_assembled = false;

// Don't need to change anything after this
module __end_of_customizer_variables() {}

// Wall thickness
thickness = 2;

// Radius of chamfer around the holes
hole_chamfer = 1.2;

stand_length = 127.5;
stand_width = 85.5;
stand_height = 73.6;
plate_top_height = 78.4;

top_plate_length = 121;
top_plate_width = 78.75;

top_plate_thickness = 10;
top_plate_bottom_round_r = 1.;
top_plate_top_round_r = 1.2;
stand_bottom_margin = [(stand_length-top_plate_length)/2, (stand_width-top_plate_width)/2];


// 50 ml tube
hole_diameter_50ml = 29.3;
hole_50ml = circle(d=hole_diameter_50ml, $fn=50);
hole_50ml_base = circle(d=8, $fn=50);

nb_holes_long_tube_plate_50ml = 3;
nb_holes_wide_tube_plate_50ml = 2;
tube_plate_50ml_A1_center = [36.4, 25.3];
tube_plate_50ml_spacing = [35, 35];

// 15 ml tube
hole_diameter_15ml = 17;
hole_15ml = circle(d=hole_diameter_15ml, $fn=50);
hole_15ml_base = circle(d=5, $fn=50);
nb_holes_long_tube_plate_15ml = 5;
nb_holes_wide_tube_plate_15ml = 3;
tube_plate_15ml_A1_center = [13.9, 17.8];
tube_plate_15ml_spacing = [25, 25];

// Mix of 15 ml and 50 ml tubes
nb_holes_long_tube_holder_15_mix = 2;
nb_holes_wide_tube_holder_15_mix = 3;
nb_holes_long_tube_holder_50_mix = 2;
nb_holes_wide_tube_holder_50_mix = 2;
tube_holder_15_mix_A1_center = tube_plate_15ml_A1_center;
tube_holder_15_mix_spacing = tube_plate_15ml_spacing;
tube_holder_50_mix_A3_center = [71.4, 25.3];
tube_holder_50_mix_spacing = tube_plate_50ml_spacing;

// 1.5 ml tubes and cap slots
hole_diameter_1p5ml = 11.4;
hole_1p5ml = circle(d=hole_diameter_1p5ml, $fn=50);
nb_holes_long_tube_plate_1p5ml = 6;
nb_holes_wide_tube_plate_1p5ml = 4;
tube_plate_1p5ml_A1_center = [18.2, 10.1];
tube_plate_1p5ml_spacing = [19.9, 19.3];

              
hole_letters = ["A", "B", "C", "D"];
difference_tolerance = 1; // This is the extra amount for a difference operation in preview
corner_size = 4*sqrt(2);

// Shelf for the top plate to rest on
shelf_height = 2;   // The plate will rest on this shelf
shelf_width = 1.2;
plate_thickness_with_shelf = top_plate_thickness + shelf_height;
plate_perimeter_rounding_r = 2;

// Height of the hollows in the sides
plate_recess_wall_thickness = 1.2;
hollow_top_r = shelf_width;       // Rounding radius of the hollow (negative space) at the top
hollow_height = plate_top_height - top_plate_thickness - shelf_height - top_plate_thickness/2 - hollow_top_r;
top_of_side_hollow = stand_height/2 + hollow_height/2;

// Depth of the holes in the base plate, measured from the top of base plate
base_top_height = (stand_height - hollow_height)/2;
base_hole_depth = base_top_height/2;

// Tapered pins in the corners to join the top and bottom parts of the stand
// ** Only used when the stand is divided into 2 pieces, but this is no longer needed **
max_pin_r = 0.5;
hole_depth = 2.0;
pin_height = hole_depth - 0.5;
pin_taper_scale = 0.85;     // The factor by which the top of the pin is smaller than the base of the pin
pin_r_tolerance = 0.1;


// Make an array of holes with uniform spacing
module uniform_hole_array(hole, nb_holes_long, nb_holes_wide, A1_offset, hole_spacing,
                          hole_depth=top_plate_thickness*2, hc=hole_chamfer)
{
    for (x = [0:nb_holes_long-1])
    {
        for (y = [0:nb_holes_wide-1])
        {
            translate([hole_spacing[0]*x+A1_offset[0], hole_spacing[1]*y+A1_offset[1], 0])
             offset_sweep(hole, height=hole_depth, check_valid=false, steps=22,
                       bottom=os_teardrop(r=-hc), top=os_circle(r=0));
        }
    }
}

// For testing hole sizes and locations
module cylinder_array(nb_holes_long, nb_holes_wide, A1_offset, hole_spacing)
{
    for (x = [0:nb_holes_long-1])
    {
        for (y = [0:nb_holes_wide-1])
        {
            translate([hole_spacing[0]*x+A1_offset[0], hole_spacing[1]*y+A1_offset[1], -0.5])
             cylinder(h=top_plate_thickness, r=hole_diameter_50ml/2);
        }
    }
}

// Label the holes
module uniform_hole_labelling(hole_diameter, nb_holes_long, nb_holes_wide, A1_offset, hole_spacing, text_size, label_location="top",
                              hole_number_offset=0)
{
    xoffset = label_location == "tl" ? -hole_diameter/2-(hole_spacing[0]-hole_diameter-hole_chamfer)/4 : 
              label_location == "l" ? -hole_diameter/2 : 0;
    yoffset = label_location == "tl" ? -hole_diameter/2-(hole_spacing[1]-hole_diameter-hole_chamfer)/4 : 
              label_location == "l" ? -2 : -hole_diameter/2-(hole_spacing[1]-hole_diameter-hole_chamfer)/4;
    
    // Upside down, so alignment is opposite
    halign = label_location == "tl" ? "left" : label_location == "l" ? "right" : "center";
    
    for (x = [0:nb_holes_long-1])
    {
        for (y = [0:nb_holes_wide-1])
        {
            linear_extrude(height=letter_height)
            translate([hole_spacing[0]*x+A1_offset[0]+xoffset, hole_spacing[1]*y+A1_offset[1]+yoffset, 0])
            mirror([0, 1, 0])
                text(str(hole_letters[y],str(x+1+hole_number_offset)), size=text_size, halign=halign, $fn=24);
        }
    }
}

module solid_top_plate(sliding_tolerance=0) 
{
    // Rectangle with a clipped corner
    clipped_corner_box_points = [[corner_size-sliding_tolerance, -sliding_tolerance], 
                                 [top_plate_length+sliding_tolerance,0], 
                                 [top_plate_length+sliding_tolerance, top_plate_width+sliding_tolerance], 
                                 [-sliding_tolerance,top_plate_width+sliding_tolerance], 
                                 [-sliding_tolerance, corner_size-sliding_tolerance]];
    outside_plate_perimeter = round_corners(clipped_corner_box_points, method="circle", 
                                            radius=plate_perimeter_rounding_r, $fn=20);
    
    color("green")
    offset_sweep(outside_plate_perimeter, height=top_plate_thickness, check_valid=false, steps=22,
           bottom=os_circle(r=top_plate_top_round_r), top=os_teardrop(r=top_plate_bottom_round_r));
    
}

// This will create a top plate that is hollow and is expected to be printed upside down
// The surface finish is not as good as when the plate is printed letter side up, so it is no longer used
module hollow_top_plate() 
{
    // Rectangle with a clipped corner
    pwt = plate_recess_wall_thickness;     // plate_wall_thickness
    inside_corner_box_points = [[corner_size+pwt, pwt], 
                                [top_plate_length-pwt,pwt], 
                                [top_plate_length-pwt,top_plate_width-pwt], 
                                [pwt,top_plate_width-pwt], [pwt, corner_size+pwt]];
        
    inside_plate_perimeter = round_corners(inside_corner_box_points, method="circle", 
                                           radius=plate_perimeter_rounding_r, $fn=20);

    // Need this translate to have the holes end up in the right place
    translate(stand_bottom_margin)
    difference()
    {
        color("green")
        solid_top_plate();
        
        // Make the plate into a shell
        up(thickness)
        offset_sweep(inside_plate_perimeter,
             height=top_plate_thickness-thickness, steps=22, check_valid=false,
             bottom=os_teardrop(r=2), top=os_teardrop(r=1,extra=1));
    }
    
}

module top_plate()
{
    // Need this translate to have the holes end up in the right place
    translate(stand_bottom_margin)
    solid_top_plate();
}

module tube_plate_50ml()
{
    difference()
    {
        top_plate();
        uniform_hole_array(hole_50ml, nb_holes_long_tube_plate_50ml, nb_holes_wide_tube_plate_50ml,
                           tube_plate_50ml_A1_center, tube_plate_50ml_spacing);
   }
   down(letter_height)
   uniform_hole_labelling(hole_diameter_50ml, nb_holes_long_tube_plate_50ml,
                           nb_holes_wide_tube_plate_50ml, tube_plate_50ml_A1_center,
                           tube_plate_50ml_spacing, letter_size, "tl");

}
module tube_plate_15ml()
{
    difference()
    {
        top_plate();
        
        uniform_hole_array(hole_15ml, nb_holes_long_tube_plate_15ml, nb_holes_wide_tube_plate_15ml,
                                    tube_plate_15ml_A1_center, tube_plate_15ml_spacing);
    }
    
    // At this point the plate is upside down, so the letters are shifted down,
    // but they will be raised in the final result
    down(letter_height)
    uniform_hole_labelling(hole_diameter_15ml, nb_holes_long_tube_plate_15ml,
                       nb_holes_wide_tube_plate_15ml,
                       tube_plate_15ml_A1_center, tube_plate_15ml_spacing, letter_size);

}

module tube_plate_15_and_50ml()
{   
    difference()
    {
        top_plate();

        // 15 ml tube holders
        uniform_hole_array(hole_15ml, nb_holes_long_tube_holder_15_mix,
                            nb_holes_wide_tube_holder_15_mix,
                                    tube_holder_15_mix_A1_center, tube_holder_15_mix_spacing);

        // 50 ml tube holders
        uniform_hole_array(hole_50ml, nb_holes_long_tube_holder_50_mix,
                           nb_holes_wide_tube_holder_50_mix,
                           tube_holder_50_mix_A3_center, tube_holder_50_mix_spacing);

    }
    
    down(letter_height)
    {
        uniform_hole_labelling(hole_diameter_15ml, nb_holes_long_tube_holder_15_mix, 
                           nb_holes_wide_tube_holder_15_mix, tube_holder_15_mix_A1_center,
                           tube_holder_15_mix_spacing, letter_size);
        uniform_hole_labelling(hole_diameter_50ml, nb_holes_long_tube_holder_50_mix,
                           nb_holes_wide_tube_holder_50_mix, tube_holder_50_mix_A3_center,
                           tube_holder_50_mix_spacing, letter_size, "tl", 2);
    }

}

module cap_holes(hole_diameter, nb_holes_long, nb_holes_wide, A1_offset, hole_spacing, 
                 hole_depth=top_plate_thickness*2)
{
    cap_length = 14;
    cap_width = 7.5;
    space_between = 0.35; // Need the little extra space to be outside of the hole
    xoffset = -(hole_diameter / (2 * sqrt(2)) + space_between);
    yoffset = (hole_diameter / (2 * sqrt(2)) + space_between);
    anchor = [0, -cap_width/2];
    
    cap_path = square([cap_length,cap_width]);
    cap_outline = round_corners(cap_path, method="smooth", 
                                cut=[0, 0, 1.5, 1.5], k=[0.5, 0.5, 1., 1.], 
                                closed=true,$fn=20);
    for (x = [0:nb_holes_long-1])
    {
        for (y = [0:nb_holes_wide-1])
        {
            translate([hole_spacing[0]*x+A1_offset[0]+xoffset, 
                       hole_spacing[1]*y+A1_offset[1]+yoffset, hole_depth/3])
            offset_sweep(cap_outline, height=hole_depth, 
                         anchor=anchor, spin=45, 
                         bottom=os_circle(r=0), top=os_circle(r=0), 
                         steps=22, check_valid=false);
        }
    }
}

// Top plate for 1.5 ml tubes and caps
module tube_plate_1p5_and_caps()
{   
    difference()
    {
        top_plate();

        // 1.5 ml tube holders
        uniform_hole_array(hole_1p5ml, nb_holes_long_tube_plate_1p5ml,
                           nb_holes_wide_tube_plate_1p5ml, tube_plate_1p5ml_A1_center,
                           tube_plate_1p5ml_spacing, top_plate_thickness, 0);
        
        // holes for caps
        cap_holes(hole_diameter_1p5ml, nb_holes_long_tube_plate_1p5ml, 
                  nb_holes_wide_tube_plate_1p5ml, tube_plate_1p5ml_A1_center,
                  tube_plate_1p5ml_spacing);
    }
    
    // Label the holes
    down(letter_height)
    uniform_hole_labelling(hole_diameter_1p5ml, nb_holes_long_tube_plate_1p5ml,
                           nb_holes_wide_tube_plate_1p5ml, tube_plate_1p5ml_A1_center,
                           tube_plate_1p5ml_spacing, letter_size, "l");


}

// The holes in the base help keep the tubes straight up and down. 
module holes_in_base()
{
    base_hole_chamfer = 0.25;
    
    translate([0, stand_width, base_top_height]) 
    mirror([0,1,0]) mirror([0, 0, 1])
    union()
    {
        uniform_hole_array(hole_50ml_base, nb_holes_long_tube_plate_50ml, 
                            nb_holes_wide_tube_plate_50ml,
                            tube_plate_50ml_A1_center, tube_plate_50ml_spacing,
                            base_hole_depth, base_hole_chamfer);
        
        uniform_hole_array(hole_15ml_base, nb_holes_long_tube_plate_15ml, 
                            nb_holes_wide_tube_plate_15ml, tube_plate_15ml_A1_center,
                            tube_plate_15ml_spacing, base_hole_depth, base_hole_chamfer);

        uniform_hole_array(hole_15ml_base, nb_holes_long_tube_holder_15_mix,
                           nb_holes_wide_tube_holder_15_mix,
                           tube_holder_15_mix_A1_center, tube_holder_15_mix_spacing,
                           base_hole_depth, base_hole_chamfer);
        
        uniform_hole_array(hole_50ml_base, nb_holes_long_tube_holder_50_mix,
                           nb_holes_wide_tube_holder_50_mix,
                           tube_holder_50_mix_A3_center, tube_holder_50_mix_spacing, 
                           base_hole_depth, base_hole_chamfer);
    }
}

// The openings on the long side of the base
module long_side_punch_out(long_side_punch_out_length, top_plate_margin, hollow_height)
{
    side_narrowing = 0.1;
    smaller_side_scale = 0.10;
    smaller_cutout_angle = atan(hollow_height/long_side_punch_out_length);
    template_punch_out = square([long_side_punch_out_length, 
                          stand_width + 2*(top_plate_margin + difference_tolerance)], center=true);
    rounded_prism(template_punch_out, apply(scale([side_narrowing, 1, 1]), template_punch_out), 
                  height=hollow_height, joint_top=3, 
                  joint_bot=5, joint_sides=0);
    
    left(long_side_punch_out_length/3+10)
    up(5)
    yrot(smaller_cutout_angle)
    rounded_prism(apply(scale([smaller_side_scale, 1, 1]), template_punch_out), 
                  apply(scale([smaller_side_scale, 1, 1]), template_punch_out), 
                  height=hollow_height/1.25, 
                 joint_top=3, 
                 joint_bot=3, joint_sides=0);
    right(long_side_punch_out_length/3+10)
    up(5)
    yrot(-smaller_cutout_angle)
    rounded_prism(apply(scale([smaller_side_scale, 1, 1]), template_punch_out), 
                  apply(scale([smaller_side_scale, 1, 1]), template_punch_out), 
                  height=hollow_height/1.25, 
                 joint_top=3, 
                 joint_bot=3, joint_sides=0);

}

module test_long_side_punch_out()
{
    long_side_punch_out_length = top_plate_length - 30;
    top_plate_margin = thickness;
    long_side_punch_out(long_side_punch_out_length, top_plate_margin, hollow_height);

}

module complete_holder_stand()
{
    hollow_length = top_plate_length-plate_recess_wall_thickness;
    hollow_width = top_plate_width-plate_recess_wall_thickness;

    long_side_punch_out_length = top_plate_length - 30;
    short_side_punch_out_width = top_plate_width - 30;
    top_plate_margin = thickness;

    shelf_box_points = [[corner_size+shelf_width, shelf_width], 
                        [top_plate_length-shelf_width,shelf_width], 
                        [top_plate_length-shelf_width,top_plate_width-shelf_width], 
                        [shelf_width,top_plate_width-shelf_width], 
                        [shelf_width, corner_size+shelf_width]];

    shelf_perimeter = round_corners(shelf_box_points, method="circle", 
                                   radius=plate_perimeter_rounding_r, $fn=20);
    side_narrowing = 0.3;
    difference()
    {
        translate([top_plate_length/2, top_plate_width/2, stand_height/2])
        difference()
        {
            difference()
            {
                rounded_prism(square([stand_length, stand_width], center=true), 
                    square([top_plate_length+2*top_plate_margin, top_plate_width+2*top_plate_margin], center=true), 
                            height=stand_height, joint_top=1.0, joint_bot=1, joint_sides=5);

                // Hollow out the inside
               rounded_prism(square([hollow_length, hollow_width], center=true), 
                    square([hollow_length, hollow_width], center=true), height=hollow_height, joint_top=hollow_top_r,
                          joint_bot=5, joint_sides=3, $fn=25);

                // Long side punch out
               long_side_punch_out(long_side_punch_out_length, top_plate_margin, hollow_height);
                
                // Short side punch out
                rounded_prism(square([stand_length + 2*(top_plate_margin + difference_tolerance), short_side_punch_out_width], center=true), 
                    apply(scale([1, side_narrowing, 1]),
                    square([stand_length + 2*(top_plate_margin + difference_tolerance), short_side_punch_out_width], center=true)), 
                    height=hollow_height, joint_top=(short_side_punch_out_width*side_narrowing)/2, joint_bot=5, joint_sides=5);
                          
                // Top punch out
                color("magenta")
                translate([-top_plate_length/2, top_plate_width/2, plate_top_height -stand_height/2])
                mirror([0,1,0]) mirror([0, 0, 1])
                offset_sweep(shelf_perimeter,
                     height=plate_thickness_with_shelf+2, steps=22, check_valid=false,
                     bottom=os_teardrop(r=0), top=os_teardrop(r=0));

            }
            
            // Top plate indent
            color("cyan")
            translate([-top_plate_length/2, top_plate_width/2, plate_top_height-stand_height/2])
            mirror([0,1,0]) mirror([0, 0, 1])
            solid_top_plate(sliding_tolerance=0.2);
        }    
        // base plate holes
        translate([-stand_bottom_margin[1], -stand_bottom_margin[1], 0])
        holes_in_base();

    }
}

// This module is only used when the base is divided into 2 parts - it is no longer used
module holder_stand_top()
{
    
    translate([0, 0, top_of_side_hollow]) 
    difference()
    {
        translate([0, 0, -top_of_side_hollow]) 
        intersection()
        {
            color("green")
            translate([0, 0, top_of_side_hollow]) 
            cube([stand_length, stand_width, plate_thickness_with_shelf], center=false);
            
            color("blue")
            translate(stand_bottom_margin)
            complete_holder_stand();
        }
        
        // Put holes in the corners for matching with the base
        for (x = [0:1])
        {
            for (y = [0:1])
            {
                if ((x <= 1 && y == 0) || (x == 0 && y <= 1))
                {
                   translate([top_plate_length*x+stand_bottom_margin[0]+(x==0?-1:1)*plate_recess_wall_thickness/4, 
                               top_plate_width*y+stand_bottom_margin[1]+(y==0?-1:1)*plate_recess_wall_thickness/4, 
                               0])
                        cylinder(h=2*hole_depth, r=max_pin_r+pin_r_tolerance, center=true, $fn=40);
                }
            }
        }

    }

}

// This module is only used when the base is divided into 2 parts - it is no longer used
module holder_stand_base()
{
    // The intersection must be adjusted by a small amount to remove an unwanted overhang of the
    // top of the hollow
    base_intersection_overlap = 0.01;
    
    translate([0, 0, top_of_side_hollow]) 
    union()
    {
        translate([0, 0, -top_of_side_hollow]) 
        intersection()
        {
            color("green")
            cube([stand_length, stand_width, top_of_side_hollow-base_intersection_overlap], center=false);
            
            translate(stand_bottom_margin)
            complete_holder_stand();
            
        }
        
        // Put tapered pins in the corners for matching with the top
        for (x = [0:1])
        {
            for (y = [0:1])
            {
                if ((x <= 1 && y == 0) || (x == 0 && y <= 1))
                {
                    translate([top_plate_length*x+stand_bottom_margin[0]+(x==0?-1:1)*plate_recess_wall_thickness/4, 
                               top_plate_width*y+stand_bottom_margin[1]+(y==0?-1:1)*plate_recess_wall_thickness/4, 
                               pin_height/2-base_intersection_overlap])
                        cylinder(h=pin_height, r1=max_pin_r, r2=pin_taper_scale*max_pin_r, center=true, $fn=40);
                }
            }
        }

    }

}

module selected_top_plate()
{
    if (part_name == "50 ml plate" || (show_assembled && part_name == "stand"))
    {
        tube_plate_50ml();
    }
    else if (part_name == "15 ml plate")
    {
        tube_plate_15ml();
    }
    else if (part_name == "1.5 ml and caps plate")
    {
        tube_plate_1p5_and_caps();
    }
    else if (part_name == "15 and 50 ml plate")
    {
         tube_plate_15_and_50ml();
    }
}

module top_plate_top_at_origin()
{
    translate([-stand_bottom_margin[0], top_plate_width+stand_bottom_margin[0], 0]) 
    mirror([0,1,0]) mirror([0, 0, 1])
    selected_top_plate();
}

module assembled()
{
    union()
    {
        translate([stand_bottom_margin[0], stand_bottom_margin[1], plate_top_height]) 
        top_plate_top_at_origin();
        
        translate(stand_bottom_margin)
        complete_holder_stand();

    }

}

// For debugging
module cutaway_view_of_shelf()
{
    holder_stand_base();
    intersection()
    {
        color("green")
        cube([stand_length, stand_width/2, plate_top_height], center=false);
        holder_stand_top();
    }
    
    intersection()
    {
        color("cyan")
        cube([stand_length, stand_width/2, plate_top_height], center=false);
        
        translate([stand_bottom_margin[0], stand_bottom_margin[1], plate_top_height]) 
        top_plate_top_at_origin();
    }

}

module cutaway_view_of_pins()
{
    intersection()
    {
        translate([0, stand_bottom_margin[1] - top_plate_bottom_round_r/2, 0])
            cube([stand_length, stand_width, stand_height]);
        translate([stand_bottom_margin[0] - top_plate_bottom_round_r/2, 0, 0])
            cube([stand_length, stand_width, stand_height]);
        union()
        {
            color("blue")
                holder_stand_top();
            holder_stand_base();
        }
    }
}

module cutaway_view_of_top_plate()
{
    intersection()
    {
        translate([0, 0, -top_plate_thickness])
        cube([2*top_plate_length, top_plate_width/2, top_plate_thickness*3]);
        top_plate_top_at_origin();
    }
}

module main()
{
    if (show_assembled)
    {
        assembled();
    }
    else
    {
        if (part_name == "stand")
        {
            complete_holder_stand();
        }
        else
        {
           top_plate_top_at_origin();
        }
    }
}

main();

// the rest of the calls are for development
//cutaway_view_of_pins();
//cutaway_view_of_shelf();
//translate([0, 0, -top_of_side_hollow])
//solid_top_plate();
//test_long_side_punch_out();

//hollow_top_plate();
//holder_stand_top();
//holder_stand_base();
//holes_in_base();
//selected_top_plate();

