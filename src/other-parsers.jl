function parse_fr_pronunciation(lang, title, heading, text)
    # todo: handle these cases{{fr-rég|zi.ɡɔ.maʁ}}
    
    pron_templates = Set(["pron", "phono", "phon"])
    # e.g. {{pron|zi.ɡɔ.maʁ|fr}}

    results = []
    for temp in matchtemplates(text)
        if temp[1] ∈ pron_templates
            push!(results, temp)
        end
    end
    return results
end