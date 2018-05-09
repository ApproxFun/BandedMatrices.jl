using BandedMatrices, Compat.Test

## Banded Matrix of Banded Matrix

BandedMatrixWithZero = Union{BandedMatrix{Float64}, UniformScaling}
# need to define the concept of zero
Base.zero(::Type{BandedMatrixWithZero}) = 0*I

@testset "misc tests" begin
   A = BandedMatrix{BandedMatrixWithZero}(undef, 1, 2, 0, 1)
   A[1,1] = BandedMatrix(Eye(1),(0,1))
   A[1,2] = BandedMatrix(Zeros(1,2),(0,1))
   A[1,2][1,1] = -1/3
   A[1,2][1,2] = 1/3
   B = BandedMatrix{BandedMatrixWithZero}(undef, 2, 1, 1, 1)
   B[1,1] = 0.2BandedMatrix(Eye(1),(0,1))
   B[2,1] = BandedMatrix(Zeros(2,1), (1,0))
   B[2,1][1,1] = -2/30
   B[2,1][2,1] = 1/3

   @test (A*B)[1,1][1,1] ≈ 1/3



   # Test dense overrides
   A = rand(10,11)
   @test bandwidths(A) == (9,10)
   A = rand(10)
   @test bandwidths(A) == (9,0)
   @test bandwidths(A') == (0,9)

   # test trivial convert routines

   A = brand(3,4,1,2)
   @test isa(BandedMatrix{Float64}(A), BandedMatrix{Float64})
   @test isa(AbstractMatrix{Float64}(A), BandedMatrix{Float64})
   @test isa(AbstractArray{Float64}(A), BandedMatrix{Float64})
   @test isa(BandedMatrix(A), BandedMatrix{Float64})
   @test isa(AbstractMatrix(A), BandedMatrix{Float64})
   @test isa(AbstractArray(A), BandedMatrix{Float64})
   @test isa(BandedMatrix{ComplexF16}(A), BandedMatrix{ComplexF16})
   @test isa(AbstractMatrix{ComplexF16}(A), BandedMatrix{ComplexF16})
   @test isa(AbstractArray{ComplexF16}(A), BandedMatrix{ComplexF16})

   # Test show function
   @test occursin("10×10 BandedMatrices.BandedMatrix{Float64,Array{Float64,2}}",
      sprint() do io
          show(io, MIME"text/plain"(), brand(10, 10, 3, 3))
      end)

   if VERSION < v"0.7-"
      needle = "1.0  0.0     \n 0.0  1.0  0.0\n      0.0  1.0"
   else
      needle = "1.0  0.0  0.0\n 0.0  1.0  0.0\n 0.0  0.0  1.0"
   end
   @test occursin(needle, sprint() do io
         show(io, MIME"text/plain"(), BandedMatrix(Eye(3),(1,1)))
      end)

   # Issue #27
   A=brand(1,10,0,9)
   B=brand(10,10,255,255)
   @test Matrix(A*B)  ≈ Matrix(A)*Matrix(B)
end
