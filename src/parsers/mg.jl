module Mg

using ..Yawipa: WiktionaryParser, parsetemplates

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

function parse_pronunciation(lang, title, heading, text)
    results = []
    for temp in matchtemplates(text)
        if temp[1] == "fanononana" && length(temp) >= 2 && temp[2] != ""
            push!(results, temp)
        end
    end
    return results
end

end # module