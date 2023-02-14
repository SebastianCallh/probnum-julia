using LinearAlgebra
using BenchmarkTools

A = [4. 12. -16.; 12. 37. -43.; -16. -43. 98.]
b = [1., 2., 3.]

function chol(A, n)
    A′ = copy(A)
    L = diagm(ones(size(A, 1)))
    for i in 1:n
        Iᵢ = A′[:,i] / sqrt(A′[i,i])
        A′ .= A′ - Iᵢ*Iᵢ'
        L[:,i] = Iᵢ
    end
    LowerTriangular(L)
end

L = chol(A, 3)
@assert L*L' == A
@assert L == cholesky(A).L

function chol_inv(A, n)
    A′ = copy(A)
    C = zeros(size(A))
    L = diagm(ones(size(A, 1)))
    for i in 1:n
        sᵢ = let
            e = zeros(size(A, 1))
            e[i] = 1.
            e
        end
        dᵢ = (I - C*A)*sᵢ
        ηᵢ = sᵢ'A*dᵢ
        Iᵢ = A′[:,i] / sqrt(A′[i,i])
        C .= C + dᵢ*dᵢ' ./ ηᵢ
        A′ .= A′ - Iᵢ*Iᵢ'
        L[:,i] = Iᵢ
    end
    LowerTriangular(L), C
end

L, C = chol_inv(A, size(A, 1))
@assert inv(A) ≈ C

function gc_inv(A, b, x₀; rtol=1e-6, atol=1e-6, maxiters=length(b))
    x = copy(x₀)
    C = zeros(size(A))
    r = fill(Inf, length(b))
    i = 0
    while norm(r) > max(rtol*norm(b), atol)
        if i == maxiters
            println("Maximum number of iterations reached")
            return x, C
        end

        r = b - A*x
        sᵢ = r
        αᵢ = sᵢ'r
        dᵢ = (I - C*A)*sᵢ
        ηᵢ = sᵢ'A*dᵢ
        C .= C + dᵢ*dᵢ' ./ ηᵢ
        x .+= dᵢ * αᵢ/ηᵢ
    end
    x, C
end

x0 = randn(size(A, 1))
x, C = gc_inv(A, b, x0)
@assert x ≈ A\b
