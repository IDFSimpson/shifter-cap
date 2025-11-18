linear_extrude(
    height = 15,
    scale = 0.5,
    slices = 100,  // More slices = smoother curves
    $fn = 100
)
import(file = "left_shifter_silhouette.svg", center = true);