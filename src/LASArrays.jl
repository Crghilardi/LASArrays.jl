module LASArrays

using FileIO, MappedArrays, StaticArrays, LinearAlgebra, CoordinateTransformations

abstract type AbstractPointDataRecordFormat end

struct PointDataRecordFormat0 <: AbstractPointDataRecordFormat
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag::UInt8
    classification::UInt8
    scanangle::Int8
    userdata::UInt8
    ptsrcid::UInt16
end

struct PointDataRecordFormat1 <: AbstractPointDataRecordFormat
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag::UInt8
    classification::UInt8
    scanangle::Int8
    userdata::UInt8
    ptsrcid::UInt16
    gpstime::Float64
end

struct PointDataRecordFormat2 <: AbstractPointDataRecordFormat
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag::UInt8
    classification::UInt8
    scanangle::Int8
    userdata::UInt8
    ptsrcid::UInt16
    red::UInt16
    green::UInt16
    blue::UInt16
end

struct PointDataRecordFormat3 <: AbstractPointDataRecordFormat
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag::UInt8
    classification::UInt8
    scanangle::Int8
    userdata::UInt8
    ptsrcid::UInt16
    gpstime::Float64
    red::UInt16
    green::UInt16
    blue::UInt16
end

#header offsets - number of bytes from beginning of file for a given header field including magic bytes(LASF)
const POINTDATA_OFFSET_SEEK = 96
const N_VLR_SEEK = 100
const FORMAT_SEEK = 104
const N_RECORDS_SEEK = 105
const X_SCALE_SEEK = 131
#probably don't need these since they are a contiguous block, but maybe useful later?
#const Y_SCALE_SEEK = 139
#const Z_SCALE_SEEK = 147
#const X_OFFSET_SEEK = 155
#const Y_OFFSET_SEEK = 163
#const Z_OFFSET_SEEK = 171

#point data record offsets - number of bytes from beginning of file to start of point records
pointdata_start(io::Stream{format"LAS"}) = read(seek(io, POINTDATA_OFFSET_SEEK), UInt32)

n_records(io::Stream{format"LAS"}) = read(seek(io, N_RECORDS_SEEK), UInt32)

#get indices of all fields that are not :x , :y, or :z
notcoord(ptype::Type{T}) where T <: AbstractPointDataRecordFormat = findall(Ref([:x, :y, :z]) .∌ fieldnames(ptype))

function calculate_offset(ptype::Type{T}, s::Symbol) where T <: AbstractPointDataRecordFormat
    if s == :coordinates
        offset = sum(sizeof.(ptype.types)[notcoord(ptype)])
    else
        offset = sum(sizeof.(ptype.types)[findall(!isequal(s), ptype.types)])
    end
    return offset
end

function get_transform(io::Stream{format"LAS"})
    seek(io, X_SCALE_SEEK)

    transform = AffineMap(Diagonal(SA_F64[read(io, Float64) 0 0; 0 read(io, Float64) 0; 0 0 read(io, Float64)]), SA_F64[read(io, Float64), read(io, Float64), read(io, Float64)])

    return transform
end

function pointformat(io::Stream{format"LAS"})
    id = read(seek(io, FORMAT_SEEK), UInt8)
    if id == 0x00
        return PointDataRecordFormat0
    elseif id == 0x01
        return PointDataRecordFormat1
    elseif id == 0x02
        return PointDataRecordFormat2
    elseif id == 0x03
        return PointDataRecordFormat3
    else
        error("unsupported point format $(Int(id))")
    end
end









function load(f::File{format"LAS"}, field::Symbol)
    open(f) do s
        load(s, field)
    end
end

function load(s::Stream{format"LAS"}, field::Symbol)
    format = pointformat(s)
    records = n_records(s)
    point_seek = pointdata_start(s)
    if !(field in(fieldnames(format))) && field != :coordinates
        error("Field not part of LAS Point Data Records Format $format")
    elseif field == :coordinates
        #coordinates = Array{Array{Int32}}(undef, records)
        coordinates = []
        transform = get_transform(s)
        seek(s, point_seek)
        while !eof(s)
            push!(coordinates, [read(s, Int32), read(s, Int32), read(s, Int32)])
            skip(s, calculate_offset(format, :coordinates))
        end
        coordinates_mapped = mappedarray(transform, coordinates)
        return coordinates_mapped
    else
        values = []
        offset = calculate_offset(format, field)
        width = format.types[findfirst(isequal(field), fieldnames(format))]
        seek(s, point_seek)
        while !eof(s)
            push!(values, read(s, width))
            skip(s, calculate_offset(format, field))
        end
        return values
    end
end

function __init__()
     add_format(format"LAS", "LASF", ".las", [:LASArrays])
end




# function Base.read(f::String)
#     io = open(f)
#     read(io, UInt32) #skiplasf - sizeof(UInt32) = 4
#     header = read(io, LasHeader)

#     n = header.records_count
#     #header
#     points = []
#     while !eof(io)
#     push!(points,[read(io, Int32), read(io, Int32), read(io, Int32)])
#     skip(io, 8)
#     end
# points
# end

export 
pointformat,
n_records



end #end module
