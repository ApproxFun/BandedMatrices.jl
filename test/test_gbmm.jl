# test gbmm! subpieces step by step and column by column
for n in (1,5,50), ν in (1,5,50), m in (1,5,50),
                Al in (0,1,2,30), Au in (0,1,2,30),
                Bl in (0,1,2,30), Bu in (0,1,2,30)
    A=brand(n,ν,Al,Au)
    B=brand(ν,m,Bl,Bu)
    α,β,T=0.123,0.456,Float64
    C=brand(Float64,n,m,A.l+B.l,A.u+B.u)
    a=pointer(A.data)
    b=pointer(B.data)
    c=pointer(C.data)
    sta=max(1,stride(A.data,2))
    stb=max(1,stride(B.data,2))
    stc=max(1,stride(C.data,2))

    sz=sizeof(T)

    mr=1:min(m,1+B.u)
    exC=(β*full(C)+α*full(A)*full(B))
    for j=mr
        BandedMatrices.A11_Btop_Ctop_gbmv!(α,β,
                                       n,ν,m,j,
                                       sz,
                                       a,A.l,A.u,sta,
                                       b,B.l,B.u,stb,
                                       c,C.l,C.u,stc)
   end
    @test C[:,mr] ≈ exC[:,mr]

    mr=1+B.u:min(1+C.u,ν+B.u,m)
    exC=(β*full(C)+α*full(A)*full(B))
    for j=mr
        BandedMatrices.Atop_Bmid_Ctop_gbmv!(α,β,
                                       n,ν,m,j,
                                       sz,
                                       a,A.l,A.u,sta,
                                       b,B.l,B.u,stb,
                                       c,C.l,C.u,stc)
   end
   if !isempty(mr)
       @test C[:,mr] ≈ exC[:,mr]
   end

   mr=1+C.u:min(m,ν+B.u,n+C.u)
   exC=(β*full(C)+α*full(A)*full(B))
   for j=mr
       BandedMatrices.Amid_Bmid_Cmid_gbmv!(α,β,
                                      n,ν,m,j,
                                      sz,
                                      a,A.l,A.u,sta,
                                      b,B.l,B.u,stb,
                                      c,C.l,C.u,stc)
  end
  if !isempty(mr)
      @test C[:,mr] ≈ exC[:,mr]
  end

  mr=ν+B.u+1:min(m,n+C.u)
  exC=(β*full(C)+α*full(A)*full(B))
  for j=mr
      BandedMatrices.Anon_Bnon_C_gbmv!(α,β,
                                     n,ν,m,j,
                                     sz,
                                     a,A.l,A.u,sta,
                                     b,B.l,B.u,stb,
                                     c,C.l,C.u,stc)
 end
 if !isempty(mr)
     @test C[:,mr] ≈ exC[:,mr]
 end
end


# test gbmm!


for n in (1,5,50), ν in (1,5,50), m in (1,5,50), Al in (0,1,2,30), Au in (0,1,2,30), Bl in (0,1,2,30), Bu in (0,1,2,30)
    A=brand(n,ν,Al,Au)
    B=brand(ν,m,Bl,Bu)
    α,β,T=0.123,0.456,Float64
    C=brand(Float64,n,m,A.l+B.l,A.u+B.u)

    exC=α*full(A)*full(B)+β*full(C)
    BandedMatrices.gbmm!('N','N', α,A,B,β,C)

    @test full(exC) ≈ full(C)
end
