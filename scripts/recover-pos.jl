# Recovers part of speech in Yawipa's output.
# Because Yawipa processes the Wiktionary dump sequentially, part of speech is extracted after pronunciation, so it is blank in the extracted output file.
# This script adds the POS back in.

using ProgressMeter 

function main()
    data = []
    for line in eachline(ARGS[1])
        arr = split(line, '\t')
        push!(data, arr)
    end

    last_word = data[end][1:2]
    last_pos = data[end][3]
    for i in length(data):-1:1
        if length(data[i]) < 3
            println("bad ", data[i])
            continue
        end
        if data[i][1:2] != last_word || data[i][3] != ""
            last_word = data[i][1:2]
            last_pos = data[i][3]
        end
        if data[i][1:2] == last_word && data[i][3] == ""
            data[i][3] = last_pos
        end
    end

    for arr in data
        println(join(arr, '\t'))
    end
end

main()