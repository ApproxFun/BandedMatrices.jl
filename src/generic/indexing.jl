
# fallbacks for inbands_getindex and inbands_setindex!
@inline function inbands_getindex(x::AbstractArray, i::Integer, j::Integer)
    @inbounds r = getindex(x, i, j)
    r
end
@inline function inbands_setindex!(x::AbstractArray, v, i::Integer, j::Integer)
    @inbounds r = setindex!(x, v, i, j)
    r
end

inbands_getindex(x::Adjoint, i::Integer, j::Integer) =
    inbands_getindex(parent(x), j, i)'
inbands_getindex(x::Transpose, i::Integer, j::Integer) =
    transpose(inbands_getindex(parent(x), j, i))
inbands_setindex!(x::Adjoint, v, i::Integer, j::Integer) =
    inbands_setindex!(parent(x), v', j, i)
inbands_setindex!(x::Transpose, v, i::Integer, j::Integer) =
    inbands_setindex!(parent(x), transpose(v), j, i)

###
# Lazy getindex
# this uses a layout-materialize idiom to construct a matrix based
# on the memory layout
# BandedMatrix requires the columns to be Base.OneTo
###

sub_materialize(::AbstractBandedLayout, V, ::NTuple{2,Base.OneTo{Int}}) = BandedMatrix(V)
sub_materialize(::AbstractBandedLayout, V, ::Tuple{<:Any,Base.OneTo{Int}}) = BandedMatrix(V)
sub_materialize(::AbstractBandedLayout, V, ::Tuple{Base.OneTo{Int},<:Any}) = BandedMatrix(V')'

@inline getindex(A::AbstractMatrix, b::Band) = layout_getindex(A, b)
@inline getindex(A::AbstractMatrix, kr::BandRangeType, j::Integer) = layout_getindex(A, kr, j)
@inline getindex(A::AbstractMatrix, k::Integer, jr::BandRangeType) = layout_getindex(A, k, jr)
