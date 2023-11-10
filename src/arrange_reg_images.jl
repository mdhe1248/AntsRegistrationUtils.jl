#### save corrected images as tiff_lowres
struct ImageVar
  bg_channel::Int
  movingfn_midres::String
  moving_midres_savefn::String
  moving_lowres_savefn::String
  mv_pxspacing_midres::NTuple{2, Number}
  mv_pxspacing_lowres::NTuple{2, Number}
  slice_order::Int
  flipped::Bool
  imgvarfn::String
end 
ImageVar(bg_channel, movingfn_midres, moving_midres_savefn, moving_lowres_savefn, mv_pxspacing_midres, mv_pxspacing_lowres, slice_order, flipped) = ImageVar(bg_channel, movingfn_midres, moving_midres_savefn, moving_lowres_savefn, mv_pxspacing_midres, mv_pxspacing_lowres, slice_order, flipped, first(splitdir(moving_lowres_savefn))*"/imgvar_"*first(splitext(last(splitdir(moving_lowres_savefn))))[end-1:end]*".jld2")

function horizontal_flip(img::AbstractArray{T, 2}, flip::Bool) where T
  if flip
    img = img[:, end:-1:1]
  end
  return(img)
end

function horizontal_flip(img::AbstractArray{T, 3}, flip::Bool) where T
  if flip
    img = img[:, end:-1:1, :]
  end
  return(img)
end

function assign_imagevars(bg_channel, movingfns_midres, moving_midres_savefns, moving_lowres_savefns, mv_pxspacing_midres, mv_pxspacing_lowres, slice_orders, flips)
 # movingfns_midres = movingfns_midres[slice_orders]
  moving_midres_savefns = moving_midres_savefns[slice_orders]
  moving_lowres_savefns = moving_lowres_savefns[slice_orders]
  flips = flips[slice_orders]
  return [ImageVar(bg_channel, vars[1], vars[2], vars[3], mv_pxspacing_midres, mv_pxspacing_lowres, vars[4], vars[5]) for vars in zip(movingfns_midres, moving_midres_savefns, moving_lowres_savefns, slice_orders, flips)]
end

function set_flips(length_flips, flipidx)
  flips = falses(length_flips)
  flips[flipidx] .= true
  flips
end

function save_image_arranged(imgvar::ImageVar)
  movingfn_midres = imgvar.movingfn_midres
  moving_midres_savefn = imgvar.moving_midres_savefn
  moving_lowres_savefn = imgvar.moving_lowres_savefn
  mv_pxspacing_midres = imgvar.mv_pxspacing_midres
  mv_pxspacing_lowres = imgvar.mv_pxspacing_lowres
  flipped = imgvar.flipped
  moving = load(imgvar.movingfn_midres)
  moving = horizontal_flip(moving, flipped)
  if flipped
    isfile(moving_midres_savefn) ? rm(moving_midres_savefn) : save(moving_midres_savefn, moving) # For overwriting. Somehow, `save` does not overwrite symbolic link files.
  else
    tmpfn = last(splitdir(movingfn_midres)) # for relative path symbolic link
    run(`ln -sf $tmpfn $(moving_midres_savefn)`) #if there is no change, just make a symbolic link
  end
  moving_low = imresize(moving, ratio = (mv_pxspacing_midres./mv_pxspacing_lowres..., 1))
  save(moving_lowres_savefn, moving_low) #save low resolution image
end

function save_imagevars(var)
  jldsave(var.imgvarfn, imgvars = var)
end
save_imagevars(vars::AbstractVector) = [save_imagevars(var) for var in vars]


