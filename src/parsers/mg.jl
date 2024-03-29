module Mg

using ..Yawipa: WiktionaryParser, DictKey, iso639_2to3, parsetemplates

struct MgParser <: WiktionaryParser
    parsing_functions::Dict{String, Function}
    lang_from_heading::Function
    
    MgParser() = new(
        Dict(
            "pron" => parse_pronunciation
        ),
        langcode_from_heading
    )
end

function langcode_from_heading(heading)
    m = match(r"==\s*{{=(.+)=}}\s*==", heading)
    if m !== nothing
        return m.captures[1]
    else
        return nothing
    end
end

function parse_pronunciation(dk::DictKey, heading, text)
    results = []
    for temp in parsetemplates(text)
        if temp.tag == "fanononana" && length(temp.content) >= 2 && temp.content != [""]
            dk.lang = iso639_2to3(temp.content[2])
            if temp.content[1] != ""
                push!(results, [temp.content...])
            end
        end
    end
    return results
end

end # module