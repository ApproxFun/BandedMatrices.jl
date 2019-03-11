using BandedMatrices, LinearAlgebra, Test

@testset "QR tests" begin
    for T in (Float64,ComplexF64,Float32,ComplexF32)
        A=brand(T,10,10,3,2)
        Q,R=qr(A)
        @test Matrix(Q)*Matrix(R) ≈ A
        b=rand(T,10)
        @test mul!(similar(b),Q,mul!(similar(b),Q',b)) ≈ b
        for j=1:size(A,2)
            @test Q' * A[:,j] ≈ R[:,j]
        end
        A=brand(T,14,10,3,2)

        Q,R=qr(A)
        @test Matrix(Q)*Matrix(R) ≈ A

        for k=1:size(A,1),j=1:size(A,2)
            @test Q[k,j] ≈ Matrix(Q)[k,j]
        end

        A=brand(T,10,14,3,2)
        Q,R=qr(A)
        @test Matrix(Q)*Matrix(R) ≈ A

        for k=1:size(Q,1),j=1:size(Q,2)
            @test Q[k,j] ≈ Matrix(Q)[k,j]
        end

        A=brand(T,100,100,3,4)
        @test qr(A).factors ≈ LinearAlgebra.qrfactUnblocked!(Matrix(A)).factors
        @test qr(A).τ ≈ LinearAlgebra.qrfactUnblocked!(Matrix(A)).τ
        b=rand(T,100)
        @test qr(A)\b ≈ Matrix(A)\b
        b=rand(T,100,2)
        @test qr(A)\b ≈ Matrix(A)\b
        @test_throws DimensionMismatch qr(A) \ randn(3)
        @test_throws DimensionMismatch qr(A).Q'randn(3)

        A=brand(T,102,100,3,4)
        @test qr(A).factors ≈ LinearAlgebra.qrfactUnblocked!(Matrix(A)).factors
        @test qr(A).τ ≈ LinearAlgebra.qrfactUnblocked!(Matrix(A)).τ
        b=rand(T,102)
        @test qr(A)\b ≈ Matrix(A)\b
        b=rand(T,102,2)
        @test qr(A)\b ≈ Matrix(A)\b
        @test_throws DimensionMismatch qr(A) \ randn(3)
        @test_throws DimensionMismatch qr(A).Q'randn(3)

        A=brand(T,100,102,3,4)
        @test qr(A).factors ≈ LinearAlgebra.qrfactUnblocked!(Matrix(A)).factors
        @test qr(A).τ ≈ LinearAlgebra.qrfactUnblocked!(Matrix(A)).τ
        b=rand(T,100)
        @test_broken qr(A)\b ≈ Matrix(A)\b

        A = Tridiagonal(randn(T,99), randn(T,100), randn(T,99))
        @test qr(A).factors ≈ LinearAlgebra.qrfactUnblocked!(Matrix(A)).factors
        @test qr(A).τ ≈ LinearAlgebra.qrfactUnblocked!(Matrix(A)).τ
        b=rand(T,100)
        @test qr(A)\b ≈ Matrix(A)\b
        b=rand(T,100,2)
        @test qr(A)\b ≈ Matrix(A)\b
        @test_throws DimensionMismatch qr(A) \ randn(3)
        @test_throws DimensionMismatch qr(A).Q'randn(3)
    end

    @testset "Mixed types" begin
        A=brand(10,10,3,2)
        b=rand(ComplexF64,10)
        Q,R=qr(A)
        @test R\(Q'*b) ≈ qr(A)\b ≈ Matrix(A)\b


        A=brand(ComplexF64,10,10,3,2)
        b=rand(10)
        Q,R=qr(A)
        @test R\(Q'*b) ≈ qr(A)\b ≈ Matrix(A)\b
    end
end
