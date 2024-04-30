include <BOSL2/std.scad>
include <BOSL2/ball_bearings.scad>
include <BOSL2/nema_steppers.scad>
include <BOSL2/joiners.scad>
include <BOSL2/rounding.scad>
include <BOSL2/screws.scad>
include <BOSL2/structs.scad>
include <BOSL2/threading.scad>

// The NEMA motor number
nema_motor_size = 17; // [11, 14, 17, 23]
// The diameter of the outside of the bearing
bearing_od = 22.0; // 0.1
// The diameter of the inside of the bearing
bearing_id = 8.0;  // 0.1
// The height of the bearing
bearing_height= 7.0;    // 0.1
// Bearing od oversize to allow for silicon adhesive
bearing_od_oversize = 0.25;
// Bearing id oversize (to be outside of the rotating center)
bearing_id_oversize = 6.;

// Show the motor and the controller board in position
show_assembled = false;

// The length of the motor body
motor_body_length = 59;

// The length of the motor shaft
motor_shaft_length = 24;

// Length of screws used to mount the motor
motor_screw_length = 6;

// Controller board plate width
controller_board_plate_width = 100;

// Controller board plate length
controller_board_plate_length = 50;

// Controller board plate depth
controller_board_plate_depth = 1;

// Controller board metric screw diameter (mm)
controller_board_screw_diameter = 3;

// Controller board screw length
controller_board_screw_length = 10;

// Thickness of the head plate that the mount will screw into
head_plate_thickness = 4;

// Allow the motor to adjusted slightly in one direction
motor_mounting_plate_adjustment_range = 2;

// Don't need to change anything after this
module __end_of_customizer_variables() {}

// Specification of the thread for the motor mount rod and nut
post_nut_height = 10;
nut_diameter = 47;
mount_thread_pitch = 1.;
rod_diameter = 30;

wall_thickness = 2.0;
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
screw_size = ceil(motor_info[4]);  // NEMA23 needs M5.1, but that size isn't supported by screw(), so use 6
motor_screw_info = screw_info(str("M", screw_size), "socket", "hex");
motor_screw_head_d = struct_val(motor_screw_info, "head_size");
motor_screw_head_height = struct_val(motor_screw_info, "head_height");
motor_screw_head_clearance_d = motor_screw_head_d + 1;

motor_mounting_plate_size = motor_info[0] + motor_screw_head_clearance_d/2;
collar_od = motor_info[2] + wall_thickness * 3 + motor_mounting_plate_adjustment_range * 2;
motor_screw_clearance = 0.5;  // Gap between end of screw and bottom of screw hole in motor
motor_mounting_plate_height = max(motor_info[1], motor_screw_length - (motor_info[5] - motor_screw_clearance));

// Use the NEMA 17 motor size to compute the spacing of the controller board attachment holes
// so that the spacing will be the fixed
motor_17_info = nema_motor_info(17);
minimum_mounting_plate_size = motor_17_info[0];
controller_board_mounting_hole_spacing = minimum_mounting_plate_size / 2;

motor_mounting_plate_width = max(motor_mounting_plate_size + motor_screw_head_clearance_d/2, 
                                 minimum_mounting_plate_size + motor_mounting_plate_adjustment_range);
motor_mounting_plate_length = max(motor_mounting_plate_size, minimum_mounting_plate_size);

// Transition between support post and rod, sloped at 45 degrees
angle_of_taper = 45;
thickness_between_collar_and_rod = sin(angle_of_taper) * ((collar_od - rod_diameter)/2 + wall_thickness);
thickness_between_inner_support_and_rod_d = max(0, sin(angle_of_taper) * ((collar_od - rod_diameter)/2 - wall_thickness));
collar_support_height = 2;

support_height = max(motor_shaft_length * 1.5, motor_shaft_length + thickness_between_collar_and_rod + collar_support_height);

// Create the threaded section that screws into the head plate of the bioreactor
module hollow_threaded_rod_with_bearing_support()
{
    rod_height = post_nut_height + head_plate_thickness;
    bearing_support_cutout_z = 2;
    tapered_bearing_support_cutout_z = 4;
    assert(rod_height > (bearing_height+bearing_support_cutout_z + tapered_bearing_support_cutout_z));

    // Hollow threaded part, with support for a bearing at the top end
    up(rod_height)
    difference()
    {
        down(rod_height/2)
        threaded_rod(d=rod_diameter, height=rod_height, pitch=mount_thread_pitch, 
                     end_len1=0, $fa=1, $fs=1, blunt_start=true);
        
        // Make a space for the bearing
        down(bearing_height/2)
        cylinder(h=bearing_height+difference_tolerance, r=(bearing_od + bearing_od_oversize)/2, center=true, $fn=100);

        // Support for the bearing
        down(bearing_height+bearing_support_cutout_z/2)
        cylinder(h=bearing_support_cutout_z, r=(bearing_id + bearing_id_oversize)/2, center=true, $fa=1, $fs=1);

        down(bearing_height+bearing_support_cutout_z+tapered_bearing_support_cutout_z/2)
        cylinder(h=tapered_bearing_support_cutout_z, r1=rod_diameter/2-wall_thickness, 
                 r2=(bearing_id + bearing_id_oversize)/2, center=true, $fa=1, $fs=1);
        
        // Hollow out the rest of the threaded rod
        down(rod_height/2+bearing_height+bearing_support_cutout_z+tapered_bearing_support_cutout_z)
        cylinder(h=rod_height, r=rod_diameter/2-wall_thickness, center=true, $fa=1, $fs=1);
    }
  
}

module hollow_motor_support_with_collar()
{
//    // Transition between support post and rod, sloped at 45 degrees
    tapered_collar_support_height = thickness_between_collar_and_rod;
    difference()
    {
        union()
        {
           cylinder(h=support_height, r=collar_od/2, $fa=1, $fs=1);

           // Collar around the post
           up(support_height-collar_support_height/2)
           cylinder(h=collar_support_height, r=collar_od/2+wall_thickness, 
                    center=true, $fa=1, $fs=1);

           // Tapered support for the collar        
           up(support_height-collar_support_height-tapered_collar_support_height/2)
           cylinder(h=tapered_collar_support_height, r2=collar_od/2+wall_thickness, 
                    r1=collar_od/2-1, center=true, $fa=1, $fs=1);
        }
        
        union()
        {  
            d_tol = thickness_between_inner_support_and_rod_d > 0 ? 0 : difference_tolerance;
            down(d_tol)
            cylinder(h=support_height-thickness_between_inner_support_and_rod_d+d_tol*2, 
                    r=collar_od/2-wall_thickness-motor_mounting_plate_adjustment_range/2, $fa=1, $fs=1);
           
            if (d_tol == 0)
            {
                // Remove the top and bottom of the tapered section, so that the difference in the preview shows correctly
                up(support_height)
                cylinder(h = difference_tolerance * 2,
                          r = rod_diameter / 2 - wall_thickness, center = true, $fa = 1, $fs = 1);
                
                up(support_height-thickness_between_inner_support_and_rod_d)
                cylinder(h = difference_tolerance,
                          r1 = collar_od / 2 - wall_thickness-motor_mounting_plate_adjustment_range/2,
                          r2 = collar_od / 2 - wall_thickness-motor_mounting_plate_adjustment_range/2-difference_tolerance,
                center = true, $fa = 1, $fs = 1);
                
                // Remove the bottom of the support tube, so that the difference in the preview shows correctly
                cylinder(h = difference_tolerance * 2,
                         r = collar_od / 2 - wall_thickness-motor_mounting_plate_adjustment_range/2, 
                         center = true, $fa = 1, $fs = 1);
            }
            
            color("red")
            up(support_height-thickness_between_inner_support_and_rod_d/2)
            cylinder(h=thickness_between_inner_support_and_rod_d, 
                    r1=collar_od/2-wall_thickness-motor_mounting_plate_adjustment_range/2, 
                    r2=rod_diameter/2-wall_thickness,
                    center=true, $fa=1, $fs=1);

        }
        
        // Make openings in the motor support tube to allow access to the shaft coupling screws
        cutout_d = min(collar_od/2,  (support_height - collar_support_height-tapered_collar_support_height) * 0.85);

        for (angle = [0:180:270])
        {
           up(support_height - collar_support_height-tapered_collar_support_height - cutout_d/2)
           zrot(angle)
           right(collar_od/2-wall_thickness)
           yrot(90)
           cylinder(h=collar_od/2, r=cutout_d/2, center=true, $fn=100 );
        }
    }
}

/*
The controller board is attached to the motor mount with a couple of cubes each with a nut trap
 */
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

        if (show_assembled)
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

/*
    The plate that the motor controller electronics will be mounted onto.  Attached by screws to the motor mount.
*/
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

module motor_mount()
{    
    // Create the threaded holder (upside down)
    difference()
    {
        up(motor_mounting_plate_height)
        {
            hollow_motor_support_with_collar();
            
            up(support_height)
            hollow_threaded_rod_with_bearing_support();
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

    front_edge_location = max(minimum_mounting_plate_size, motor_mounting_plate_width)/2;
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

if (show_assembled)
{
    zflip()
        {
            motor_mount();
            
            // Show the controller board
//            board_back_face_location = max(minimum_mounting_plate_size, motor_mounting_plate_width)/2-
//              motor_mounting_plate_adjustment_range+controller_board_plate_depth + attachment_nut_cuboid_length/2+1;
            board_back_face_location = max(minimum_mounting_plate_size, motor_mounting_plate_width)/2+
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
            threaded_nut(nutwidth = nut_diameter, id = rod_diameter, h = post_nut_height, pitch = mount_thread_pitch, $slop =
            0.05, $fa = 1, $fs = 1);
            
            // Show the bearing
            up(post_nut_height + motor_mounting_plate_height + support_height + head_plate_thickness-bearing_height/2)
            ball_bearing(id=bearing_id,od=bearing_od,width=bearing_height, shield=true, flange=false, $fn=72);
        }
    
}
else
{
    motor_mount();

    left(100)
    controller_board_mounting_plate();
    
    // The matching nut
    right(motor_mounting_plate_width+nut_diameter/2)
    up(post_nut_height/2)
    zrot(30)
    threaded_nut(nutwidth=nut_diameter, id=rod_diameter, h=post_nut_height, pitch=mount_thread_pitch, $slop=0.05, $fa=1, $fs=1);
}





