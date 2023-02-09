"""
My default registration parameters:

runAntsRegistration_default(dim, outname, f, m) = \`antsRegistration -v -d \$dim -o \$outname -r initialTransform\\[\$f, \$m, 1\\] -m MI\\[\$f, \$m, 1, 32, regular, 0.2\\] -t Translation\\[0.1\\] -c \\[100x100x100, 1e-8, 10\\] -s 4x2x1mm -f 8x4x1 -m MI\\[\$f, \$m, 1, 32, regular, 0.2\\] -t rigid\\[0.1\\] -c \\[100x100x100, 1e-8, 10\\] -s 4x2x1mm -f 8x4x1 -m MI\\[\$f, \$m, 1, 32, regular, 0.2\\] -t affine\\[0.1\\] -c \\[100x100x100, 1e-8, 10\\] -s 4x2x1mm -f 8x4x1\`

"""
runAntsRegistration_default(dim, outname, f, m) = `antsRegistration -v -d $dim -o $outname -r initialTransform\[$f, $m, 1\] -m MI\[$f, $m, 1, 32, regular, 0.2\] -t Translation\[0.1\] -c \[100x100x100, 1e-8, 10\] -s 4x2x1mm -f 8x4x1 -m MI\[$f, $m, 1, 32, regular, 0.2\] -t rigid\[0.1\] -c \[100x100x100, 1e-8, 10\] -s 4x2x1mm -f 8x4x1 -m MI\[$f, $m, 1, 32, regular, 0.2\] -t affine\[0.1\] -c \[100x100x100, 1e-8, 10\] -s 4x2x1mm -f 8x4x1`

"""
My default registration parameters:

runAntsTransform_default(imgw_outname, f, m, tform1) = \`antsApplyTransforms -d 2 -i \$m -r \$f -o \$imgw_outname -n Linear -t \$tform1 -v 1\`
runAntsTransform_default(imgw_outname, f, m, tform2, tform1) = \`antsApplyTransforms -d 2 -i \$m -r \$f -o \$imgw_outname -n Linear -t \$tform2 \$tform1 -v 1\`
"""
runAntsTransform_default(imgw_outname, f, m, tform1) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t $tform1 -v`
runAntsTransform_default(imgw_outname, f, m, tform2, tform1) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t $tform2 -t $tform1 -v`
runAntsTransform_inv_default(imgw_outname, f, m, tform1) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t \[$tform1, 1\] -v`
runAntsTransform_inv_default(imgw_outname, f, m, inv_tform2, tform1) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t $inv_tform2 -t \[$tform1, 1\] -v`

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
	end
	#run registration
	for i in eachindex(movingfns)
    run(antsRegisterFunc(dim, outnames[i], fixedfns[i], movingfns[i]))
  end
	return(outnames)
end

"""
Run pairwise transformation. Non-linear warping has not been implemented. 
"""
function _runAntsTransformPairwise(fixedfns, movingfns; outfile_tag = false, tform_tag = false)
  tformfns = Vector{String}(undef, 0)
  syntformfns = Vector{String}(undef, 0)
  imgw_outnames = Vector{String}(undef, 0)
  for i in eachindex(movingfns)
  	# Assign output image file name
  	if outfile_tag == false
  		outfn = splitext(movingfns[i])[1]*"_"
  	else
  		outfn = outfile_tag[i]*"_"
  	end
    imgw_outname = outfn*"warped.nrrd"
		push!(imgw_outnames, imgw_outname)
    # Assign input tform
  	if tform_tag == false
  		tform_fn = splitext(movingfns[i])[1]*"_"
  	else
  		tform_fn = tform_tag[i]*"_"
  	end
  	# assign input tform file name
    tform = tform_fn*"0GenericAffine.mat"
		syntform = tform_fn*"1Warp.nii.gz"
		push!(tformfns, tform)
		push!(syntformfns, syntform)
  end
	return(imgw_outnames, tformfns, syntformfns)
end

function runAntsTransformsPairwise(fixedfns, movingfns; outfile_tag = false, tform_tag = false, antsTransformFunc = runAntsTransform_default)
  imgw_outnames, tformfns, syntformfns = _runAntsTransformPairwise(fixedfns, movingfns; outfile_tag = outfile_tag, tform_tag = tform_tag)
  for i in eachindex(movingfns)
      run(antsTransformFunc(imgw_outnames[i], fixedfns[i], movingfns[i], tformfns[i]))
  end
  return(imgw_outnames)
end

function runAntsTransformsPairwiseSyN(fixedfns, movingfns; outfile_tag = false, tform_tag = false, antsTransformFunc = runAntsTransform_syn)
	imgw_outnames, tformfns, syntformfns = _runAntsTransformPairwise(fixedfns, movingfns; outfile_tag = outfile_tag, tform_tag = tform_tag)
	for i in eachindex(movingfns)
			run(antsTransformFunc(imgw_outnames[i], fixedfns[i], movingfns[i], syntformfns[i], tformfns[i]))
	end
	return(imgw_outnames)
end

"""
1. apply the same 2d antsTransformations to each frame of a 3d image (channel image).
2. save the output file `warpoutfn`
Must use .nrrd format
`tform2_fn` is a non-rigid transformation
`tform1_fn` is a rigid/affine transformation
"""
function applyAntsTransforms(warpoutfn, fixedfn, movingfn, tform2_fn, tform1_fn, mv_pxspacing; antsTransformFunc)
  img = load(movingfn)
  nimgs = size(img, 3)
  tmp = [];
  for i in 1:nimgs
    infn = string("/tmp/tmpin_", i, ".nrrd")  #input file
    imga = setAxis(parent(img[:,:,i]), mv_pxspacing)
    save(infn, imga) #temporary save
    outfn = string("/tmp/tmpout_",i, ".nrrd") #output file
    run(antsTransformFunc(outfn, fixedfn, infn, tform2_fn, tform1_fn))
    push!(tmp, load(outfn))
    rm(infn)
    rm(outfn)
  end
  save(warpoutfn, cat(tmp..., dims = 3))
end




