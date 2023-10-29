module AntsRegistrationUtils

using AxisArrays, Unitful, Images, BrainAnnotationMapping
const μm = u"μm"

export setAxis, applyAntsTransforms_01, runAntsRegistration_01, runAntsTransform_01, runAntsTransform_inv, padOrigin, Regvars, assign_regvars, save_regvars, runAntsRegistrationSyN, runAntsRegistrationAffine, runAntsTransformSyN, runAntsTransformInvFixedSyN, runAntsTransformInvAttnSyN, overlay_boundary, applyAntsTransform
include("setaxis.jl")
include("runANTs.jl")

end
