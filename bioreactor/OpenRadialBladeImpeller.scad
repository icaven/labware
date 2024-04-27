/*
    Modified from https://www.printables.com/model/517025-impeller-open-radial-blade/files
*/

$fn = 100;  // Number of fragments used to approximate circles

// Parameters
bladeCount = 6;          // Number of blades
bladeThickness = 4;       // Thickness of each blade
impellerDiameter = 70;    // Diameter of the impeller
impellerThickness = 27;
hubRadius = 7.5;         // Radius of the hub
shaftDiameter = 4.7;
shroudThickness = 2;
shroudDiameter = 40;
hubRelief = 18;
reliefAngle = 50;
hubOnly = false;

module __end_of_customizer_variables() {}

impellerRadius = impellerDiameter / 2;    // Radius of the impeller
shroudRadius = shroudDiameter / 2;    // Radius of the shroud

module Blade() {
    translate([0,bladeThickness/2,0])
    rotate([90,0,0])
    cube([impellerRadius, impellerThickness, bladeThickness], center=false);
}


module Impeller() {
    union()
    for (i = [0:bladeCount-1]) {
        rotate([0, 0, i*360/bladeCount])
        Blade();
    }
}

module hub() {
    translate([0,0,impellerThickness/2])
        cylinder(h=impellerThickness, r=hubRadius, center=true);
}

module shaft() {
    translate([0,0,impellerThickness/2])
    cylinder(h=impellerThickness, r=shaftDiameter/2, center=true);
}
module shroud() {
    translate([0,0,shroudThickness/2]){
        cylinder(h=shroudThickness, r=shroudRadius, center=true);
    }
}

module hubReliefCutout() {
    rotate_extrude()
    translate([hubRadius, impellerThickness-hubRelief, 0])
    polygon([[0,0],[-hubRadius, 0],[-hubRadius,hubRelief],[tan(reliefAngle)*hubRelief,hubRelief]
                ]);
}

intersection(){
    if (hubOnly) {hub();}
    difference(){
        union(){
            Impeller(); hub(); shroud();
        }
        {
            union(){
                hubReliefCutout();
                shaft();
            }
        }
    }
}