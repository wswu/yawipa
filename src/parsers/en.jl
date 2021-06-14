module En

using Unicode
using ..Yawipa: WiktionaryParser, DictKey

include("en/template.jl")

mutable struct EnParser <: WiktionaryParser
    parsing_functions::Vector
    lang_from_heading::Function
    
    EnParser() = new(
        [
            "pos" => parse_pos,
            "pron" => parse_pronunciation,

            "alter" => parse_alter,
            "cog" => simple_parser("cog"),
            "cog" => simple_parser("cognate"),
            "noncog" => simple_parser("noncog"),
            "noncog" => simple_parser("noncognate"),

            "syn" => make_parser_col_l("Synonyms"),
            "ant" => make_parser_col_l("Antonyms"),
            "hyper" => make_parser_col_l("Hypernyms"),
            "hypo" => make_parser_col_l("Hyponyms"),
            "mero" => make_parser_col_l("Meronyms"),
            "holo" => make_parser_col_l("Holonyms"),
            "coord" => make_parser_col_l("Coordinate terms"),
            "der" => make_parser_col_l("Derived terms"),
            "rel" => make_parser_col_l("Related terms"),
            "desc" => simple_parser("desc"),  # Descendants
            "anagrams" => simple_parser("anagrams"), 

            "tr" => parse_translations,
            "def" => parse_definitions,
            "def tr" => parse_definition_translations,

            "etym" => parse_etymology,
            "formof" => parse_form_of
        ],
        langcode_from_heading
    )
end

"""
List from https://en.wiktionary.org/wiki/Wiktionary:List_of_languages
See scripts/grab_wiktionary_language_list.jl
"""
function read_languages()
    name2code = Dict{String,String}()
    for line in eachline(joinpath(@__DIR__, "en", "languages.tsv"))
        code, names, family = split(line, '\t')
        names = split(names, ',')
        for name in names
            if name ∉ keys(name2code)
                name2code[name] = code
            end
        end
    end
    return name2code
end

const langname2code = read_languages()

function langcode_from_heading(heading)
    lang = strip(join(collect(graphemes(strip(heading, ['='])))))
    return get(langname2code, lang, nothing)
end

#---

const PRONUNCIATION_TAGS = Set(["IPA", "rhymes", "homophones", "hyph"])

function parse_pronunciation(dk::DictKey, heading, text)
    results = []
    if heading == "Pronunciation"
        for line in split(text, '\n')
            variant = nothing
            for x in parsetemplates(line)
                if variant !== nothing
                    # variant (if it exists) comes before pronunciation
                    # e.g. {{a|GA}} {{enPR|nŏl′ij}}, {{IPA|en|/ˈnɑlɪdʒ/}}
                    push!(x.attrs, "variant=$variant")
                end

                if x.tag == "a"  
                    variant = x.lang
                elseif x.tag == "hyph" || x.tag == "hyphenation"
                    push!(results, [x.tag, join(x.content, '-'), x.attrs...])
                elseif endswith(x.tag, "PR")
                    push!(results, [x.tag, x.lang, x.attrs...])
                else
                    push!(results, [x.tag, x.content..., x.attrs...])
                end
            end
        end
    end
    return results
end

#---

# list from https://en.wiktionary.org/wiki/Wiktionary:Entry_layout#Part_of_speech
const POS_HEADINGS = Set(readlines(joinpath(@__DIR__, "en", "pos-headings.txt")))

"""
Also sets dk.lang
"""
function parse_pos(dk::DictKey, heading, text)
    if heading ∈ POS_HEADINGS
        dk.pos = heading
        return [[heading]]
    else
        return []
    end
end

#---

function make_parser_col_l(which_heading)
    function parse(dk::DictKey, heading, text)
        if heading == which_heading
            results = parse_col(text)
            if length(results) == 0
                for x in parsetemplates(text)
                    if x.tag == "l"
                        push!(results, [x.lang, x.content...])
                    end
                end
            end
            return results
        else
            return []
        end
    end
    return parse
end

function parse_col(text)
    results = []
    for x in parsetemplates(text)
        if startswith(x.tag, "col") || startswith(x.tag, "der") || startswith(x.tag, "rel") || startswith(x.tag, "alter")
            for word in x.content
                word = strip(word)
                p = parsetemplates(word)
                if length(p) == 1  # one template, probably {{l|...}}
                    push!(results, [p[1].lang, p[1].content...])
                elseif word != ""  # no template, just the word
                    push!(results, [x.lang, word])
                end
            end
        end
    end
    return results
end

#---

function simple_parser(tag)
    function parse_simple(dk::DictKey, heading, text)
        results = []
        for x in parsetemplates(text)
            if x.tag == tag
                push!(results, [x.lang, x.content..., x.attrs...]) 
            end
        end
        return results
    end
    return parse_simple
end

#---

function get_alter_dialect(arr)
    dialects = []
    start_dialect = false
    for elem in arr
        if elem == ""
            start_dialect = true
            continue
        end
        if start_dialect
            push!(dialects, elem)
        end
    end
    return dialects
end

function parse_alter(dk::DictKey, heading, text)
    results = []
    if heading != "Alternative forms"
        return results
    end

    for x in parsetemplates(text)
        if x.tag == "alter"  # {{alter|en|worde||obsolete}}
            dialects = get_alter_dialect(x.content)
            for word in x.content
                if word == ""  # blank before dialect
                    break
                end
                push!(results, [x.lang, word, dialects..., x.attrs...])
            end
        elseif x.tag == "l"  # * {{l|en|ravin}}, {{l|en|ravine}}
            push!(results, [x.lang, x.content..., x.attrs...])
        end
    end
    return results
end

#---

const TRANSLATION_TAGS = Set(["t", "t+", "t-simple"])

function parse_translations(dk::DictKey, heading, text)
    result = []
    if heading == "Translations"
        sense = ""
        for temp in parsetemplates(text)
            if temp.tag == "trans-top"
                sense = temp.lang  # the 2nd element in {{trans-top|sense}}
            elseif temp.tag ∈ TRANSLATION_TAGS && length(temp.content) >= 1
                    push!(result, (sense, temp.lang, temp.content..., temp.attrs...))
            end
        end
    end
    return result
end

#---

function parse_definitions(dk::DictKey, heading, text)
    results = []
    if heading ∈ POS_HEADINGS
        dk.pos = heading
        for line in split(text, '\n')
            arr = split(line, ' ', limit=2)
            length(arr) != 2 && continue

            # first_space = findfirst(' ', line)
            # isnothing(first_space) && continue

            bullet, definition = arr
            if endswith(bullet, "#")  # fits "# ", "## ", etc but not "#: " or "#* "
                # definition = line[first_space + 1:end]
                push!(results, [definition])
            end
        end
    end
    return results
end

function parse_definition_translations(dk::DictKey, heading, text)
    # only interested in other languages, whose definitions are in English
    if dk.lang == "en"
        return []
    end

    results = []
    for line in split(text, '\n')
        if startswith(line, "# ")
            for def in clean_definition(line[3:end])
                push!(results, [heading, def])
            end
        end
    end
    return results
end

function clean_definition(line)
    results = []

    def = replace(line, r"\([^\)]*\)" => "")  # remove parentheses
    def = replace(def, r"{{[^{}]*?}}" => "")  # remove templates
    def = replace(def, r"{{[^{}]*?}}" => "")  # once more for nested

    for d in split(def, r"[,;]")
        d = strip(d, [' ', '.'])
        if startswith(d, "a ")
            d = d[3:end]
        end
        if startswith(d, "an ")
            d = d[4:end]
        end
        if startswith(d, "to ")
            d = d[3:end]
        end
        d = strip(d)

        # longer definitions are probably not translations
        if d != "" && count(c -> c == ' ', d) <= 5  
            push!(results, d)
        end
    end

    return results
end

#---

function parse_etymology(dk::DictKey, heading, text)
    result = []
    if occursin("Etymology", heading)
        lines = split(text, '\n')

        if occursin("{{PIE ", lines[1])
            # parse e.g. {{PIE root|en|bʰeh₂|id=speak}} and then continue
            # but may have other templates, including inh and cog
            for x in parsetemplates(lines[1])
                push!(result, ["$(dk.lang)|$(dk.word)", x.tag, x.content..., x.attrs...])
            end
            deleteat!(lines, 1)
        end

        if length(lines) > 0
            tree = clean_etymology(lines[1])

            curr = ["$(dk.lang)|$(dk.word)"]
            for level in tree
                for c in curr
                    for etym_result in level
                        words = map(etym_result.words) do word
                            "$(word.lang)|$(join([word.content; word.attrs], '|'))"
                        end
                        push!(result, [c, etym_result.relation, words...])
                    end
                end
                
                curr = ["$(etym_result.words[1].lang)|$(join(etym_result.words[1].content, '|'))" for etym_result in level]
            end
        end
    end
    return result
end

struct EtymResult
    relation::String
    words::Vector{TemplateResult}
end

function clean_etymology(text)
    text = strip(text)
    text = replace(text, r"[Bb]orrowed from " => "from ")
    text = replace(text, r"From " => "from ")
    text = replace(text, "See " => "from ")
    text = replace(text, r"{{etyl\|[^}]*}}" => "")
    
    tree = []
    
    for sentence in split(text, ". ")
        # from {{...}}, inherited from {{...}}
        for from in split(sentence, r"[,;][\w\s]+from\s+")
            from = replace(from, "from " => "")
            current_level = []

            # {{...}} + {{...}} as a compound
            m = match(r"{{(.+?)}} \+ {{(.+?)}}", from)
            if m !== nothing    
                temps = parsetemplates(from)
                push!(current_level, EtymResult("comp", [temps[1], temps[2]]))
                push!(tree, current_level)
                continue
            end

            # otherwise parse a level {{...}}, {{...}}
            for p in parsetemplates(from)
                push!(current_level, EtymResult(p.tag, [p]))
            end
            push!(tree, current_level)
        end

        break  # only first sentence
    end

    return tree
end

#---

# list from https://en.wiktionary.org/wiki/Category:Form-of_templates
const FORM_OF_TEMPLATES = Set(readlines(joinpath(@__DIR__, "en", "form-of.txt")))

function parse_form_of(dk::DictKey, heading, text)
    result = []
    for x in parsetemplates(text)
        if x.tag ∈ FORM_OF_TEMPLATES
            push!(result, [x.tag, x.lang, x.content..., x.attrs...])
        end
    end
    return result
end

end # module