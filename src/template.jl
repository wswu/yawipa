struct TemplateResult
    tag::String
    content::Vector{String}
    attrs::Vector{String}
end

const GenericTemplate = r"{{([^{]+?)}}"

"""
    parsetemplates(text) -> Vector{TemplateResult}

Extracts Wiktionary templates from text.
"""
function parsetemplates(text)
    map(eachmatch(GenericTemplate, text)) do m
        arr = split(m[1], '|')
        interpret(arr)
    end
end

function interpret(arr)
    tag = strip(arr[1])
    content = String[]
    attrs = String[]
    for x in arr[2:end]
        if occursin('=', x)
            push!(attrs, strip(x))
        else
            push!(content, strip(x))
        end
    end
    return TemplateResult(tag, content, attrs)
end

strip_heading(x) = strip(x, ['=', ' '])