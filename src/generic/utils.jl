# BLAS/linear algebra overrides
@inline dot(x...) = Compat.LinearAlgebra.dot(x...)
@inline dot(M::Int,a::Ptr{T},incx::Int,b::Ptr{T},incy::Int) where {T<:Union{Float64,Float32}} =
    BLAS.dot(M,a,incx,b,incy)
@inline dot(M::Int,a::Ptr{T},incx::Int,b::Ptr{T},incy::Int) where {T<:Union{ComplexF64,ComplexF32}} =
    BLAS.dotc(M,a,incx,b,incy)

dotu(f::StridedVector{T},g::StridedVector{T}) where {T<:Union{ComplexF32,ComplexF64}} =
    BLAS.dotu(f,g)
dotu(f::AbstractVector{Complex{Float64}},g::AbstractVector{N}) where {N<:Real} = dot(conj(f),g)
dotu(f::AbstractVector{N},g::AbstractVector{T}) where {N<:Real,T<:Number} = dot(f,g)


normalize!(w::AbstractVector) = rmul!(w,inv(norm(w)))
normalize!(w::Vector{T}) where {T<:BlasFloat} = normalize!(length(w),w)
normalize!(n,w::Union{Vector{T},Ptr{T}}) where {T<:Union{Float64,Float32}} =
    BLAS.scal!(n,inv(BLAS.nrm2(n,w,1)),w,1)
normalize!(n,w::Union{Vector{T},Ptr{T}}) where {T<:Union{ComplexF64,ComplexF32}} =
    BLAS.scal!(n,T(inv(BLAS.nrm2(n,w,1))),w,1)


# check dimensions of inputs
checkdimensions(sizedest::Tuple{Int, Vararg{Int}}, sizesrc::Tuple{Int, Vararg{Int}}) =
    (sizedest == sizesrc ||
        throw(DimensionMismatch("tried to assign $(sizesrc) sized " *
                                "array to $(sizedest) destination")) )

checkdimensions(dest::AbstractVector, src::AbstractVector) =
    checkdimensions(size(dest), size(src))

checkdimensions(ldest::Int, src::AbstractVector) =
    checkdimensions((ldest, ), size(src))

checkdimensions(kr::AbstractRange, jr::AbstractRange, src::AbstractMatrix) =
    checkdimensions((length(kr), length(jr)), size(src))


# helper functions in matrix multiplication routines
@inline _size(::Val{'N'}, A::AbstractMatrix, k::Int) = size(A, k)
@inline _size(::Val, A::AbstractMatrix, k::Int) = size(A, 3-k)
@inline _size(t::Val{'N'}, A::AbstractMatrix) = size(A)
@inline _size(t::Val, A::AbstractMatrix) = (size(A, 2), size(A, 1))
@inline _bandwidth(t::Val{'N'}, A::AbstractMatrix, k::Int) = bandwidth(A, k)
@inline _bandwidth(t::Val, A::AbstractMatrix, k::Int) = bandwidth(A, 3-k)
@inline _bandwidths(t::Val{'N'}, A::AbstractMatrix) = bandwidths(A)
@inline _bandwidths(t::Val, A::AbstractMatrix) = (bandwidth(A, 2), bandwidth(A, 1))
@inline _view(t::Val{'N'}, A::AbstractMatrix, I, J) = view(A, I, J)
@inline _view(t::Val, A::AbstractMatrix, I, J) = view(A, J, I)

# return the bandwidths of A*B
function prodbandwidths(tA::Val, tB::Val, A::AbstractMatrix, B::AbstractMatrix)
    Al, Au = _bandwidths(tA, A)
    Bl, Bu = _bandwidths(tB, B)
    Al + Bl, Au + Bu
end
prodbandwidths(A::AbstractMatrix, B::AbstractMatrix) = prodbandwidths(Val{'N'}(), Val{'N'}(), A, B)

function banded_similar(tA::Val, tB::Val, A::AbstractMatrix, B::AbstractMatrix, T::DataType)
    BandedMatrix{T}(undef, _size(tA, A, 1), _size(tB, B, 2), prodbandwidths(tA, tB, A, B)...)
end

# helper functions in matrix addition routines
function sumbandwidths(A::AbstractMatrix, B::AbstractMatrix)
    max(bandwidth(A, 1), bandwidth(B, 1)), max(bandwidth(A, 2), bandwidth(B, 2))
end
