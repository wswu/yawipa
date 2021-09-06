module Es

using ..Yawipa: WiktionaryParser, DictKey, iso639_2to3, parsetemplates

struct EsParser <: WiktionaryParser
    parsing_functions::Dict{String, Function}
    lang_from_heading::Function
    
    EsParser() = new(
        Dict(
            "pron" => parse_pronunciation
        ),
        langcode_from_heading
    )
end

function langcode_from_heading(heading)
    m = match(r"==\s*{{\-(.+)\-}}\s*==", heading)
    if m !== nothing
        return m.captures[1]
    else
        return nothing
    end
end

function parse_pronunciation(dk::DictKey, heading, text)
    headtemp = parsetemplates(heading)
    if length(headtemp) == 1 && headtemp[1].tag == "lengua"
        dk.lang = iso639_2to3(headtemp[1].content[1])
    end

    results = []
    for temp in parsetemplates(text)
        temp.tag != "pron-graf" && continue
        
        for attr in temp.attrs
            k, v = split(attr, '=')
            push!(results, (k, v))
        end
    end
    return results
end

end # module