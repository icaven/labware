/*
    Head plate mold for a bioreactor.
    
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
include <BOSL2/bottlecaps.scad>
include <BOSL2/joiners.scad>
include <BOSL2/rounding.scad>
include <BOSL2/screws.scad>
include <BOSL2/structs.scad>
include <BOSL2/threading.scad>

use <magnet_trap.scad>

/* [Viewing options] */

// Show a part, or the assembled parts in position
part_to_show = "jar lid from mold";// [jar lid from mold, lid top mold,lid bottom mold,posts for solid bottom design,caps for posts,plugs for lid,test screw together columns, plate drilling template,jar lid cutting jig,18 mm port mold,14 mm port mold,10 mm port mold,test post hole fit,test jar insert]

// Show the embedded support_plate
show_support_plate = false;
// Thickness of embedded support plate (accounting for convexity)
support_plate_thickness = 1.5; // 0.1
// Show a cross section
show_cross_section_view = "none"; // [none, back, left, front, right, back+left, front+right]

// Reveal the zone around a port that nothing else should intrude into
show_port_zones = false;
// for the mold parts
show_molded_part = false;
/*
Disabled
// Hollow out beneath the support support plate
hollow_out_stopper = false;
*/

/* [Port specifications] */
// Number of large ports (the number of each of the smaller ports will be half of this)
number_ports = 6;

// Diameter of the 3 sizes of ports
port_d = 18;
small_port_d = 14;
mini_port_d = 10;

port_height = 6;
// Thickness of the walls of the bearing pocket
bearing_pocket_wall_thickness = 2.8; // 0.1
// Add support plate posts if the support plate will be included during the casting of the silicone
add_support_plate_posts = false;

/* [Bearing choice] */
bearing_to_use = "608ZZ"; // ["608ZZ", "R4ZZ", "635ZZ", "685ZZ"]

/* [Mold specifications] */
// Printer layer height
layer_height = 0.2; // [0.05, 0.07, 0.1, 0.15, 0.2, 0.25]
//Printer nozzle diameter
nozzle_diameter = 0.4;

// Angle from vertical to make the extraction from the mold easier
mold_draft_angle = 1;

// Screws or magnets to hold the halves together
use_screws_to_hold_together_mold_halves = true;
use_side_nut_trap = false;
mold_screw = "M3";  // [6-32, M4, M3]
mold_screw_head = "pan"; // [pan, socket]
number_mold_joining_columns = 6; // [3:6]

/* [Jar lid cutting jig specifications] */

jar_nominal_dia_and_type_number = "110-400";
// The size of the screw for attaching the lid to the center bar of the lid cutting jig
screw_for_holding_lid = "M3";  // ["6-32", "M4", "M3"]

/* [Other specifications] */
impeller_shaft_diameter = 6.35;
impeller_shaft_clearance_width = 1.;
sliding_tolerance = 0.1;

// Thickness of the part that rests on the jar rim
gasket_thickness = 1; // 0.5

// For the nut: The printer-specific slop value, which adds clearance 4*slop to internal threads.
slop = 0.07; // 0.01
tapered_nut_slop = 0.1; // 0.01

// Don't need to change anything after this
module __end_of_customizer_variables() {}

$fn = 200;
$fa = 1;
$fs = 1;
difference_tolerance = 0.01;
screw_hole_slop = 0.05;

cut_plane_normal = show_cross_section_view == "back" ? BACK :
            show_cross_section_view == "left" ? LEFT :
                    show_cross_section_view == "front" ? FRONT :
                            show_cross_section_view == "right" ? RIGHT :
                                    show_cross_section_view == "back+left" ? BACK + LEFT :
                                            show_cross_section_view == "front+right" ? FRONT + RIGHT :
                                                BACK;

function mm_to_inch(x) = x / 25.4;
function inch_to_mm(x) = 25.4 * x;

// Obsolete specification - to be removed
threaded_post_wall_thickness = 2.8; // 0.1

// Hollow out beneath the support support plate
// Functionality not updated for latest design - this replaces the customizer variable above until the functionality can be restored
hollow_out_stopper = false;

mold_wall_thickness = 2.0;

// Subset from BOSL2 and augmented for additional bearings
// Update this list for those available from local suppliers
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

// Bearing inner diameter oversize (to be outside of the rotating center)
// Make it half-way between the inner and outer diameters
shaft_clearance_d = (bearing_od - bearing_id) / 2 + bearing_id;

// Use to drill holes in the support plate manually using drill bit sizes in increments of 1/8 inch
support_plate_shaft_hole_d = inch_to_mm(quantup(mm_to_inch(shaft_clearance_d), 1 / 8));
support_plate_port_hole_d = inch_to_mm(quantup(mm_to_inch(port_d), 1 / 8));
support_plate_small_port_hole_d = inch_to_mm(quantup(mm_to_inch(small_port_d), 1 / 8));
support_plate_mini_port_hole_d = inch_to_mm(quantup(mm_to_inch(mini_port_d), 1 / 8));

/**
  Dimensions of the jar and lid
 */
jar_nominal_dia = parse_int(str_split(jar_nominal_dia_and_type_number, "-")[0]);
jar_type_number = parse_int(str_split(jar_nominal_dia_and_type_number, "-")[1]);

selected_jars_by_trade_size = [
    // trade_size, T,          E,                 H,              I_min, R_max, thread_r, S, number_turns, TPI, type, 
    [110, inch_to_mm(4.307), inch_to_mm(4.187), inch_to_mm(0.582), inch_to_mm(3.737),
     inch_to_mm(0.078), inch_to_mm(0.06), inch_to_mm(0.062), 1.0, 5, "A",],
    ];

jar_info_index = search([jar_nominal_dia], selected_jars_by_trade_size, 1);
assert(jar_info_index != [], str("Unsupported jar size: ", jar_type_number));
jar_info = selected_jars_by_trade_size[jar_info_index[0]];

// The diameter of the outside of the jar threads
jar_od = jar_info[1];

// The height of the lid
jar_lid_height = jar_info[3];
taper_height = jar_lid_height;      // Make the height of the tapered head plate the same as the lid height
lid_bottom_mold_height = taper_height - 2 * difference_tolerance;


// The thickness of the glass jar at the rim
jar_rim_thickness = 3; // Measured from jar
jar_mouth_largest_id = jar_info[2] - 2 * jar_rim_thickness;

neck_taper_angle = 82.4;   // Taper inside the neck of the jar; measured from jar

// Width of lid inside the jar opening (chosen)
lid_rim_width = 2;

function taper_dia_adjustment(thickness) = 2 * thickness / tan(neck_taper_angle);
lid_taper_smallest_d = jar_mouth_largest_id - taper_dia_adjustment(taper_height);

// Radius of the support plate from the cut-out lid
bit_diameter = inch_to_mm(1 / 8);
bit_clearance = 1;
cutting_r = (jar_mouth_largest_id) / 2 - lid_rim_width - (bit_diameter + bit_clearance) / 2;
support_plate_or = cutting_r - bit_diameter / 2;  // Don't include the bit_clearance here
//echo("Diameter of support plate = ", 2 * support_plate_or);


// Angles of small and mini ports relative to the angle of a main port
phase_angle_small = 180 / (number_ports);
phase_angle_mini = 180 / (number_ports);

// When using magnets to hold the two mold halves together
mold_magnet_dims = struct_set([], ["diameter", 8, "thickness", 3]);

// When using screws to hold the two mold halves together
mold_screw_drive = mold_screw_head == "pan" ? "phillips" : "hex";
mold_screw_info = screw_info(mold_screw, mold_screw_head, mold_screw_drive);
mold_screw_head_height = struct_val(mold_screw_info, "head_height") == undef ?
    0 : struct_val(mold_screw_info, "head_height");


thickness_above_support_plate = 2;
thickness_below_support_plate = 2;
support_plate_surround_thickness = thickness_above_support_plate + thickness_below_support_plate;
thickness_above_rim = support_plate_thickness + support_plate_surround_thickness;

// Posts that keep the support_plate in place during molding
support_plate_post_d = inch_to_mm(1 / 8);
support_plate_post_ridge_thickness = 0.5;


layer_containing_support_plate_d = jar_mouth_largest_id - 2 * lid_rim_width;
// == 2*cutting_r + bit_diameter + bit_clearance
//echo("Diameter of open circle in lid = ", layer_containing_support_plate_d);

// Ensure that the part can be easily removed from mold by tapering the section above the gasket that will sit on
// the jar rim
function draft_dia_adjustment(thickness) = 2 * thickness / tan(90 - mold_draft_angle);
upper_surface_d = layer_containing_support_plate_d - draft_dia_adjustment(thickness_above_rim);


support_plate_d = 2 * support_plate_or;

// gasket_thickness is not included in the stopper thickness, since the gasket height is part of the thickness_above_rim
stopper_thickness = taper_height + thickness_above_rim;
stopper_taper_width = 4;


trapezoidal_thread_angle = 45;
mounting_plate_thread_pitch = 3;
mounting_plate_thread_depth = mounting_plate_thread_pitch / 2;

gasket_thickness_qup = quantup(gasket_thickness, layer_height);
thickness_above_rim_qup = quantup(thickness_above_rim, layer_height);
stopper_thickness_qup = quantup(stopper_thickness, layer_height);
bearing_width_qup = quantup(bearing_width, layer_height);
post_label_text_depth = quantup(0.75, layer_height);

lid_mold_height = thickness_above_rim_qup + mold_wall_thickness + bearing_width_qup + difference_tolerance;
magnetic_column_d = struct_val(mold_magnet_dims, "diameter") + mold_wall_thickness;
height_of_post_recess = 2*layer_height;

post_hole_shortening = 0;
post_height_in_top_lid = (hollow_out_stopper ? lid_mold_height :
                bearing_width + mold_wall_thickness - height_of_post_recess) -
    post_hole_shortening;
use_textured_grip = false;
height_of_post_grip = 5;    // The height of the region to grip the posts with when unscrewing
height_of_posts_when_using_solid_bottom = taper_height + height_of_post_grip + 1 +
    (lid_mold_height - post_height_in_top_lid);

// Variables used to control the hollowing out of the base inside the tapered walls.  A small angle is used to 
// allow the part to be extracted from the mold more easily.
diameter_outside_hollow_of_tapered_base = lid_taper_smallest_d;
// The draft angle could be used instead of the taper angle, but since there is enough clearance for the instruments
// to be inserted through the outermost ports, the extra supporting material that the taper angle provides may be used
//diameter_outside_hollow_of_tapered_base_with_draft = diameter_outside_hollow_of_tapered_base - draft_dia_adjustment(taper_height+2*difference_tolerance);
diameter_outside_hollow_of_tapered_base_with_draft = diameter_outside_hollow_of_tapered_base - 
    taper_dia_adjustment(taper_height);
diameter_inside_hollow_of_tapered_base = diameter_outside_hollow_of_tapered_base - 2 * mold_wall_thickness;
diameter_inside_hollow_of_tapered_base_with_draft = diameter_outside_hollow_of_tapered_base_with_draft - 2 *
    mold_wall_thickness;
exterior_dome_diameter_base = diameter_outside_hollow_of_tapered_base - 2 * stopper_taper_width;
exterior_dome_diameter_top = diameter_outside_hollow_of_tapered_base_with_draft - 2 * stopper_taper_width;
interior_dome_diameter_base = diameter_inside_hollow_of_tapered_base - 2 * stopper_taper_width;
interior_dome_diameter_top = diameter_inside_hollow_of_tapered_base_with_draft - 2 * stopper_taper_width;

length_of_screw_for_posts = 25;
assert ((height_of_posts_when_using_solid_bottom + lid_mold_height - post_height_in_top_lid) > length_of_screw_for_posts, 
        "height of posts is too short or screws too long");

// Specifications for the connector for the posts that make the holes in the lid
// For the motor shaft hole
post_specs_shaft = struct_set([], ["type", "screw", "size", "M3", "length", length_of_screw_for_posts, "head", "pan", 
                        "drive", "phillips", "ring_d_inc", nozzle_diameter]);
// For the smaller sizes of holes
post_specs_small = struct_set([], ["type", "screw", "size", "M3", "length", length_of_screw_for_posts, "head", "pan", 
                        "drive", "phillips", "ring_d_inc", nozzle_diameter]);
// For the larger sizes of holes
post_specs_large = struct_set([], ["type", "screw", "size", "M3", "length", length_of_screw_for_posts, "head", "pan", 
                        "drive", "phillips", "ring_d_inc", nozzle_diameter]);


module test_insert()
{
    thickness = 0.4;
    theta = atan(15 / (4 / 2));
    echo("theta = ", theta);
    smallest_d = 96;
    h = 15;
    new_largest_d = 2 * h / tan(theta) + smallest_d;
    echo("2*h / tan(theta) = ", 2 * h / tan(theta));
    echo("new_largest_d = ", new_largest_d);
    echo("new_smallest_d = ", new_largest_d - 2 * h / tan(theta));
    
    //    tube(h = 1, od = 107, id = new_largest_d - thickness, anchor = BOTTOM)
    
    //    position(TOP)
    tube(h=h, od1=new_largest_d, id1=new_largest_d - thickness, od2=smallest_d, id2=smallest_d - thickness,
         anchor=BOTTOM);
    
}


module threaded_post_for_shaft()
{
    // For testing, show the size of the hole in the support plate
    //         #cylinder(h = bearing_width + 2 * difference_tolerance, d = 25.4 * 3 / 8, anchor = BOTTOM);
    
    // For testing, show the extent of the zone around the shaft port
    port_zone(bearing_od + 2 * difference_tolerance, 4 * threaded_post_wall_thickness);
    
    difference()
    {
        trapezoidal_threaded_rod(d=bearing_od + 2 * threaded_post_wall_thickness, height=bearing_width,
                                 pitch=mounting_plate_thread_pitch, thread_depth=mounting_plate_thread_depth,
                                 thread_angle=trapezoidal_thread_angle, internal=false, starts=1,
                                 blunt_start=true, anchor=BOTTOM);
        
        down(difference_tolerance)
        cylinder(h=bearing_width + 2 * difference_tolerance, d=bearing_od, anchor=BOTTOM);
    }
}

module port_zone(port_od, post_increase_d)
{
    if (show_port_zones)
        // For testing, show the extent of the zone around the port
        #cylinder(h=port_height + 2 * difference_tolerance, d=port_od + post_increase_d, anchor=BOTTOM);
}

// This module is adapted from npt_threaded_rod() in threading.scad in the BOSL2 library
module tapered_threaded_part(l, d, pitch, left_handed=false, bevel, bevel1, bevel2, lead_in, lead_in1, lead_in2,
                             end_len, end_len1, end_len2, hollow=false, internal=false, anchor, spin, orient)
{
    assert(is_bool(left_handed));
    assert(is_undef(bevel) || is_bool(bevel));
    assert(is_bool(internal));
    assert(!(internal && !is_undef(hollow)), "Cannot created a hollow internal threads mask.");
    rr = d / 2;
    rr2 = rr - l / 32;
    r1 = internal? rr2 : rr;
    r2 = internal? rr : rr2;
    depth = pitch * cos(30) * 5 / 8;
    profile = internal? [
            [-6 / 16, -depth / pitch],
            [-1 / 16, 0],
            [-1 / 32, 0.02],
            [1 / 32, 0.02],
            [1 / 16, 0],
            [6 / 16, -depth / pitch]
            ] : [
            [-7 / 16, -depth / pitch * 1.07],
            [-6 / 16, -depth / pitch],
            [-1 / 16, 0],
            [1 / 16, 0],
            [6 / 16, -depth / pitch],
            [7 / 16, -depth / pitch * 1.07]
            ];
    attachable(anchor, spin, orient, l=l, r1=r1, r2=r2) {
        difference() {
            generic_threaded_rod(
            d1=2 * r1, d2=2 * r2, l=l,
            pitch=pitch,
            profile=profile,
            left_handed=left_handed,
            bevel=bevel, bevel1=bevel1, bevel2=bevel2,
            lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2,
            end_len=end_len, end_len1=end_len1, end_len2=end_len2,
            internal=internal,
            blunt_start=true,
            $slop=tapered_nut_slop);
            if (!is_undef(hollow) && hollow) cylinder(h=l + 1, d=hollow, center=true);
        }
        children();
    }
}

// Create the parts for the mold for a bung for a port 
module mold_for_bung_for_port(port_od)
{
    spread_of_partition_halves = 10;
    cutsize = 1;
    bung_od = port_od - 2 * sliding_tolerance;
    cap_od = port_od + 2;
    cap_thickness = 2;
    pull_tab_size = port_od / 3;
    mold_wall_thickness = 2;
    mold_od = cap_od + 2 * mold_wall_thickness;
    bung_height = thickness_above_rim_qup + cap_thickness + 2 * pull_tab_size;
    dovetail_width = mold_od / 2.5;
    dovetail_length = mold_od / 3;
    dovetail_height = mold_od / 6;
    dovetail_angle = 0;  // Not a dovetail, using straight sides
    dovetail_height_clearance = dovetail_height + sliding_tolerance + 0.2;
    
    mold_height = bung_height + mold_wall_thickness;
    threaded_portion_height = mold_height / 2;
    truncated_mold_r = (mold_od - (mold_wall_thickness - difference_tolerance)) / 2;
    
    module bung()
    {
        bung_chamfer_height = 1;
        difference()
        {
            cylinder(h=thickness_above_rim_qup, d=bung_od, anchor=BOTTOM) {
                
                // Add a resistance ring in the center of the bung height
                attach(CENTER)
                torus(id=port_od - 2, od=port_od + 1, anchor=CENTER);
                
                // Add the cap
                down(difference_tolerance)
                attach(TOP)
                difference()
                {
                    cylinder(h=cap_thickness + 2 * difference_tolerance, d=cap_od, anchor=BOTTOM);
                    up(cap_thickness / 4)
                    chamfer_cylinder_mask(d=cap_od, chamfer=(cap_thickness + difference_tolerance) / 2, anchor=BOTTOM);
                }
            }
            
            // Chamfer the end of the bung
            up(bung_chamfer_height)
            xrot(180)
            chamfer_cylinder_mask(d=bung_od, chamfer=bung_chamfer_height, anchor=BOTTOM);
            
        }
        
        // Add a pull tab on the cap
        up(thickness_above_rim_qup + cap_thickness - bung_chamfer_height / 2)
        difference() {
            union()
            {
                up(pull_tab_size)
                xrot(90)
                cylinder(h=pull_tab_size, d=pull_tab_size * 2, anchor=CENTER);
                
                down(difference_tolerance)
                cuboid([pull_tab_size * 2, pull_tab_size, pull_tab_size], anchor=BOTTOM)
                {
                    down(pull_tab_size / 2)
                    right(pull_tab_size)
                    zrot(-90)
                    yrot(-90)
                    fillet(pull_tab_size, r=pull_tab_size / 2.5, ang=90, spin=0, anchor=CENTER);
                    
                    down(pull_tab_size / 2)
                    left(pull_tab_size)
                    zrot(90)
                    yrot(-90)
                    fillet(pull_tab_size, r=pull_tab_size / 2.5, ang=90, spin=0, anchor=CENTER);
                    
                }
            }
            
            // Add finger indents on each side of the pull tab
            up (pull_tab_size)
            union()
            {
                fwd(1.25 * pull_tab_size)
                sphere(d=pull_tab_size * 2);
                back(1.25 * pull_tab_size)
                sphere(d=pull_tab_size * 2);
            }
        }
        
    }
    
    module mold()
    {
        intersection()
        {
            // Use this difference to compute the mold of the bung
            difference()
            {
                // Thread the outside of the mold with a tapered thread, but only for part of the height
                tapered_threaded_part(l=mold_height, d=mold_od, pitch=1,
                                      end_len1=mold_height - threaded_portion_height,
                                      anchor=BOTTOM, orient=UP);
                down(difference_tolerance)
                bung();
            }
            
            // Flatten two opposite sides, so that when the mold is partitioned, the flat side can lie on the print bed
            cuboid([cap_od + 2 * mold_wall_thickness,
                    mold_od - (mold_wall_thickness - difference_tolerance),
                    mold_height], anchor=BOTTOM);
        }
        
    }
    
    // The tapered nut holds the two halves of the mold together
    module tapered_nut_for_mold()
    {
        nut_height = threaded_portion_height + mold_wall_thickness + dovetail_height_clearance;
        nut_d = mold_od + 2 * mold_wall_thickness;
        nut_thread_pitch = 1;
        
        up(nut_height)
        fwd(nut_d / 2)
        xrot(180)
        fwd(nut_d / 2)
        difference()
        {
            tex = texture("pyramids_vnf", $fn=16);
            linear_sweep(circle(d=nut_d), texture=tex, h=nut_height, tex_size=[4, 4], style="concave", anchor=BOTTOM);
            
            down(difference_tolerance)
            tapered_threaded_part(l=threaded_portion_height + dovetail_height_clearance, d=mold_od,
                                  pitch=nut_thread_pitch, end_len2=dovetail_height_clearance - nut_thread_pitch,
                                  anchor=BOTTOM, orient=UP);
        }
    }
    
    // This will partition of the mold into two halves
    module partition_mold()
    {
        //      %partition_cut_mask(l=port_od*4, h=mold_height*3, cutpath="flat", anchor=CENTER);
        partition([port_od * 6, port_od, mold_height * 3], cutpath="flat", spread=spread_of_partition_halves)
        mold();
        
    }
    
    // Isolate and orient the first half of the mold
    module part_a()
    {
        xrot(-90)
        fwd((mold_od - (mold_wall_thickness - difference_tolerance)) / 2)
        union()
        {
            // Add a dovetail to lock the two halves
            fwd(spread_of_partition_halves / 2)
            back_half()
            partition_mold();
            
            up(mold_height - difference_tolerance)
            back(dovetail_length)
            difference()
            {
                // Must chamfer the edge that will be on the lower side when the mold half is printed
                up(dovetail_height / 2)
                xrot(180)
                dovetail("male", angle=dovetail_angle, width=dovetail_width, height=dovetail_height,
                         slide=dovetail_length * 1.5, anchor=FRONT);
                up(dovetail_height)
                chamfer_edge_mask(l=dovetail_width, chamfer=dovetail_height, orient=RIGHT);
            }
        }
    }
    
    // Isolate and orient the second half of the mold
    module part_b()
    {
        up(truncated_mold_r)
        xrot(180)
        union()
        {
            fwd(mold_height)
            xrot(-90)
            back(spread_of_partition_halves / 2)
            front_half()
            partition_mold();
            
            fwd(difference_tolerance)
            zrot(180)
            xrot(90)
            difference()
            {
                diff()
                {
                    cuboid([dovetail_length * 2, dovetail_width * 0.5, dovetail_height], anchor=BOTTOM + FRONT)
                    position(BACK + BOTTOM)
                    chamfer_edge_mask(l=dovetail_length * 2, chamfer=dovetail_height, orient=RIGHT,
                                      anchor=RIGHT);
                    
                }
                // Make the female dovetail channel wider so that the male part will easily fit in
                dovetail("female", angle=dovetail_angle, width=dovetail_width + 4 * sliding_tolerance,
                         height=dovetail_height + sliding_tolerance, slide=dovetail_length + dovetail_height,
                         anchor=TOP + FRONT);
            }
            
        }
        
    }
    
    module show_mated_mold_halves()
    {
        back(truncated_mold_r)
        xrot(90)
        part_a();
        
        up(mold_height)
        fwd(truncated_mold_r)
        xrot(-90)
        part_b();
        
    }
    
    module show_mold_part_a_with_nut()
    {
        zrot(90)
        {
            up(mold_wall_thickness + dovetail_height)
            right(truncated_mold_r)
            zrot(90)
            xrot(-90)
            fwd(mold_height)
            part_a();
            
            zrot(-90)
            tapered_nut_for_mold();
        }
        
    }
    
    module show_mold_part_b_with_nut()
    {
        up(mold_wall_thickness + dovetail_height)
        back(truncated_mold_r)
        xrot(90)
        part_b();
        
        zrot(180)
        tapered_nut_for_mold();
    }
    
    module create_parts_for_printing()
    {
        if (show_molded_part) {
            // Show the result of using the mold
            difference()
            {
                up(difference_tolerance)
                cylinder(h=bung_height, d=cap_od);
                mold();
            }
        }
        else
        {
            // Show all the parts to be printed
            distribution_spacing = [-mold_height, mold_height, mold_height + mold_od];
            distribute(spacing=10, sizes=distribution_spacing, dir=RIGHT)
            {
                zrot(90)
                part_a();
                
                zrot(90)
                fwd(mold_height)
                part_b();
                
                tapered_nut_for_mold();
            }
        }
    }
    
    create_parts_for_printing();
    
    // These are for testing the stages
    //    tapered_nut_for_mold();
    //    partition_mold();
    //    part_a();
    //    show_mold_part_a_with_nut();
    //    show_mold_part_b_with_nut();
    //    part_b();
    //    show_mated_mold_halves();
    //    mold();
    //    bung();
}

module port_locator(port_index, port_od, phase_angle)
{
    angle_of_port = port_index * 360 / number_ports + phase_angle;
    zrot(angle_of_port)
    fwd(support_plate_or - port_od / 2 - bearing_pocket_wall_thickness)
    children();
}
module support_plate(show_center=false)
{
    module cyl_with_plus(h, d, anchor=BOTTOM)
    {
        difference()
        {
            if (show_center)
            {
                union()
                {
                    cuboid([d, 0.5, h], anchor=anchor);
                    cuboid([0.5, d, h], anchor=anchor);
                    tube(h=h, od=d + 0.5, id=d, anchor=anchor);
                }
            }
            else
            {
                cylinder(h=h, d=d, anchor=anchor);
            }
        }
    }
    
    difference()
    {
        cylinder(h=support_plate_thickness, d=support_plate_d, anchor=BOTTOM);
        {
            union()
            {
                down(difference_tolerance)
                cyl_with_plus(h=bearing_width + 2 * difference_tolerance, d=support_plate_shaft_hole_d, 
                              anchor=BOTTOM);
                
                for (port_index = [0:number_ports - 1])
                {
                    port_locator(port_index, port_d, 0)
                    down(difference_tolerance)
                    cyl_with_plus(h=support_plate_thickness + 2 * difference_tolerance, d=support_plate_port_hole_d,
                                  anchor=BOTTOM);
                }
                
                for (port_index = [0:2:number_ports - 1])
                {
                    port_locator(port_index, small_port_d, phase_angle_small)
                    down(difference_tolerance)
                    cyl_with_plus(h=support_plate_thickness + 2 * difference_tolerance,
                                  d=support_plate_small_port_hole_d, anchor=BOTTOM);
                }
                
                for (port_index = [1:2:number_ports - 1])
                {
                    port_locator(port_index, mini_port_d, phase_angle_mini)
                    down(difference_tolerance)
                    cyl_with_plus(h=support_plate_thickness + 2 * difference_tolerance,
                                  d=support_plate_mini_port_hole_d, anchor=BOTTOM);
                }
                
                // Drill the holes the posts for positioning the support plate
                for (post_index = [0:number_ports - 1])
                {
                    zrot(post_index * 360 / number_ports)
                    left(upper_surface_d / 2 - 2 * support_plate_post_d - port_d)
                    down(difference_tolerance)
                    cyl_with_plus(h=support_plate_thickness + 2 * difference_tolerance, d=support_plate_post_d,
                                  anchor=BOTTOM);
                }
                
            }
            
        }
    }
    
}

module support_plate_post()
{
    
    up(support_plate_thickness)
    cylinder(h=lid_mold_height - thickness_below_support_plate, d=support_plate_post_d, anchor=BOTTOM)
    
    recolor("blue")
    down(support_plate_thickness - support_plate_post_ridge_thickness / 2)
    position(TOP)
    torus(od=support_plate_post_d + support_plate_post_ridge_thickness, 
          id=support_plate_post_d - 0.5 * support_plate_post_ridge_thickness, anchor=BOTTOM);
    
}

module holes_for_ports(h, anchor, in_lid=true, cylinder_only, make_screw_hole)
{
    post_increase_d = 0;
    
    // Make the holes for the ports
    for (port_index = [0:number_ports - 1])
    {
        port_label = chr(port_index + ord("A"));
        port_locator(port_index, port_d, 0)
        post_for_port_hole(h, port_d, post_specs_large, anchor, in_lid, cylinder_only, make_screw_hole, port_label)
        
        position(-anchor)
        port_zone(port_d, post_increase_d);
        
    }
    
    for (port_index = [0:2:number_ports - 1])
    {
        port_label = chr(floor(port_index/2) + number_ports + ord("A"));
        port_locator(port_index, small_port_d, phase_angle_small)
        post_for_port_hole(h, small_port_d, post_specs_large, anchor, in_lid, cylinder_only, make_screw_hole, 
                           port_label)
        
        position(-anchor)
        port_zone(small_port_d, post_increase_d);
    }
    
    for (port_index = [1:2:number_ports - 1])
    {
        port_label = chr(floor(port_index/2) + number_ports + 1 + floor((number_ports - 1)/2) + ord("A"));
        port_locator(port_index, mini_port_d, phase_angle_mini)
        post_for_port_hole(h, mini_port_d, post_specs_small, anchor, in_lid, cylinder_only, make_screw_hole, port_label)
        
        position(-anchor)
        port_zone(mini_port_d, post_increase_d);
    }
    
}

module half_prismic_cylinder(top_size, height, anchor, spin, orient, bottom_ratio=1 / 2)
{
    attachable(anchor=anchor, spin=spin, orient=orient, size=[top_size * 1.5, top_size, height],
               size2=[top_size, bottom_ratio * top_size])
    {
        union()
        {
            cylinder(h=height, d1=top_size * bottom_ratio, d2=top_size, anchor=CENTER, spin=spin, orient=UP);
            
            right_half()
            prismoid(size2=[top_size * 1.5, top_size], size1=[top_size * 1.5, top_size * bottom_ratio], h=height,
                     anchor=CENTER, spin=spin, orient=UP);
        }
        children();
    }
}

// Add columns for the magnet traps on the outside of mold cavity
module magnetic_columns(number_columns, height, anchor, spin, orient)
{
    half_prismic_cylinder_top_size = magnetic_column_d * 1.5;
    for (column_index = [0:number_columns - 1])
    {
        zrot(column_index * 360 / number_columns)
        left(jar_od / 2 + 0.75 * half_prismic_cylinder_top_size)
        diff()
        {
            half_prismic_cylinder(half_prismic_cylinder_top_size, height, BOTTOM, spin, orient)
            {
                down(4 * layer_height)
                zrot(90)
                attach(TOP)
                tag("remove")
                circular_magnet_trap_side(struct_val(mold_magnet_dims, "diameter"),
                                          struct_val(mold_magnet_dims, "thickness"),
                                          poke_len=half_prismic_cylinder_top_size + difference_tolerance, poke_diam=1,
                                          anchor=TOP);
            }
            
        }
    }
}

// Add columns for the screws and nut traps on the outside of mold cavity
module screw_together_columns(number_columns, height, anchor, spin, orient)
{
    nut_info = nut_info(mold_screw);
    nut_width = struct_val(nut_info, "width");
    nut_thickness = struct_val(nut_info, "thickness");
    
    half_prismic_cylinder_top_size = nut_width * (use_side_nut_trap ? 1.5 : 2);
    for (column_index = [0:number_columns - 1])
    {
        zrot(column_index * 360 / number_columns)
        left(jar_od / 2 + (use_side_nut_trap ? 0.75 : 0.65) * half_prismic_cylinder_top_size)
        union()
        {
            diff()
            {
                half_prismic_cylinder(half_prismic_cylinder_top_size, height, BOTTOM, spin, orient, bottom_ratio=1.)
                {
                    if (anchor == TOP)
                    {
                        // The top lid mold needs a nut trap
                        if (use_side_nut_trap)
                        {
                            up(nut_thickness + difference_tolerance)
                            zrot(90)
                            attach(BOTTOM)
                            tag("remove")
                            screw_hole(mold_screw, length=2 * height, $slop=screw_hole_slop)
                            nut_trap_side(trap_width=half_prismic_cylinder_top_size,
                                          poke_len=half_prismic_cylinder_top_size + difference_tolerance, poke_diam=1,
                                          anchor=TOP);
                            
                        }
                        else
                        {
                            up(difference_tolerance)
                            zrot(90)
                            attach(BOTTOM)
                            tag("remove")
                            screw_hole(mold_screw, length=2 * height, $slop=screw_hole_slop)
                            
                            up(difference_tolerance * 2)
                            nut_trap_inline(l=nut_thickness * 2, spec=nut_info, orient=UP, anchor=TOP,
                                            $slop=sliding_tolerance / 2);
                            
                        }
                        
                        
                    }
                    else {
                        // The bottom lid mold needs a screw hole.  
                        // When this mold is in place the screw head will be at the top.
                        attach(CENTER)
                        tag("remove")
                        screw_hole(mold_screw, length=2 * height, $slop=screw_hole_slop);
                    }
                }
                
                // Add fillets between the outer mold cylinder and the columns
                up(height)
                union()
                {
                    right(0.75 * half_prismic_cylinder_top_size)
                    back(half_prismic_cylinder_top_size / 2)
                    fillet(height, r=0.75 * half_prismic_cylinder_top_size, ang=90, spin=90, anchor=TOP);
                    
                    right(0.75 * half_prismic_cylinder_top_size)
                    fwd(half_prismic_cylinder_top_size / 2)
                    fillet(height, r=0.75 * half_prismic_cylinder_top_size, ang=90, spin=180, anchor=TOP);
                }
            }
            
        }
    }
}

module post_for_port_hole(h, d, post_connector_specs, anchor, in_lid, cylinder_only, make_screw_hole, port_label="X")
{
    module label_port()
    {
        screw_size = struct_val(post_connector_specs, "size");
        info_on_nut = nut_info(screw_size);
        nut_d = struct_val(info_on_nut, "width");
        
        zrot(30)  // So that the letter will be along a flat side of the hexagon
        left(d / 3)   // Move off the center of the post
        down(post_label_text_depth)
        attachable()
        {
            linear_extrude(post_label_text_depth+difference_tolerance)
            text(port_label, size=nut_d / 2, halign="center", valign="center", $fn=100);
            
            children();
        }
    }
    
    attachable(d=d, h=h)
    {
        if (cylinder_only)
        {
            diff("screw")
            {
                // The post will be shorter than the lid height
                // <post_hole_shortening>  is used when the height will be short by this amount to keep the hole off the bottom
//                up(post_hole_shortening)
                cylinder(h=h, d=d + (show_molded_part || hollow_out_stopper ?2 * difference_tolerance: 0), 
                         anchor=anchor);
            }
        }
        else
        {
            if (struct_val(post_connector_specs, "type") == "screw")
            {
                screw_size = struct_val(post_connector_specs, "size");
                screw_length = struct_val(post_connector_specs, "length");
                screw_head = struct_val(post_connector_specs, "head");
                screw_drive = struct_val(post_connector_specs, "drive");
                info_on_screw = screw_info(screw_size, head=screw_head, drive=screw_drive);
                //                echo_struct(info_on_screw);
                info_on_nut = nut_info(screw_size);
                //                washer_diameter = struct_val(info_on_nut, "width") / sin(60) ;
                screw_head_height = struct_val(info_on_screw, "head_height");
                nut_thickness = struct_val(info_on_nut, "thickness");
                //                echo_struct(info_on_nut);
                
                if (in_lid)
                {
                    // A post in the lid with a clearance hole (no threads) for a screw
                    if (!make_screw_hole) {
                        // A small indent into the surface of the top mold so that the post will align
                        up(mold_wall_thickness + bearing_width + difference_tolerance)
                        cylinder(d2=d, d1=d - height_of_post_recess * 2, h=height_of_post_recess + difference_tolerance,
                                 anchor=BOTTOM);
                        
                        up(post_height_in_top_lid + height_of_post_recess)
                        label_port();
                            
                        
                    }
                    else
                    {
                        // Create an unthreaded hole based on the screw size
                        screw_hole(screw_size, length=screw_length, head=screw_head, thread=false,
                                   counterbore=screw_head_height, tolerance="loose", anchor=TOP, orient=DOWN, $slop=0.);
                    }
                }
                else
                {
                    nut_trap_h = h - screw_length + post_height_in_top_lid + screw_head_height + difference_tolerance;
                    diff("screw")
                    {
                        // Create a bottom chamfered post with an unthreaded hole, and a nut trap
                        down(height_of_post_recess)
                        difference()
                        {
                            cylinder(d=d, h=h, anchor=BOTTOM)
                            {
                                tag("screw")
                                
                                // Identify the port with a letter on the bottom
                                position(BOTTOM)
                                up(post_label_text_depth)
                                xflip()
                                label_port()
                                right(d / 3)   // Move back to the center of the post
                                xflip()
                                
                                position(TOP)
                                down(post_height_in_top_lid)
                                screw_hole(screw_size, length=screw_length, head=screw_head,
                                           thread=false, counterbore=screw_head_height, tolerance="loose", anchor=TOP,
                                           orient=DOWN, $slop=0.)
                                
                                
                                // Allow the nut hole to be a little longer to ensure that the post can be screwed down firmly
                                position(TOP)
                                down(screw_length + screw_head_height - nut_thickness * 2)
                                nut_trap_inline(l=nut_trap_h, spec=info_on_screw, orient=DOWN, anchor=BOTTOM, 
                                                $slop=sliding_tolerance/2)
                                
                                // Identify the port with a letter on the top
                                position(TOP)
                                label_port();
                            }
                        }
                    }

                }
            }
        }
        
        children();
        
    }
}

module cap_for_port_hole_post(d, post_connector_specs, label)
{
    screw_size = struct_val(post_connector_specs, "size");
    info_on_nut = nut_info(screw_size);
    nut_d = struct_val(info_on_nut, "width") / sin(60) + 2 * sliding_tolerance;
    cap_text_height = quantup(0.5, layer_height);
    insert_height = quantup(2, layer_height);
    cap_lid_height = quantup(0.5, layer_height);
    
    module chamfered_hex_cyl()
    {
        attachable()
        {
            difference()
            {
                // Chamfer with a steep angle, the part that will fit into the nut trap 
                cylinder(d=nut_d, h=insert_height, $fn=6, anchor=BOTTOM);
                chamfer_cylinder_mask(d=nut_d, chamfer=insert_height, ang=87, anchor=BOTTOM, $fn=6);
            }
            children();
        }

    }

    union()
    {
        union() {
            // The cap lid
            cylinder(d=d, h=cap_lid_height, anchor=BOTTOM)
            
            down(difference_tolerance)
            position(TOP)
            chamfered_hex_cyl();
        }
        // Label the post cap
        up(cap_lid_height + insert_height-difference_tolerance)
        linear_extrude(cap_text_height)
        text(label, size=nut_d / 2, halign="center", valign="center", $fn=100);
    }
    
}

module caps_for_posts()
{
    post_increase_d = 0;
    
    // Make the cap for the post for the shaft hole
    cap_for_port_hole_post(shaft_clearance_d, post_specs_shaft, "S");

    // Make the caps for the outer posts
    for (port_index = [0:number_ports - 1])
    {
        port_label = chr(port_index + ord("A"));
        port_locator(port_index, port_d, 0)
        cap_for_port_hole_post(port_d, post_specs_large, port_label);
    }
    
    for (port_index = [0:2:number_ports - 1])
    {
        port_label = chr(floor(port_index/2) + number_ports + ord("A"));
        port_locator(port_index, small_port_d, phase_angle_small)
        cap_for_port_hole_post(small_port_d, post_specs_large, port_label);
   }
    
    for (port_index = [1:2:number_ports - 1])
    {
        port_label = chr(floor(port_index/2) + number_ports + 1 + floor((number_ports - 1)/2) + ord("A"));
        port_locator(port_index, mini_port_d, phase_angle_mini)
        cap_for_port_hole_post(mini_port_d, post_specs_small, port_label);
    }
    
}

// This plug may be used in the screw holes in the top lid where a post is not desired
module plug_for_post_screw_hole(d, post_connector_specs, label)
{
    screw_size = struct_val(post_connector_specs, "size");
    info_on_screw = screw_info(screw_size);                
    screw_d = struct_val(info_on_screw, "diameter");

    plug_lid_height = height_of_post_recess;
    normal_screw_tolerance = 0.4;
    
    union() {
        // The plug lid
        cylinder(d=d, h=plug_lid_height, anchor=BOTTOM)
        
        // The plug stem
        position(TOP)
        cylinder(d=screw_d + normal_screw_tolerance, h=quantup(2, layer_height), anchor=BOTTOM);
        
    }
}

module plugs_for_top_lid()
{
    
    // Make the cap for the post for the shaft hole
    plug_for_post_screw_hole(shaft_clearance_d, post_specs_shaft, "S");

    // Make the caps for the outer posts
    for (port_index = [0:number_ports - 1])
    {
        port_label = chr(port_index + ord("A"));
        port_locator(port_index, port_d, 0)
        plug_for_post_screw_hole(port_d, post_specs_large, port_label);
    }
    
    for (port_index = [0:2:number_ports - 1])
    {
        port_label = chr(floor(port_index/2) + number_ports + ord("A"));
        port_locator(port_index, small_port_d, phase_angle_small)
        plug_for_post_screw_hole(small_port_d, post_specs_large, port_label);
   }
    
    for (port_index = [1:2:number_ports - 1])
    {
        port_label = chr(floor(port_index/2) + number_ports + 1 + floor((number_ports - 1)/2) + ord("A"));
        port_locator(port_index, mini_port_d, phase_angle_mini)
        plug_for_post_screw_hole(mini_port_d, post_specs_small, port_label);
    }
    
}

module lid_top_mold()
{
    // The recessed post mounting areas OR the posts used for showing the molded part
    module post_mounting_areas()
    {
        union()
        {
            // Make the post for the shaft that will create the hole in the molded part
            //                    down(show_molded_part ? post_hole_shortening : 0)
            post_for_port_hole(post_height_in_top_lid + (show_molded_part?lid_mold_height:0), shaft_clearance_d,
                                post_specs_shaft, BOTTOM, true, show_molded_part || hollow_out_stopper, false,
                                "S");
            
            // Create the posts that will create the holes for the instruments
            //                    down(show_molded_part ? post_hole_shortening : 0)
            holes_for_ports(post_height_in_top_lid + (show_molded_part?lid_mold_height:0), BOTTOM, true,
                            show_molded_part || hollow_out_stopper, false);
        }
    }
    
    if (show_support_plate)
    {
        // Show where the support plate will be
        recolor("cyan")
        up(lid_mold_height - thickness_below_support_plate - support_plate_post_ridge_thickness / 2)
        #support_plate();
    }
    
    diff("screw")
    {
        difference()
        {
            union()
            {
                cylinder(h=lid_mold_height, d=jar_od + mold_wall_thickness, anchor=BOTTOM);
                
                if (use_screws_to_hold_together_mold_halves)
                    // Add columns for the screws nut traps on the outside of mold cavity
                    screw_together_columns(number_mold_joining_columns, lid_mold_height, anchor=TOP, spin=0,
                                           orient=UP);
                else
                    // Add columns for the magnet traps on the outside of mold cavity - THIS IS DEPRECATED, use screws 
                    // to hold_together mold the halves instead
                    magnetic_columns(number_mold_joining_columns, lid_mold_height, anchor=TOP, spin=0,
                                     orient=UP);
            }
            
            if (!show_molded_part)
            {
                // Make a chamfered pocket for the post to sit in
                down(height_of_post_recess - difference_tolerance)
                post_mounting_areas();
            }

            // The lid, including the well for the bearing
            up(lid_mold_height)
            union()
            {
                up(difference_tolerance)
                cylinder(h=gasket_thickness_qup + difference_tolerance, d1=jar_od,
                         d2=jar_od - draft_dia_adjustment(gasket_thickness), anchor=TOP)
                
                // The section with the embedded support plate overlaps the gasket
                position(BOTTOM)
                up(gasket_thickness_qup)
                cylinder(h=thickness_above_rim_qup, d1=layer_containing_support_plate_d, d2=upper_surface_d,
                         anchor=TOP)
                
                position(BOTTOM)
                up(difference_tolerance)
                diff()
                {
                    tube(h=bearing_width_qup + difference_tolerance, id=bearing_od,
                         od=bearing_od + 2 * bearing_pocket_wall_thickness, anchor=TOP)
                    
                    attach([BOTTOM]) tag("remove")
                    down(2)
                    chamfer_cylinder_mask(r=bearing_od / 2 + bearing_pocket_wall_thickness, chamfer=2, anchor=BOTTOM);
                }
                
            }
        }
        
        tag("screw")
        union()
        {
            // Hollow out the clearance holes for the screws that are used to attach the posts
            post_for_port_hole(post_height_in_top_lid, shaft_clearance_d, post_specs_shaft, BOTTOM, true, false, true, 
                               "S");
            holes_for_ports(post_height_in_top_lid, BOTTOM, true, false, true);
        }
        
    }
    
    if (show_molded_part) 
    {
        // Remove the posts when creating the view of the molded part
        post_mounting_areas();
    }
    
    if (add_support_plate_posts)
    {
        // Add the posts for positioning the support plate, including a rings that will trap the support plate when embedding it
        for (post_index = [0:number_ports - 1])
        {
            zrot(post_index * 360 / number_ports)
            left(upper_surface_d / 2 - 2 * support_plate_post_d - port_d)
            support_plate_post();
        }
    }
    
}

module lid_bottom_mold()
{
    /*     
           // Used during development to show where the gasket region is  
           up(taper_height)
           %cylinder(h = gasket_thickness, d1 = jar_od, d2 = jar_od - draft_dia_adjustment(gasket_thickness),
           anchor = BOTTOM);
   */
    
    difference()
    {
        union()
        {
            cylinder(h=lid_bottom_mold_height, d=jar_od + mold_wall_thickness, anchor=BOTTOM);
            
            if (use_screws_to_hold_together_mold_halves)
                // Add columns for the screws nut traps on the outside of mold cavity
                screw_together_columns(number_mold_joining_columns, lid_bottom_mold_height, anchor=BOTTOM, spin=0,
                                       orient=UP);
            else
                // Add columns for the magnet traps on the outside of mold cavity
                magnetic_columns(number_mold_joining_columns, lid_bottom_mold_height, anchor=BOTTOM, spin=0,
                                 orient=UP);
        }
        
        down(difference_tolerance)
        difference()
        {
            cylinder(h=taper_height, d1=lid_taper_smallest_d, d2=jar_mouth_largest_id, anchor=BOTTOM);
            
            if (hollow_out_stopper)
            {
                // Hollow out the interior
                down(difference_tolerance)
                cylinder(h=taper_height, d1=exterior_dome_diameter_base, d2=exterior_dome_diameter_top, anchor=BOTTOM);
                
                // Make bridges for the silicone pour channels to join the interior to the exterior of the mold 
                number_channels = 4;
                for (channel_index = [0:number_channels - 1])
                {
                    zrot(channel_index * 360 / number_channels)
                    left(jar_mouth_largest_id / 2 - stopper_taper_width)
                    down(difference_tolerance)
                    cube([stopper_taper_width * 2, stopper_taper_width * 2, 2 + difference_tolerance], anchor=BOTTOM);
                }
            }
        }
        
    }
}

module lid_cutting_jig()
{
    //Get the information on the nut used to attach the lid to the support
    lid_nut_info = nut_info(screw_for_holding_lid);
    lid_nut_width = struct_val(lid_nut_info, "width");
    lid_nut_thickness = struct_val(lid_nut_info, "thickness");
    dome_height_above_nut = lid_nut_width / 2.5;
    
    jig_wall_thickness = 2;
    min_support_width = 6;
    number_supports = 2;
    support_dims = [jar_od - 2 * jar_rim_thickness, lid_nut_width + 4, 2 * lid_nut_thickness + dome_height_above_nut];
    min_support_height = support_dims[2];
    max_support_height = jar_lid_height;
    pivot_hole_d = inch_to_mm(1 / 16);
    max_cutter_height = 5;
    
    partial_support_only = false;
    
    difference()
    {
        union()
        {
            difference()
            {
                xrot(180)
                sp_neck(jar_nominal_dia, jar_type_number, jar_rim_thickness, anchor=TOP);
                if (partial_support_only)
                {
                    for (support_index = [0:number_supports - 1])
                    {
                        zrot(support_index * 180 / (number_supports / 2) + 30 / (number_supports / 2))
                        down(difference_tolerance)
                        pie_slice(ang=120 / (number_supports / 2), l=20 + 2 * difference_tolerance, d=jar_od, 
                                  anchor=BOTTOM);
                    }
                }
            }
            
            for (support_index = [0:number_supports - 1])
            {
                zrot(support_index * 180 / (number_supports / 2))
                {
                    cuboid(support_dims, anchor=BOTTOM);
                    
                    left(jar_mouth_largest_id / 2 - support_dims[1] / 2)
                    diff()
                    {
                        cuboid([support_dims[1], support_dims[1], jar_lid_height - 1], anchor=BOTTOM)
                        {
                            edge_mask(TOP + RIGHT)
                            chamfer_edge_mask(l=support_dims[1], chamfer=support_dims[1] - 2);
                        }
                    }
                }
                
            }
        }
        
        down(difference_tolerance)
        union()
        {
            down(difference_tolerance)
            tube(h=max_cutter_height / 2 + 2 * difference_tolerance,
                 or=cutting_r + (bit_diameter + bit_clearance) / 2,
                 ir=cutting_r - (bit_diameter + bit_clearance) / 2, anchor=BOTTOM)
            position(TOP)
            torus(or=cutting_r + (bit_diameter + bit_clearance) / 2,
                  ir=cutting_r - (bit_diameter + bit_clearance) / 2, anchor=CENTER);
            
            
            
            // Make the hole in the center for the pivot
            down(difference_tolerance)
            cylinder(h=min_support_height + 2 * difference_tolerance, d=pivot_hole_d, anchor=BOTTOM);
            
            // Make the holes in the support to attach the lid
            for (support_index = [0:number_supports - 1])
            {
                zrot(support_index * 180 / (number_supports / 2))
                left(jar_mouth_largest_id / 4)
                down(difference_tolerance)
                cylinder(h=min_support_height + 2 * difference_tolerance, d=pivot_hole_d, anchor=BOTTOM)
                
                // Create a domed nut trap for the screw
                zrot(90)
                down(dome_height_above_nut / 2)
                position(CENTER)
                screw_hole(screw_for_holding_lid, length=support_dims[1] + dome_height_above_nut, $slop=screw_hole_slop)
                nut_trap_side(trap_width=support_dims[1], poke_len=support_dims[1], anchor=CENTER)
                
                if (dome_height_above_nut > 0) {
                    position(TOP)
                    top_half()
                    onion(d=lid_nut_width, cap_h=dome_height_above_nut);
                }
                else
                    children();
                
            }
            
            // Make the hole at the center of where the router bit will be as a guide for drilling the hole
            down(difference_tolerance)
            left(cutting_r)
            cylinder(h=jar_lid_height + 2 * difference_tolerance, d=pivot_hole_d, anchor=BOTTOM);
            
            // Label the screw hole
            text_depth = 1;
            up(min_support_height - text_depth / 2)
            left(jar_mouth_largest_id / 4 - lid_nut_width / 2)
            linear_extrude(text_depth)
            text(screw_for_holding_lid, size=support_dims[1] / 3, halign="left",
                 valign="center", $fn=100);
            
            // Inscribe the jar lid type
            path = path3d(arc(n=100, d=jar_mouth_largest_id + 3 * jar_rim_thickness,
                              angle=[130, 230]));
            specs_text_height = 2.5;
            up(jar_lid_height - specs_text_height)
            path_text(path, jar_nominal_dia_and_type_number, h=jar_lid_height / 2.5, size=specs_text_height, 
                      center=true, valign="top", textmetrics=true);
            
        }
    }
}

module lid_top_from_mold(show_molded_part)
{
    up(show_molded_part ? lid_mold_height : 0)
    xrot(show_molded_part ? 180: 0)
    difference()
    {
        if (show_molded_part) {
            up(difference_tolerance)
            cylinder(h=lid_mold_height - 2 * difference_tolerance, d=jar_od);
        }
        lid_top_mold();
        
    }
    
}

module lid_bottom_from_mold(show_molded_part)
{
    up(taper_height)
    xrot(180)
    difference()
    {
        if (show_molded_part)
        {
            cylinder(h=taper_height, d2=lid_taper_smallest_d, d1=jar_mouth_largest_id, anchor=BOTTOM);
        }
        xrot(180)
        down(taper_height + difference_tolerance)
        lid_bottom_mold();
        
        if (show_molded_part)
        {
            if (hollow_out_stopper)
            {
                down(difference_tolerance)
                cylinder(h=taper_height + mold_wall_thickness + 2 * difference_tolerance, 
                         d2=diameter_inside_hollow_of_tapered_base, 
                         d1=diameter_inside_hollow_of_tapered_base_with_draft,
                         anchor=BOTTOM);
                
            }
            else
            {
                down((height_of_posts_when_using_solid_bottom - taper_height) - difference_tolerance)
                {
                    holes_for_ports(height_of_posts_when_using_solid_bottom, BOTTOM, false, true);
                    post_for_port_hole(height_of_posts_when_using_solid_bottom, shaft_clearance_d, post_specs_shaft,
                                       BOTTOM, false, true, "S");
                    
                }
            }
        }
        
    }
}

module show_parts()
{
    // Allow a cross section to be displayed for any part
    half_of(cut_plane_normal, s=show_cross_section_view == "none" ? 0 : 200)
    
    if (part_to_show == "lid top mold")
    {
        lid_top_from_mold(show_molded_part);
    }
    else if (part_to_show == "lid bottom mold")
    {
        lid_bottom_from_mold(show_molded_part);
    }
    else if (part_to_show == "jar lid from mold")
    {
        union()
        {
            up(show_molded_part ? 0: lid_mold_height + lid_bottom_mold_height)
            xrot(show_molded_part ? 0: 180)
            lid_bottom_from_mold(show_molded_part);
            
            up(show_molded_part ? lid_bottom_mold_height : 0)
            lid_top_from_mold(show_molded_part);
            
            if (!show_molded_part && !hollow_out_stopper)
            {
                recolor("#00bbff")
                up(post_height_in_top_lid)
                {
                    holes_for_ports(height_of_posts_when_using_solid_bottom, BOTTOM, false, false, false);
                    post_for_port_hole(height_of_posts_when_using_solid_bottom, shaft_clearance_d, post_specs_shaft,
                                       BOTTOM, false, false, false, "S");
                    
                }
                
            }
        }
        
    }
    else if (part_to_show == "posts for solid bottom design")
    {
        holes_for_ports(height_of_posts_when_using_solid_bottom, BOTTOM, false, false, false);
        post_for_port_hole(height_of_posts_when_using_solid_bottom, shaft_clearance_d, post_specs_shaft, BOTTOM, false,
                           false, false, "S");
    }
    
    else if (part_to_show == "jar lid cutting jig")
    {
        lid_cutting_jig();
    }
    else if (part_to_show == "18 mm port mold")
    {
        mold_for_bung_for_port(port_d);
    }
    else if (part_to_show == "14 mm port mold")
    {
        mold_for_bung_for_port(small_port_d);
    }
    else if (part_to_show == "10 mm port mold")
    {
        mold_for_bung_for_port(mini_port_d);
    }
    else if (part_to_show == "plate drilling template")
    {
        projection(cut=true)
        down(support_plate_thickness / 2)
        support_plate(true);
    }
    else if (part_to_show == "test post hole fit")
    {
        // Cut out a part of the lid top mold to print the parts for testing the fit of the post 
        
        // The post for the center hole
        up(height_of_post_recess)
        post_for_port_hole(height_of_posts_when_using_solid_bottom, shaft_clearance_d, post_specs_shaft, BOTTOM, false,
                           false, false, "S");

        // Make the cap for the post for the shaft hole
        left(bearing_od + 2 * bearing_pocket_wall_thickness)
/*
        // Use these 3 lines instead of the above line when visualising the part in place
        up(height_of_posts_when_using_solid_bottom)
        zflip()
        zrot(30)
*/
        cap_for_port_hole_post(shaft_clearance_d, post_specs_shaft, "S");

        right(bearing_od + 2 * bearing_pocket_wall_thickness)
        // Use this next line instead of the previous line when visualising the part in place
//        down(bearing_width+mold_wall_thickness-height_of_post_recess)
        intersection()
        {
            lid_top_from_mold(show_molded_part);
            down(difference_tolerance)
            cylinder(h=lid_mold_height, d=bearing_od, anchor=BOTTOM);
        }
        
        // Make a plug for the lid screw hole
        back(bearing_od + 2 * bearing_pocket_wall_thickness)
        plug_for_post_screw_hole(shaft_clearance_d, post_specs_shaft, "S");
        
    }
    else if (part_to_show == "caps for posts")
    {
        caps_for_posts();
    }
    else if (part_to_show == "plugs for lid")
    {
//        plug_for_post_screw_hole(shaft_clearance_d, post_specs_shaft, "S");

        plugs_for_top_lid();
    }
    else if (part_to_show == "test screw together columns")
    {
        // Use this to test a single column for the outside of the mold
        
        // Lid top column (actually on the bottom when the mold is assembled)
        screw_together_columns(1, lid_mold_height, anchor=TOP, spin=0, orient=UP);
        
        // Lid bottom column (actually on the top when the mold is assembled)
        zrot(90)
        screw_together_columns(1, lid_bottom_mold_height, anchor=BOTTOM, spin=0, orient=UP);
    }
    else if (part_to_show == "test jar insert")
    {
        test_insert();
    }
    
}

show_parts();