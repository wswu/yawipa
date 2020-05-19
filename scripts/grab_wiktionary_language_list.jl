using EzXML

function main()
    run(`wget https://en.wiktionary.org/wiki/Wiktionary:List_of_languages`)
    
    reader = open(EzXML.StreamReader, "Wiktionary:List_of_languages")
    fout = open(joinpath(@__DIR__, "..", "src", "languages.tsv"), "w")

    while (item = iterate(reader)) !== nothing
        if reader.type != EzXML.READER_ELEMENT || reader.name != "tr"
            continue
        end
        
        tree = EzXML.expandtree(reader)
        row = elements(tree)
        if row[1].name == "th"
            continue
        end

        code = strip(row[1].content)
        names = [strip(row[2].content)]
        family = strip(row[3].content)
        other_names = filter(x -> x != "", strip.(split(row[5].content, ',')))
        push!(names, other_names...)

        println(fout, join([code, join(names, ','), family], '\t'))
    end

    close(reader)
    close(fout)
end

main()