module AntsRegistrationUtils

using AxisArrays, Unitful, Images, JLD2
const μm = u"μm"

export setAxis, applyAntsTransforms_01, runAntsRegistration_01, runAntsTransform_01, runAntsTransform_inv, padOrigin, pad_images, Regvars, assign_regvars, save_regvars, runAntsRegistrationSyN, runAntsRegistrationAffine, runAntsTransformSyN, runAntsTransformInvFixedSyN, runAntsTransformInvAttnSyN, applyAntsTransform, ImageVar, horizontal_flip, assign_imagevars, set_flips, save_image_arranged, save_imagevars
include("arrange_reg_images.jl")
include("setaxis.jl")
include("runANTs.jl")

end
