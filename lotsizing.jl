using JuMP
using HiGHS

const MATRÍCULA = "2020041973"

function read_horizon(file::IOStream, size::Int64)
    cost::Vector{Float64} = zeros(size)
    demand::Vector{Float64} = zeros(size)
    storage::Vector{Float64} = zeros(size)
    penalty::Vector{Float64} = zeros(size)
    for line in eachline(file)
        data = split(line, "\t")
        if data[1] == "c"
            cost[parse(Int64, data[2])] = parse(Float64, data[3])
        elseif data[1] == "d"
            demand[parse(Int64, data[2])] = parse(Float64, data[3])
        elseif data[1] == "s"
            storage[parse(Int64, data[2])] = parse(Float64, data[3])
        elseif data[1] == "p"
            penalty[parse(Int64, data[2])] = parse(Float64, data[3])
        end
    end
    return demand, cost, storage, penalty
end

function print_solution(solution::Float64, p)
    println("SOLUÇÃO: $solution")
    for i in axes(p, 1)
        println("PRODUÇÃO PERIODO $i : $(p[i]) ")
    end
end

function main()
    if length(ARGS) == 0
        return
    end

    input_file::IOStream = open(ARGS[1], "r")
    horizon::Int64 = parse(Int64, split(readline(input_file), "\t")[2])
    demand, cost, storage, penalty = read_horizon(input_file, horizon)

    model = Model(HiGHS.Optimizer)
    v = @variable(model, [1:horizon], base_name = "v") # Estoque -> Multa
    w = @variable(model, [1:horizon], base_name = "w") # Produção Excedente
    x = @variable(model, [1:horizon], base_name = "x") # Produção Período Atual
    y = @variable(model, [1:horizon], base_name = "y") # Estoque
    z = @variable(model, [1:horizon], base_name = "z") # Multa

    for i in 1:horizon
        # Todas as variáveis precisam ser não-negativas
        @constraint(model, v[i] >= 0)
        @constraint(model, w[i] >= 0)
        @constraint(model, x[i] >= 0)
        # A produção atual não pode ser maior que a demanda atual
        @constraint(model, x[i] <= demand[i])
    end

    # No primeiro dia, não faz sentido usar alguma quantidade do estoque para pagar a multa
    # Afinal, se você quisesse pagar menos multa, bastaria aumentar a produção para o primeiro dia
    # Ou seja, não é necessário tirar alguma quantia da produção extra (que é o estoque nesse caso)
    # Isso implica que a quantidade que é transformada de estoque para pagar a multa é 0 (v[1]=0)
    @constraint(model, z[1] == demand[1] - x[1])
    @constraint(model, y[1] == w[1])

    for i in 2:horizon
        # Todas as variáveis precisam ser não-negativas
        @constraint(model, y[i] >= 0)
        @constraint(model, z[i] >= 0)
        # O estoque atual é o anterior + produção excedente - quantidade destinada para pagar multa
        @constraint(model, y[i] == y[i-1] + w[i] - v[i])
        # A multa atual é a anterior + o que ficou de dívida para hoje - quantidade destinada para pagar multa
        @constraint(model, z[i] == z[i-1] + demand[i] - x[i] - v[i])
    end

    # A demanda deve ser atendida até o final
    @constraint(model, sum(x[i] + w[i] for i in 1:horizon) == sum(demand[i] for i in 1:horizon))

    @objective(model, Min, sum(cost[i] * (w[i] + x[i]) + storage[i] * y[i] + penalty[i] * z[i] for i in 1:horizon))
    set_silent(model)
    optimize!(model)

    # print_solution(objective_value(model), value.(x) + value.(w))
    model_solution = objective_value(model)
    println("TP1 $MATRÍCULA = $model_solution")
end

main()
