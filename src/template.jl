GenericTemplate = r"{{([^{]+?)}}"

"""
in {{der|lang1|lang2|...}}
lang1 is the home language, lang2 is the parent's language
"""
const TEMPLATE_2LANG = Set(["derived", "der", "borrowed", "bor", "learned borrowing", "lbor", "orthographic borrowing", "obor", "inherited", "inh", "phono-semantic matching", "psm"])

struct TemplateResult
    tag::String
    lang::String
    content::Vector{String}
    attrs::Vector{String}
end

const TEMPLATE_ALIASES = map(readlines(joinpath(@__DIR__, "aliases.txt"))) do line
    split(line, '\t')
end |> Dict

resolve_alias(tag) = get(TEMPLATE_ALIASES, tag, tag)

function interpret(arr)
    tag = arr[1] |> resolve_alias 
    attrs = []

    if length(arr) == 1  # {{trans-mid}}, {{...}}, etc
        return TemplateResult("", "", [], [])
    end

    # remove attributes (e.g. title="blah") from the array
    # do this before setting the language
    i = 2
    while i <= length(arr)
        if '=' in arr[i]
            push!(attrs, arr[i])
            deleteat!(arr, i)
        else
            i += 1
        end
    end

    if length(arr) == 1  # {{trans-mid}}, {{...}}, etc
        return TemplateResult("", "", [], [])
    end
    
    if tag ∈ TEMPLATE_2LANG
        # delete the home language
        deleteat!(arr, 2)
    end

    if length(arr) == 1  # {{trans-mid}}, {{...}}, etc
        return TemplateResult("", "", [], [])
    end

    return TemplateResult(tag, strip(arr[2]), arr[3:end], attrs)
end

function parsetemplates(text)
    result = []
    for m in eachmatch(GenericTemplate, text)
        arr = split(m[1], '|')
        push!(result, interpret(arr))
    end
    return result
end

"""does not parse"""
function matchtemplates(text)
    result = []
    for m in eachmatch(GenericTemplate, text)
        arr = split(m[1], '|')
        push!(result, arr)
    end
    return result
end