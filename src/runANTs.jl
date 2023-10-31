mutable struct Regvars
  outdir::String
  movingfn::String
  bg_channel::Number
  fixed_slice::Number
  tag::String
  dim::Int
  mv_pxspacing::NTuple{2, Number}
  winsorizor::NTuple{2, Float64}
  SyN_thresh::Float64
  fixed2d_fn::String
  annotation2d_fn::String
  moving2d_fn::String
  warpout_fn::String #all channel
  regvars_fn::String
  inverse_warp_fn::String
  tform1_fn::String
  tform2_fn::String
  warpedfn::String #single moving channel
  fixedinvfn::String
  attninvfn::String
end
Regvars(outdir, movingfn, bg_channel, fixed_slice, tag, dim, mv_pxspacing, winsorizor, SyN_thresh,
) = Regvars(outdir, movingfn, bg_channel, fixed_slice, tag, dim, mv_pxspacing, winsorizor, SyN_thresh,, fixed2d_fn, annotation2d_fn, moving2d_fn, warpout_fn, regvars_fn,
  string(outdir, "fixed2d_", slice, ".nrrd"),
  string(outdir, "annotation2d_", slice,".nrrd"),
  outdir*first(splitext(last(splitdir(movingfn))))*string("_c", bg_channel, ".nrrd"),
  replace(outdir*first(splitext(last(splitdir(movingfn))))*string("_c", bg_channel, ".nrrd"), string("_c", bg_channel, ".nrrd") => "_warped.nrrd"),
  outdir*"regvars_"*first(splitext(last(splitdir(movingfn))))[end-1:end]*".jld2",
  string(first(splitext(outdir*first(splitext(last(splitdir(movingfn))))*string("_c", bg_channel, ".nrrd"))), "_"),  #output tag
  string(tag, "1InverseWarp.nii.gz"),
  string(tag, "0GenericAffine.mat"),
  string(tag, "1Warp.nii.gz"),
  string(tag, "warped.nrrd"),
  string(tag, "fixedinv.nrrd"),
  string(tag, "attninv.nrrd"))

#Regvars(outdir, movingfn, bg_channel, fixed_slice, fixed2d_fn, annotation2d_fn, moving2d_fn, warpout_fn, regvars_fn, tag, dim, mv_pxspacing, winsorizor, SyN_thresh,
## visualize moving images
function pad_images(vector_of_images; h = :auto, w = :auto)
  if h == :auto
    h = max([size(vector_of_images[i],1) for i in eachindex(vector_of_images)]...)
  end
  if w == :auto
    w = max([size(vector_of_images[i],2) for i in eachindex(vector_of_images)]...)
  end
  paddedimages= [PaddedView(0, vector_of_images[i], (h, w), padOrigin((h, w), vector_of_images[i])) for i in eachindex(vector_of_images)]
  return(paddedimages)
end


## assign input and output file names 
function assign_regvars(outdir, movingfn, fixed_slice, bg_channel, dim, mv_pxspacing, winsorizor, SyN_thresh)

function assign_regvars(outdir, movingfns, slices, channel, dim, mv_pxspacing, winsorizor, SyN_thresh)
  vars = Vector{Regvars}(undef, length(movingfns))
  for i in eachindex(vars)
    fixed2d_fn = string(outdir, "fixed2d_", slices[i], ".nrrd")
    annotation2d_fn = string(outdir, "annotation2d_", slices[i],".nrrd") #save filename
    moving2d_fn = outdir*first(splitext(last(splitdir(movingfns[i]))))*string("_c", channel, ".nrrd")
    warpoutfn = replace(moving2d_fn, string("_c", channel, ".nrrd") => "_warped.nrrd")
    n = first(splitext(last(splitdir(movingfns[i]))))[end-1:end]
    regvars_fn = outdir*"regvars_"*n*".jld2"
    tag = string(first(splitext(moving2d_fn)), "_")  #output tag
    vars[i] = Regvars(outdir, movingfns[i], fixed2d_fn, annotation2d_fn, moving2d_fn, warpoutfn, regvars_fn, tag, dim, mv_pxspacing, winsorizor, SyN_thresh)
  end
  return(vars)
end

"""file name is `regvars_idx.jld2`, where `idx` is a two-digit number. e.g. regvars_01.jld2"""
function save_regvars(var)
  jldsave(var.regvars_fn, regvars = var)
end
save_regvars(vars::AbstractVector) = [save_regvars(var) for var in vars]

function runAntsRegistrationSyN(var::Regvars)
  run(runAntsRegistration_01(var.dim, var.tag, var.fixed2d_fn, var.moving2d_fn; winsorizor = var.winsorizor, SyN_thresh = var.SyN_thresh)) #my default is winsorizor = (0.01, 0.99)
end
runAntsRegistrationSyN(vars::AbstractVector) = [runAntsRegistrationSyN(var) for var in vars]

function runAntsRegistrationAffine(var::Regvars)
  run(runAntsTransform_01(var.warpedfn, var.fixed2d_fn, var.moving2d_fn, var.tform1_fn)) # only rigid and affine
end
runAntsRegistrationAffine(vars::AbstractVector) = [runAntsRegistrationAffine(var) for var in vars]

function runAntsTransformSyN(var::Regvars)
  run(runAntsTransform_01(var.warpedfn, var.dim, var.fixed2d_fn, var.moving2d_fn, var.tform2_fn, var.tform1_fn)) #rigid, affine, and SyN 
end
runAntsTransformSyN(vars::AbstractVector) = [runAntsTransformSyN(var) for var in vars]

function runAntsTransformInvFixedSyN(var::Regvars)
  run(runAntsTransform_inv(var.fixedinvfn, var.dim, var.moving2d_fn, var.fixed2d_fn, var.tform2_fn, var.tform1_fn)) # inverse transformation of fixed image
end
runAntsTransformInvFixedSyN(vars::AbstractVector) = [runAntsTransformInvFixedSyN(var) for var in vars]

function runAntsTransformInvAttnSyN(var::Regvars)
  run(runAntsTransform_inv(var.attninvfn, var.dim, var.moving2d_fn, var.annotation2d_fn, var.tform2_fn, var.tform1_fn)) #inverse transformation of annotation
end
runAntsTransformInvAttnSyN(vars::AbstractVector) = [runAntsTransformInvAttnSyN(var) for var in vars]

function applyAntsTransform(var; antsTransformFunc = runAntsTransform_01)
  applyAntsTransforms_01(var.warpoutfn, var.dim, var.fixed2d_fn, var.moving2d_fn, var.tform2_fn, var.tform1_fn, var.mv_pxspacing; antsTransformFunc = runAntsTransform_01)
end
applyAntsTransform(vars::AbstractVector; antsTransformFunc = runAntsTransform_01) = [applyAntsTransform(var; antsTransformFunc = runAntsTransform_01) for var in vars]

"""
Apply transform to all channels of an image.
This function will load a 3d tif image (potentially multi channel 2d image), convert it into nrrd, temporarily store it in `/tmp`, apply the same transform to all frames, save the transformed image in `/tmp`, 
"""
function applyAntsTransforms_01(warpoutfn::String, d::Int, fixedfn::String, movingfn::String, tform2_fn::String, tform1_fn::String, mv_pxspacing; antsTransformFunc)
  img = load(movingfn)
  nimgs = size(img, 3) #find the number of channels
  tmp = Vector{AbstractMatrix}();
  for i in 1:nimgs
    infn = string("/tmp/tmpin_", i, ".nrrd")  #input nrrd file
    imga = setAxis(parent(img[:,:,i]), mv_pxspacing) #read a single channel, set axis
    save(infn, imga) #temporarily save as nrrd
    outfn = string("/tmp/tmpout_",i, ".nrrd") #output nrrd file
    run(antsTransformFunc(outfn, d, fixedfn, infn, tform2_fn, tform1_fn)) #run transform
    push!(tmp, load(outfn))
    rm(infn)
    rm(outfn)
  end
  tmpm = reshape( reduce(hcat, tmp), size(tmp[1],1), size(tmp[1],2), :)
  save(warpoutfn, tmpm)
end

"""Registration function
`runAntsRegistration_01(dim, outname, f, m; winsorizor = (0.001, 0.99), SyN_thresh = 1e-2)`
`dim` should be 2 dimentional
`outname` output file name
`f` fixed image file name
`m` moving image file name
`winsorizor` -w in antsRegistration. Basically thresholding. Seem to affect a lot on affine.
`SyN_threshold` is in -c in antsRegistration. Basically thresholding. 

Good affine transformation is almost necessary for good registration. 
If registration does not look satisfactory, initially try different winsorizor:
(0.001, 0.999), (0.001, 1), (0, 0.999), or (0, 1).
For `SyN_thresh`, if the image does not need a lot of warping, 1e-2 or 1e-3 would be a good start. Or, 1e-4 seems work fine. The `-c` value lower than 1e-6 may not be recommended but worth trying up to 1e-8. 
"""
runAntsRegistration_01(dim, outname, f, m; winsorizor = (0.001, 0.99), SyN_thresh = 1e-2) = `antsRegistration -v -d $dim -o $outname
-w \[$(winsorizor[1]), $(winsorizor[2])\] 
-r initialTransform\[$f, $m, 1\] 
-t rigid\[0.1\] -m GC\[$f, $m, 1, 32, none\] -c \[1000x1000x1000, 1e-10, 10\] -f 8x4x1 -s 4x2x1 
-t affine\[0.1\] -m GC\[$f, $m, 1, 32, none\] -c \[1000x1000x1000, 1e-10, 10\] -f 8x4x1 -s 4x2x1
-t Syn\[0.1, 3, 0\] -m MI\[$f, $m, 1, 32\] -c \[100x100x100, $SyN_thresh, 10\] -f 8x4x1 -s 4x2x1`

"""Transformation function
`tform1` affine transformation ants file.
`tform2` warp ants file.
"""
runAntsTransform_01(imgw_outname, d, f, m, tform1) = `antsApplyTransforms -d $d -i $m -r $f -o $imgw_outname -n Linear -t $tform1 -v`
runAntsTransform_01(imgw_outname, d, f, m, tform2, tform1) = `antsApplyTransforms -d $d -i $m -r $f -o $imgw_outname -n Linear -t $tform2 -t $tform1 -v`

"""Transformation function
`tform1` affine transformation ants file.
`inv_tform2` inverse warp ants file.
"""
runAntsTransform_inv(imgw_outname, d, f, m, tform1) = `antsApplyTransforms -d $d -i $m -r $f -o $imgw_outname -n Linear -t \[$tform1, 1\] -v`
runAntsTransform_inv(imgw_outname, d, f, m, inv_tform2, tform1) = `antsApplyTransforms -d $d -i $m -r $f -o $imgw_outname -n Linear -t $inv_tform2 -t \[$tform1, 1\] -v`


""" find an origin to put the image `A` in the center of PaddedView. v is a 2-element vector"""
function padOrigin(v, A)
  r, c = (ceil(Int, (v[1]-size(A,1))/2)+1, ceil(Int, (v[2]-size(A,2))/2)+1)
  return(r, c)
end
#"""
#My default registration parameters:
#
#runAntsRegistration_default(dim, outname, f, m) = \`antsRegistration -v -d \$dim -o \$outname -r initialTransform\\[\$f, \$m, 1\\] -m MI\\[\$f, \$m, 1, 32, regular, 0.2\\] -t Translation\\[0.1\\] -c \\[100x100x100, 1e-8, 10\\] -s 4x2x1mm -f 8x4x1 -m MI\\[\$f, \$m, 1, 32, regular, 0.2\\] -t rigid\\[0.1\\] -c \\[100x100x100, 1e-8, 10\\] -s 4x2x1mm -f 8x4x1 -m MI\\[\$f, \$m, 1, 32, regular, 0.2\\] -t affine\\[0.1\\] -c \\[100x100x100, 1e-8, 10\\] -s 4x2x1mm -f 8x4x1\`
#
#"""
#runAntsRegistration_default(dim, outname, f, m) = `antsRegistration -v -d $dim -o $outname -r initialTransform\[$f, $m, 1\] -m MI\[$f, $m, 1, 32, regular, 0.2\] -t Translation\[0.1\] -c \[100x100x100, 1e-8, 10\] -s 4x2x1mm -f 8x4x1 -m MI\[$f, $m, 1, 32, regular, 0.2\] -t rigid\[0.1\] -c \[100x100x100, 1e-8, 10\] -s 4x2x1mm -f 8x4x1 -m MI\[$f, $m, 1, 32, regular, 0.2\] -t affine\[0.1\] -c \[100x100x100, 1e-8, 10\] -s 4x2x1mm -f 8x4x1`
#
#"""
#My default registration parameters:
#
#runAntsTransform_default(imgw_outname, f, m, tform1) = \`antsApplyTransforms -d 2 -i \$m -r \$f -o \$imgw_outname -n Linear -t \$tform1 -v 1\`
#runAntsTransform_default(imgw_outname, f, m, tform2, tform1) = \`antsApplyTransforms -d 2 -i \$m -r \$f -o \$imgw_outname -n Linear -t \$tform2 \$tform1 -v 1\`
#"""
#runAntsTransform_default(imgw_outname, f, m, tform1) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t $tform1 -v`
#runAntsTransform_default(imgw_outname, f, m, tform2, tform1) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t $tform2 -t $tform1 -v`
#runAntsTransform_inv_default(imgw_outname, f, m, tform1) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t \[$tform1, 1\] -v`
#runAntsTransform_inv_default(imgw_outname, f, m, inv_tform2, tform1) = `antsApplyTransforms -d 2 -i $m -r $f -o $imgw_outname -n Linear -t $inv_tform2 -t \[$tform1, 1\] -v`
#
#""" 
#Run Pairwise antsRegistration
#"""
#function runAntsRegistrationPairwise(dim, fixedfns, movingfns; tag = false, antsRegisterFunc = runAntsRegistration_default)
#	outnames = Vector{String}(undef, 0)
#  for i in eachindex(movingfns)
#    if tag == false
#      outname = splitext(movingfns[i])[1]*"_"
#		else
#			outname = tag[i]*"_"
#		end
#		push!(outnames, outname)
#	end
#	#run registration
#	for i in eachindex(movingfns)
#    run(antsRegisterFunc(dim, outnames[i], fixedfns[i], movingfns[i]))
#  end
#	return(outnames)
#end
#
#"""
#Run pairwise transformation. Non-linear warping has not been implemented. 
#"""
#function _runAntsTransformPairwise(fixedfns, movingfns; outfile_tag = false, tform_tag = false)
#  tformfns = Vector{String}(undef, 0)
#  syntformfns = Vector{String}(undef, 0)
#  imgw_outnames = Vector{String}(undef, 0)
#  for i in eachindex(movingfns)
#  	# Assign output image file name
#  	if outfile_tag == false
#  		outfn = splitext(movingfns[i])[1]*"_"
#  	else
#  		outfn = outfile_tag[i]*"_"
#  	end
#    imgw_outname = outfn*"warped.nrrd"
#		push!(imgw_outnames, imgw_outname)
#    # Assign input tform
#  	if tform_tag == false
#  		tform_fn = splitext(movingfns[i])[1]*"_"
#  	else
#  		tform_fn = tform_tag[i]*"_"
#  	end
#  	# assign input tform file name
#    tform = tform_fn*"0GenericAffine.mat"
#		syntform = tform_fn*"1Warp.nii.gz"
#		push!(tformfns, tform)
#		push!(syntformfns, syntform)
#  end
#	return(imgw_outnames, tformfns, syntformfns)
#end
#
#function runAntsTransformsPairwise(fixedfns, movingfns; outfile_tag = false, tform_tag = false, antsTransformFunc = runAntsTransform_default)
#  imgw_outnames, tformfns, syntformfns = _runAntsTransformPairwise(fixedfns, movingfns; outfile_tag = outfile_tag, tform_tag = tform_tag)
#  for i in eachindex(movingfns)
#      run(antsTransformFunc(imgw_outnames[i], fixedfns[i], movingfns[i], tformfns[i]))
#  end
#  return(imgw_outnames)
#end
#
#function runAntsTransformsPairwiseSyN(fixedfns, movingfns; outfile_tag = false, tform_tag = false, antsTransformFunc = runAntsTransform_syn)
#	imgw_outnames, tformfns, syntformfns = _runAntsTransformPairwise(fixedfns, movingfns; outfile_tag = outfile_tag, tform_tag = tform_tag)
#	for i in eachindex(movingfns)
#			run(antsTransformFunc(imgw_outnames[i], fixedfns[i], movingfns[i], syntformfns[i], tformfns[i]))
#	end
#	return(imgw_outnames)
#end
#
#"""
#1. apply the same 2d antsTransformations to each frame of a 3d image (channel image).
#2. save the output file `warpoutfn`
#Must use .nrrd format
#`tform2_fn` is a non-rigid transformation
#`tform1_fn` is a rigid/affine transformation
#"""
#function applyAntsTransforms(warpoutfn, fixedfn, movingfn, tform2_fn, tform1_fn, mv_pxspacing; antsTransformFunc)
#  img = load(movingfn)
#  nimgs = size(img, 3)
#  tmp = [];
#  for i in 1:nimgs
#    infn = string("/tmp/tmpin_", i, ".nrrd")  #input file
#    imga = setAxis(parent(img[:,:,i]), mv_pxspacing)
#    save(infn, imga) #temporary save
#    outfn = string("/tmp/tmpout_",i, ".nrrd") #output file
#    run(antsTransformFunc(outfn, fixedfn, infn, tform2_fn, tform1_fn))
#    push!(tmp, load(outfn))
#    rm(infn)
#    rm(outfn)
#  end
#  save(warpoutfn, cat(tmp..., dims = 3))
#end
#
#
#
#
