// =====================================================
// Shifter Cap - Left Side
// =====================================================

// ===== PARAMETERS =====

// SVG scale correction
svg_scale = 0.782;  // Adjust to match actual dimensions

// Dome parameters
layers = 30;
dome_height = 12;
silhouette = "left_shifter_silhouette.svg";
outline = "left_shifter_outline.svg";
wall_thickness = 2;
cap_height = 2;
show_base_outline = false;

// Screw tube parameters
screw_head_diameter = 7;
tube_outer_diameter = screw_head_diameter + 1;
screw_diameter = 3.2;
tube_depth = dome_height - 2;
screw_positions = [
    [-20.2, -24.1],
    [-15.6, 19]
];

// Cutout parameters
trigger_slot_cutout_width = 22.5;
trigger_slot_cutout_height = 4;
cable_hole_diameter = 9;


// ===== DOME MODULE =====

module dome(height, layers, wall_offset = 0) {
    for (i = [0 : layers - 1]) {
        z = i * (height / layers);
        progress = i / layers;
        // Parabolic curve - gentle rounded dome
        scale_factor = 1 - (progress * progress) * 0.7;

        translate([0, 0, z])
            linear_extrude(height = height / layers + 0.1)
                scale([scale_factor, scale_factor, 1])
                    offset(r = wall_offset)
                        scale([svg_scale, svg_scale, 1])
                            import(file = silhouette, center = true);
    }
}

module void_screw_hole(depth,screw,screw_head) {
    cylinder(h = depth + 10, d = screw, $fn = 30);
    translate([0, 0, 1])
        cylinder(h = tube_depth + 10, d = screw_head, $fn = 30);
}

module void_trigger_slot(cutout_width = 22.5, cutout_height = 6) {
            cube([cutout_width, 10, cutout_height], center = true);
}


// ===== BUILD =====

difference() {
    // Main dome with screw tubes
    difference() {
        // Combine dome and tubes, then cut tubes to dome shape
        intersection() {
            // Bounding box that includes tubes
            union() {
                // Hollow dome
                difference() {
                    dome(dome_height, layers);
                    translate([0, 0, -cap_height])
                        dome(dome_height, layers, -wall_thickness);
                }

                // Tubes extending above dome
                for (pos = screw_positions) {
                    translate([pos.x, pos.y, dome_height - tube_depth])
                        cylinder(h = tube_depth + 5, d = tube_outer_diameter, $fn = 40);
                }
            }

            // Cut everything to dome outer shape
            translate([0, 0, -1])
                dome(dome_height + 1, layers);
        }

        // Drill screw holes
        for (pos = screw_positions) {
            translate([pos.x, pos.y, dome_height - tube_depth - 0.1])
                void_screw_hole(tube_depth, screw_diameter, screw_head_diameter);
        }
    }

    // Trigger slot
    translate([0, 27, trigger_slot_cutout_height/2])
        void_trigger_slot(trigger_slot_cutout_width,trigger_slot_cutout_height);

    // Shifter cable exit
    translate([-20, -34, 0])
        rotate([90, 0, -50.5])
            cylinder(h = 20, d = cable_hole_diameter, center = true, $fn = 40);
}

// ===== DEBUG: Base outline for positioning screws =====
if (show_base_outline) {
    %translate([0, 0, 0])
        linear_extrude(height = 0.1)
            scale([svg_scale, svg_scale, 1])
                import(file = outline, center = true);
}
