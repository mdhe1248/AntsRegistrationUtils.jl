""" 
Assign axes
"""
setAxis(img::AbstractArray{T, 2}, pixelspacing) where T = AxisArray(parent(img), Axis{:P}(0unit(pixelspacing[1]):pixelspacing[1]:pixelspacing[1]*(size(img,1)-1)), Axis{:R}(0unit(pixelspacing[2]):pixelspacing[2]:pixelspacing[2]*(size(img,2)-1))) 

setAxis(img::AbstractArray{T, 3}, pixelspacing) where T = AxisArray(parent(img), Axis{:P}(0unit(pixelspacing[1]):pixelspacing[1]:pixelspacing[1]*(size(img,1)-1)), Axis{:R}(0unit(pixelspacing[2]):pixelspacing[2]:pixelspacing[2]*(size(img,2)-1)), Axis{:S}(0unit(pixelspacing[3]):pixelspacing[3]:pixelspacing[3]*(size(img,3)-1))) #Assign axes

