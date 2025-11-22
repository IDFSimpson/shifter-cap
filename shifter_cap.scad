// Dome parameters
layers = 30;
dome_height = 12;
silhouette = "left_shifter_silhouette.svg";
outline = "left_shifter_outline.svg";
wall_thickness = 2;
cap_height = 2;
show_base_outline = false;

// Screw tube parameters
tube_outer_diameter = 7;
screw_diameter = 3.2;
tube_depth = dome_height - 2;
screw_positions = [
    [-27.3, -32.2],
    [-19, 25]
];

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
                        import(file = silhouette, center = true);
    }
}

// Hollow dome with closed top
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
            cylinder(h = tube_depth + 10, d = screw_diameter, $fn = 30);
    }
}

// TEMPORARY: Base outline for positioning screws
if (show_base_outline) {
    %translate([0, 0, 0])
        linear_extrude(height = 0.1)
            import(file = outline, center = true);
}