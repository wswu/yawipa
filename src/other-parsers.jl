function parse_es_pronunciation(lang, title, heading, text)
    pron_templates = Set(["pron-graf", "pronunciación"])

    results = []
    for temp in parsetemplates2(text)
        if temp.tag == "pron-graf"
            if length(temp.content) == 1
                push!(temp.attrs, "fone=$(temp.content)")
            end
            for attr in temp.attrs
                attr_k, attr_v = split(attr, '=')
                if occursin("fone", attr_k)
                    for pronunciation in split(attr_v, " o ")  #  pol o poul
                        pronunciation = strip(attr_v, ['[', ']', ' ', '"'])
                        idx = isnumeric(attr_k[1]) ? attr_k[1] : ""
                        attrs = [a for a in temp.attrs
                            if a != attr && startswith(a, idx) && !startswith(a, "leng=")]
                        push!(results, [temp.tag, pronunciation, attrs...])
                    end
                end
            end
        elseif temp.tag == "pronunciación"
            pron = length(temp.content) == 1 ? strip(temp.content[1], ['[', ']', ' ', '"']) : ""
            push!(results, [temp.tag, pron, [a for a in temp.attrs if !startswith(a, "leng=")]...])
        end
    end
    return results
end