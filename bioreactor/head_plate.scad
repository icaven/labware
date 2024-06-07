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
part_to_show = "jar lid from mold"; // ["jar lid from mold","lid_top_mold","lid_bottom_mold","plate drilling template","jar lid cutting jig","18 mm port mold","10 mm port mold","6 mm port mold","test"]

// Show the embedded support_plate
show_support_plate = true; 
// Thickness of embedded support plate (accounting for convexity)
support_plate_thickness = 1.5; // 0.1
// Reveal the embedded support plate
show_cross_section = false;
// Reveal the zone around a port that nothing else should intrude into
show_port_zones = false;
// for the mold parts
show_molded_part = false;
// Hollow out beneath the support support plate
hollow_out_stopper = true;

/* [Jar specification] */

jar_nominal_dia_and_type_number = "110-400";
// The size of the screw for attaching the lid to the center bar
screw_for_holding_lid = "6-32";  // ["6-32", "M4", "M3"]

/* [Port specifications] */
// Number of large ports (the number of each of the smaller ports will be half of this)
number_ports = 6;

// Diameter of the 3 sizes of ports
port_d = 18;
small_port_d = 10;
mini_port_d = 6;

port_height = 6;
// Width of the ledge inside the large ports, to allow an insert to narrow the opening
port_inner_support_width = 0; // 0.1
// Thickness of the walls of the ports
threaded_post_wall_thickness = 2.8; // 0.1

/* [Bearing choice] */
bearing_to_use = "608ZZ"; // ["608ZZ", "R4ZZ", "635ZZ", "685ZZ"]

/* [Mold specifications] */
// Printer layer height (for the Prusa Mini)
layer_height = 0.2; // [0.05, 0.07, 0.1, 0.15, 0.2, 0.25]

// Minimum thickness of the mold walls in layer_height units
mold_wall_thickness_num_layers = 10;
// Angle from vertical to make the extraction from the mold easier
mold_draft_angle = 1;

/* [Other specifications] */
impeller_shaft_diameter = 6.35;
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
screw_hole_slop = 0.05;

mold_wall_thickness = mold_wall_thickness_num_layers * layer_height;

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

// Use to drill holes in the support plate manually using commonly drill bit sizes
support_plate_shaft_hole_d = 25.4 * 3 / 8;
support_plate_port_hole_d = 25.4 * 5 / 8;
support_plate_small_port_hole_d = 25.4 * 1 / 2;
support_plate_mini_port_hole_d = 25.4 * 3 / 8;

/**
  Dimensions of the jar and lid
 */
jar_nominal_dia = parse_int(str_split(jar_nominal_dia_and_type_number, "-")[0]);
jar_type_number = parse_int(str_split(jar_nominal_dia_and_type_number, "-")[1]);
//echo("jar_nominal_dia = ", jar_nominal_dia);
//echo("jar_type_number = ", jar_type_number);

//jar_od = sp_diameter(jar_nominal_dia, jar_type_number);

function inch_to_mm(x) = 25.4 * x;
selected_jars_by_trade_size = [
    // trade_size, T,          E,                 H,              I_min, R_max, thread_r, S, number_turns, TPI, type, 
        [110, inch_to_mm(4.307), inch_to_mm(4.187), inch_to_mm(0.582), inch_to_mm(3.737), inch_to_mm(0.078), inch_to_mm(
    0.06), inch_to_mm(0.062), 1.0, 5, "A",],
    ];

jar_info_index = search([jar_nominal_dia], selected_jars_by_trade_size, 1);
assert(jar_info_index != [], str("Unsupported jar size: ", jar_type_number));
jar_info = selected_jars_by_trade_size[jar_info_index[0]];

// The diameter of the outside of the jar threads
jar_od = jar_info[1];

// The height of the lid
jar_lid_height = jar_info[3];
taper_height = jar_lid_height;      // Make the height of the tapered head plate the same as the lid height


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

mold_magnet_dims = struct_set([], ["diameter", 8, "thickness", 3]);

thickness_above_support_plate = 2;
thickness_below_support_plate = 2;
support_plate_surround_thickness = thickness_above_support_plate + thickness_below_support_plate;
thickness_above_rim = support_plate_thickness + support_plate_surround_thickness;

// Posts that keep the support_plate in place during molding
support_plate_post_d = inch_to_mm(1/8);
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
difference_tolerance = 0.01;

gasket_thickness_qup = quantup(gasket_thickness, layer_height);
thickness_above_rim_qup = quantup(thickness_above_rim, layer_height);
stopper_thickness_qup = quantup(stopper_thickness, layer_height);
bearing_width_qup = quantup(bearing_width, layer_height);
lid_mold_height = thickness_above_rim_qup+mold_wall_thickness+bearing_width_qup+difference_tolerance;
number_magnetic_columns = 3;
magnetic_column_d = struct_val(mold_magnet_dims, "diameter")+mold_wall_thickness;
impeller_shaft_d_slide = impeller_shaft_diameter + 2*sliding_tolerance;

// Variables used to control the hollowing out of the base inside the tapered walls.  A small angle is used to 
// allow the part to be extracted from the mold more easily.
diameter_outside_hollow_of_tapered_base = lid_taper_smallest_d;
// The draft angle could be used instead of the taper angle, but since there is enough clearance for the instruments
// to be inserted through the outermost ports, the extra supporting material that the taper angle provides may be used
//diameter_outside_hollow_of_tapered_base_with_draft = diameter_outside_hollow_of_tapered_base - draft_dia_adjustment(taper_height+2*difference_tolerance);
diameter_outside_hollow_of_tapered_base_with_draft = diameter_outside_hollow_of_tapered_base - taper_dia_adjustment(taper_height);
diameter_inside_hollow_of_tapered_base = diameter_outside_hollow_of_tapered_base - 2*mold_wall_thickness;
diameter_inside_hollow_of_tapered_base_with_draft = diameter_outside_hollow_of_tapered_base_with_draft - 2*mold_wall_thickness;
exterior_dome_diameter_base = diameter_outside_hollow_of_tapered_base - 2 * stopper_taper_width;
exterior_dome_diameter_top = diameter_outside_hollow_of_tapered_base_with_draft - 2 * stopper_taper_width;
interior_dome_diameter_base = diameter_inside_hollow_of_tapered_base - 2 * stopper_taper_width;
interior_dome_diameter_top = diameter_inside_hollow_of_tapered_base_with_draft - 2 * stopper_taper_width;


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
    tube(h = h, od1 = new_largest_d, id1 = new_largest_d - thickness, od2 = smallest_d, id2 = smallest_d - thickness,
    anchor = BOTTOM);

}


module threaded_post_for_shaft()
{
    // For testing, show the size of the hole in the support plate
    //         #cylinder(h = bearing_width + 2 * difference_tolerance, d = 25.4 * 3 / 8, anchor = BOTTOM);

    // For testing, show the extent of the zone around the shaft port
    port_zone(bearing_od + 2 * difference_tolerance, 4 * threaded_post_wall_thickness);

    difference()
    {
        trapezoidal_threaded_rod(d = bearing_od + 2 * threaded_post_wall_thickness, height = bearing_width,
        pitch = mounting_plate_thread_pitch, thread_depth = mounting_plate_thread_depth,
        thread_angle = trapezoidal_thread_angle, internal = false, starts = 1,
        blunt_start = true, anchor = BOTTOM);

        down(difference_tolerance)
        cylinder(h = bearing_width + 2 * difference_tolerance, d = bearing_od, anchor = BOTTOM);
    }
}

module port_zone(port_od, post_increase_d)
{
    if (show_port_zones)
    // For testing, show the extent of the zone around the port
    #cylinder(h = port_height + 2 * difference_tolerance, d = port_od + post_increase_d, anchor = BOTTOM);
}

module threaded_post_for_port(port_od, post_increase_d, hole_size_reduction)
{
    diameter_in_stopper = port_od + post_increase_d;

    // For testing, show the size of the hole in the support plate
    //     #cylinder(h=port_height+2*difference_tolerance, d=25.4*5/8, anchor = BOTTOM);

    // For testing, show the extent of the zone around the port
    //      port_zone(port_od, post_increase_d);
    difference()
    {
        trapezoidal_threaded_rod(d = port_od + 2 * threaded_post_wall_thickness, height = port_height,
        pitch = mounting_plate_thread_pitch, thread_depth = mounting_plate_thread_depth,
        thread_angle = trapezoidal_thread_angle, internal = false, starts = 1,
        blunt_start = true, anchor = BOTTOM);

        /*
                position(BOTTOM)
                #trapezoidal_threaded_rod(d = diameter_in_stopper, height = support_plate_surround_thickness/2 - 0.5,
                pitch = mounting_plate_thread_pitch/2, thread_depth = mounting_plate_thread_depth,
                thread_angle = trapezoidal_thread_angle, internal = false, starts = 1,
                blunt_start = true, anchor = TOP);
        */

        down(difference_tolerance)
        cylinder(h = port_height + 2 * difference_tolerance, d = port_od, anchor = BOTTOM);


        /*
                position(BOTTOM)
                up(difference_tolerance)
                #cylinder(h = support_plate_surround_thickness / 2 + 2 * difference_tolerance,
                d = port_od - 2 * hole_size_reduction, anchor = TOP);
        */
    }
}

module tapered_threaded_part(l, d, pitch, left_handed = false, bevel, bevel1, bevel2, hollow = false,
    internal = false, anchor, spin, orient)
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
    attachable(anchor, spin, orient, l = l, r1 = r1, r2 = r2) {
        difference() {
            generic_threaded_rod(
            d1 = 2 * r1, d2 = 2 * r2, l = l,
            pitch = pitch,
            profile = profile,
            left_handed = left_handed,
            bevel = bevel, bevel1 = bevel1, bevel2 = bevel2,
            internal = internal,
            blunt_start = true,
            $slop = tapered_nut_slop);
            if (!is_undef(hollow) && hollow) cylinder(h = l + 1, d = hollow, center = true);
        }
        children();
    }
}
module mold_for_threaded_post_for_port(port_od, post_increase_d, hole_size_reduction, snap_pin_specs, partition_specs)
{
    nozzle_diameter = 0.4;
    spread_of_partition_halves = 10;
    cutsize = 1;
    mold_wall_thickness = 1;
    edge_thickness = threaded_post_wall_thickness + mold_wall_thickness;
    inner_chamfer_height = mounting_plate_thread_pitch;
    snap_pin_size = struct_val(snap_pin_specs, "size");
    snap_pin_length = struct_val(snap_pin_specs, "length");
    mold_od = port_od + 2 * inner_chamfer_height + edge_thickness;
    mold_height = port_height + inner_chamfer_height + 2 * mold_wall_thickness + snap_pin_length;

    retaining_ledge_thickness = 3 * nozzle_diameter;
    retaining_nut_thickness = 4;
    retaining_nut_side_thickness = 4;
    retaining_nut_id = mold_od + 2 * retaining_nut_side_thickness;
    retaining_nut_od = retaining_nut_id + 4;
    retaining_nut_thread_pitch = 1;


    module mold()
    {
        intersection()
        {
            union()
            {
                difference()
                {
                    intersection()
                    {
                        union()
                        {
                            tube(h = mold_height, od = mold_od,
                            id = port_od + difference_tolerance, anchor = BOTTOM);

                            // Add the cap
                            up(mold_height)
                            cylinder(h = mold_wall_thickness, d = mold_od, anchor = TOP);
                        }

                        tapered_threaded_part(l = mold_height, d = mold_od, pitch = 1,
                        anchor = BOTTOM, orient = UP);
                    }
                    threaded_post_for_port(port_od, post_increase_d, hole_size_reduction);
                }

                // Add the snap pin for the internal cylinder
                up(mold_height - mold_wall_thickness)
                difference()
                {
                    cylinder(r = port_od / 2, h = snap_pin_length, anchor = TOP);
                    snap_pin_socket(size = snap_pin_size, pointed = false, anchor = TOP, orient = UP);
                }

                // Add a ledge that will allow the post to be retained on the head plate during molding using the
                // retaining nut
                tube(h = retaining_ledge_thickness, od = retaining_nut_od, id = mold_od - 2 * mold_wall_thickness,
                anchor = BOTTOM);
            }

            // Flatten two opposite sides, so that when the mold is partitioned, the flat side can lie on the print bed
            cuboid([retaining_nut_od, mold_od - 4 * mold_wall_thickness, mold_height],
            anchor = BOTTOM);
        }

    }

    module post_docking_space()
    {
        difference()
        {
            threaded_rod(d = retaining_nut_id, height = retaining_nut_thickness, pitch = retaining_nut_thread_pitch,
            end_len1 = retaining_ledge_thickness, blunt_start = true, bevel2 = false,
            anchor = BOTTOM);

            // Flatten two opposite sides, so that when the mold is partitioned, the flat side can lie on the print bed
            down(difference_tolerance)
            cuboid([retaining_nut_od, mold_od - 4 * mold_wall_thickness + 2 * sliding_tolerance, retaining_nut_thickness
                + 2 * difference_tolerance],
            anchor = BOTTOM);
        }

        right_half()
        intersection()
        {
            tube(h = retaining_ledge_thickness, id = retaining_nut_od, od = retaining_nut_od + 6,
            anchor = BOTTOM);
            down(difference_tolerance)
            cuboid([retaining_nut_od + 6, mold_od - 4 * mold_wall_thickness, retaining_nut_thickness + 2 *
                difference_tolerance],
            anchor = BOTTOM);

        }


    }

    module retaining_nut()
    {
        recolor("blue")
        zrot(180)
        threaded_nut(nutwidth = retaining_nut_od, id = retaining_nut_id, h = retaining_nut_thickness,
        pitch = retaining_nut_thread_pitch, bevel = false, ibevel = false, anchor = BOTTOM,
        $slop = slop);
    }

    module internal_post_hollow_mask()
    {
        cylinder(h = stopper_thickness + port_height, d = port_od, anchor = BOTTOM)
        down(snap_pin_length)
        position(TOP)
        snap_pin(snap_pin_size, l = snap_pin_length, snap = 0.125 * port_od / 2, anchor = BOTTOM, orient = UP, pointed =
        false
        , thickness = 1);
    }

    module tapered_nut_for_mold()
    {
        up(mold_height + mold_wall_thickness)
        xrot(180)
        difference()
        {
            tex = texture("pyramids_vnf", $fn = 16);
            linear_sweep(
            circle(d = mold_od + 2 * mold_wall_thickness), texture = tex, h = mold_height + mold_wall_thickness,
            tex_size = [4, 4], style = "concave", anchor = BOTTOM
            );

            tapered_threaded_part(l = mold_height, d = mold_od, pitch = 1, internal = true, hollow = undef,
            anchor = TOP, orient = DOWN);

        }
    }

    module partition_mold(partition_specs)
    {
        cutsize = struct_val(partition_specs, "cutsize");
        gap = struct_val(partition_specs, "gap");
        cutpath = struct_val(partition_specs, "cutpath");

        //        %partition_cut_mask(l=port_od*4, h=mold_height*2, cutsize=cutsize, gap=gap, cutpath=cutpath, anchor=CENTER);
        partition([port_od * 6, port_od, mold_height * 2], cutsize = cutsize, gap = gap, cutpath = cutpath, spread =
        spread_of_partition_halves)
        mold();

    }

    module part_a()
    {
        xrot(180)
        back(mold_height / 2)
        zrot(180)
        back(mold_height / 2)
        xrot(90)
        fwd(spread_of_partition_halves / 2 + mold_od / 2 - mold_wall_thickness)
        back_half()
        partition_mold(partition_specs);

    }
    module part_b()
    {
        xrot(180)
        fwd(mold_height / 2)
        zrot(180)
        fwd(mold_height / 2)
        xrot(-90)
        back(spread_of_partition_halves / 2 + mold_od / 2 - mold_wall_thickness)
        front_half()
        partition_mold(partition_specs);

    }

    // Show all the parts to be printed
    distribution_spacing = [mold_od, mold_od, mold_od, port_od, retaining_nut_od];
    distribute(spacing = 10, sizes = distribution_spacing, dir = RIGHT)
    {
        recolor("green")
        part_a();
        fwd(mold_height)
        part_b();
        tapered_nut_for_mold();
        internal_post_hollow_mask();
        retaining_nut();

    }
    //        partition_mold(partition_specs);
    //    mold();
    /*
        zrot(90)
        {
            mold();
            recolor("orange")
            post_docking_space();
            up(retaining_ledge_thickness)
            retaining_nut();
        }
    */
}

module port_locator(port_index, port_od, phase_angle)
{
    angle_of_port = port_index * 360 / number_ports + phase_angle;
    zrot(angle_of_port)
    fwd(support_plate_or - port_od / 2 - threaded_post_wall_thickness)
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
                    cuboid([d, 0.5, h], anchor = anchor);
                    cuboid([0.5, d, h], anchor = anchor);
                    tube(h = h, od = d+0.5, id=d, anchor = anchor);
                }
            }
            else
            {
                cylinder(h = h, d = d, anchor = anchor);
            }
        }
    }
    
    difference()
    {
        cylinder(h = support_plate_thickness, d = support_plate_d, anchor = BOTTOM);
        {
            union()
            {
                down(difference_tolerance)
                cyl_with_plus(h = bearing_width + 2 * difference_tolerance, d = support_plate_shaft_hole_d, anchor = BOTTOM);

                for (port_index = [0:number_ports - 1])
                {
                    port_locator(port_index, port_d, 0)
                    down(difference_tolerance)
                    cyl_with_plus(h = support_plate_thickness + 2 * difference_tolerance, d = support_plate_port_hole_d,
                    anchor = BOTTOM);
                }

                for (port_index = [0:2:number_ports - 1])
                {
                    port_locator(port_index, small_port_d, phase_angle_small)
                    down(difference_tolerance)
                    cyl_with_plus(h = support_plate_thickness + 2 * difference_tolerance, d = support_plate_small_port_hole_d
                    , anchor = BOTTOM);
                }

                for (port_index = [1:2:number_ports - 1])
                {
                    port_locator(port_index, mini_port_d, phase_angle_mini)
                    down(difference_tolerance)
                    cyl_with_plus(h = support_plate_thickness + 2 * difference_tolerance, d = support_plate_mini_port_hole_d,
                    anchor = BOTTOM);
                }
                
                // Drill the holes the posts for positioning the support plate
                for (post_index = [0:number_ports - 1])
                {
                    zrot(post_index * 360 / number_ports)
                    left(upper_surface_d / 2 - 2 * support_plate_post_d - port_d)
                    down(difference_tolerance)
                    cyl_with_plus(h = support_plate_thickness + 2 * difference_tolerance, d = support_plate_post_d,
                    anchor = BOTTOM);
                }

            }

        }
    }

}

module support_plate_post()
{
    up(thickness_above_rim)
    {
        cylinder(h = thickness_above_rim, d = support_plate_post_d, anchor = TOP)
        
        recolor("blue")
        position(BOTTOM)
        up(thickness_below_support_plate + support_plate_thickness - support_plate_post_ridge_thickness / 2)
        torus(od = support_plate_post_d + support_plate_post_ridge_thickness, id = support_plate_post_d - 0.5 *
            support_plate_post_ridge_thickness, anchor = BOTTOM);

    }
}

module holes_for_ports()
{
    post_increase_d = 0;

    // Make the holes for the ports
    for (port_index = [0:number_ports - 1])
    {
        port_locator(port_index, port_d, 0)
        down(difference_tolerance)
        cylinder(h = stopper_thickness + port_height + 2 * difference_tolerance,
        d = port_d - 2 * port_inner_support_width, anchor = BOTTOM)

        position(TOP)
        port_zone(port_d, post_increase_d);

    }

    for (port_index = [0:2:number_ports - 1])
    {
        port_locator(port_index, small_port_d, phase_angle_small)
        down(difference_tolerance)
        cylinder(h = stopper_thickness + port_height + 2 * difference_tolerance,
        d = small_port_d, anchor = BOTTOM)

        position(TOP)
        port_zone(small_port_d, post_increase_d);
    }

    for (port_index = [1:2:number_ports - 1])
    {
        port_locator(port_index, mini_port_d, phase_angle_mini)
        down(difference_tolerance)
        cylinder(h = stopper_thickness + port_height + 2 * difference_tolerance,
        d = mini_port_d, anchor = BOTTOM)

        position(TOP)
        port_zone(mini_port_d, post_increase_d);
    }

}

module magnetic_columns(height, anchor=BOTTOM, orient=DOWN, spin=90)
{
    // Add columns for the magnet traps on the outside of mold cavity
    for (column_index = [0:number_magnetic_columns-1])
    {
        zrot(column_index*360/number_magnetic_columns)
        left(jar_od/2+0.75*magnetic_column_d)
        diff()
        {
            default_tag("remove")
            attachable(anchor = anchor, orient = orient, spin=spin)
            {
                union()
                {
                    right_half()
                    prismoid(size1 = [magnetic_column_d * 1.5, magnetic_column_d],
                    size2 = [magnetic_column_d * 1.5, magnetic_column_d / 2],
                    h = height, anchor = anchor, orient = orient, spin=spin);
                    cylinder(h = height, d2 = magnetic_column_d / 2, d1 = magnetic_column_d, anchor = anchor, orient =
                    orient, spin=spin);
                }
                children();
            }
            
//            position(TOP)
            zrot(90)
            down(2*layer_height+struct_val(mold_magnet_dims, "thickness"))
            circular_magnet_trap_side(struct_val(mold_magnet_dims, "diameter"), 
                                      struct_val(mold_magnet_dims, "thickness"), 
                                      poke_len = magnetic_column_d/2 + difference_tolerance, poke_diam=1, anchor = TOP);
        }
    }

}
module lid_top_mold()
{

    if (show_support_plate)
    {
        // Show where the support plate will be
        recolor("cyan")
        up(thickness_below_support_plate + support_plate_post_ridge_thickness/2)
        #support_plate();
    }

    difference()
    {
        union()
        {
            up(difference_tolerance)
            cylinder(h = lid_mold_height, d=jar_od+mold_wall_thickness, anchor = BOTTOM);

            // Add columns for the magnet traps on the outside of mold cavity
//            magnetic_columns(lid_mold_height);
            // Add columns for the magnet traps on the outside of mold cavity
            for (column_index = [0:number_magnetic_columns-1])
            {
                zrot(column_index*360/number_magnetic_columns)
                left(jar_od/2+0.75*magnetic_column_d)
                difference()
                {
                    union()
                    {
                        right_half()
                        prismoid(size1=[magnetic_column_d*1.5, magnetic_column_d], 
                                 size2=[magnetic_column_d*1.5, magnetic_column_d/2], 
                                 h=lid_mold_height, anchor = BOTTOM);
                        cylinder(h = lid_mold_height, d2 = magnetic_column_d/2, d1 = magnetic_column_d, anchor = BOTTOM);
                    }
                    
                    zrot(90)
                    up(2*layer_height+struct_val(mold_magnet_dims, "thickness"))
                    circular_magnet_trap_side(struct_val(mold_magnet_dims, "diameter"), 
                                              struct_val(mold_magnet_dims, "thickness"), 
                                              poke_len = magnetic_column_d/2 + difference_tolerance, poke_diam=1, anchor = TOP);
                }
            }
            
        }
        
        difference()
        {
            // The lid exterior, including the well for the bearing
            union()
            {
                cylinder(h = gasket_thickness_qup, d1 = jar_od, d2 = jar_od - draft_dia_adjustment(gasket_thickness),
                anchor = BOTTOM)

                // The section with the embedded support plate overlaps the gasket
                position(TOP)
                down(gasket_thickness_qup)
                cylinder(h = thickness_above_rim_qup, d1 = layer_containing_support_plate_d, d2 = upper_surface_d, anchor =
                BOTTOM)

                position(TOP)
                down(difference_tolerance)
                diff()
                {
                    tube(h = bearing_width_qup+difference_tolerance, id = bearing_od,
                    od = bearing_od + 2 * threaded_post_wall_thickness, anchor = BOTTOM)
            
                    attach([TOP]) tag("remove")
                    down(2)
                    chamfer_cylinder_mask(r = bearing_od / 2 + threaded_post_wall_thickness, chamfer = 2,
                    anchor = BOTTOM);
            
                }

            }

            // Make the hole for the shaft
            union()
            {
                down(difference_tolerance)
                cylinder(h = thickness_above_rim_qup + bearing_width_qup + 2 * difference_tolerance, 
                         d = impeller_shaft_d_slide, anchor = BOTTOM);
            }

            holes_for_ports();
            
        }
    }
    
    // Add the posts for positioning the support plate, including a rings that will trap the support plate when embedding it
    for (post_index = [0:number_ports - 1])
    {
        zrot(post_index*360/number_ports)
        left(upper_surface_d/2 - 2 * support_plate_post_d - port_d)
        support_plate_post();
    }
    
}

module lid_bottom_mold()
{
/*
    up(taper_height)
    %cylinder(h = gasket_thickness, d1 = jar_od, d2 = jar_od - draft_dia_adjustment(gasket_thickness),
    anchor = BOTTOM);
*/
//    up(taper_height)
//    %lid_top_mold();

    lid_bottom_mold_height = taper_height;
    magnetic_column_height = lid_bottom_mold_height;
    difference()
    {
        union()
        {
            cylinder(h = lid_bottom_mold_height-2*difference_tolerance, d = jar_od+mold_wall_thickness, anchor = BOTTOM);

            // Add columns for the magnet traps on the outside of mold cavity
//            magnetic_columns(lid_bottom_mold_height, orient=DOWN);

            for (column_index = [0:number_magnetic_columns-1])
            {
                zrot(column_index*360/number_magnetic_columns)
                left(jar_od/2+0.75*magnetic_column_d)
                up(magnetic_column_height)
                difference()
                {
                    union()
                    {
                        right_half()
                        cuboid([magnetic_column_d*1.5, magnetic_column_d, magnetic_column_height], anchor = TOP);
                        cylinder(h = magnetic_column_height, d = magnetic_column_d, anchor = TOP);
                    }
                    
                    zrot(90)
                    down(2*layer_height)
                    circular_magnet_trap_side(struct_val(mold_magnet_dims, "diameter"), 
                                              struct_val(mold_magnet_dims, "thickness"), 
                                              poke_len = magnetic_column_d/2 + difference_tolerance, poke_diam=1, anchor = TOP);
//                    position(TOP)
//                    top_half()
//                    onion(d = struct_val(mold_magnet_dims, "diameter"), cap_h = struct_val(mold_magnet_dims, "diameter")/2.5);

                }
            }

        }

        down(difference_tolerance)
        difference()
        {
            union()
            {
                cylinder(h = taper_height, d1 = lid_taper_smallest_d, d2 = jar_mouth_largest_id,
                anchor = BOTTOM);
                
            }

            // Hollow out the interior
            down(difference_tolerance)
            cylinder(h = taper_height, d1 = exterior_dome_diameter_base, d2 = exterior_dome_diameter_top, anchor = BOTTOM);

            // Make bridges for the silicone pour channels to join the interior to the exterior of the mold 
            number_channels = 4;
            for (channel_index = [0:number_channels - 1])
            {
                zrot(channel_index * 360 / number_channels)
                left(jar_mouth_largest_id / 2 - stopper_taper_width)
                down(difference_tolerance)
                cube([stopper_taper_width * 2, stopper_taper_width*2, 2 + difference_tolerance], anchor = BOTTOM);
            }
        }
        
//         down(difference_tolerance)
//       #cylinder(h = taper_height - mold_wall_thickness + difference_tolerance, d2 = interior_dome_diameter_top,
//        d1 = interior_dome_diameter_base, anchor = BOTTOM);

    }
//    up(taper_height-mold_wall_thickness+difference_tolerance)
//    yrot(180)
//    linear_extrude(1)
//    text("DON'T POUR SILICONE IN HERE!", size= 3.5, halign = "center",
//            valign = "center", $fn = 100);
}

module lid()
{
    post_increase_d = 0; //2*threaded_post_wall_thickness;

    // Show the maximum circle available for the ports
    if (show_port_zones)
    {
        up(taper_height + gasket_thickness + thickness_above_rim)
        %cylinder(h = 1, d = min(lid_taper_smallest_d, upper_surface_d), anchor = BOTTOM);
    }

    difference()
    {
        union()
        {
            cylinder(h = taper_height, d1 = lid_taper_smallest_d, d2 = jar_mouth_largest_id,
            anchor = BOTTOM)

            position(TOP)
            cylinder(h = gasket_thickness, d1 = jar_od, d2 = jar_od - draft_dia_adjustment(gasket_thickness),
            anchor = BOTTOM)

            // The section with the embedded support plate overlaps the gasket
            position(TOP)
            down(gasket_thickness)
            cylinder(h = thickness_above_rim, d1 = layer_containing_support_plate_d, d2 = upper_surface_d, anchor =
            BOTTOM);

            up(stopper_thickness)
            threaded_post_for_shaft();

            /*
                        // Thread the ports with an external thread
                        up(stopper_thickness)
                        {
                            for (port_index = [0:number_ports - 1])
                            {
                                port_locator(port_index, port_d, 0)
                                threaded_post_for_port(port_d, 4 * threaded_post_wall_thickness, port_inner_support_width);
                            }
            
                            for (port_index = [0:2:number_ports - 1])
                            {
                                port_locator(port_index, small_port_d, phase_angle_small)
                                threaded_post_for_port(small_port_d, 4 * threaded_post_wall_thickness, 0);
                            }
            
                            for (port_index = [1:2:number_ports - 1])
                            {
                                port_locator(port_index, mini_port_d, phase_angle_mini)
                                threaded_post_for_port(mini_port_d, 4 * threaded_post_wall_thickness, 0);
                            }
                        }
            */

        }

        if (show_support_plate)
        {
            // Show where the support plate will be
            recolor("cyan")
            up(taper_height + thickness_below_support_plate - support_plate_thickness / 2)
            #support_plate();
        }

        // Make the holes
        down(difference_tolerance)
        union()
        {
            // Make the hole for the shaft
            cylinder(h = stopper_thickness + bearing_width + 2 * difference_tolerance, d = impeller_shaft_diameter +
                sliding_tolerance, anchor = BOTTOM);

            cylinder(h = hollow_out_stopper ? stopper_thickness - thickness_above_rim : 0,
            r1 = lid_taper_smallest_d / 2 - stopper_taper_width,
            r2 = jar_mouth_largest_id / 2 - stopper_taper_width, anchor = BOTTOM);

            holes_for_ports();
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
                sp_neck(jar_nominal_dia, jar_type_number, jar_rim_thickness, anchor = TOP);
                if (partial_support_only)
                {
                    for (support_index = [0:number_supports - 1])
                    {
                        zrot(support_index * 180 / (number_supports / 2) + 30 / (number_supports / 2))
                        down(difference_tolerance)
                        pie_slice(ang = 120 / (number_supports / 2), l = 20 + 2 * difference_tolerance,
                        d = jar_od, anchor = BOTTOM);
                    }
                }
            }

            for (support_index = [0:number_supports - 1])
            {
                zrot(support_index * 180 / (number_supports / 2))
                {
                    cuboid(support_dims, anchor = BOTTOM);

                    left(jar_mouth_largest_id / 2 - support_dims[1] / 2)
                    diff()
                    {
                        cuboid([support_dims[1], support_dims[1], jar_lid_height - 1], anchor = BOTTOM)
                        {
                            edge_mask(TOP + RIGHT)
                            chamfer_edge_mask(l = support_dims[1], chamfer = support_dims[1] - 2);
                        }
                    }
                }

            }
        }

        down(difference_tolerance)
        union()
        {
            down(difference_tolerance)
            tube(h = max_cutter_height / 2 + 2 * difference_tolerance,
            or = cutting_r + (bit_diameter + bit_clearance) / 2,
            ir = cutting_r - (bit_diameter + bit_clearance) / 2, anchor = BOTTOM)
            position(TOP)
            torus(or = cutting_r + (bit_diameter + bit_clearance) / 2,
            ir = cutting_r - (bit_diameter + bit_clearance) / 2, anchor = CENTER);



            // Make the hole in the center for the pivot
            down(difference_tolerance)
            cylinder(h = min_support_height + 2 * difference_tolerance, d = pivot_hole_d, anchor = BOTTOM);

            // Make the holes in the support to attach the lid
            for (support_index = [0:number_supports - 1])
            {
                zrot(support_index * 180 / (number_supports / 2))
                left(jar_mouth_largest_id / 4)
                down(difference_tolerance)
                cylinder(h = min_support_height + 2 * difference_tolerance, d = pivot_hole_d, anchor = BOTTOM)

                // Create a domed nut trap for the screw
                zrot(90)
                down(dome_height_above_nut / 2)
                position(CENTER)
                screw_hole(screw_for_holding_lid, length = support_dims[1] + dome_height_above_nut, $slop =
                screw_hole_slop)
                nut_trap_side(trap_width = support_dims[1], poke_len = support_dims[1], anchor = CENTER)

                if (dome_height_above_nut > 0) {
                    position(TOP)
                    top_half()
                    onion(d = lid_nut_width, cap_h = dome_height_above_nut);
                }
                else
                    children();

            }

            // Make the hole at the center of where the router bit will be as a guide for drilling the hole
            down(difference_tolerance)
            left(cutting_r)
            cylinder(h = jar_lid_height + 2 * difference_tolerance, d = pivot_hole_d, anchor = BOTTOM);

            // Label the screw hole
            text_depth = 1;
            up(min_support_height - text_depth / 2)
            left(jar_mouth_largest_id / 4 - lid_nut_width / 2)
            linear_extrude(text_depth)
            text(screw_for_holding_lid, size = support_dims[1] / 3, halign = "left",
            valign = "center", $fn = 100);

            // Inscribe the jar lid type
            path = path3d(arc(n = 100, d = jar_mouth_largest_id + 3 * jar_rim_thickness,
            angle = [130, 230]));
            specs_text_height = 2.5;
            up(jar_lid_height - specs_text_height)
            path_text(path, jar_nominal_dia_and_type_number, h = jar_lid_height / 2.5, size = specs_text_height, center
            = true,
            valign = "top", textmetrics = true);

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
            cylinder(h = lid_mold_height-difference_tolerance, d = jar_od);
        }
        //zrot(130)
        up(lid_mold_height)
        xrot(180)
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
            cylinder(h = taper_height, d2 = lid_taper_smallest_d, d1 = jar_mouth_largest_id,
            anchor = BOTTOM);
        }
        //zrot(130)
        xrot(180)
        down(taper_height + difference_tolerance)
        lid_bottom_mold();

        if (show_molded_part)
        {
            down(difference_tolerance)
            cylinder(h = taper_height+mold_wall_thickness+2*difference_tolerance, d2 = diameter_inside_hollow_of_tapered_base, 
                     d1 = diameter_inside_hollow_of_tapered_base_with_draft, 
            anchor = BOTTOM);
        }
    }
}

if (part_to_show == "lid")
{
    back_half(s = show_cross_section ? 200 : 0)
    //zrot(130)
    lid();

}
else if (part_to_show == "lid_top_mold")
{
    back_half(s = show_cross_section ? 200 : 0)
     lid_top_from_mold(show_molded_part);
}
else if (part_to_show == "lid_bottom_mold")
{
    back_half(s = show_cross_section ? 200 : 0)
    lid_bottom_from_mold(show_molded_part);
}

else if (part_to_show == "jar lid from mold")
{
    back_half(s = show_cross_section ? 200 : 0)
    union()
    {
        lid_bottom_from_mold(true);
        up(taper_height)
        lid_top_from_mold(true);
    }       

}
else if (part_to_show == "jar lid cutting jig")
{
    back_half(s = show_cross_section ? 200 : 0)
    lid_cutting_jig();
}
else if (part_to_show == "18 mm port mold")
{
    snap_pin_specs = struct_set([], ["size", "standard", "length", 10.8, "diameter", 7]);
    partition_specs = struct_set([], ["cutsize", 3.5, "gap", 28.75, "cutpath", "comb"]);  // Tuned by experimentation
    back_half(s = show_cross_section ? 200 : 0)
    mold_for_threaded_post_for_port(port_d, 4 * threaded_post_wall_thickness, 0, snap_pin_specs, partition_specs);
}
else if (part_to_show == "10 mm port mold")
{
    snap_pin_specs = struct_set([], ["size", "standard", "length", 10.8, "diameter", 7]);
    partition_specs = struct_set([], ["cutsize", 3.5, "gap", 25., "cutpath", "comb"]);  // Tuned by experimentation
    back_half(s = show_cross_section ? 200 : 0)
    mold_for_threaded_post_for_port(small_port_d, 4 * threaded_post_wall_thickness, 0, snap_pin_specs, partition_specs);
}
else if (part_to_show == "6 mm port mold")
{
    snap_pin_specs = struct_set([], ["size", "medium", "length", 8, "diameter", 4.6]);
    partition_specs = struct_set([], ["cutsize", 2, "gap", 20., "cutpath", "comb"]);  // Tuned by experimentation
    back_half(s = show_cross_section ? 200 : 0)
    mold_for_threaded_post_for_port(mini_port_d, 4 * threaded_post_wall_thickness, 0, snap_pin_specs, partition_specs);
}
else if (part_to_show == "plate drilling template")
{
    //zflip()
//    test_insert();
    projection(cut = true) 
    down(support_plate_thickness/2)
    support_plate(true);

}
else if (part_to_show == "test")
{
    //zflip()
    test_insert();
//    %up(lid_mold_height/2) prismic_column(lid_mold_height, BOTTOM, 0, DOWN)
//    tag("remove") attach(CENTER) recolor("red") down(lid_mold_height) cyl(d=2, h=3);
//    %prismic_column(lid_mold_height, BOTTOM, 0, DOWN)
//    show_anchors(10);
    
//    left(30)
//        prismic_column(lid_mold_height, TOP, UP);

}

