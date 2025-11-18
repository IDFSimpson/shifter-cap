// Easy to adjust dome shape
layers = 30;
dome_height = 12;
min_scale = 0.3;      // Scale at the top
roundness = 5;        // 1 = linear, 2 = parabolic, 3 = more curved
silhouette = "left_shifter_silhouette.svg";

for (i = [0 : layers - 1]) {
    z = i * (dome_height / layers);
    progress = i / layers;

    // Adjustable curve - change 'roundness' to adjust shape
    scale_factor = 1 - pow(progress, roundness) * (1 - min_scale);

    translate([0, 0, z])
        linear_extrude(height = dome_height / layers + 0.1)
            scale([scale_factor, scale_factor, 1])
                import(file = silhouette, center = true);
}