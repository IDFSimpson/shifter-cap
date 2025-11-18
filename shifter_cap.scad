layers = 30;
dome_height = 12;
silhouette = "left_shifter_silhouette.svg";

for (i = [0 : layers - 1]) {
    z = i * (dome_height / layers);
    progress = i / layers;
    // Parabolic curve - gentle rounded dome
    scale_factor = 1 - (progress * progress) * 0.7;

    translate([0, 0, z])
        linear_extrude(height = dome_height / layers + 0.1)
            scale([scale_factor, scale_factor, 1])
                import(file = silhouette, center = true);
}