include <BOSL2/std.scad>
include <BOSL2/screws.scad>
$fn = 16;

// Slight modification of nut_trap_side() from BOSL2/screws.scad
module circular_magnet_trap_side(magnet_d, magnet_thickness, anchor = BOT, orient, spin, poke_len = 0, poke_diam)
{
    cubesize = [magnet_d, magnet_d, magnet_thickness];
    halfwidth = magnet_d / 2;
    shift = cubesize[0] / 2 - halfwidth / 2;


   default_tag("remove")
   attachable(size = cubesize + [halfwidth, 0, 0], offset = [shift, 0, 0], anchor = anchor, orient = orient, 
               spin = spin)
    {
        union()
        {
            cuboid(cubesize, anchor = LEFT);
            linear_extrude(height = magnet_thickness, center = true) circle(r = magnet_d / 2);
            if (poke_len > 0)
            xcyl(l = poke_len, d = default(poke_diam, magnet_thickness), anchor = RIGHT);
        }
        children();
    }

}

module _test_magnet_trap()
{
    layer_height = 0.15;
    magnet_d = 8;
    magnet_thickness = 3;
    difference_tolerance = 0.1;

    thicknesses = [1.25/2];

    box_size = magnet_d * 2;
    for (layer_height_index = [0:len(thicknesses)-1])
    {
//        total_layer_height = number_layers[layer_height_index] * layer_height;
        thickness_above_and_below_magnet = thicknesses[layer_height_index];
        box_height = 2*thickness_above_and_below_magnet + magnet_thickness;
//        echo(quant_magnet_thickness);
        fwd(layer_height_index * 2 * box_size)
        diff()
        {
            cuboid([box_size - difference_tolerance, box_size - difference_tolerance, box_height], anchor = BOTTOM)
            position(BOTTOM)
            up(thickness_above_and_below_magnet)
            circular_magnet_trap_side(magnet_d, magnet_thickness, poke_len = 3 + difference_tolerance, anchor = BOTTOM);
        }

    }
    
}

_test_magnet_trap();