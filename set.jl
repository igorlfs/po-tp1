using JuMP
using HiGHS

function read_matrix(file::IOStream, size::Int64)::Matrix{Bool}
    adj_matrix::Matrix{Bool} = zeros(Bool, size, size)
    for line in eachline(file)
        data = split(line, "\t")
        adj_matrix[parse(Int64, data[2]), parse(Int64, data[3])] = true
    end
    return adj_matrix
end

function print_solution(num_vertices::Int64, solution::Float64, v)
    println("$solution VERTICES")
    for j = 1:num_vertices
        if value(v[j]) > 0.5
            print("$j ")
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
    v = @variable(model, [1:num_vertices], binary = true, base_name = "v")

    for i in 1:num_vertices, j in 1:num_vertices
        # Se existe aresta entre dois vértices, ambas não podem estar presente no conjunto independente
        if adj_matrix[i, j]
            @constraint(model, v[i] + v[j] <= 1)
        end
    end

    @objective(model, Max, sum(v[k] for k in 1:num_vertices))

    set_silent(model)
    optimize!(model)

    print_solution(num_vertices, objective_value(model), v)
end

main()
