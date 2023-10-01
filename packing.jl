using JuMP
using HiGHS

const MAX_WEIGHT::Float64 = 20.0

function read_weights(file::IOStream, size::Int64)::Vector{Float64}
    weights::Vector{Float64} = zeros(size)
    for line in eachline(file)
        data = split(line, "\t")
        weights[parse(Int64, data[2])+1] = parse(Float64, data[3])
    end
    return weights
end

function print_solution(num_objects::Int64, solution::Float64, x, y)
    println("$solution CAIXAS")
    caixa = 1
    for j in 1:num_objects
        if value(y[j]) > 0.5
            print("CAIXA $caixa :")
            caixa += 1
            for i in 1:num_objects
                if value(x[i, j]) > 0.5
                    print(" $(i-1)")
                end
            end
            println()
        end
    end
end

function main()
    if length(ARGS) == 0
        return
    end

    input_file::IOStream = open(ARGS[1], "r")
    num_objects::Int64 = parse(Int64, split(readline(input_file), "\t")[2])
    weights::Vector{Float64} = read_weights(input_file, num_objects)

    model = Model(HiGHS.Optimizer)
    y = @variable(model, [1:num_objects], binary = true, base_name = "y")
    x = @variable(model, [1:num_objects, 1:num_objects], binary = true, base_name = "x")

    for i in 1:num_objects
        # Todo objeto precisa estar em uma caixa
        @constraint(model, sum(x[i, j] for j in 1:num_objects) == 1)
    end

    for j in 1:num_objects
        # Toda caixa (que está sendo usada) precisa ter seu limite de peso respeitado
        @constraint(model, sum(x[i, j] * weights[i] for i in 1:num_objects) <= MAX_WEIGHT * y[j])
    end

    @objective(model, Min, sum(y[j] for j in 1:num_objects))

    set_silent(model)
    optimize!(model)

    print_solution(num_objects, objective_value(model), x, y)
end

main()
