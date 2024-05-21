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
part_to_show = "all, assembled"; // ["all, assembled", "motor_mount_test_threads", "threaded post", "tapered bearing support", "shaft coupler", "motor mount", "nut", "bearing bushing", "controller_mounting_board", "impeller shaft flat filing jig"]

/* [NEMA motor specifications] */
// The NEMA motor number
nema_motor_size = 17; // [11, 14, 17, 23]

// The length of the motor shaft
motor_shaft_length = 24;

// Length of screws used to mount the motor
motor_screw_length = 8;

// Impeller shaft diameter
impeller_shaft_diameter = 6.50;

// The length of the motor body (used for visualization only)
motor_body_length = 59;

/* [Bearing dimensions] */
bearing_choice = "608ZZ"; // ["635ZZ", "685ZZ", "R4ZZ", "608ZZ"]
// Bearing outer diameter oversize
bearing_od_oversize = 0.1;

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
// Thickness of the motor mount walls
wall_thickness = 3.0; // [2.0:0.1:5.0]

// Thickness of the head plate that the mount will screw into
head_plate_thickness = 15;

// Allow the motor to adjusted slightly in one direction
motor_mounting_plate_adjustment_range = 2;

// For the head plate nut: The printer-specific slop value, which adds clearance 4*slop to internal threads.
slop = 0.10; // 0.01

// For the motor mount internal threads: The printer-specific slop value, which adds clearance 4*slop to internal threads.
mount_slop = 0.20; // 0.01

// Show the parts in their assembled configuration
show_assembly = true;
exploded_view = false;

// Don't need to change anything after this
module __end_of_customizer_variables() {}

// Specification of the thread for the motor mount rod and nut
post_nut_height = 10;
nut_diameter = 47;
mount_thread_pitch = 1.;
mount_thread_depth = 5/8 * cos(30) * mount_thread_pitch;  // For a ISO metric thread

// Diameter of the part that screws into the head plate
head_plate_post_d = 30;

rod_o_ring_od = head_plate_post_d + 10;

// Diameter of set screws for impeller 
set_screw_diameter = 2;

difference_tolerance = 0.1;
$fn=100;    // Default resolution

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

// The diameter of the motor shaft diameter ( same as the rod attaching the motor to the impeller)
motor_shaft_diameter = motor_info[6];
echo("Motor shaft diameter: ", motor_shaft_diameter);
motor_shaft_diameter_at_flat = motor_shaft_diameter - 0.5;

// Subset from BOSL2 and augmented for additional bearings
// Update this list for those available from local suppliers
inch_to_mm = 25.4;
selected_bearings_by_trade_size = [
     // trade_size, ID,     OD,      width,  shielded, flanged, fd, fw 
    [   "635ZZ",    5,      19,      6,      true,     false,   0,  0 ],
    [   "685ZZ",    5,      11,      5,      true,     false,   0,  0 ],
    [   "R4ZZ",  1/4*inch_to_mm,  5/8*inch_to_mm, 0.196*inch_to_mm, true,    false,   0,  0  ],
    [   "608ZZ",    8,      22,      7,      true,     false,   0,  0 ],
];

bearing_to_use = bearing_choice;
echo("Bearing to use: ", bearing_to_use);

bearing_info_index = search([bearing_to_use], selected_bearings_by_trade_size, 1);
assert(bearing_info_index!=[], str("Unsupported ball bearing: ", bearing_to_use));
bearing_info = selected_bearings_by_trade_size[bearing_info_index[0]];

// The diameter of the inside of the bearing
bearing_id = bearing_info[1];
// The diameter of the outside of the bearing
bearing_od = bearing_info[2];
// The width of the bearing
bearing_width= bearing_info[3];

// The impeller shaft will be fitted inside the bearing with a part that has a minimum 0.5 mm thickness
assert (bearing_id >= impeller_shaft_diameter + 1, "Bearing inner diameter must be at least 1 mm larger than the impeller shaft");

// The distance from the bottom of one bearing to the bottom of the other
distance_between_bearings = 50;

// Bearing washer dimensions - this washer supports the shaft coupler resting on the bearing closest
// to the motor
bearing_washer_od = bearing_id + 0.75;
//bearing_washer_insert_thickness = bearing_id - motor_shaft_diameter/2;
bearing_washer_id = bearing_id; // - 2* bearing_washer_insert_thickness;
bearing_washer_thickness = 1;

// Bearing inner diameter oversize (to be outside of the rotating center)
// Make it half-way between the inner and outer diameters
shaft_clearance_d = (bearing_od - bearing_id)/2 + bearing_id;

shaft_coupler_wall_thickness = 4;
shaft_coupler_d = max(motor_shaft_diameter, impeller_shaft_diameter) + 2*shaft_coupler_wall_thickness;
assert (shaft_clearance_d >= shaft_coupler_d, str("Shaft clearance diameter must be no more than ", 
        shaft_coupler_d - shaft_clearance_d, " mm larger than the shaft coupler diameter"));
//echo("shaft_coupler_d", shaft_coupler_d, "impeller_shaft_diameter", impeller_shaft_diameter, 
//"motor_shaft_diameter", motor_shaft_diameter, "shaft_clearance_d", shaft_clearance_d);
impeller_shaft_diameter_at_flat = impeller_shaft_diameter - impeller_shaft_diameter/2;

// Allow for a sliding clearance for the bearing
oversized_bearing_or = bearing_od/2 + bearing_od_oversize;
bearing_support_thickness = 2;

// Taper angle is 45 degrees
thickness_of_taper_for_supporting_bearing = oversized_bearing_or - shaft_clearance_d/2;
thickness_of_tapered_bearing_support = thickness_of_taper_for_supporting_bearing + bearing_support_thickness;

motor_mounting_plate_size = motor_info[0] + motor_screw_head_clearance_d/2;
collar_od = motor_info[2] + wall_thickness * 3 + motor_mounting_plate_adjustment_range * 2;
motor_screw_clearance = 0.5;  // Gap between end of screw and bottom of screw hole in motor
motor_mounting_plate_height = max(motor_info[1], motor_screw_length - (motor_info[5] - motor_screw_clearance));

// The pitch of the thread used to join the post to the motor mount plate
mounting_plate_thread_pitch = 3;
internal_thread_depth = mounting_plate_thread_pitch/2;
threaded_rod_inside_r = head_plate_post_d/ 2 - wall_thickness - mount_thread_depth + internal_thread_depth + shaft_clearance_d/2;
internal_thread_height = 2*bearing_support_thickness + bearing_width + 2;

// Use the NEMA 17 motor size to compute the spacing of the controller board attachment holes
// so that the spacing will be the fixed
motor_17_info = nema_motor_info(17);
minimum_mounting_plate_size = motor_17_info[0];
controller_board_mounting_hole_spacing = minimum_mounting_plate_size / 2;

motor_mounting_plate_width = max(motor_mounting_plate_size + motor_screw_head_clearance_d/2, 
                                 minimum_mounting_plate_size + motor_mounting_plate_adjustment_range);
motor_mounting_plate_length = max(motor_mounting_plate_size, minimum_mounting_plate_size);

// Transition between support post and rod, sloped at specified angle
angle_of_taper = 45;
thickness_between_collar_and_rod = sin(angle_of_taper) * ((collar_od - head_plate_post_d)/2);
thickness_between_inner_support_and_rod_d = max(0, sin(angle_of_taper) * ((collar_od - head_plate_post_d)));
collar_support_height = 2;
tapered_collar_support_height = thickness_between_collar_and_rod;

support_height = max(motor_shaft_length * 1.5, motor_shaft_length + thickness_between_collar_and_rod + collar_support_height);

// Specify other dimensions of the motor and impeller shafts, and the coupler that joins them
shaft_flat_length = 15;     // Length of the flat part of the D-shaft
space_between_shafts = 5;
shaft_coupler_height = 2 * shaft_flat_length + space_between_shafts;

head_plate_post_height = bearing_width + (distance_between_bearings -  thickness_of_tapered_bearing_support) 
                  + shaft_coupler_height;

// Maximum overlap between the motor mount post and the shaft post
overlap_height = mounting_plate_thread_pitch * 2.5;

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
    rod_height = post_nut_height + head_plate_thickness;

    support_cylinder_height = 2;

    // Calculate the height of the based on the internal structure
    part_height = bearing_width + (distance_between_bearings -  thickness_of_tapered_bearing_support) 
                  + shaft_coupler_height;

    // Hollow threaded part, with support for two bearings inside, held in place by screwed-in supports
    up(part_height)
    difference()
    {
        union()
        {
            // Attach the first exterior features top-down
            union()
            {
                threaded_rod(d = head_plate_post_d, height = rod_height, pitch = mount_thread_pitch,
                end_len1 = 0, $fa = 1, $fs = 1, blunt_start = true, bevel2 = true,
                anchor = TOP)
                
                // Collar below the external threaded section
                position(BOTTOM)
                cylinder(h = collar_support_height, r = rod_o_ring_od / 2,
                anchor = TOP, $fa = 1, $fs = 1)
                
                // Tapered support for the collar        
                position(BOTTOM)
                cylinder(h = tapered_collar_support_height, r2 = rod_o_ring_od / 2,
                r1 = collar_od / 2, anchor = TOP, $fa = 1, $fs = 1)
            
                // The spacing between the bearings above the taper        
                position(BOTTOM)
                cylinder(h = part_height-(rod_height + collar_support_height + tapered_collar_support_height + overlap_height), r = collar_od / 2, 
                    anchor = TOP, $fa = 1, $fs = 1)

                position(BOTTOM)
                trapezoidal_threaded_rod(d = collar_od, height = overlap_height,
                pitch = mounting_plate_thread_pitch, thread_depth = internal_thread_depth,
                thread_angle = 30, internal = false, starts=1, $fa = 1, $fs = 1, $fn = 100, blunt_start = true,
                anchor=TOP);               
          }
            
        }


        // Hollow out the full length of the part
        up(difference_tolerance)
        cylinder(h=part_height+difference_tolerance, r=shaft_clearance_d/2, 
        anchor=TOP, $fa=1, $fs=1);

        union()
        {
            // Make a space for the bearing closest to the impeller - press fit
            up(difference_tolerance)
            cylinder(h=bearing_width+difference_tolerance, r=bearing_od/2, anchor=TOP, $fn=100);
        }

        // Hollow out section where the shaft coupler will be located
        down(part_height+difference_tolerance)
        union()
        {
            cylinder(h = shaft_coupler_height-(oversized_bearing_or-bearing_od/2)+difference_tolerance, 
                      r = oversized_bearing_or, anchor=BOTTOM, $fa = 1, $fs = 1)

            // Taper between the sliding fit radius and the press fit bearing radius
            position(TOP)
            cylinder(h = oversized_bearing_or-bearing_od/2, r1 = oversized_bearing_or, r2=bearing_od/2,  
                      anchor=BOTTOM, $fa = 1, $fs = 1)

            // Make space for the bearing closest to the motor shaft
            position(TOP)
            cylinder(h=bearing_width, r=bearing_od/2, anchor=BOTTOM, $fn=100)

            position(TOP)
            tapered_bearing_support();
        }


    }
    
}

// This is an inserted part used to support the bearing that is closest to the motor
// When printed, it is scaled to be smaller in the x and y directions to allow for a sliding fit.
// Use full size for making the space for it.
module tapered_bearing_support(anchor=BOTTOM, scale_for_sliding_fit=false)
{
    sliding_fit_tolerance = 0.05;
    scale_factor = scale_for_sliding_fit ? (bearing_od/2 - sliding_fit_tolerance)/(bearing_od/2) : 1.;

    cylinder(h=bearing_support_thickness, r=scale_factor*bearing_od/2, 
             anchor=anchor, $fn=100)

    position(-anchor)
    cylinder(h=thickness_of_taper_for_supporting_bearing*scale_factor, r2=scale_factor*shaft_clearance_d/2, 
             r1=scale_factor*bearing_od/2, anchor=anchor, $fa=1, $fs=1, $fn=100)

    children();
}

// This is a part to mark where to file the flats onto the ends of the impeller shaft
module impeller_shaft_flat_filing_jig(shaft_clearance_tolerance=0.2)
{
    impeller_shaft_mask_dims = [bearing_id,
                            bearing_id + 2 * difference_tolerance,
                            shaft_flat_length + bearing_washer_thickness + bearing_width + difference_tolerance];

    intersection() {
        difference() {
            cylinder(h = 2 * shaft_flat_length, r = bearing_washer_id / 2, anchor = BOTTOM, $fn = 100);

            down(difference_tolerance)
            cylinder(h = 2 * (shaft_flat_length + difference_tolerance), 
                     r = impeller_shaft_diameter / 2 + shaft_clearance_tolerance, anchor = BOTTOM, $fa = 1, $fs = 1);
        }

        intersection() {
            union() {
                down(difference_tolerance)
                cylinder(h = shaft_flat_length + difference_tolerance , r = bearing_washer_id / 2, anchor = BOTTOM, $fn = 100);

                up(shaft_flat_length)
                left((bearing_id - impeller_shaft_diameter_at_flat)/2)
                cuboid(impeller_shaft_mask_dims, anchor = BOTTOM, $fa = 1, $fs = 1);
            }
        }

    }

}

// This is an attached part used to support the shaft coupler inside the bearing that is 
// closest to the motor.
module bearing_washer(with_shaft_fastener=false)
{
    difference()
    {
        union()
        {
            if (with_shaft_fastener)
            {
                color("blue")
                difference()
                    {
                        cylinder(h = bearing_width, r = bearing_washer_od / 2, anchor = TOP, $fn = 100);

                        // Make a hole for a set screw that will hold the washer to the impeller shaft
                        down(bearing_width / 2)
                        yrot(90)
                        screw_hole(str("M", set_screw_diameter, "x0.25"), thread = true, 
                                    length = bearing_washer_od / 2, head = "none", anchor = TOP);
                    }
            }
            
            cylinder(h=bearing_washer_thickness, r=bearing_washer_od/2, 
                 anchor=BOTTOM, $fn=100)
            color("red")
            cylinder(h=bearing_width-0.5, r=bearing_washer_id/2, 
                 anchor=BOTTOM, $fn=100);
        }
        if (with_shaft_fastener)
        {
            // Hollow out the inside
            down(difference_tolerance)
            cylinder(h = 2 * bearing_width + bearing_washer_thickness + 2 * difference_tolerance,
            r = impeller_shaft_diameter / 2, anchor = CENTER, $fa = 1, $fs = 1, $fn = 100);
        }
    }

}


module shaft_coupler()
{
    shaft_coupler_height_without_washer = shaft_coupler_height - bearing_washer_thickness;
    bearing_bushing_thickness = bearing_width + bearing_washer_thickness;
    // Construct upside-down for printing
    difference()
    {
        union() {
            cylinder(h = shaft_coupler_height_without_washer, r = shaft_coupler_d / 2,
            anchor = BOTTOM, $fa = 1, $fs = 1);
            up(shaft_coupler_height_without_washer - difference_tolerance)
            bearing_washer(with_shaft_fastener = false);

        }
        
        // Make a hole for a set screw that will hold the shaft coupler to the impeller shaft
        up(shaft_coupler_height - min(shaft_flat_length/2, 2*set_screw_diameter))
        yrot(-90)
        screw_hole(str("M", set_screw_diameter, "x0.25"), thread = true, length = shaft_coupler_d / 2, 
                    head = "none", anchor = TOP);

        union()
        {
            // Create the motor shaft mask
            motor_shaft_mask_dims = [motor_shaft_diameter_at_flat, 
                                     motor_shaft_diameter+2*difference_tolerance, 
                                     shaft_flat_length+difference_tolerance];
            down(difference_tolerance)
            intersection()
            {
                cylinder(h = shaft_flat_length+difference_tolerance, r = motor_shaft_diameter / 2,
                          anchor = BOTTOM, $fa = 1, $fs = 1);
                left(motor_shaft_diameter-motor_shaft_diameter_at_flat)
                cuboid(motor_shaft_mask_dims, anchor = BOTTOM, $fa = 1, $fs = 1);


            }

            // Construct the impeller shaft mask
            impeller_shaft_mask_dims = [bearing_id,
                                        bearing_id + 2 * difference_tolerance,
                                        shaft_flat_length + bearing_washer_thickness + bearing_width + difference_tolerance];
            up(shaft_coupler_height_without_washer-bearing_bushing_thickness)
            intersection()
            {
                union()
                    {
                        cylinder(h = shaft_flat_length + difference_tolerance, r = impeller_shaft_diameter / 2,
                        anchor = BOTTOM, $fa = 1, $fs = 1);
                    }
                union()
                    {
                        up(bearing_washer_thickness)
                        left((bearing_id - impeller_shaft_diameter_at_flat)/2)
                        cuboid(impeller_shaft_mask_dims, anchor = BOTTOM, $fa = 1, $fs = 1);

                    }
            }

        }
            
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
    up(attachment_nut_cuboid_depth/2)
    {
        difference()
        {
            cuboid([attachment_nut_cuboid_width, attachment_nut_cuboid_length, attachment_nut_cuboid_depth],
            rounding = 0.6, edges = [FRONT, "Y"], except=BOT, anchor = CENTER);
            xrot(90)
            {
                screw_hole(str("M", controller_board_screw_diameter), length = controller_board_screw_length)
                up(2) position(BOT)
                zrot(90)
                nut_trap_side(trap_width = attachment_nut_cuboid_width + 2, poke_len = attachment_nut_cuboid_width +
                    motor_mounting_plate_height);
            }
        }

        if (part_to_show == "all, assembled")
        {
            // Show the screw and nut in place
            color("grey")
            back(attachment_nut_cuboid_length / 2)
            xrot(90)
            screw(str("M", controller_board_screw_diameter), "socket", "hex", length = controller_board_screw_length,
            anchor = BOTTOM);

            color("grey")
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
                right(controller_board_plate_width / 2 - attachment_nut_cuboid_depth/2)
                screw_hole(str("M", controller_board_screw_diameter), length = controller_board_plate_depth * 3,
                anchor = CENTER);
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
            cylinder(h = overlap_height, r = collar_od/2 + (wall_thickness + internal_thread_depth),
            anchor = BOTTOM, $fa = 1, $fs = 1);
        }
        
        union()
        {        
            // Hollow out the tube threads
            zrot(180)
            trapezoidal_threaded_rod(d = collar_od, height = overlap_height, pitch = mounting_plate_thread_pitch, 
            thread_depth = internal_thread_depth, thread_angle = 30, internal = true, starts = 1, 
            $fa = 1, $fs = 1, $fn = 100, blunt_start = true, anchor = BOTTOM, $slop=mount_slop)
            
            position(TOP)
            down(difference_tolerance)
            cylinder(h = 2*difference_tolerance,
                     r = collar_od / 2,
                     anchor = BOTTOM, $fa = 1, $fs = 1);
            
            up(motor_mounting_plate_height)
            cylinder(h = difference_tolerance, r = collar_od / 2, anchor = TOP, $fa = 1, $fs = 1);

            if (label_parts)
            {
                // Inscribe the details about the threads on the mount nut 
                nut_labels = [str("D", collar_od), str("P", mounting_plate_thread_pitch), str("L", overlap_height), str("S", mount_slop)];
                for (i = [0:len(nut_labels)])
                {
                    zrot(60 * i)
                    fwd(collar_od/2 + (wall_thickness + internal_thread_depth) - text_depth / 2)
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
    xrot((1 - switch_between_assembled) * 180)
    up(switch_between_assembled * test_post_height)
    difference()
    {
        union()
        {
            // Attach the first exterior features top-down
            union()
            {
                // The spacing between the bearings above the taper        
                cylinder(h = test_post_height-overlap_height, r = collar_od / 2,  anchor = TOP, $fa = 1, $fs = 1)

                position(BOTTOM)
                trapezoidal_threaded_rod(d = collar_od, height = overlap_height,
                pitch = mounting_plate_thread_pitch, thread_depth = internal_thread_depth,
                thread_angle = 30, internal = false, starts=1, $fa = 1, $fs = 1, $fn = 100, blunt_start = true,
                anchor=TOP);               
          }
            
        }
        
        // Hollow out the test part
        up(difference_tolerance)
        cylinder(h=test_post_height+difference_tolerance, r=collar_od/2 - wall_thickness, 
        anchor=TOP, $fa=1, $fs=1);

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
                     r = collar_od/2 + (wall_thickness + internal_thread_depth),
            anchor = BOTTOM, $fa = 1, $fs = 1);

        }
        
        union()
        {        
            // Hollow out the tube threads
            up(motor_mounting_plate_height)
            zrot(180)
            trapezoidal_threaded_rod(d = collar_od, height = overlap_height, pitch = mounting_plate_thread_pitch, 
            thread_depth = internal_thread_depth, thread_angle = 30, internal = true, starts = 1, 
            $fa = 1, $fs = 1, $fn = 100, blunt_start = true, anchor = BOTTOM, $slop=mount_slop)
            
            position(TOP)
            down(difference_tolerance)
            cylinder(h = 2*difference_tolerance,
                     r = collar_od / 2,
                     anchor = BOTTOM, $fa = 1, $fs = 1);
            
            up(motor_mounting_plate_height)
            cylinder(h = difference_tolerance, r = collar_od / 2, anchor = TOP, $fa = 1, $fs = 1);


        }
        
        // Cut out parts of the support tube if motor screw clearance is needed
        for (screw_x = [-1, 1])
        {
            for (screw_y = [-1, 1])
            {
                up((motor_mounting_plate_height+motor_screw_length+motor_screw_head_height)/2)
                fwd(screw_y * screw_spacing / 2)
                right(screw_x * screw_spacing / 2)
                union()
                {
                    cylinder(h = motor_screw_length + motor_screw_head_height, r = motor_screw_head_clearance_d / 2, center = true);
                    up((motor_screw_length+motor_screw_head_height)/2)
                    sphere(r = motor_screw_head_clearance_d / 2);
                }
            }
        }

    }

    front_edge_location = max(max(minimum_mounting_plate_size, motor_mounting_plate_width), collar_od + attachment_nut_cuboid_width)/2;
    up(motor_mounting_plate_height/2)
    union()
    {
        difference()
        {
            // The rounded motor plate with the area for the screw mounting cubes 
            down(motor_mounting_plate_height/2)
            union()
            {
                linear_extrude(height=motor_mounting_plate_height)
                polygon(round_corners(square([motor_mounting_plate_length, motor_mounting_plate_width + motor_mounting_plate_adjustment_range/2 + attachment_nut_cuboid_length/2], center=true), cut=3, $fn=96*4));
                
                fwd((front_edge_location))
                linear_extrude(height=motor_mounting_plate_height)
            polygon(round_corners(square([attachment_nut_cuboid_width+controller_board_mounting_hole_spacing, 
            attachment_nut_cuboid_length], center=true), cut=0.25, $fn=96*4));

            }
            
            // Cut out the slots for mounting the motor
            nema_mount_mask(size=nema_motor_size, depth=motor_mounting_plate_height+1, l=motor_mounting_plate_adjustment_range, $fn=100);
            
            // Put poke holes in the mounting plate to push the nuts for the controller board attachment screws
            for (socket_index = [-1, 1])
            {
                // Add a socket for the clip that will be used to attach the controller board
                right(0.5*socket_index * controller_board_mounting_hole_spacing)
                down(motor_mounting_plate_height)
                fwd(front_edge_location-struct_val(controller_board_attachment_nut_info, "thickness") * 0.75)
                cylinder(h=motor_mounting_plate_height*4, r=struct_val(controller_board_attachment_nut_info, "thickness")/2);
            }
        }
        
        for (socket_index = [-1, 1])
        {
            // Add a cube with the nut trap that will be used to attach the controller board
            right(0.5*socket_index * controller_board_mounting_hole_spacing)
            up(motor_mounting_plate_height/2)
            fwd(front_edge_location)
            controller_board_attachment_nut_trap();
        }
    }

}

if (part_to_show == "all, assembled")
{
    zflip()  // Show the assembly in the orientation that it will be used in
        {
            motor_mount();
            
            // Show the controller board
            board_back_face_location = max(max(minimum_mounting_plate_size, motor_mounting_plate_width), 
                                           collar_od + attachment_nut_cuboid_width)/2+
                    controller_board_plate_depth/2 + attachment_nut_cuboid_length/2;

            color([0, 1, 0, 0.5])
            fwd(board_back_face_location)
            down(controller_board_plate_width / 2 - motor_mounting_plate_height - attachment_nut_cuboid_depth)
            zrot(90) yrot(-90)
            controller_board_mounting_plate();

            // Show the motor
            nema_stepper_motor(size = nema_motor_size, h = motor_body_length, shaft_len = motor_shaft_length);

            // Show the screws that secure the motor
            for (screw_x = [-1, 1])
            {
                for (screw_y = [-1, 1])
                {
                    color("grey")
                    down(motor_screw_length-motor_mounting_plate_height)
                    fwd(screw_y * screw_spacing / 2)
                    right(screw_x * screw_spacing / 2)
                    screw(str("M", screw_size), "socket", "hex", length = motor_screw_length, anchor = BOTTOM);
                }
            }

            // Show the nut in place
            up(post_nut_height / 2 + motor_mounting_plate_height + support_height + head_plate_thickness)
            zrot(30)
            threaded_nut(nutwidth = nut_diameter, id = head_plate_post_d, h = post_nut_height, pitch = mount_thread_pitch, $slop =
            slop, $fa = 1, $fs = 1);
            
            // Show the bearing
            up(post_nut_height + motor_mounting_plate_height + support_height + head_plate_thickness-bearing_width/2)
            ball_bearing(id=bearing_id,od=bearing_od,width=bearing_width, shield=true, flange=false, $fn=72);
        }
    
}
else if (part_to_show=="shaft coupler")
{
    shaft_coupler();
}
else if (part_to_show=="motor mount")
{
    motor_mount();
    if (show_assembly)
    {
        // Show the screws that secure the motor - this is separate from the distributed parts since they are
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
        
        distribution_spacing = exploded_view ? [motor_body_length+motor_mounting_plate_height, shaft_coupler_height, 
                                bearing_width, thickness_of_taper_for_supporting_bearing, head_plate_post_height, 
                                post_nut_height, bearing_width, bearing_washer_thickness+bearing_width] : [0, 0, 0, 0, 0, 0, 0, 0];
        distribute(spacing=0,sizes=distribution_spacing, dir=UP)
        {
            // Index 0
            nema_stepper_motor(size = nema_motor_size, h = motor_body_length, shaft_len = motor_shaft_length);

            // Index 1
            up(motor_mounting_plate_height)
            shaft_coupler();
            
            // Index 2
            up(motor_mounting_plate_height + shaft_coupler_height)
            ball_bearing(id=bearing_id,od=bearing_od,width=bearing_width, shield=true, flange=false, $fn=72, anchor=BOTTOM);
    
            // Index 3
            up(motor_mounting_plate_height + shaft_coupler_height + bearing_width)
            difference()
            {
                tapered_bearing_support(BOTTOM, true);
                
                down(difference_tolerance)
                cylinder(h=thickness_of_taper_for_supporting_bearing+bearing_support_thickness+2*difference_tolerance,
                         r=shaft_clearance_d/2, anchor=BOTTOM, $fa=1, $fs=1, $fn=100);
            }
            
            // Index 4
            if (exploded_view)
            {
                back_half(s=350)
                up(motor_mounting_plate_height)
                shaft_connection_post();

            }
            else
            {
                up(motor_mounting_plate_height)
                shaft_connection_post();
            }
    
            // Index 5 - Show the nut in place
            up(motor_mounting_plate_height + head_plate_post_height-bearing_width)
            zrot(30)
            threaded_nut(nutwidth = nut_diameter, id = head_plate_post_d, h = post_nut_height, pitch = mount_thread_pitch, $slop =
            slop, $fa = 1, $fs = 1);

            // Index 6 - ball bearing closest to the impeller blades
            up(motor_mounting_plate_height + head_plate_post_height-bearing_width)
            ball_bearing(id=bearing_id,od=bearing_od,width=bearing_width, shield=true, flange=false, $fn=72, anchor=BOTTOM);
    
            // Index 7 - bearing washer to keep the bearing in place on the shaft
            up(motor_mounting_plate_height + head_plate_post_height + bearing_washer_thickness)
            zflip()
            bearing_washer(with_shaft_fastener=true);
            

        }
    }

}
else if (part_to_show=="threaded post")
{
//    back_half(s=350) 
//    motor_mount();
    shaft_connection_post();

}
else if (part_to_show=="tapered bearing support")
{
//    back_half(s=350)
    difference()
    {
        tapered_bearing_support(BOTTOM, true);
        
        down(difference_tolerance)
        cylinder(h=thickness_of_taper_for_supporting_bearing+bearing_support_thickness+2*difference_tolerance,
                 r=shaft_clearance_d/2, anchor=BOTTOM, $fa=1, $fs=1, $fn=100);
    }
}

else if (part_to_show=="controller_mounting_board")
{
    controller_board_mounting_plate();
}
else if (part_to_show=="nut")
{
    // The matching nut
    up(post_nut_height/2)
    zrot(30)
    threaded_nut(nutwidth=nut_diameter, id=head_plate_post_d, h=post_nut_height, pitch=mount_thread_pitch, $slop=slop, $fa=1, $fs=1);
}
else if (part_to_show=="bearing bushing")
{
    up(bearing_width)
    bearing_washer(with_shaft_fastener=true);
}
else if (part_to_show == "impeller shaft flat filing jig")
{
    impeller_shaft_flat_filing_jig();
}
else if (part_to_show == "motor_mount_test_threads")
{
    if (show_assembly)
    {
        back_half()
        motor_mount_test_threads();
    }
    else
    {
        motor_mount_test_threads();
    }
}


