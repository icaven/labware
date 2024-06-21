/*
    Agitator motor mount for a bioreactor.
    
    Software license:
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
    
    Hardware license:
    CERN Open Hardware Licence Version 2 - Permissive

    Copyright (c) 2024, Ian Cavén
    All rights reserved.
*/

/*
    Download and install BOSL2 from https://github.com/BelfrySCAD/BOSL2
*/
include <BOSL2/std.scad>
include <BOSL2/ball_bearings.scad>
include <BOSL2/nema_steppers.scad>
include <BOSL2/rounding.scad>
include <BOSL2/screws.scad>
include <BOSL2/structs.scad>
include <BOSL2/threading.scad>

// Show a part, or the assembled parts in position
part_to_show = "all"; // ["all","shaft connection post", "shaft coupler", "motor mount","controller_mounting_board", "motor", "impeller shaft flat filing jig"]

/* [View options] */
// Show the parts in their assembled configuration
show_assembly = true;
// Show the parts distributed 
exploded_view = false;
// Show a cross section of the part
show_cross_section_view = "none"; // ["none", "back", "left", "front", "right", "back+left", "front+right"]

/* [Motor specifications] */
// The NEMA motor number
nema_motor_size = 17; // [17, 23]

// The length of the motor shaft
motor_shaft_length = 25;

// Length of the flat part of the D-shaft for both motor and impeller shafts
shaft_flat_length = 16;     

// Length of screws used to mount the motor
motor_screw_length = 8;

// The length of the motor body (used for visualization only)
motor_body_length = 25;

/* [Impeller shaft specifications] */
// Impeller shaft diameter
impeller_shaft_diameter = 6.35; // [5.0, 6.35]

// Screw to hold the impeller shaft to the coupler
impeller_shaft_screw_type = "pan"; // ["set", "pan", "socket"]

// Diameter of screw to hold the shaft coupler to the impeller shaft
impeller_shaft_screw_diameter = 2.5;  // 0.5

// Length of threaded part of the screw
impeller_shaft_screw_length = 9.5; // 0.5

/* [Head plate bearing choice] */
bearing_to_use = "608ZZ"; // ["608ZZ", "R4ZZ", "635ZZ", "685ZZ"]
// Thickness of the walls of the bearing pocket
bearing_pocket_wall_thickness = 2.8; // 0.1

/* [Controller board dimensions] */
// Controller board plate width
controller_board_plate_width = 100;

// Controller board plate length
controller_board_plate_length = 50;

// Controller board plate depth
controller_board_plate_depth = 1;

// Diameter of screw to attach controller board to mount (mm)
controller_board_screw_diameter = 3;

// Length of screw to attach controller board to mount (mm)
controller_board_screw_length = 10;

/* [Other dimensions] */
// Printer layer height (for the Prusa Mini)
layer_height = 0.2; // [0.05, 0.07, 0.1, 0.15, 0.2, 0.25]

// Thickness of the motor mount walls
wall_thickness = 3.0; // [2.0:0.1:5.0]

// Sliding tolerance for parts that fit inside another
sliding_tolerance = 0.1;

// Tolerance at the end of a blind hole
blind_hole_tolerance = 0.25;

// Allow the motor to adjusted slightly in one direction
motor_mounting_plate_adjustment_range = 1;

// For the head plate nut: The printer-specific slop value, which adds clearance 4*slop to internal threads.
slop = 0.10; // 0.01

// For the motor mount internal threads: The printer-specific slop value, which adds clearance 4*slop to internal threads.
mount_slop = 0.20; // 0.01

// For the other screw holes: The printer-specific slop value, which adds clearance 4*slop to internal threads.
screw_hole_slop = 0.05; // 0.01

// Don't need to change anything after this
module __end_of_customizer_variables() {}

difference_tolerance = 0.1;
$fn = 100;    // Default resolution

cross_section_view = show_cross_section_view == "back" ? BACK : 
                     show_cross_section_view == "left" ? LEFT :
                     show_cross_section_view == "front" ? FRONT :
                     show_cross_section_view == "right" ? RIGHT :
                     show_cross_section_view == "back+left" ? BACK+LEFT :
                     show_cross_section_view == "front+right" ? FRONT+RIGHT :
                     BACK;

// For development, certain dimensions are shown with arrows
show_dimension_arrows = false;

// Dimensions of the screw for securing the impeller shaft to coupler
impeller_screw_size = str("M", impeller_shaft_screw_diameter);
impeller_screw_head = impeller_shaft_screw_type == "set" ? "none" : impeller_shaft_screw_type;
impeller_screw_drive = impeller_shaft_screw_type == "pan" ? "phillips" : "hex";

impeller_screw_info = screw_info(impeller_screw_size, impeller_screw_head, impeller_screw_drive);
impeller_screw_head_height = struct_val(impeller_screw_info, "head_height") == undef ? 0 : struct_val(impeller_screw_info, "head_height");
impeller_shaft_total_screw_length = impeller_shaft_screw_length + impeller_screw_head_height;

/*
    Get the information on the nut used to attach the controller board to the motor motor_mount
*/
controller_board_attachment_nut_info = nut_info(str("M", controller_board_screw_diameter));
attachment_nut_cuboid_width = struct_val(controller_board_attachment_nut_info, "width") * 2;
attachment_nut_cuboid_length = controller_board_screw_length - controller_board_plate_depth;
attachment_nut_cuboid_depth = struct_val(controller_board_attachment_nut_info, "width") * 2;

/*
    Get the information on the motor as a list of scalar values, containing, in order:
    MOTOR_WIDTH: The full width and length of the motor.
    PLINTH_HEIGHT: The height of the circular plinth on the face of the motor.
    PLINTH_DIAM: The diameter of the circular plinth on the face of the motor.
    SCREW_SPACING: The spacing between screwhole centers in both X and Y axes.
    SCREW_SIZE: The diameter of the screws.
    SCREW_DEPTH: The depth of the screwholes.
    SHAFT_DIAM: The diameter of the motor shaft.
*/

motor_info = nema_motor_info(nema_motor_size);

// Get the information on the screws used to attach the motor to the mount
screw_spacing = motor_info[3];
screw_size = round(motor_info[4]);
motor_screw_info = screw_info(str("M", screw_size), "socket", "hex");
motor_screw_head_d = struct_val(motor_screw_info, "head_size");
motor_screw_head_height = struct_val(motor_screw_info, "head_height");
motor_screw_head_clearance_d = motor_screw_head_d + 1;
motor_plinth_height = motor_info[1];

// The diameter of the motor shaft diameter ( same as the rod attaching the motor to the impeller)
motor_shaft_diameter = motor_info[6];
motor_shaft_diameter_oversized = motor_shaft_diameter + 2 * sliding_tolerance;
motor_shaft_diameter_at_flat = motor_shaft_diameter_oversized - 0.5;

// Subset from BOSL2 and augmented for additional bearings
// Update this list for those available from local suppliers
function inch_to_mm(x) = 25.4 * x;
selected_bearings_by_trade_size = [
    // trade_size, ID,     OD,      width,  shielded, flanged, fd, fw 
        ["635ZZ", 5, 19, 6, true, false, 0, 0],
        ["685ZZ", 5, 11, 5, true, false, 0, 0],
        ["R4ZZ", inch_to_mm(1 / 4), inch_to_mm(5 / 8), inch_to_mm(0.196), true, false, 0, 0],
        ["608ZZ", 8, 22, 7, true, false, 0, 0],
    ];

bearing_info_index = search([bearing_to_use], selected_bearings_by_trade_size, 1);
assert(bearing_info_index != [], str("Unsupported ball bearing: ", bearing_to_use));
bearing_info = selected_bearings_by_trade_size[bearing_info_index[0]];

// The diameter of the inside of the bearing
bearing_id = bearing_info[1];
// The diameter of the outside of the bearing
bearing_od = bearing_info[2];
// The width of the bearing
bearing_width = bearing_info[3];

assert(bearing_id >= impeller_shaft_diameter, str("Impeller shaft diameter ", impeller_shaft_diameter, " mm",
       " too small for the selected bearing with inner diameter ", bearing_id, " mm"));
bearing_sleeve_height = bearing_id >= impeller_shaft_diameter + 1 ? bearing_width - 0.5 : 0;

// Bearing washer dimensions - this washer supports the shaft coupler resting on the bearing closest
// to the motor
bearing_washer_od = bearing_id + 0.75;
bearing_washer_id = bearing_id; 
bearing_washer_thickness = 1;

// Bearing inner diameter oversize (to be outside of the rotating center)
// Make it half-way between the inner and outer diameters
shaft_clearance_d = (bearing_od - bearing_id)/2 + bearing_id;

shaft_coupler_wall_thickness = 1;
shaft_coupler_d = max(impeller_shaft_diameter + 2 * shaft_coupler_wall_thickness, 
                     impeller_shaft_total_screw_length + shaft_coupler_wall_thickness);

minimum_shaft_coupler_d = max(motor_shaft_diameter_oversized, impeller_shaft_diameter) + sliding_tolerance + 
        2 * shaft_coupler_wall_thickness;
assert(impeller_shaft_total_screw_length > minimum_shaft_coupler_d/2, 
       str("The impeller shaft screw must be at least ", minimum_shaft_coupler_d/2 - impeller_shaft_total_screw_length, " mm longer"));
assert(shaft_coupler_d >= minimum_shaft_coupler_d, 
       str("The shaft coupler diameter must be at least ", minimum_shaft_coupler_d - shaft_coupler_d, " mm larger"));
impeller_shaft_diameter_at_flat = impeller_shaft_diameter - impeller_shaft_diameter / 2;
impeller_max_screw_length_into_shaft = impeller_shaft_diameter/2; // To ensure that the screw can tighten into the shaft

// Allow for a sliding clearance for the bearing
oversized_bearing_or = bearing_od / 2 + sliding_tolerance;
bearing_support_thickness = 2;

// Taper angle is 45 degrees
thickness_of_taper_for_supporting_bearing = bearing_od / 2 - shaft_clearance_d / 2;
thickness_of_tapered_bearing_support = thickness_of_taper_for_supporting_bearing + bearing_support_thickness;

motor_mounting_plate_size = motor_info[0] + motor_screw_head_clearance_d / 2;
collar_od = motor_info[2] + 2 * (wall_thickness + motor_mounting_plate_adjustment_range);
motor_screw_clearance = 0.5;  // Gap between end of screw and bottom of screw hole in motor
motor_mounting_plate_height = max(motor_plinth_height, motor_screw_length - (motor_info[5] - motor_screw_clearance));

// Diameter of connection post plate that rests on the molded head plate 
connection_support_plate_d = nema_motor_size == 17 ? 40 : 50;

// The pitch of the thread used to join the post to the motor mount plate
mounting_plate_thread_pitch = 3;
mounting_plate_thread_depth = mounting_plate_thread_pitch / 2;

// Use the NEMA 17 motor size to compute the spacing of the controller board attachment holes
// so that the spacing will be the fixed
motor_17_info = nema_motor_info(17);
minimum_mounting_plate_size = motor_17_info[0];
controller_board_mounting_hole_spacing = minimum_mounting_plate_size / 2;

motor_mounting_plate_width = max(motor_mounting_plate_size + motor_screw_head_clearance_d / 2,
    minimum_mounting_plate_size + motor_mounting_plate_adjustment_range);
motor_mounting_plate_length = max(motor_mounting_plate_size, minimum_mounting_plate_size);

// Specify other dimensions of the motor and impeller shafts, and the coupler that joins them
space_between_shafts = 6;
dome_space_above_motor_shaft = (motor_shaft_diameter_oversized + sliding_tolerance)/2;
shaft_coupler_height = shaft_flat_length + (shaft_flat_length - bearing_sleeve_height) + dome_space_above_motor_shaft + 
    blind_hole_tolerance + space_between_shafts + bearing_washer_thickness; 

// Maximum overlap between the motor mount post and the shaft post
overlap_height = mounting_plate_thread_pitch * 2.5;

trapezoidal_thread_angle = 45;  // Use this angle to avoid overhangs

// Minimum internal and external heights of the shaft connection post
height_of_chamfer_above_external_threads = mounting_plate_thread_depth;
external_features_height = (connection_support_plate_d - collar_od) + overlap_height;
internal_features_height = bearing_width + shaft_coupler_height + (motor_shaft_length - shaft_flat_length - motor_mounting_plate_height);
connection_post_height = max(external_features_height, internal_features_height);

// This module is used for debugging
module dimension_arrow(length, size, double, orient, anchor)
{
    
    arrow_head_length = min(10, max(length / 5, 2));
    arrow_shaft_length = length - arrow_head_length - (double ? arrow_head_length : 0);
    union()
    {
        recolor("red")
        cylinder(h = arrow_head_length, r1 = size, r2 = 0.1, anchor = TOP, orient = DOWN)

        recolor("blue")
        position(BOTTOM)
        cylinder(h = arrow_shaft_length, r = size / 3, anchor = BOTTOM, orient = DOWN)

        recolor("green")
        position(TOP)
        cylinder(h = double ? arrow_head_length: 0, r1 = size, r2 = 0.1, anchor = BOTTOM, orient = UP);
    }
    
}


// Module: nema_stepper_motor_d_shaft()
// Synopsis: Create a motor with a flat on the motor shaft.
// Usage:
//   nema_stepper_motor_d_shaft(motor_size, motor_body_length, shaft_length, shaft_flat_length, shaft_diameter_at_flat);
// Description:
//   Create the motor with a D shaft.
module nema_stepper_motor_d_shaft(size, body_length, shaft_len, shaft_flat_len, shaft_diameter_at_flat)
{
    motor_info = nema_motor_info(size);
    plinth_height = motor_info[1];
    shaft_diameter = motor_info[6];
    difference()
    {
        nema_stepper_motor(size = nema_motor_size, h = body_length, shaft_len = shaft_len);

        up(shaft_len - shaft_flat_length)
        fwd(shaft_diameter_at_flat)
        cuboid([shaft_diameter, shaft_diameter, shaft_flat_length+difference_tolerance], anchor = BOTTOM);
    }
}

// 
// Module: shaft_connection_post()
// Synopsis: Create the threaded post that supports the impeller shaft with two bearings.
// Usage:
//   shaft_connection_post();
// Description:
//   Create the threaded section that screws into the head plate of the bioreactor, and onto the motor mount.
//   Allows for two bearings to be inserted to support the impeller shaft.
module shaft_connection_post()

{
    
    module transistion_between_bearing_surround_and_post(anchor)
    {
        attachable(h=connection_support_plate_d - collar_od, d=connection_support_plate_d, anchor=anchor, orient=UP)
        {
            diff("chamfer")
            {
                cylinder(h = connection_support_plate_d - collar_od, d = connection_support_plate_d,
                        anchor = CENTER, $fn=200, $fa = 1, $fs = 1)
                
                // Tapered support for the post above the threaded section        
                tag("chamfer")
                attach([TOP])
                chamfer_cylinder_mask(d = connection_support_plate_d, 
                                     chamfer = (connection_support_plate_d - collar_od)/2, anchor=CENTER, orient = UP,
                                     $fn=200);
            }
            children();
        }
    }
    
    module transistion_between_post_and_thread(anchor)
    {
        attachable(h=connection_post_height - external_features_height, d=collar_od, anchor=anchor, orient=UP)
        {
            diff("chamfer")
            {
                cylinder(h = connection_post_height - external_features_height, d = collar_od,
                        anchor = CENTER, $fa = 1, $fs = 1)
                
                // Tapered support for the post above the threaded section        
                tag("chamfer")
                attach([TOP])
                chamfer_cylinder_mask(d = collar_od, chamfer = height_of_chamfer_above_external_threads, anchor=CENTER, orient = UP);
            }
            children();
        }
    }
    
    // Hollow threaded part - printed bearing pocket at the top
    up(connection_post_height)
    xrot(180)
    difference()
    {
        // Build the exterior features bottom up
        union()
        {
            transistion_between_bearing_surround_and_post(BOTTOM)
            
            position(TOP)
            transistion_between_post_and_thread(BOTTOM)
            
            // The overlap threaded section
            position(TOP)
            trapezoidal_threaded_rod(d = collar_od, height = overlap_height,
                                    pitch = mounting_plate_thread_pitch, thread_depth = mounting_plate_thread_depth,
                                    thread_angle = trapezoidal_thread_angle, internal = false, starts = 1, $fa = 1, 
                                    $fs = 1, $fn = 100, blunt_start = true, anchor = BOTTOM);
        }

        union()
        {
            // Hollow out the full length of the part
            down(difference_tolerance)
            cylinder(h = connection_post_height + 2 * difference_tolerance, d = shaft_clearance_d,
                    anchor = BOTTOM, $fa = 1, $fs = 1);
            
            // Hollow out the space for the bearing pocket
            down(difference_tolerance)
            cylinder(h = bearing_width + difference_tolerance, 
                     d = bearing_od + 2 * (bearing_pocket_wall_thickness + sliding_tolerance), 
                     anchor = BOTTOM, $fa = 1, $fs = 1);
            
            // Inscribe the motor size
            text_depth = 1;
            motor_text_path = path3d(arc(n = 100, d = collar_od - text_depth / 2, angle = [0, 150]));
            motor_size_text_height = 4;
            up(2 * overlap_height)
            path_text(motor_text_path, str("NEMA ", nema_motor_size), h = text_depth, size = motor_size_text_height,
                     center = true, valign = "bottom", textmetrics = true);
        }
    }

}

// This is an inserted part used to support the bearing that is closest to the motor
// When printed, it is scaled to be smaller in the x and y directions to allow for a sliding fit.
// Use full size for making the space for it.
module tapered_bearing_support(scale_part_smaller_for_sliding_fit = false)
{
    sliding_fit_tolerance = 0.05;
    scale_factor = scale_part_smaller_for_sliding_fit ? (bearing_od / 2 - sliding_fit_tolerance) / (bearing_od / 2) : 1.;

    diff()
    {
        cylinder(h = thickness_of_taper_for_supporting_bearing + bearing_support_thickness,
        d = scale_factor * bearing_od, anchor = BOTTOM, $fa = 1, $fs = 1, $fn = 100)

        attach([TOP])
        chamfer_cylinder_mask(r = scale_factor * bearing_od / 2, 
                              chamfer = thickness_of_taper_for_supporting_bearing );
    }
}

// This is a part to mark where to file the flats onto the ends of the impeller shaft
module impeller_shaft_flat_filing_jig(shaft_clearance_tolerance = 0.2)
{
    jig_height = 2 * shaft_flat_length;
    shaft_r_with_clearance = impeller_shaft_diameter / 2 + shaft_clearance_tolerance;
    impeller_shaft_mask_dims = [
                               impeller_shaft_diameter_at_flat + 2 * wall_thickness,
                               impeller_shaft_diameter + 3 * wall_thickness,
                               shaft_flat_length + bearing_washer_thickness + difference_tolerance
                               ];
    
    difference() {
        cylinder(h = jig_height, r = shaft_r_with_clearance + wall_thickness, anchor = BOTTOM, $fn = 100);
        
        down(difference_tolerance)
        cylinder(h = jig_height + 2 * difference_tolerance,
                r = impeller_shaft_diameter / 2 + shaft_clearance_tolerance, anchor = BOTTOM, $fa = 1, $fs = 1);
        
        up(jig_height + difference_tolerance)
        left((impeller_shaft_diameter - impeller_shaft_diameter_at_flat) / 2 + wall_thickness)
        cuboid(impeller_shaft_mask_dims, anchor = TOP, $fa = 1, $fs = 1);
    }
    
}

// This is an attached part used to support the shaft coupler inside the bearing that is 
// closest to the motor.
module bearing_washer(with_shaft_fastener = false, with_bearing_washer = true)
{
    difference()
    {
        union()
        {
            if (with_shaft_fastener && bearing_sleeve_height > 0)
            {
                recolor("blue")
                difference()
                {
                    cylinder(h = bearing_width, r = bearing_washer_od / 2, anchor = TOP, $fn = 100);

                    // Make a hole for a screw that will hold the washer to the impeller shaft
                    down(bearing_width / 2)
                    yrot(90)
                    screw_hole(str("M", impeller_shaft_screw_diameter, "x0.25"), thread = true,
                    length = bearing_washer_od / 2, head = "none", anchor = TOP, $slop=screw_hole_slop);
                }
            }

            // Only render a washer if the it is for the shaft coupler
            recolor("orange")
            cylinder(h = with_bearing_washer ? bearing_washer_thickness : 0, 
            r = bearing_washer_od / 2, anchor = BOTTOM, $fn = 100)
            
            recolor("red")
            position(TOP)
            cylinder(h = bearing_sleeve_height, r = bearing_washer_id / 2,
            anchor = BOTTOM, $fn = 100);
        }
        if (with_shaft_fastener)
        {
            // Hollow out the inside
            up(bearing_washer_thickness/2-2*difference_tolerance)
            cylinder(h = bearing_width + bearing_sleeve_height + bearing_washer_thickness + 2 * difference_tolerance,
            r = impeller_shaft_diameter / 2, anchor = CENTER, $fa = 1, $fs = 1, $fn = 100);
        }
    }

}


module shaft_coupler()
{
    shaft_coupler_height_without_washer = shaft_coupler_height - bearing_washer_thickness;
    bearing_bushing_thickness = bearing_width + bearing_washer_thickness;
    if (show_dimension_arrows)
    {
        fwd(bearing_id / 2)
        right(bearing_id / 2)
        %dimension_arrow(shaft_coupler_height, 3, double = true, anchor = BOTTOM);
    }

    if (show_assembly)
    {
        // Show the impeller shaft screw in place
        color("grey")
        up(shaft_coupler_height - min(shaft_flat_length / 2, 2 * impeller_shaft_screw_diameter))
        fwd(shaft_coupler_d / 2 + (exploded_view ?  impeller_shaft_total_screw_length : 0))
        xrot(90)
        screw(impeller_screw_size, head=impeller_screw_head, drive=impeller_screw_drive, 
        length = impeller_shaft_screw_length, anchor = TOP);
    }

//    echo("shaft_coupler_d = ", shaft_coupler_d);
//    echo("impeller_shaft_total_screw_length = ", impeller_shaft_total_screw_length);
    difference()
    {
        union() {
            cylinder(h = shaft_coupler_height_without_washer, r = shaft_coupler_d / 2,
            anchor = BOTTOM, $fa = 1, $fs = 1)
            
            // There is an extension to the cylinder for the bearing washer that fits inside the bearing
            position(TOP)
            bearing_washer(with_shaft_fastener = false, true);
        }

        // Make a hole for a screw that will hold the shaft coupler to the impeller shaft by screwing into the latter
        back(shaft_coupler_d/2-shaft_coupler_wall_thickness)
        up(shaft_coupler_height - min(shaft_flat_length / 2, 2 * impeller_shaft_screw_diameter))
        xrot(90)
        screw_hole(impeller_screw_size, thread = true, length = impeller_shaft_screw_length, head = impeller_screw_head, 
                  counterbore = impeller_screw_head_height > 0 ? impeller_screw_head_height : false, 
                  teardrop = true, oversize = [0, impeller_screw_head_height > 0 ? 0.25: 0], anchor = BOTTOM, 
                  $slop=screw_hole_slop);
        
        union()
        {
            // Create the motor shaft mask
            motor_shaft_mask_dims = [motor_shaft_diameter_oversized+sliding_tolerance, motor_shaft_diameter_oversized+sliding_tolerance, 
                    shaft_flat_length];
            down(difference_tolerance)
            difference()
            {
                cylinder(h = shaft_flat_length, r = (motor_shaft_diameter_oversized + sliding_tolerance) / 2,
                anchor = BOTTOM, $fa = 1, $fs = 1);
                fwd(motor_shaft_diameter_at_flat+sliding_tolerance)
                cuboid(motor_shaft_mask_dims, anchor = BOTTOM, $fa = 1, $fs = 1);
            }
            
            // Dome the top of the shaft hole to reduce the overhang
            up(shaft_flat_length) 
            onion(d=motor_shaft_diameter_oversized + sliding_tolerance, cap_h=dome_space_above_motor_shaft);
            
            // Construct the impeller shaft mask
            impeller_shaft_mask_dims = [impeller_shaft_diameter + sliding_tolerance * 2, 
                    impeller_shaft_diameter + sliding_tolerance * 2, 
                    shaft_flat_length + blind_hole_tolerance
                ];
            up(shaft_coupler_height + bearing_sleeve_height - shaft_flat_length)
            difference()
            {
                cylinder(h = shaft_flat_length + blind_hole_tolerance, r = impeller_shaft_diameter / 2 + sliding_tolerance,
                         anchor = BOTTOM, $fa = 1, $fs = 1);
                
                fwd(impeller_shaft_diameter_at_flat+sliding_tolerance)
                cuboid(impeller_shaft_mask_dims, anchor = BOTTOM, $fa = 1, $fs = 1);
            }
        }
            
        // Inscribe the details about the screw on the shaft coupler 
        text_depth = 1;

        screw_specs_labels = [str("dia ", impeller_shaft_screw_diameter), 
            str("len ", impeller_shaft_screw_length), 
            impeller_shaft_screw_type
            ];
        screw_specs_text_height = 2.5;
        text_z = shaft_coupler_height - 3 * impeller_shaft_screw_diameter - screw_specs_text_height;
        for (i = [0:len(screw_specs_labels)-1])
        {
            path = path3d(arc(n=100, d=shaft_coupler_d - text_depth / 2, angle=[-60, 60]));
            up(text_z - 1.5*i*screw_specs_text_height)
            zrot(-90)
            path_text(path, screw_specs_labels[i], h=text_depth, size=screw_specs_text_height, center=true, 
                      textmetrics=true);
        }

        
        // Inscribe the motor shaft and impeller shaft diameters
        path = path3d(arc(n=100, d=shaft_coupler_d - text_depth / 2, angle=[0, 240]));
        specs_text_height = 2.5;
        up(shaft_coupler_height - bearing_washer_thickness - specs_text_height)
        path_text(path, str("dia ", impeller_shaft_diameter, " mm"), h = text_depth, size = specs_text_height, center = true,
        valign="top", textmetrics = true);

        up(1.5* specs_text_height)
        path_text(path, str("dia ", motor_shaft_diameter, " mm"), h = text_depth, size = specs_text_height, center = true,
        valign="bottom", textmetrics = true);
        
        up(3* specs_text_height)
        path_text(path, str("len ", motor_shaft_length, " mm"), h = text_depth, size = specs_text_height, center = true,
        valign="bottom", textmetrics = true);

    }

    children();

}

// Module: controller_board_attachment_nut_trap()
// Synopsis: Nut trap.
// Usage:
//   controller_board_attachment_nut_trap();
// Description:
//   The controller board is attached to the motor mount with a couple of cubes each with a nut trap.
module controller_board_attachment_nut_trap()
{
    up(attachment_nut_cuboid_depth / 2)
    {
        difference()
        {
            cuboid([attachment_nut_cuboid_width, attachment_nut_cuboid_length, attachment_nut_cuboid_depth],
            rounding = 0.6, edges = [FRONT, "Y"], except = BOT, anchor = CENTER);
            xrot(90)
            {
                screw_hole(str("M", controller_board_screw_diameter), length = controller_board_screw_length, 
                           $slop=screw_hole_slop)
                up(2) position(BOT)
                zrot(90)
                nut_trap_side(trap_width = attachment_nut_cuboid_width + 2, poke_len = attachment_nut_cuboid_width +
                    motor_mounting_plate_height);
            }
        }

        if (show_assembly)
        {
            // Show the screw and nut in place
            color("grey")
            back(attachment_nut_cuboid_length / 2 - (exploded_view ? controller_board_screw_length + 5 : 0))
            xrot(90)
            screw(str("M", controller_board_screw_diameter), "socket", "hex", length = controller_board_screw_length,
            anchor = BOTTOM);

            color("grey")
            up((exploded_view ? attachment_nut_cuboid_depth + 5 : 0))
            back(struct_val(controller_board_attachment_nut_info, "thickness") / 4)
            zrot(90)
            yrot(90)
            nut(str("M", controller_board_screw_diameter), thickness = "normal", anchor = BOT);
        }
    }
}

// Module: controller_board_mounting_plate()
// Synopsis: The plate that the motor controller electronics will be mounted onto.
// Usage:
//   controller_board_mounting_plate();
// Description:
//   The plate that the motor controller electronics will be mounted onto.
//   Attached by screws to the motor mount.
module controller_board_mounting_plate()
{
    difference()
    {
        // The rounded controller mounting plate
        down(controller_board_plate_depth / 2)
        linear_extrude(height = controller_board_plate_depth)
        polygon(round_corners(square([controller_board_plate_width, controller_board_plate_length], center =
        true), cut = 1, $fn = 96 * 4));

        // Make holes for the screws that will be used to attach controller board
        for (socket_index = [-1, 1])
        {
            fwd(0.5 * socket_index * controller_board_mounting_hole_spacing)
            right(controller_board_plate_width / 2 - attachment_nut_cuboid_depth / 2)
            screw_hole(str("M", controller_board_screw_diameter), length = controller_board_plate_depth * 3,
            anchor = CENTER, $slop=screw_hole_slop);
        }

    }
}

// Internal module to test the threads used to connect the shaft_connection_post to the motor_mount
module motor_mount_test_threads()
{
    label_parts = true;
    text_depth = 1;

    // Threaded part of the mount
    difference()
    {
        union()
        {
            // Hollow tube below the external threaded section
            cylinder(h = overlap_height, r = collar_od / 2 + (wall_thickness + mounting_plate_thread_depth),
            anchor = BOTTOM, $fa = 1, $fs = 1);
        }

        union()
        {
            // Hollow out the tube threads
            zrot(180)
            trapezoidal_threaded_rod(d = collar_od, height = overlap_height, pitch = mounting_plate_thread_pitch,
            thread_depth = mounting_plate_thread_depth, thread_angle = trapezoidal_thread_angle, internal = true, starts = 1,
            $fa = 1, $fs = 1, $fn = 100, blunt_start = true, anchor = BOTTOM, $slop = mount_slop)

            position(TOP)
            down(difference_tolerance)
            cylinder(h = 2 * difference_tolerance,
            r = collar_od / 2,
            anchor = BOTTOM, $fa = 1, $fs = 1);

            up(motor_mounting_plate_height)
            cylinder(h = difference_tolerance, r = collar_od / 2, anchor = TOP, $fa = 1, $fs = 1);

            if (label_parts)
            {
                // Inscribe the details about the threads on the mount nut 
                nut_labels = [str("D", collar_od), str("P", mounting_plate_thread_pitch), str("L",
                overlap_height), str("S", mount_slop)];
                for (i = [0:len(nut_labels)])
                {
                    zrot(60 * i)
                    fwd(collar_od / 2 + (wall_thickness + mounting_plate_thread_depth) - text_depth / 2)
                    up(overlap_height / 2)
                    xrot(90)
                    linear_extrude(text_depth)
                    text(nut_labels[i], size = overlap_height * 0.5, halign = "center",
                    valign = "center", $fn = 100);
                }
            }

        }

    }

    test_post_height = overlap_height + 5;
    switch_between_assembled = show_assembly ? 1 : 0;
    // Threaded part of the post
    left((1 - switch_between_assembled) * collar_od * 2)
    up(test_post_height)
    difference()
    {
        union()
        {
            // Attach the first exterior features top-down
            union()
            {
                // The spacing between the bearings above the taper        
                cylinder(h = test_post_height - mounting_plate_thread_depth - overlap_height, r = collar_od / 2, anchor = TOP, $fa = 1,
                $fs = 1)

                // Tapered support for the post above the threaded section        
                position(BOTTOM)
                cylinder(h = mounting_plate_thread_depth, r2 = collar_od / 2,
                r1 = collar_od / 2 - mounting_plate_thread_depth, anchor = TOP, $fa = 1, $fs = 1)

                position(BOTTOM)
                trapezoidal_threaded_rod(d = collar_od, height = overlap_height,
                pitch = mounting_plate_thread_pitch, thread_depth = mounting_plate_thread_depth,
                thread_angle = trapezoidal_thread_angle, internal = false, starts = 1, $fa = 1, $fs = 1, $fn = 100,
                blunt_start = true,
                anchor = TOP);
            }

        }

        // Hollow out the test part
        up(difference_tolerance)
        cylinder(h = test_post_height + difference_tolerance, r = collar_od / 2 - wall_thickness,
        anchor = TOP, $fa = 1, $fs = 1);

        if (label_parts)
        {
            // Inscribe the details about the threads on the post 
            post_labels = [str("D", collar_od), str("P", mounting_plate_thread_pitch), str("L", overlap_height)];
            for (i = [0:len(post_labels)])
            {
                zrot(60 * i)
                fwd(collar_od / 2 - text_depth / 2)
                down((test_post_height - overlap_height) / 2)
                xrot(90)
                linear_extrude(text_depth)
                text(post_labels[i], size = (test_post_height - overlap_height) * 0.5, halign = "center",
                valign = "center", $fn = 100);
            }
        }

    }

}


// Module: motor_mount()
// Synopsis: Creates a threaded plate to mount a motor to.
// Usage:
//   motor_mount();
// Description:
//   Creates a threaded plate to mount a motor to.
module motor_mount()
{
    // Create the threaded holder (upside down)
    difference()
    {
        up(motor_mounting_plate_height)
        union()
        {
            // Hollow tube below the external threaded section
            cylinder(h = overlap_height,
            r = collar_od / 2 + (wall_thickness + mounting_plate_thread_depth),
            anchor = BOTTOM, $fa = 1, $fs = 1);

        }

        union()
        {
            // Hollow out the tube threads
            up(motor_mounting_plate_height)
            zrot(180)
            trapezoidal_threaded_rod(d = collar_od, height = overlap_height, pitch = mounting_plate_thread_pitch,
            thread_depth = mounting_plate_thread_depth, thread_angle = trapezoidal_thread_angle, internal = true, starts = 1,
            $fa = 1, $fs = 1, $fn = 100, blunt_start = true, anchor = BOTTOM, $slop = mount_slop)

            position(TOP)
            down(difference_tolerance)
            cylinder(h = 2 * difference_tolerance, r = collar_od / 2+ mounting_plate_thread_depth/2, anchor = BOTTOM, 
                    $fa = 1, $fs = 1);

            up(motor_mounting_plate_height+difference_tolerance)
            cylinder(h = 2*difference_tolerance, r = collar_od / 2, anchor = TOP, $fa = 1, $fs = 1);
        }

        // Cut out parts of the support tube if motor screw clearance is needed
        for (screw_x = [-1, 1])
        {
            for (screw_y = [-1, 1])
            {
                up((motor_mounting_plate_height + motor_screw_length + motor_screw_head_height) / 2)
                fwd(screw_y * screw_spacing / 2)
                right(screw_x * screw_spacing / 2)
                union()
                {
                    cylinder(h = motor_screw_length + motor_screw_head_height, r = motor_screw_head_clearance_d
                        / 2, center = true);
                    up((motor_screw_length + motor_screw_head_height) / 2)
                    sphere(r = motor_screw_head_clearance_d / 2);
                }
            }
        }
        
        // Inscribe the motor size
        text_depth = 1;
        motor_text_path = path3d(arc(n=100, d = collar_od + 2*(wall_thickness + mounting_plate_thread_depth) - text_depth/2, angle=[0, 180]));
        motor_size_text_height = overlap_height/2;
        up(motor_mounting_plate_height+overlap_height/2)
        path_text(motor_text_path, str("NEMA ", nema_motor_size), h = text_depth, size = motor_size_text_height, center = true,
        valign="center", textmetrics = true);

    }

    adjusted_plate_width = motor_mounting_plate_width + motor_mounting_plate_adjustment_range / 2 + attachment_nut_cuboid_length / 2;
    adjusted_dimensions = [motor_mounting_plate_length, adjusted_plate_width];
    plate_outline = square(adjusted_dimensions, center = true);
    motor_mounting_plate_path = round_corners(plate_outline, cut = 3, $fn = 96 * 4);
    front_edge_location = max(max(minimum_mounting_plate_size, motor_mounting_plate_width), collar_od +
        attachment_nut_cuboid_width) / 2;
    up(motor_mounting_plate_height / 2)
    union()
    {
        difference()
        {
            // The rounded motor plate with the area for the screw mounting cubes 
            down(motor_mounting_plate_height / 2)
            union()
            {
                linear_extrude(height = motor_mounting_plate_height)
                polygon(motor_mounting_plate_path);

                fwd((front_edge_location))
                linear_extrude(height = motor_mounting_plate_height)
                polygon(round_corners(square([attachment_nut_cuboid_width +
                    controller_board_mounting_hole_spacing,
                    attachment_nut_cuboid_length], center = true), cut = 0.25, $fn = 96 * 4));

            }

            // Cut out the slots for mounting the motor
            nema_mount_mask(size = nema_motor_size, depth = motor_mounting_plate_height + 1, l =
            motor_mounting_plate_adjustment_range, $fn = 100);

            // Put poke holes in the mounting plate to push the nuts for the controller board attachment screws
            for (socket_index = [-1, 1])
            {
                // Add a socket for the clip that will be used to attach the controller board
                right(0.5 * socket_index * controller_board_mounting_hole_spacing)
                down(motor_mounting_plate_height)
                fwd(front_edge_location - struct_val(controller_board_attachment_nut_info, "thickness") * 0.75)
                cylinder(h = motor_mounting_plate_height * 4, r = struct_val(
                controller_board_attachment_nut_info, "thickness") / 2);
            }

            // Add the author's name
            text_depth = 1;
            motor_mounting_plate_text_path = round_corners(plate_outline, cut = 3, $fn = 96 * 4);
            path = path3d(reverse(motor_mounting_plate_text_path));
            path_text(path, "Designed by Ian Cavén 2024", h = text_depth, size = motor_mounting_plate_height / 2,
            center = true, valign = "bottom", textmetrics = true, font = "Helvetica");
        }

        for (socket_index = [-1, 1])
        {
            // Add a cube with the nut trap that will be used to attach the controller board
            right(0.5 * socket_index * controller_board_mounting_hole_spacing)
            up(motor_mounting_plate_height / 2)
            fwd(front_edge_location)
            controller_board_attachment_nut_trap();
        }
    }

}

// Module: assembled()
// Synopsis: Internal module to show the assembled connection post and parts.
// Usage:
//   assembled();
// Description:
//   Displays the parts.
module assembled()
{
    // Show the screws that secure the motor - this is done separately from the distributed parts since they are
    // above the motor mount
    screw_bottom_position = exploded_view ? motor_screw_length + 5 : motor_mounting_plate_height -
        motor_screw_length;
    for (screw_x = [-1, 1])
    {
        for (screw_y = [-1, 1])
        {
            color("grey")
            up(screw_bottom_position)
            fwd(screw_y * screw_spacing / 2)
            right(screw_x * screw_spacing / 2)
            screw(str("M", screw_size), "socket", "hex", length = motor_screw_length, anchor = BOTTOM);
        }
    }
    
    part_heights_above_motor = [
                               (motor_shaft_length - shaft_flat_length), // 0: bottom of shaft coupler
                               motor_mounting_plate_height, // 1: bottom of connection post
                               (motor_shaft_length - shaft_flat_length) + shaft_coupler_height // 2: bottom of bearing
                               ];
    
    distribution_spacing = exploded_view ? [motor_shaft_length,
                                           shaft_coupler_height, connection_post_height,
                                           bearing_width
                                           ] : [0, 0, 0, 0];
    up(exploded_view ? motor_shaft_length : 0)
    back_half(s=show_dimension_arrows ? 350 : 0)
    distribute(spacing = 0, sizes = distribution_spacing, dir = UP)
    {
        nema_stepper_motor_d_shaft(nema_motor_size, motor_body_length, motor_shaft_length, shaft_flat_length,
        motor_shaft_diameter_at_flat);

        up(part_heights_above_motor[0])
        shaft_coupler();
        
        half_of(cross_section_view, s = show_cross_section_view == "none" ? 0 : 350)
        up(part_heights_above_motor[1] + (exploded_view ? bearing_width : 0))
        shaft_connection_post();
        
        up(part_heights_above_motor[2])
        ball_bearing(id = bearing_id, od = bearing_od, width = bearing_width, shield = true, flange = false, 
                    $fn = 72, anchor = BOTTOM);
    }
}

module show_part()
{
    if (part_to_show == "all")
    {
        if (show_assembly)
        {
            xrot(180)  // Show the assembly in the orientation that it will be used in
            {
                motor_mount();
                
                // Show the controller board
                board_back_face_location = max(max(minimum_mounting_plate_size, motor_mounting_plate_width),
                                              collar_od + attachment_nut_cuboid_width) / 2 +
                        controller_board_plate_depth / 2 + attachment_nut_cuboid_length / 2;
                
                color([0, 1, 0, 0.5])
                fwd(board_back_face_location)
                down(controller_board_plate_width / 2 - motor_mounting_plate_height - attachment_nut_cuboid_depth)
                zrot(90) yrot(-90)
                controller_board_mounting_plate();
                
                assembled();
            }
        }
        else
        {
            // Show all the parts to be printed
            distribution_spacing = [shaft_coupler_d, motor_mounting_plate_width, connection_support_plate_d, 
                                   impeller_shaft_diameter, controller_board_plate_length];
            distribute(spacing = 10, sizes = distribution_spacing, dir = RIGHT)
            {
                shaft_coupler();
                motor_mount();
                shaft_connection_post();
                impeller_shaft_flat_filing_jig();
                zrot(90) controller_board_mounting_plate();
            }
        }
        
    }
    else if (part_to_show == "shaft coupler")
    {
        if (show_assembly)
        {
            distribution_spacing = exploded_view ? [-motor_shaft_length, -shaft_coupler_height] : [0, 0];
            distribute(spacing = 0, sizes = distribution_spacing, dir = UP)
            {
                half_of(cross_section_view, s = show_cross_section_view == "none" ? 0 : 200)
                
                up(motor_shaft_length - shaft_flat_length)
                shaft_coupler();
                
                nema_stepper_motor_d_shaft(nema_motor_size, motor_body_length, motor_shaft_length, shaft_flat_length,
                                          motor_shaft_diameter_at_flat);
            }
        }
        else
        {
            half_of(cross_section_view, s = show_cross_section_view == "none" ? 0 : 200)
            shaft_coupler();
        }
        
    }
    else if (part_to_show == "motor mount")
    {
        motor_mount();
        
        if (show_assembly)
        {
            assembled();
        }
        
    }
    else if (part_to_show == "shaft connection post")
    {
        if (show_assembly)
        {
            motor_mount();
        }
        half_of(cross_section_view, s = show_cross_section_view == "none" ? 0 : 350)
        up((show_assembly ? motor_mounting_plate_height + (exploded_view ? 10 : 0) : 0))
        shaft_connection_post();
        
    }
    else if (part_to_show == "tapered bearing support")
    {
        half_of(cross_section_view, s = show_cross_section_view == "none" ? 0 : 350)
        difference()
        {
            tapered_bearing_support(true);
            
            down(difference_tolerance)
            cylinder(h = thickness_of_taper_for_supporting_bearing + bearing_support_thickness + 2 *
                difference_tolerance,
                    r = shaft_clearance_d / 2, anchor = BOTTOM, $fa = 1, $fs = 1, $fn = 100);
        }
    }
    
    else if (part_to_show == "controller_mounting_board")
    {
        controller_board_mounting_plate();
    }
    else if (part_to_show == "impeller shaft flat filing jig")
    {
        impeller_shaft_flat_filing_jig();
    }
    else if (part_to_show == "motor")
    {
        nema_stepper_motor_d_shaft(nema_motor_size, motor_body_length, motor_shaft_length, shaft_flat_length,
                                  motor_shaft_diameter_at_flat);
    }
/*
        // For testing the thread fit only
    else if (part_to_show == "motor_mount_test_threads")
    {
        if (show_assembly)
        {
            half_of(cross_section_view, s = show_cross_section_view == "none" ? 0 : 350)
            motor_mount_test_threads();
        }
        else
        {
            motor_mount_test_threads();
        }
    }
*/
/*
    else if (part_to_show == "test")
    {
        
    }
*/
}

show_part();

