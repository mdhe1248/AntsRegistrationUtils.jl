# AntsRegistrationUtils
runAntsRegistration_01(dim, outname, f, m) = `antsRegistration -v -d $dim -o $outname
-w \[0.001, 0.99\]
-r initialTransform\[$f, $m, 1\]
-t translation\[0.1\] -m GC\[$f, $m, 1, 32, none\] -c \[100x100x100x50, 1e-10, 10\] -f 16x8x4x1 -s 8x4x2x1
-t rigid\[0.1\] -m GC\[$f, $m, 1, 32, none\] -c \[100x100x100x50, 1e-10, 10\] -f 16x8x4x1 -s 8x4x2x1
-t affine\[0.1\] -m GC\[$f, $m, 1, 32, none\] -c \[100x100x100x50, 1e-10, 10\] -f 16x8x4x1 -s 8x4x2x1
-t Syn\[0.1, 3, 0\] -m MI\[$f, $m, 1, 32\] -c \[100x100x100, 1e-4, 10\] -f 8x4x1 -s 4x2x1`

runAntsTransform_01(imgw_outname, f, m, tform1) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t $tform1 -v`
