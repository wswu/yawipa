using StringDistances

using Pkg
Pkg.activate("..")
using Yawipa

include("../src/parsers/en/template.jl")

struct Translation
    lang::String
    word::String
    pos::String
    english::String
    sense::String
    source::String
end

distance(s1, s2) = Levenshtein()(s1, s2) / max(length(s1), length(s2))

split_gloss(gloss) = strip.(split(gloss, [',', ';']))

TRANSLATION = "t"
FOREIGN_TRANSLATION = "ft"
DEFINITION_TRANSLATION = "dt"

function extract_translations(path)
    translations = []

    for line in eachline(path)
        arr = split(line, '\t')
        
        if length(arr) < 5
            continue
        end

        lang = arr[1]
        word = arr[2]
        pos = arr[3]

        rel = arr[4]

        if rel == "tr"
            english = replace(word, "/translations" => "")
            sense = arr[5]
            other_lang = arr[6]
            other_word = arr[7]

            if lang == "eng"
                # english -> foreign
                push!(translations, Translation(other_lang, other_word, pos, english, sense, TRANSLATION))
            elseif other_lang == "eng"
                # foreign -> english
                push!(translations, Translation(lang, word, other_word, pos, sense, FOREIGN_TRANSLATION))
            end
        
        elseif lang != "eng" && rel == "deftr"
            # definition translations
            sense = arr[5]
            english = arr[6]
            push!(translations, Translation(lang, word, pos, english, "", DEFINITION_TRANSLATION))

        elseif rel == "etym"
            # glosses from etymology
            for elem in arr[6:end]
                temp = interpret(["etym", split(elem, '|')...])
                for attr in temp.attrs
                    key, value = split(attr, '=')
                    key = strip(key)
                    value = strip(value)

                    m = match(r"^(t|gloss)(\d)", key)
                    word = ""
                    if m !== nothing  # e.g. t2
                        idx = m.captures[2]
                        idx = parse(Int, idx)
                        if idx <= length(temp.content)
                            word = temp.content[idx]
                            for gloss in split_gloss(value)
                                push!(translations, Translation(temp.lang, word, pos, gloss, "", "e$key"))
                            end
                        else
                            println(stderr, "bad attr: ", temp)
                        end

                    elseif key == "t" || key == "gloss"
                        content = filter(x -> x != "", temp.content)
                        if length(content) == 1
                            word = content[1]
                            for gloss in split_gloss(value)
                                push!(translations, Translation(temp.lang, word, pos, gloss, "", "e$key"))
                            end
                        elseif length(content) == 2 && distance(content[1], content[2]) <= 0.5
                            # heuristic: if there are two items in content, they might be forms of each other
                            # TemplateResult("etym", "la", ["necare", "necāre"], ["t=to kill"])
                            for word in content
                                for gloss in split_gloss(value)
                                    push!(translations, Translation(temp.lang, word, pos, gloss, "", "e$key"))
                                end
                            end
                        else
                            println(stderr, "bad: ", temp)
                        end
                    end
                end

                # positional gloss
                if length(temp.attrs) == 0 && length(temp.content) == 3
                    push!(translations, Translation(temp.lang, word, pos, temp.content[3], "", "epos"))
                end
            end
        end
    end

    for tr in translations
        println(join([tr.lang, tr.english, tr.word, tr.pos, tr.sense, tr.source], '\t'))
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    extract_translations(ARGS[1])
end