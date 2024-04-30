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
