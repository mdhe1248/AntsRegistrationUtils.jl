"""
My default registration parameters:

Note: remove one backslash from every locaion. (e.g. backslash --> nothing, double backslash --> single backslash) 

runAntsRegistration_default(dim, outname, f, m) = `antsRegistration -v -d \$dim -o \$outname -r initialTransform\\[\$f, \$m, 1\\] -m MI\\[\$f, \$m, 1, 32, regular, 0.2\\] -t Translation\\[0.1\\] -c \\[100x100x100, 1e-8, 10\\] -s 4x2x1mm -f 8x4x1 -m MI\\[\$f, \$m, 1, 32, regular, 0.2\\] -t rigid\\[0.1\\] -c \\[100x100x100, 1e-8, 10\\] -s 4x2x1mm -f 8x4x1 -m MI\\[\$f, \$m, 1, 32, regular, 0.2\\] -t affine\\[0.1\\] -c \\[100x100x100, 1e-8, 10\\] -s 4x2x1mm -f 8x4x1`

"""
runAntsRegistration_default(dim, outname, f, m) = `antsRegistration -v -d $dim -o $outname -r initialTransform\[$f, $m, 1\] -m MI\[$f, $m, 1, 32, regular, 0.2\] -t Translation\[0.1\] -c \[100x100x100, 1e-8, 10\] -s 4x2x1mm -f 8x4x1 -m MI\[$f, $m, 1, 32, regular, 0.2\] -t rigid\[0.1\] -c \[100x100x100, 1e-8, 10\] -s 4x2x1mm -f 8x4x1 -m MI\[$f, $m, 1, 32, regular, 0.2\] -t affine\[0.1\] -c \[100x100x100, 1e-8, 10\] -s 4x2x1mm -f 8x4x1`

"""
My default registration parameters:

Note: remove one backslash from every locaion. (e.g. backslash --> nothing, double backslash --> single backslash) 

runAntsTransform_default(imgw_outname, f, m, tform) = `antsApplyTransforms -d 2 -i \$m -r \$f -o \$imgw_outname -n Linear -t \$tform -v 1`
"""
runAntsTransform_default(imgw_outname, f, m, tform) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t $tform -v 1`

""" 
Run Pairwise antsRegistration
"""
function runAntsRegistrationPairwise(dim, fixedfns, movingfns; tag = false, antsRegisterFunc = runAntsRegistration_default)
	outnames = Vector{String}(undef, 0)
  for i in eachindex(movingfns)
    if tag == false
      outname = splitext(movingfns[i])[1]*"_"
		else
			outname = tag[i]*"_"
		end
		push!(outnames, outname)
    antsRegisterFunc(dim, outname, fixedfns[i], movingfns[i])
  end
	return(outnames)
end

"""
Run pairwise transformation. Non-linear warping has not been implemented. 
"""
function runAntsTransformsPairwise(fixedfns, movingfns; outfile_tag = false, tform_tag = false, antsTransformFunc = runAntsTransform_default)
  for i in eachindex(movingfns)
  	# Assign output image file name
  	if outfile_tag == false
  		outfn = splitext(movingfns[i])[1]*"_"
  	else
  		outfn = outfile_tag[i]*"_"
  	end
    imgw_outname = outfn*"warped.nrrd"
  
    # Assign input tform
  	if tform_tag == false
  		tform_fn = splitext(movingfns[i])[1]*"_"
  	else
  		tform_fn = tform_tag[i]*"_"
  	end
  	# assign input tform file name
    tform = tform_fn*"0GenericAffine.mat"
    antsTransformFunc(imgw_outname, fixedfns[i], movingfns[i], tform)
  end
end
