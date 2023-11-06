""" find an origin to put the image `A` in the center of PaddedView. v is a 2-element vector"""
function padOrigin(v, A)
  r, c = (ceil(Int, (v[1]-size(A,1))/2)+1, ceil(Int, (v[2]-size(A,2))/2)+1)
  return(r, c)
end

"""
Given a vector of images, this function generates images with the same size (x-y dimentions). If kwargs `h` and `w` is not given, the largest height and width will be chosen among all images.
"""
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

"""
`lbl_img_ordering` may be used with `pad_images` and `ImageView.imshow`. 
This function annotate the image number at the corner of each image.

paddedmovings = pad_images(imgs); #`imgs` is a vector of five images, whose size does not have to be the same.
guidict = imshow(vcat(paddedmovings...)); # `nrows` x `ncols` image array
lbl_img_ordering(guidict, paddedmovings[1], first_lbl, nrows, ncols); #paddedmovings[1] is used to get the size of each paddedimage.
"""
function lbl_img_ordering(guidict, paddedmoving, first_lbl, nrows, ncols; xoffset = 20, yoffset = 20, color = RGB(0,1,0), fontsize = 20, transpose_numbering = false)
  if transpose_numbering
    dim1, dim2 = 2,1
  else
    dim1, dim2 = 1,2
  end
  lbl_y = round.(Int, collect(range(1, size(paddedmoving, dim1)*(nrows-1), nrows)))
  lbl_x = round.(Int, collect(range(1, size(paddedmoving, dim2)*(ncols-1), ncols)))
  lbl = first_lbl
  if transpose_numbering
    for i in lbl_x, j in lbl_y
      idx = annotate!(guidict, AnnotationText(j+xoffset, i+yoffset, string(lbl) , color = color, fontsize = fontsize))
      lbl += 1
    end
  else
    for i in lbl_x, j in lbl_y
      idx = annotate!(guidict, AnnotationText(i+xoffset, j+yoffset, string(lbl) , color = color, fontsize = fontsize))
      lbl += 1
    end
  end
end


