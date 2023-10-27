using JuMP
using HiGHS

const MATRÍCULA = "2020041973"

function read_matrix(file::IOStream, size::Int64)::Matrix{Float64}
    adj_matrix::Matrix{Float64} = zeros(Bool, size, size)
    for line in eachline(file)
        data = split(line, "\t")
        adj_matrix[parse(Int64, data[2]), parse(Int64, data[3])] = parse(Float64, data[4])
    end
    return adj_matrix
end

function print_solution(num_vertices::Int64, solution::Float64, y)
    println("$solution PESO")
    for i = 1:num_vertices
        if value(y[i]) > 0.5
            print("$i ")
        end
    end
end

function main()
    if length(ARGS) == 0
        return
    end

    input_file::IOStream = open(ARGS[1], "r")
    num_vertices::Int64 = parse(Int64, split(readline(input_file), "\t")[2])
    adj_matrix::Matrix{Float64} = read_matrix(input_file, num_vertices)

    model = Model(HiGHS.Optimizer)
    x = @variable(model, [1:num_vertices, 1:num_vertices], binary = true, base_name = "x")
    y = @variable(model, [1:num_vertices], binary = true, base_name = "y")

    for i in 1:num_vertices, j in 1:num_vertices
        # Se o vértice i está ausente, a aresta (i,j) deve estar ausente
        @constraint(model, x[i, j] <= y[i])
        # Se o vértice j está ausente, a aresta (i,j) deve estar ausente
        @constraint(model, x[i, j] <= y[j])
        # Se ambos os vértices estão presentes, a aresta deve estar presente
        @constraint(model, x[i, j] >= (y[i] + y[j]) - 1)
    end

    @objective(model, Max, sum(x[i, j] * adj_matrix[i, j] for i in 1:num_vertices, j in 1:num_vertices))

    set_silent(model)
    optimize!(model)

    # print_solution(num_vertices, objective_value(model), y)
    model_solution = objective_value(model)
    print("TP1 $MATRÍCULA $model_solution")
end

main()
