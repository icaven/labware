include <BOSL2/std.scad>
include <BOSL2/ball_bearings.scad>
include <BOSL2/bottlecaps.scad>
include <BOSL2/joiners.scad>
include <BOSL2/rounding.scad>
include <BOSL2/screws.scad>
include <BOSL2/structs.scad>
include <BOSL2/threading.scad>

/* [Viewing options] */

// Show a part, or the assembled parts in position
part_to_show = "lid"; // ["lid","jar lid cutting jig","18 mm port mold","10 mm port mold","6 mm port mold"]

// Include the embedded support_plate
include_support_plate = true;
// Thickness of embedded support plate
support_plate_thickness = 2.0; // 0.1
// Reveal the embedded support plate
show_cross_section = false;

// Hollow out beneath the support support plate
hollow_out_stopper = true;

/* [Jar specification] */

jar_nominal_dia_and_type_number = "110-400";
// The size of the screw for attaching the lid to the center bar
screw_for_holding_lid = "6-32";  // ["6-32", "M4", "M3"]

/* [Port specifications] */
// Number of large ports (the number of each of the smaller ports will be half of this)
number_ports = 4;

// Diameter of the 3 sizes of ports
port_d = 18;
small_port_d = 10;
mini_port_d = 6;

port_height = 6;
// Width of the ledge inside the large ports, to allow an insert to narrow the opening
port_inner_support_width = 1.5; // 0.1
// Thickness of the walls of the ports
threaded_post_wall_thickness = 2.8; // 0.1

/* [Bearing choice] */
bearing_to_use = "608ZZ"; // ["608ZZ", "R4ZZ", "635ZZ", "685ZZ"]

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

/**
  Dimensions of the jar and lid
 */
jar_nominal_dia = parse_int(str_split(jar_nominal_dia_and_type_number, "-")[0]);
jar_type_number = parse_int(str_split(jar_nominal_dia_and_type_number, "-")[1]);
echo("jar_nominal_dia = ", jar_nominal_dia);
echo("jar_type_number = ", jar_type_number);

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

neck_taper_angle = 82.4;   // Measured from jar

// Measured from lid
lid_id = 110;
lid_thickness = 2;
lid_od = lid_id + 2 * lid_thickness;

// Width of lid inside the jar opening
lid_rim_width = 2;

lid_taper_smallest_d = jar_mouth_largest_id - 2 * taper_height / tan(neck_taper_angle);

// Radius of the support plate from the cut-out lid
bit_diameter = inch_to_mm(1 / 8);
bit_clearance = 1;
cutting_r = (jar_mouth_largest_id) / 2 - lid_rim_width - (bit_diameter + bit_clearance) / 2;
support_plate_or = cutting_r - (bit_diameter + bit_clearance) / 2;
echo("Radius of open circle in lid = ", support_plate_or);

// Angles of small and mini ports relative to the angle of a main port
phase_angle_small = 180 / (number_ports);
phase_angle_mini = 180 / (number_ports);

support_plate_surround_thickness = 4 * support_plate_thickness;
thickness_above_rim = support_plate_thickness + support_plate_surround_thickness;

layer_containing_support_plate_d = jar_mouth_largest_id - 2 * lid_rim_width;
support_plate_d = layer_containing_support_plate_d - 2;

stopper_thickness = taper_height + thickness_above_rim; // +  gasket_thickness;
stopper_taper_width = 4;


trapezoidal_thread_angle = 45;
mounting_plate_thread_pitch = 3;
mounting_plate_thread_depth = mounting_plate_thread_pitch / 2;
difference_tolerance = 0.01;



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

    tube(h = 1, od = 107, id = new_largest_d - thickness, anchor = BOTTOM)

    position(TOP)
    tube(h = h, od1 = new_largest_d, id1 = new_largest_d - thickness,
    od2 = smallest_d, id2 = smallest_d - thickness, anchor = BOTTOM,
    $fa = 1, $fs = 1);

}


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

support_plate_shaft_hole_d = 25.4 * 3 / 8;
support_plate_port_hole_d = 25.4 * 5 / 8;
support_plate_small_port_hole_d = 25.4 * 1 / 2;
support_plate_mini_port_hole_d = 25.4 * 3 / 8;

module threaded_post_for_shaft()
{
    // For testing, show the size of the hole in the support plate
    //         #cylinder(h = bearing_width + 2 * difference_tolerance, d = 25.4 * 3 / 8, anchor = BOTTOM,
    //         $fa = 1, $fs = 1);

    // For testing, show the extent of the zone around the shaft port
    //     #cylinder(h = bearing_width + 2 * difference_tolerance, d = bearing_od+4*threaded_post_wall_thickness, anchor = BOTTOM,
    //     $fa = 1, $fs = 1);

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

module threaded_post_for_port(port_od, post_increase_d, hole_size_reduction)
{

    // For testing, show the size of the hole in the support plate
    //     #cylinder(h=port_height+2*difference_tolerance, d=25.4*5/8, anchor = BOTTOM, 
    //          $fa = 1, $fs = 1);

    // For testing, show the extent of the zone around the port
    //     #cylinder(h=port_height+2*difference_tolerance, d=port_od+4*threaded_post_wall_thickness, anchor = BOTTOM, 
    //          $fa = 1, $fs = 1);
    diameter_in_stopper = port_od + post_increase_d;
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
        cylinder(h = port_height + 2 * difference_tolerance,
        d = port_od, anchor = BOTTOM, $fa = 1, $fs = 1);


        /*
                position(BOTTOM)
                up(difference_tolerance)
                #cylinder(h = support_plate_surround_thickness / 2 + 2 * difference_tolerance,
                d = port_od - 2 * hole_size_reduction, anchor = TOP, $fa = 1, $fs = 1);
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
            $slop=tapered_nut_slop);
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
    
    retaining_ledge_thickness = 3*nozzle_diameter;
    retaining_nut_thickness = 4;
    retaining_nut_side_thickness = 4;
    retaining_nut_id = mold_od + 2*retaining_nut_side_thickness;
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
                    cylinder(r = port_od / 2, h = snap_pin_length, anchor = TOP, $fa = 1, $fs = 1);
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
            end_len1 = retaining_ledge_thickness, $fa = 1, $fs = 1, $fn = 100, blunt_start = true, bevel2 = false, 
            anchor = BOTTOM);

            // Flatten two opposite sides, so that when the mold is partitioned, the flat side can lie on the print bed
            down(difference_tolerance)
            cuboid([retaining_nut_od, mold_od - 4 * mold_wall_thickness+2*sliding_tolerance, retaining_nut_thickness+2*difference_tolerance],
            anchor = BOTTOM);
        }

        right_half()
        intersection()
        {
            tube(h = retaining_ledge_thickness, id = retaining_nut_od, od = retaining_nut_od + 6,
                  anchor = BOTTOM);
            down(difference_tolerance)
            cuboid([retaining_nut_od + 6, mold_od - 4 * mold_wall_thickness, retaining_nut_thickness+2*difference_tolerance],
            anchor = BOTTOM);

        }
        

    }

    module retaining_nut()
    {
        recolor("blue")
        zrot(180)
        threaded_nut(nutwidth = retaining_nut_od, id = retaining_nut_id, h = retaining_nut_thickness, 
                     pitch = retaining_nut_thread_pitch, bevel=false, ibevel=false, anchor=BOTTOM, 
                     $slop = slop, $fa = 1, $fs = 1, $fn = 100);
    }

    module internal_post_hollow_mask()
    {
        cylinder(h = stopper_thickness + port_height, d = port_od, anchor = BOTTOM)
        down(snap_pin_length)
        position(TOP)
        snap_pin(snap_pin_size, l = snap_pin_length, snap = 0.125 * port_od / 2, anchor = BOTTOM, orient = UP, pointed = false
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
        partition([port_od*6, port_od, mold_height*2], cutsize = cutsize, gap = gap, cutpath = cutpath, spread = spread_of_partition_halves)
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

module support_plate()
{
    difference()
    {
        cylinder(h = support_plate_thickness, d = support_plate_d, anchor = BOTTOM);
        {
            union()
            {
                down(difference_tolerance)
                cylinder(h = bearing_width + 2 * difference_tolerance, d = support_plate_shaft_hole_d, anchor = BOTTOM);

                for (port_index = [0:number_ports - 1])
                {
                    angle_of_port = port_index * 360 / number_ports;
                    zrot(angle_of_port)
                    fwd(support_plate_or - port_d / 2 - threaded_post_wall_thickness)
                    down(difference_tolerance)
                    cylinder(h = support_plate_thickness + 2 * difference_tolerance, d = support_plate_port_hole_d,
                    anchor = BOTTOM);
                }

                for (port_index = [0:2:number_ports - 1])
                {
                    angle_of_port = port_index * 360 / number_ports + phase_angle_small;
                    zrot(angle_of_port)
                    fwd(support_plate_or - small_port_d / 2 - threaded_post_wall_thickness)
                    down(difference_tolerance)
                    cylinder(h = support_plate_thickness + 2 * difference_tolerance, d = support_plate_small_port_hole_d
                    , anchor = BOTTOM);
                }

                for (port_index = [1:2:number_ports - 1])
                {
                    angle_of_port = port_index * 360 / number_ports + phase_angle_mini;
                    zrot(angle_of_port)
                    fwd(support_plate_or - mini_port_d / 2 - threaded_post_wall_thickness)
                    down(difference_tolerance)
                    cylinder(h = support_plate_thickness + 2 * difference_tolerance, d = support_plate_mini_port_hole_d,
                    anchor = BOTTOM);
                }
            }

        }
    }

}

module lid()
{

    difference()
    {
        union()
        {
            cylinder(h = taper_height, d1 = lid_taper_smallest_d, d2 = jar_mouth_largest_id,
            anchor = BOTTOM)

            position(TOP)
            cylinder(h = gasket_thickness, d = jar_od, anchor = BOTTOM)

            // The section with the embedded support plate overlaps the gasket
            position(TOP)
            down(gasket_thickness)
            cylinder(h = thickness_above_rim, d = layer_containing_support_plate_d, anchor = BOTTOM);

            up(stopper_thickness)
            threaded_post_for_shaft();

            up(stopper_thickness)
            {
                for (port_index = [0:number_ports - 1])
                {
                    angle_of_port = port_index * 360 / number_ports;
                    zrot(angle_of_port)
                    fwd(support_plate_or - port_d / 2 - threaded_post_wall_thickness)
                    threaded_post_for_port(port_d, 4 * threaded_post_wall_thickness, port_inner_support_width);
                }

                for (port_index = [0:2:number_ports - 1])
                {
                    angle_of_port = port_index * 360 / number_ports + phase_angle_small;
                    zrot(angle_of_port)
                    fwd(support_plate_or - small_port_d / 2 - threaded_post_wall_thickness)
                    threaded_post_for_port(small_port_d, 4 * threaded_post_wall_thickness, 0);
                }

                for (port_index = [1:2:number_ports - 1])
                {
                    angle_of_port = port_index * 360 / number_ports + phase_angle_mini;
                    zrot(angle_of_port)
                    fwd(support_plate_or - mini_port_d / 2 - threaded_post_wall_thickness)
                    //                    fwd(bearing_width + 4 * threaded_post_wall_thickness + mini_port_d)
                    threaded_post_for_port(mini_port_d, 4 * threaded_post_wall_thickness, 0);
                }
            }

        }

        if (include_support_plate)
        {
            // Show where the support plate will be
            recolor("cyan")
            up(taper_height + thickness_above_rim / 2 - support_plate_thickness / 2)
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

            // Make the holes for the ports
            for (port_index = [0:number_ports - 1])
            {
                angle_of_port = port_index * 360 / number_ports;
                zrot(angle_of_port)
                fwd(support_plate_or - port_d / 2 - threaded_post_wall_thickness)
                cylinder(h = stopper_thickness + port_height + 2 * difference_tolerance,
                d = port_d - 2 * port_inner_support_width, anchor = BOTTOM);
            }

            for (port_index = [0:2:number_ports - 1])
            {
                angle_of_port = port_index * 360 / number_ports + phase_angle_small;
                zrot(angle_of_port)
                fwd(support_plate_or - small_port_d / 2 - threaded_post_wall_thickness)
                cylinder(h = stopper_thickness + port_height + 2 * difference_tolerance,
                d = small_port_d, anchor = BOTTOM);
            }

            for (port_index = [1:2:number_ports - 1])
            {
                angle_of_port = port_index * 360 / number_ports + phase_angle_mini;
                zrot(angle_of_port)
                fwd(support_plate_or - mini_port_d / 2 - threaded_post_wall_thickness)
                //                fwd(bearing_width + 4 * threaded_post_wall_thickness + mini_port_d)
                cylinder(h = stopper_thickness + port_height + 2 * difference_tolerance,
                d = mini_port_d, anchor = BOTTOM);
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
    dome_height_above_nut = 0; //lid_nut_width / 2.5;

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
if (part_to_show == "lid")
{
    back_half(s = show_cross_section ? 200 : 0)
    //zrot(130)
    lid();

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
else if (part_to_show == "test")
{
    //zflip()
    test_insert();
}

