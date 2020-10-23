module Fr

using ..Yawipa: WiktionaryParser, parsetemplates2, iso639_2to3, strip_heading

struct FrParser <: WiktionaryParser
    parsing_functions::Dict{String, Function}
    lang_from_heading::Function
    
    FrParser() = new(
        Dict(
            "p" => parse_pronunciation,
            "pos" => parse_pos,
            "t" => parse_translations,
        ),
        langcode_from_heading
    )
end

function langcode_from_heading(heading)
    m = match(r"{{langue\|(.+)}}", strip(heading, [' ', '=']))
    if m !== nothing
        return m.captures[1]
    else
        return nothing
    end
end

PRON_TEMPLATES = Set(["pron", "phono", "phon"])

function parse_pronunciation(lang, title, heading, text)
    results = []
    for temp in parsetemplates2(text)
        temp.tag ∉ PRON_TEMPLATES && continue
        length(temp.content) < 2 && continue

        pron = temp.content[1]
        pron_lang = iso639_2to3(temp.content[2])
        push!(results, (temp.tag, pron, pron_lang, temp.content[3:end]..., temp.attrs...))
    end
    return results
end

function parse_pos(lang, title, heading, text)
    results = []
    for temp in parsetemplates2(heading)
        if temp.tag == "S" && length(temp.content) >= 2 && iso639_2to3(temp.content[2]) == lang
            push!(results, (temp.content[1], temp.content[3:end]..., temp.attrs...))
        end
    end
    return results
end

function parse_translations(lang, title, heading, text)
    strip_heading(heading) != "{{S|traductions}}" && return []

    results = []
    sense = ""
    for temp in parsetemplates2(text)
        if temp.tag == "trad-début"
            if length(temp.content) > 0
                sense = temp.content[1]
            end
        elseif temp.tag == "trad-fin"
            continue
        elseif startswith(temp.tag, "trad")
            if length(temp.content) == 0
                println(temp)
            end
            tr_lang = iso639_2to3(temp.content[1])
            push!(results, (sense, tr_lang, temp.content[2:end]..., temp.attrs...))
        end
    end
    return results
end

end # module