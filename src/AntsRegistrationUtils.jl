module AntsRegistrationUtils

using AxisArrays, Unitful, Images, JLD2, ImageView
const μm = u"μm"

export setAxis, applyAntsTransforms_01, runAntsRegistration_01, runAntsTransform_01, runAntsTransform_inv, padOrigin, pad_images, lbl_img_ordering, Regvars, assign_regvars, save_regvars, runAntsRegistrationSyN, runAntsRegistrationAffine, runAntsTransformSyN, runAntsTransformInvFixedSyN, runAntsTransformInvAttnSyN, applyAntsTransform, ImageVar, horizontal_flip, assign_imagevars, set_flips, save_image_arranged, save_imagevars
include("arrange_reg_images.jl")
include("setaxis.jl")
include("runANTs.jl")
include("pad_images.jl")

end
