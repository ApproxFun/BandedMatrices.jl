export sbrand, sbeye, sbzeros

#
# Represent a symmetric banded matrix
# [ a_11 a_12 a_13
#   a_12 a_22 a_23 a_24
#   a_13 a_23 a_33 a_34
#        a_24 a_34 a_44  ]
# ordering the data like  (columns first)
#       [ *      *      a_13   a_24
#         *      a_12   a_23   a_34
#         a_11   a_22   a_33   a_44 ]
###
function _SymBandedMatrix end

mutable struct SymBandedMatrix{T} <: AbstractBandedMatrix{T}
    data::Matrix{T}  # k+1 x n (# of columns)
    k::Int # bandwidth ≥ 0
    global function _SymBandedMatrix(data::Matrix{T}, k) where {T}
        if size(data,1) != k+1
            error("Data matrix must have number rows equal to number of superdiagonals")
        else
            new{T}(data,k)
        end
    end
end


MemoryLayout(::SymBandedMatrix) = BlasSymBanded()


"""
    SymBandedMatrix(T, n, k)

returns an unitialized `n`×`n` symmetric banded matrix of type `T` with bandwidths `(-k,k)`.
"""
SymBandedMatrix{T}(::UndefInitializer, n::Integer, k::Integer) where {T<:BlasFloat} =
    _SymBandedMatrix(Matrix{T}(undef, k+1, n), k)
# Use zeros to avoid unallocated entries for bigfloat
SymBandedMatrix{T}(::UndefInitializer, n::Integer, k::Integer) where {T<:Number} =
    _SymBandedMatrix(zeros(T, k+1, n), k)
SymBandedMatrix{T}(::UndefInitializer, n::Integer, k::Integer) where {T} =
    _SymBandedMatrix(Matrix{T}(undef, k+1, n), k)

for MAT in (:SymBandedMatrix, :AbstractBandedMatrix, :AbstractMatrix, :AbstractArray)
    @eval Base.convert(::Type{$MAT{V}}, M::SymBandedMatrix) where {V} =
        SymBandedMatrix{V}(undef, convert(Matrix{V}, M.data), M.k)
end

Base.copy(B::SymBandedMatrix{T}) where T = _SymBandedMatrix(copy(B.data),B.k)

Base.promote_rule(::Type{SymBandedMatrix{T}},::Type{SymBandedMatrix{V}}) where {T,V} =
    SymBandedMatrix{promote_type(T,V)}



for (op,bop) in ((:(Base.rand),:sbrand),)
    @eval begin
        $bop(::Type{T}, n::Integer, a::Integer) where {T} = _SymBandedMatrix($op(T,a+1,n),a)
        $bop(n::Integer, a::Integer) = $bop(Float64,n,a)

        $bop(B::AbstractMatrix) = $bop(eltype(B), size(B,1), bandwidth(B,2))
    end
end

#####
# Convert abstract matrix
#####
# TODO: uncomment: this is commented out because of

# function BandedMatrix{T}(A::AbstractMatrix, a::Int) where T
#     (n,m) = size(A)
#     @boundscheck n == m || throw(BoundsError())
#     ret = SymBandedMatrix{T}(undef, n, a)
#     @inbounds for j = 1:m, k = max(1,j-u):min(n,j+l)
#         syminbands_setindex!(ret, A[k,j], k, j)
#     end
#     ret
# end

function SymBandedMatrix{V}(Z::Ones{T,2}, a::Int) where {T,V}
    n,m = size(Z)
    @boundscheck n == m || throw(BoundsError())
    _SymBandedMatrix(ones(V, a+1, n),a)
end

function SymBandedMatrix{V}(Z::Zeros{T,2}, a::Int) where {T,V}
    n,m = size(Z)
    @boundscheck n == m || throw(BoundsError())
    _SymBandedMatrix(zeros(V,a+1,n),a)
end

SymBandedMatrix(Z::AbstractFill{T,2}, a::Int) where T = SymBandedMatrix{T}(Z, a)


function SymBandedMatrix{T}(E::Eye, a::Int) where T
    n,m = size(E)
    @boundscheck n == m || throw(BoundsError())
    ret = SymBandedMatrix(Zeros{T}(E), a)
    ret[band(0)] = one(T)
    ret
end

SymBandedMatrix(Z::Eye{T}, a::Int) where T = SymBandedMatrix{T}(Z, a)
SymBandedMatrix(Z::Eye) = SymBandedMatrix(Z, 0)


"""
    sbrand(T,n,k)

Creates an `n×n` symmetric banded matrix  with random numbers in the bandwidth of type `T` with bandwidths `(k,k)`
"""
sbrand



Base.similar(B::SymBandedMatrix) =
    SymBandedMatrix(eltype(B),size(B,1),bandwidth(B,1))


## Abstract Array Interface

size(A::SymBandedMatrix, k) = k <= 0 ? error("dimension out of range") :
                              k == 1 ? size(A.data, 2) :
                              k == 2 ? size(A.data, 2) : 1
function size(A::SymBandedMatrix)
    n = size(A.data, 2)
    n,n
end

bandwidth(A::SymBandedMatrix, k::Integer) = A.k

Base.IndexStyle(::Type{SymBandedMatrix{T}}) where {T} = IndexCartesian()


@inline inbands_getindex(A::SymBandedMatrix, k::Integer, j::Integer) =
    A.data[A.k - abs(k-j) + 1, max(k,j)]


# banded get index, used for banded matrices with other data types
@inline function symbanded_getindex(data::AbstractMatrix, l::Integer, u::Integer, k::Integer, j::Integer)
    if -l ≤ j-k ≤ u
        inbands_getindex(data, u, k, j)
    else
        zero(eltype(data))
    end
end

# scalar - integer - integer
@inline function getindex(A::SymBandedMatrix, k::Integer, j::Integer)
    @boundscheck  checkbounds(A, k, j)
    if -A.k ≤ j-k ≤ A.k
        inbands_getindex(A, k, j)
    else
        zero(eltype(A))
    end
end


# scalar - colon - colon
@inline getindex(A::SymBandedMatrix, kr::Colon, jr::Colon) = copy(A)

# ~ indexing along a band

# scalar - band - colon
@inline function getindex(A::SymBandedMatrix{T}, b::Band) where {T}
    @boundscheck checkband(A, b)
    vec(A.data[A.k - abs(b.i) + 1, b.i+1:end])
end

@inline function view(A::SymBandedMatrix{T}, b::Band) where {T}
    @boundscheck checkband(A, b)
    view(A.data,A.k - abs(b.i) + 1, b.i+1:size(A.data,2))
end



# ~~ setindex! ~~

# ~ Special setindex methods ~

# slow fall back method
@inline syminbands_setindex!(A::SymBandedMatrix, v, k::Integer, j::Integer) =
    syminbands_setindex!(A.data, A.k, v, k, j)

# fast method used below
@inline function syminbands_setindex!(data::AbstractMatrix{T}, u::Integer, v, k::Integer, j::Integer) where {T}
    @inbounds data[u - abs(k-j) + 1, max(k,j)] = convert(T, v)::T
    v
end

@inline function symbanded_setindex!(data::AbstractMatrix, u::Int, v, k::Integer, j::Integer)
    if -u ≤ j-k ≤ u
        syminbands_setindex!(data, u, v, k, j)
    elseif v ≠ 0  # allow setting outside bands to zero
        throw(BandError(SymBandedMatrix(data,u),j-k))
    else # v == 0
        v
    end
end

# scalar - colon - colon
function setindex!(A::SymBandedMatrix{T}, v, ::Colon, ::Colon) where {T}
    if v == zero(T)
        @inbounds A.data[:] = convert(T, v)::T
    else
        throw(BandError(A, A.k+1))
    end
end

function Base.convert(::Type{Matrix}, A::SymBandedMatrix)
    ret=zeros(eltype(A),size(A,1),size(A,2))
    for j = 1:size(ret,2), k = colrange(ret,j)
        @inbounds ret[k,j] = A[k,j]
    end
    ret
end



# algebra
function +(A::SymBandedMatrix{T}, B::SymBandedMatrix{V}) where {T,V}
    if size(A) != size(B)
        throw(DimensionMismatch("+"))
    end
    n,m=size(A)

    ret = sbzeros(promote_type(T,V),n,max(A.k,B.k))
    axpy!(1.,A,ret)
    axpy!(1.,B,ret)

    ret
end

function -(A::SymBandedMatrix{T}, B::SymBandedMatrix{V}) where {T,V}
    if size(A) != size(B)
        throw(DimensionMismatch("+"))
    end
    n,m=size(A)

    ret = sbzeros(promote_type(T,V),n,max(A.k,B.k))
    axpy!(1.,A,ret)
    axpy!(-1.,B,ret)

    ret
end


function *(A::SymBandedMatrix{T},B::SymBandedMatrix{V}) where {T<:Number,V<:Number}
    if size(A,2) != size(B,1)
        throw(DimensionMismatch("*"))
    end
    Ak = bandwidth(A,2)
    Bk = bandwidth(B,2)
    n = size(A,1)
    Y = BandedMatrix(promote_type(T,V),n,Ak+Bk)
    mul!(Y,A,B)
end

function *(A::SymBandedMatrix{T},B::AbstractMatrix{V}) where {T<:Number,V<:Number}
    if size(A,2)!=size(B,1)
        throw(DimensionMismatch("*"))
    end
    n,m=size(A,1),size(B,2)

    mul!(Array(promote_type(T,V),n,m),A,B)
end

*(A::AbstractMatrix{T},B::SymBandedMatrix{V}) where {T<:Number,V<:Number} =
    A*Array(B)

*(A::SymBandedMatrix{T},b::AbstractVector{T}) where {T<:BlasFloat} =
    mul!(Vector{T}(undef,size(A,1)),A,b)

function *(A::SymBandedMatrix{T},b::AbstractVector{T}) where {T}
    ret = zeros(T,size(A,1))
    for j = 1:size(A,2), k = colrange(A,j)
        @inbounds ret[k]+=A[k,j]*b[j]
    end
    ret
end


function *(A::SymBandedMatrix{TT},b::AbstractVector) where {TT}
    T=promote_type(eltype(A),eltype(b))
    convert(BandedMatrix{T},A)*convert(AbstractVector{T},b)
end

transpose(B::SymBandedMatrix) = copy(B)

adjoint(B::SymBandedMatrix{T}) where {T<:Real} = copy(B)



diag(A::SymBandedMatrix{T}) where {T} = vec(A.data[A.k+1,:])


## eigvals routine


function tridiagonalize!(A::SymBandedMatrix{T}) where {T}
    n=size(A, 1)
    d = Vector{T}(undef,n)
    e = Vector{T}(undef,n-1)
    q = Vector{T}(undef,0)
    work = Vector{T}(undef,n)

    sbtrd!('N','U',
                size(A,1),A.k,pointer(A),leadingdimension(A),
                pointer(d),pointer(e),pointer(q), n, pointer(work))

    SymTridiagonal(d,e)
end


tridiagonalize(A::SymBandedMatrix) = tridiagonalize!(copy(A))

eigvals!(A::SymBandedMatrix) = eigvals!(tridiagonalize!(A))
eigvals(A::SymBandedMatrix) = eigvals!(copy(A))

function eigvals!(A::SymBandedMatrix{T}, B::SymBandedMatrix{T}) where {T}
    n = size(A, 1)
    @assert n == size(B, 1)
    # compute split-Cholesky factorization of B.
    kb = bandwidth(B, 2)
    ldb = leadingdimension(B)
    pbstf!('U', n, kb, pointer(B), ldb)
    # convert to a regular symmetric eigenvalue problem.
    ka = bandwidth(A, 2)
    lda = leadingdimension(A)
    X = Array{T}(undef,0,0)
    work = Vector{T}(undef,2n)
    sbgst!('N', 'U', n, ka, kb, pointer(A), lda, pointer(B), ldb,
           pointer(X), max(1, n), pointer(work))
    # compute eigenvalues of symmetric eigenvalue problem.
    eigvals!(A)
end

eigvals(A::SymBandedMatrix, B::SymBandedMatrix) = eigvals!(copy(A), copy(B))


## These routines give access to the necessary information to call BLAS

@inline leadingdimension(B::SymBandedMatrix) = stride(B.data,2)
@inline Base.pointer(B::SymBandedMatrix) = pointer(B.data)
