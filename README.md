# LASArrays [![Build Status](https://github.com/crghilardi/LASArrays.jl/workflows/CI/badge.svg)](https://github.com/crghilardi/LASArrays.jl/actions)

## LASArrays

`LASArrays.jl` is a package for interacting with `.las` LiDAR files.
While much less fully functional than [LasIO.jl](https://github.com/visr/LasIO.jl), this package attempts a different approach.

```julia
] add https://github.com/Crghilardi/LASArrays.jl
```

## Basic Idea

The package defines a function `load("points.las", s::Symbol)` that allows users to choose which individual attributes to load that correspond to a field in the [ASPRS format](https://www.asprs.org/a/society/committees/standards/LAS_1_4_r13.pdf) rather than object with all the information. All fields return as regular Julia `Array`s

Coordinates values are also returned as `Float`s in a [mappedarray](https://github.com/JuliaArrays/MappedArrays.jl) with the offset and scale read from the header information. See [this discussion](https://github.com/visr/LasIO.jl/issues/34) for inspiration.


## Examples

```julia

using FileIO, LASArrays

#:coordinates is an additional special symbol that loads the point x,y,z values

julia> load("points.las", :coordinates)
497536-element mappedarray(AffineMap([0.01 0.0 0.0; 0.0 0.01 0.0; 0.0 0.0 0.01], [-0.0, -0.0, -0.0]), ::Array{Any,1}) with eltype Any:
 [1.44013394e6, 375000.23, 846.66]
 [1.44012426e6, 375000.49, 846.5500000000001]
 [1.44011447e6, 375000.77, 846.44]
 [1.44010469e6, 375001.04, 846.32]
 [1.4400948900000001e6, 375001.35000000003, 846.21]
 ⋮
 [1.44495771e6, 375001.31, 863.7]
 [1.4449471300000001e6, 375000.89, 863.79]
 [1.4449366400000001e6, 375000.48, 863.91]


#otherwise, one can just use field names
load("points.las", :classification)
6227397-element Array{Any,1}:
 0xdd
 0xd7
 0x63
 0x03
 0xc2
    ⋮
 0x78


julia> load("./test/points.las", :intensity)
6019818-element Array{Any,1}:
 0xd7dd
 0x0363
 0xf4ac
 0x1e1a
 0x9d54
      ⋮
 0x04ea
 0x5437
 0x78c8
 0x4102

#look at what fields are called for a given point format
julia> fieldnames(LASArrays.PointDataRecordFormat0)
(:x, :y, :z, :intensity, :flag, :classification, :scanangle, :userdata, :ptsrcid)

```

## Cool stuff

```julia
using FileIO, LASArrays
using NearestNeighbors

pts = load("points.las", :coordinates)

kdtree = KDTree(pts; leafsize = 10)

#five closest points to a randomly chosen point
idxs, dists = knn(kdtree, SVector{3}[1.44010469e6, 375001.04, 846.32], 5, true)


... more to come?
```

## To Do
1. Support for returning multiple attributes at a time `load("file.las", [:classification, :gpstime, :intensity]` ?
2. Add a `:color` symbol to use [ColorTypes](https://github.com/JuliaGraphics/ColorTypes.jl) for `:red`, `:green`, `:blue` fields
3. Support for padding out missing values, currently can return different Array lengths for different attributes?
4. Add functions for better getting at sub-byte fields (return number, etc)
5. Improve variable length record handling
6. General performance and profiling
