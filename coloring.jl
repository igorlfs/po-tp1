using JuMP
using HiGHS

const MATRÍCULA = "2020041973"

function read_matrix(file::IOStream, size::Int64)::Matrix{Bool}
    adj_matrix::Matrix{Bool} = zeros(Bool, size, size)
    for line in eachline(file)
        data = split(line, "\t")
        adj_matrix[parse(Int64, data[2]), parse(Int64, data[3])] = true
    end
    return adj_matrix
end

function print_solution(solution::Float64, x, y)
    println("$solution CORES")
    cor = 1
    for j in axes(x, 2)
        if value(y[j]) > 0.5
            print("COR $cor :")
            cor += 1
            for i in axes(x, 1)
                if value(x[i, j]) > 0.5
                    print(" $i ")
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
    num_vertices::Int64 = parse(Int64, split(readline(input_file), "\t")[2])
    adj_matrix::Matrix{Bool} = read_matrix(input_file, num_vertices)


    model = Model(HiGHS.Optimizer)
    x = @variable(model, [1:num_vertices, 1:num_vertices], binary = true, base_name = "x")
    y = @variable(model, [1:num_vertices], binary = true, base_name = "y")

    # Todo vértice deve ter exatamente uma cor
    for i in 1:num_vertices
        @constraint(model, sum(x[i, j] for j in 1:num_vertices) == 1)
    end

    # Se existe aresta entre dois vértices, ambos não podem ter a mesma cor
    # Mas só verificamos isso se escolhemos (precisamos escolher) aquela cor
    for i in 1:num_vertices, j in 1:num_vertices, k in 1:num_vertices
        if adj_matrix[i, k]
            @constraint(model, x[i, j] + x[k, j] <= y[j])
        end
    end

    @objective(model, Min, sum(y[j] for j in 1:num_vertices))

    set_silent(model)
    optimize!(model)

    # print_solution(objective_value(model), x, y)
    model_solution = objective_value(model)
    println("TP1 $MATRÍCULA = $model_solution")
end

main()
