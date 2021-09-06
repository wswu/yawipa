module El

using ..Yawipa: WiktionaryParser, DictKey, iso639_2to3, parsetemplates

struct ElParser <: WiktionaryParser
    parsing_functions::Dict
    lang_from_heading::Function
    ElParser() = new(
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
        # {{ΔΦΑ|a.ðʝa.ˈci.ni.tɔs|a.ði.a.ˈci.ni.tɔs|γλ=el}}
        temp.tag != "ΔΦΑ" && continue
        if length(temp.attrs) > 1
            println(temp)
        end

        if length(temp.attrs) == 1
            lang = rsplit(temp.attrs[1], '=')[end]
            dk.lang = iso639_2to3(lang)
        end

        # if "γλ" ∈ keys(temp.attrs)
        #     temp.attrs["lang"] = temp.attrs["γλ"]
        #     delete!(temp.attrs, "γλ")
        # end
        for ipa in temp.content
            if ipa != "?"
                push!(results, (temp.tag, ipa, temp.attrs...))
            end
        end
    end
    return results
end

end # module