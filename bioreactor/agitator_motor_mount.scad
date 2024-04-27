include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
include <BOSL2/threading.scad>
include <BOSL2/nema_steppers.scad>
include <BOSL2/ball_bearings.scad>
include <BOSL2/joiners.scad>

// The NEMA motor number
nema_motor_size = 17; // [11, 17, 23]
// The diameter of the outside of the bearing plus 0.25 mm to allow for silicon
bearing_od = 20.25; // 0.25
// The diameter of the inside of the bearing plus 2 mm
bearing_id = 12;  
// The height of the bearing
bearing_height= 6.0;    // 0.1

// Show the motor and the controller board in position
show_motor = false;

// The length of the motor body
motor_body_length = 59;

// The length of the motor shaft
motor_shaft_length = 24;

// Length of screws used to mount the motor
motor_screw_length = 6;

// Controller board plate width
controller_board_plate_width = 100;

// Controller board plate length
controller_board_plate_length = 40;

// Controller board plate depth
controller_board_plate_depth = 1;

show_nut = true;

// Don't need to change anything after this
module __end_of_customizer_variables() {}

wall_thickness = 2.0;

nut_height = 10;

rod_diameter = 30;
collar_o_ring_od = 42.5;
motor_mounting_plate_adjustment_range = 3;

rod_height = nut_height + 5;

bearing_support_cutout_z = 2;
tapered_bearing_support_cutout_z = 4;
assert(rod_height > (bearing_height+bearing_support_cutout_z + tapered_bearing_support_cutout_z));
rod_cutout_d = rod_height-bearing_height-tapered_bearing_support_cutout_z;
thread_pitch = 1.;

nut_diameter = 47;

difference_tolerance = 0.1;

min_clip_length = 10;   // The clip for mounting the controller board
medium_snap_pin_length = 8;
medium_snap_pin_d = 4.6;
snap_pin_socket_cuboid_length = medium_snap_pin_length + 2;
snap_pin_socket_cuboid_width = 12;


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

info = nema_motor_info(nema_motor_size);
motor_mounting_plate_size = max(info[0], info[0] + min_clip_length/2);
collar_od = info[2] + wall_thickness * 2 + motor_mounting_plate_adjustment_range * 2;
motor_screw_clearance = 0.5;  // Gap between end of screw and bottom of screw hole in motor
motor_mounting_plate_height = max(info[1], motor_screw_length - (info[5] - motor_screw_clearance));
clip_length = max(7, motor_mounting_plate_size/2 - collar_od/2);


// Transition between support post and rod, sloped at 45 degrees
thickness_between_collar_and_rod = sin(45) * ((collar_od - rod_diameter)/2 + wall_thickness);
collar_support_height = 2;

support_height = max(motor_shaft_length * 1.5, motor_shaft_length + thickness_between_collar_and_rod + collar_support_height);

// Create the threaded holder
module hollow_threaded_rod_with_bearing_support()
{
    // Hollow threaded part, with support for a bearing at the top end
    up(rod_height)
    difference()
    {
        down(rod_height/2)
        threaded_rod(d=rod_diameter, height=rod_height, pitch=thread_pitch, 
                     end_len1=0, $fa=1, $fs=1, blunt_start=true);
        
        // Make a space for the bearing
        down(bearing_height/2)
        cylinder(h=bearing_height, r=bearing_od/2, center=true, $fn=100);

        // Support for the bearing
        down(bearing_height+bearing_support_cutout_z/2)
        cylinder(h=bearing_support_cutout_z, r=bearing_id/2, center=true, $fa=1, $fs=1);

        down(bearing_height+bearing_support_cutout_z+tapered_bearing_support_cutout_z/2)
        cylinder(h=tapered_bearing_support_cutout_z, r1=rod_diameter/2-wall_thickness, r2=bearing_id/2, center=true, $fa=1, $fs=1);
        
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
           down(difference_tolerance)
           cylinder(h=support_height-thickness_between_collar_and_rod+difference_tolerance*2, 
                    r=collar_od/2-wall_thickness, $fa=1, $fs=1);
           
           color("red")
           up(support_height-thickness_between_collar_and_rod/2)
           cylinder(h=thickness_between_collar_and_rod, 
                    r1=collar_od/2-wall_thickness, r2=rod_diameter/2-wall_thickness,
                    center=true, $fa=1, $fs=1);
           up(support_height/2)
           cylinder(h=support_height+difference_tolerance*2, 
                    r=rod_diameter/2-wall_thickness, center=true, $fa=1, $fs=1);

        }


    // Make openings in the motor support tube to allow access to the shaft coupling screws
    cutout_d = min(collar_od/2,  (support_height - collar_support_height-tapered_collar_support_height) * 0.85);

        for (angle = [0:90:270])
        {
           up(support_height - collar_support_height-tapered_collar_support_height - cutout_d/2)
           zrot(angle)
           right(collar_od/2-wall_thickness)
           yrot(90)
           cylinder(h=collar_od/2, r=cutout_d/2, center=true, $fn=100 );

        }
    }
}

// Clip and socket modified from examples:
// https://github.com/BelfrySCAD/BOSL2/wiki/joiners.scad#module-rabbit_clip
module controller_board_clip_socket(length, width, depth, snap, thickness, compression, lock=false)
{
  extra_depth = 4;// Change this to 0.4 for closed sockets
  diff("remove")
      cuboid([width+4,max(10,length+wall_thickness/2),depth+3], chamfer=.5, edges=[FRONT,"Y"], anchor=BOTTOM)
        tag("remove")
          attach(FRONT)
            rabbit_clip(type="socket",length=length, width=width,snap=snap,thickness=thickness,
                        depth=depth+extra_depth, lock=lock,compression=0);
}

// A clip to join the controller board to the motor mount, via a snap pin
module controller_board_clip(length, width, depth, snap, thickness, compression, lock=false)
{
    up(2)
    difference()
    {
        cuboid([max(width+4,12),10, depth], chamfer=.5, edges=[FRONT,"Y"], anchor=CENTER)
      attach(BACK)
        rabbit_clip(type="pin",length=length, width=width,snap=snap,thickness=thickness,depth=depth,
                    compression=compression, lock=lock);
        fwd(0.35)
        xrot(-90)
        snap_pin_socket("medium", anchor=CENTER, orient=UP, fins=true, pointed=false, $fn=40);
    }
   
}

module controller_board_snap_pin_socket(depth)
{
    up(2)
    difference()
    {
        cuboid([snap_pin_socket_cuboid_width,snap_pin_socket_cuboid_length, depth], chamfer=.5, edges=[FRONT,"Y"], 
                anchor=CENTER);
        fwd(1)
        xrot(-90)
        snap_pin_socket("medium", anchor=CENTER, orient=UP, fins=true, pointed=false, $fn=40);
    }
   
}


module controller_board_mounting_plate()
{
    // The rounded controller mounting plate
    down(controller_board_plate_depth/2)
    linear_extrude(height=controller_board_plate_depth)
    polygon(round_corners(square([controller_board_plate_width, controller_board_plate_length], center=true), cut=1, $fn=96*4));
    
    // Join a snap pin that will be used to attach controller board
    for (socket_index = [-1, 1])
    {
        fwd(0.5*socket_index*motor_mounting_plate_size/3)
        right(controller_board_plate_width/2-1.5)
        top_half()
        zrot(90)
        snap_pin("medium", anchor=CENTER, orient=UP, pointed=false, thickness = 1, $fn=40);
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
            // Cut out the slots for mounting the motor
            up((motor_mounting_plate_height+motor_screw_length)/2)
            nema_mount_mask(size=nema_motor_size, depth=motor_mounting_plate_height+motor_screw_length, l=motor_mounting_plate_adjustment_range, $fn=100);

    }

    up(motor_mounting_plate_height/2)
    union()
    {
        difference()
        {
            // The rounded motor plate with the area for the clip
            down(motor_mounting_plate_height/2)
            union()
            {
                linear_extrude(height=motor_mounting_plate_height)
                polygon(round_corners(square([motor_mounting_plate_size, motor_mounting_plate_size + motor_mounting_plate_adjustment_range/2 + snap_pin_socket_cuboid_length/2], center=true), cut=3, $fn=96*4));
                
                fwd(max((snap_pin_socket_cuboid_length+collar_od)/2, motor_mounting_plate_size/2-(snap_pin_socket_cuboid_length+wall_thickness)/2))
                linear_extrude(height=motor_mounting_plate_height)
            polygon(round_corners(square([snap_pin_socket_cuboid_width*2, snap_pin_socket_cuboid_length], center=true), cut=0.5, $fn=96*4));

            }
            
            // Cut out the slots for mounting the motor
            nema_mount_mask(size=nema_motor_size, depth=motor_mounting_plate_height+1, l=motor_mounting_plate_adjustment_range, $fn=100);
        }
        
        y_adjust = max(motor_mounting_plate_size/2-snap_pin_socket_cuboid_length/2+motor_mounting_plate_adjustment_range+0.25,
                    (snap_pin_socket_cuboid_length+collar_od)/2);
        for (socket_index = [-1, 1])
        {
            // Add a socket for the clip that will be used to attach the controller board
            right(0.5*socket_index*motor_mounting_plate_size/3)
            up(motor_mounting_plate_height/2)
            fwd(y_adjust)
            controller_board_snap_pin_socket(depth=4);
        }
    }

}

//intersection()
//{
////    hollow_threaded_rod_with_bearing_support();
////    hollow_motor_support_with_collar();
//
//    motor_mount();
////    down(support_height+rod_height)
//    cube([motor_mounting_plate_size, motor_mounting_plate_size, 2*support_height+rod_height]);
//    
//}


motor_mount();

left(100)
controller_board_mounting_plate();

// Add a separate clip that will be used to attach the controller board to the motor support tube
//fwd(motor_mounting_plate_size)
//controller_board_clip(length=clip_length, width=7, depth=4, snap=1, thickness=1.2, compression=0.2);

//back(snap_pin_socket_cuboid_length/2)
//controller_board_snap_pin_socket(width=7, depth=4);

// Show the motor https://www.canadarobotix.com/products/2688
if (show_motor)
{
    nema_stepper_motor(size=nema_motor_size, h=motor_body_length, shaft_len=motor_shaft_length);
}
//else
//{
//    left(100)
//    controller_board_mounting_plate();
//}

// Show the bearing
//color("blue")
//up(support_height+rod_height+motor_mounting_plate_height-bearing_height/2)
//cylinder(h=bearing_height, r=bearing_od/2, center=true, $fn=100);


// Add the matching nut
if (show_nut)
{
    right(motor_mounting_plate_size+nut_diameter/2)
    up(nut_height/2)
    zrot(30)
    threaded_nut(nutwidth=nut_diameter, id=rod_diameter, h=nut_height, pitch=thread_pitch, $slop=0.05, $fa=1, $fs=1);
}


