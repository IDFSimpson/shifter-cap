layers = 30;
dome_height = 12;
silhouette = "left_shifter_silhouette.svg";
wall_thickness = 2;

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
    dome(dome_height, layers);  // Full height outer dome
    translate([0, 0, -wall_thickness])  // Move inner dome DOWN
        dome(dome_height, layers, -wall_thickness);  // Inner dome
}