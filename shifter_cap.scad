// =====================================================
// Shifter Cap
// =====================================================

// ===== PARAMETERS =====

// SVG scale correction
svg_scale = 0.782;  // Adjust to match actual dimensions

// "left" or "right" part
handedness = "left";

// Dome parameters
layers = 30;
dome_height = 17.5;
silhouette = "left_shifter_silhouette.svg";
outline = "left_shifter_outline.svg";
wall_thickness = 1;
cap_height = 2;
show_base_outline = false;
base_height = 5.5;

// Screw tube parameters
screw_head_diameter = 7;
tube_outer_diameter = screw_head_diameter + 1;
screw_diameter = 3.2;
screw_positions = [
    [-20.2, -24.1, 4],
    [-15.6, 19, 1]
];          //[x,y,distance_from_bottom] (3rd is a bit naff)

// Cutout parameters
trigger_slot_cutout_width = 22.5;
trigger_slot_cutout_height = 4;
cable_hole_diameter = 9;

// Gear window parameters (viewing window for the selected-gear indicator)
// -----------------------------------------------------------------
// Same pattern as the screw tubes: the boss is deliberately oversized so
// it overshoots the dome's true outer surface, then sits inside the same
// intersection() as screw_tubes, which trims that overshoot away and
// leaves it flush - no need to know or calculate where the curved
// surface actually is. gear_window_boss_reach is the boss's known INNER
// face (into the cavity), used as the anchor for the lip cut.
gear_window_enable        = false;
gear_window_pos           = [14, -8, 9];   // [x, y, z] - roughly on the dome's wall
gear_window_rot           = [0, 55, 0];    // aims the boss/hole's local Z axis through the wall

gear_window_dia           = 7;     // the visible opening - this is the size of the "glass"
gear_window_lip_width     = 1.2;   // how much wider the inner counterbore is than the window (the glue ledge)
gear_window_lip_depth     = 1;     // how deep the counterbore is cut, starting from the boss's inner face
gear_window_boss_pad      = 1.5;   // extra material around the counterbore, for strength
gear_window_boss_dia      = gear_window_dia + 2 * (gear_window_lip_width + gear_window_boss_pad);
gear_window_boss_reach    = 6;     // how far inward (into the cavity) the boss reaches from gear_window_pos
gear_window_boss_overshoot = 8;    // how far outward past gear_window_pos the boss extends - just needs
                                    // to exceed the dome's wall thickness here; intersection() trims the rest


// ===== MODULES =====

module silhouette_cache(wall_offset = 0) {
    offset(r = wall_offset)
        scale([svg_scale, svg_scale, 1])
            import(file = silhouette, center = true);
}

module dome(height, layers, base_h = 0, wall_offset = 0) {

    // Cache silhouette once
    module base_shape() {
        silhouette_cache(wall_offset);
    }

    // Vertical base section ---
    linear_extrude(height = base_h + 0.1)
        base_shape();

    // Dome section above the base
    dome_h = height - base_h;
    layer_h = dome_h / layers;

    translate([0, 0, base_h]) {
        for (i = [0 : layers - 1]) {

            z = i * layer_h;
            progress = i / layers;  // 0 → 1 over the dome only

            scale_factor = 1 - (progress * progress) * 0.7;

            translate([0, 0, z])
                linear_extrude(height = layer_h + 0.1)
                    scale([scale_factor, scale_factor, 1])
                        base_shape();
        }
    }
}


module void_bar_curve(width=16, height=6.5, thickness=3, resolution=60, center=false) {

    // Helper function for the curve calculation
    function curve_y(x) = (-0.016 * pow(x, 2)) - (0.16 * x) + 6.6;

    // Generate the profile points
    points = concat(
        [for (i = [0 : resolution])
            let (x = i * width / resolution)
            [x, curve_y(x)]
        ],
        [[width, height], [0, height]]
    );

    // Centering logic
    x_offset = center ? -width / 2 : 0;
    y_offset = center ? -thickness / 2 : 0;

    translate([x_offset, y_offset, height])
        rotate([-90, 0, 0])
        linear_extrude(height = thickness)
            polygon(points);
}


module void_trigger_slot(cutout_width = 22.5, cutout_height = 6) {
    cube([cutout_width, 10, cutout_height], center = true);
}

module screw_tubes(positions, dome_height, outer_diameter)  {
    for (pos = positions) {
        tube_depth = dome_height - pos.z;
        translate([pos.x, pos.y, dome_height - tube_depth])
            cylinder(h = tube_depth + 5, d = outer_diameter, $fn = 40);
    }
}

module screw_holes(positions, dome_height, screw_diameter, head_diameter){
    for (pos = positions) {
        tube_depth = dome_height - pos.z;
        translate([pos.x, pos.y, dome_height - tube_depth - 0.1]){
            cylinder(h = tube_depth + 10, d = screw_diameter, $fn = 30);
            translate([0, 0, 1])
                cylinder(h = tube_depth + 10, d = head_diameter, $fn = 30);
        }
    }
}

// Oversized cylinder reaching from a known point inside the cavity
// (gear_window_boss_reach) out past the dome's true outer surface
// (gear_window_boss_overshoot). Sits inside the same intersection() as
// screw_tubes, which trims the overshoot to match the curved surface
// exactly - same trick, no manual surface-tracking needed.
module gear_window_boss() {
    translate(gear_window_pos)
        rotate(gear_window_rot)
            translate([0, 0, -gear_window_boss_reach])
                cylinder(h = gear_window_boss_reach + gear_window_boss_overshoot, d = gear_window_boss_dia, $fn = 60);
}

// Two cylinders removed from the boss. The through-hole (the visible
// window) is drilled well past both ends, since we don't know exactly
// where intersection() ended up trimming the boss's outer face - same
// idea as screw_holes drilling past the tube's known length. The
// counterbore / lip is anchored to the boss's KNOWN inner face instead,
// cut outward by gear_window_lip_depth, leaving a flat shoulder for a
// clear plastic disc to be glued onto from inside.
module gear_window_cut() {
    translate(gear_window_pos)
        rotate(gear_window_rot) {
            // Through-hole - the viewing window, well past both ends
            translate([0, 0, -gear_window_boss_reach - 1])
                cylinder(h = gear_window_boss_reach + gear_window_boss_overshoot + 2, d = gear_window_dia, $fn = 60);

            // Counterbore / lip - cut from the boss's known inner face
            translate([0, 0, -gear_window_boss_reach])
                cylinder(h = gear_window_lip_depth, d = gear_window_dia + 2 * gear_window_lip_width, $fn = 60);
        }
}


// ===== BUILD =====

module build_shifter() {
    difference() {
        // Combine dome and tubes, then cut tubes to dome shape
        intersection() {
            // Bounding box that includes tubes
            union() {
                // Hollow dome
                difference() {
                    dome(dome_height, layers, base_height);
                    translate([0, 0, -cap_height])
                        dome(dome_height, layers, base_height, -wall_thickness);
                }

                // Tubes extending above dome
                screw_tubes(screw_positions, dome_height, tube_outer_diameter);

                // Gear window boss - same trick as the tubes above: it
                // overshoots the dome's true outer surface, and this
                // intersection() trims that overshoot away, leaving it
                // flush with the curved skin automatically.
                if (gear_window_enable)
                    gear_window_boss();
            }

            // Cut everything to dome outer shape
            translate([0, 0, -1])
                dome(dome_height + 1, layers, base_height);
        }

        // Drill screw holes
        screw_holes(screw_positions, dome_height, screw_diameter, screw_head_diameter);

        // Trigger slot
        translate([0, 27, trigger_slot_cutout_height/2])
            void_trigger_slot(trigger_slot_cutout_width,trigger_slot_cutout_height);

        // Shifter cable exit
        translate([-20, -34, 0])
            rotate([90, 0, -50.5])
                cylinder(h = 20, d = cable_hole_diameter, center = true, $fn = 40);

        // Handlebar attachhment clamp cutout
        translate([18.3,25,0]){
            // Box section
            translate([9.5,1.1,0])
                rotate([0,0,-22])
                    cube([4,9,5]);
            // Curved section
            rotate([0,0,27])
                void_bar_curve();
        }

        // Gear window
        if (gear_window_enable)
            gear_window_cut();
    }

    // ===== DEBUG: Base outline for positioning screws =====
    if (show_base_outline) {
        %translate([0, 0, 0])
            linear_extrude(height = 0.1)
                scale([svg_scale, svg_scale, 1])
                    import(file = outline, center = true);
    }
}

if (handedness == "left")
    mirror([0,1,0])
        build_shifter();
else
    build_shifter();
