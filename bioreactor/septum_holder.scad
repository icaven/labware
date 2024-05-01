/*
    Septum holder for Bioreactor.
    
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
include <BOSL2/threading.scad>

// Show a part, or the assembled parts in position
part_to_show = "all, assembled"; // ["all, assembled", "holder", "nut"]

threaded_rod_height = 30;
rod_diameter = 18;
cap_diameter = 19.9;
cap_height = 3.7;
thread_pitch = 1.5;
wall_thickness = 2.0;
nut_diameter = 27;

// Don't need to change anything after this
module __end_of_customizer_variables() {}

nut_height = 10;
plate_ring_height = 1.5;


module septum_holder()
{
    // Create the threaded holder, upside down (the way it should be printed)
    up(threaded_rod_height / 2)
    difference()
        {
            union()
                {
                    threaded_rod(d = rod_diameter, height = threaded_rod_height, pitch = thread_pitch, end_len1 = cap_height * 4,
                    $fa = 1, $fs = 1, blunt_start = true, bevel2 = true);

                    // The cap at the top
                    down(threaded_rod_height / 2 - cap_height / 2)
                    cylinder(h = cap_height, r = cap_diameter / 2, center = true, $fa = 1, $fs = 1);

                    // Collar around the post
                    down(threaded_rod_height / 2 - cap_height * 3 - plate_ring_height*2)
                    cylinder(h = plate_ring_height, r = nut_diameter / 2, center = true, $fa = 1, $fs = 1);

                    // Tapered support for the collar
                    down(threaded_rod_height / 2 - cap_height * 3 - plate_ring_height / 2)
                    cylinder(h = plate_ring_height*2, r2 = nut_diameter / 2, r1 = rod_diameter / 2 - 1, center = true, $fa
                    = 1, $fs = 1);


                }
            cylinder(h = threaded_rod_height + 2, r = rod_diameter / 2 - wall_thickness, center = true, $fa = 1, $fs = 1);
        }
}
module septum_holder_nut()
{
    // The matching nut
    threaded_nut(nutwidth = nut_diameter, id = rod_diameter, h = nut_height, pitch = thread_pitch, $slop = 0.05, $fa = 1
    , $fs = 1);
}

if (part_to_show == "all, assembled")
{
    up(threaded_rod_height)
    zflip()  // Show the assembly in the orientation that it will be used in
    {
        septum_holder();

        // The matching nut
        up(threaded_rod_height - nut_height / 2)
        septum_holder_nut();
    }
}
else if (part_to_show=="holder")
{
//    back_half(s=150) 
    septum_holder();
}
else if (part_to_show=="nut")
{
   up(nut_height / 2)
   septum_holder_nut();
}
