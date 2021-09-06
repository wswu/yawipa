module It

using ..Yawipa: WiktionaryParser, DictKey, parsetemplates

struct ItParser <: WiktionaryParser
    parsing_functions::Dict{String, Function}
    lang_from_heading::Function
    
    ItParser() = new(
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
    results = []
    for temp in parsetemplates(text)
        temp.tag != "IPA" && continue
        
        for ipa in temp.content
            push!(results, (temp.tag, ipa, temp.attrs...))
        end
    end
    return results
end

end # module