using StringDistances

include("../src/template.jl")

struct Translation
    lang::String
    word::String
    english::String
    sense::String
    source::String
end

distance(s1, s2) = Levenshtein()(s1, s2) / max(length(s1), length(s2))

function extract_translations(path)
    translations = []

    for line in eachline(path)
        arr = split(line, '\t')
        
        if length(arr) < 5
            continue
        end

        lang = arr[1]
        word = arr[2]
        rel = arr[3]

        if lang == "en" && rel == "tr"
            english = replace(word, "/translations" => "")
            sense = arr[4]
            other_lang = arr[5]
            other_word = arr[6]
            push!(translations, Translation(other_lang, other_word, english, sense, "t"))
        elseif lang != "en" && rel == "def tr"
            english = arr[5]
            push!(translations, Translation(lang, word, english, "", "d"))
        elseif rel == "etym"
            for elem in arr[6:end]
                temp = interpret(["etym", split(elem, '|')...])
                for attr in temp.attrs
                    key, value = split(attr, '=')
                    key = strip(key)
                    value = strip(value)
                    m = match(r"^(t|gloss)(\d)", key)
                    word = ""
                    if m !== nothing
                        idx = m.captures[2]
                        idx = parse(Int, idx)
                        if idx <= length(temp.content)
                            word = temp.content[idx]
                            push!(translations, Translation(temp.lang, word, value, "", "etym-$key"))
                        else
                            println(stderr, "bad attr: ", temp)
                        end
                    elseif key == "t"
                        content = filter(x->x != "", temp.content)
                        if length(content) == 1
                            word = content[1]
                            push!(translations, Translation(temp.lang, word, value, "", "etym-$key"))
                        elseif length(content) == 2 && distance(content[1], content[2]) <= 0.5
                            # heuristic, if there are two items in content, they might be forms of each other
                            # TemplateResult("etym", "la", ["necare", "necāre"], ["t=to kill"])
                            for word in content
                                push!(translations, Translation(temp.lang, word, value, "", "etym-$key"))
                            end
                        else
                            println(stderr, "bad t:", temp)
                        end
                    end
                end

                if length(temp.attrs) == 0 && length(temp.content) == 3
                    push!(translations, Translation(temp.lang, word, temp.content[3], "", "etym-tpos"))
                end
            end
        end
    end

    for tr in translations
        println(join([tr.english, tr.sense, tr.lang, tr.word, tr.source], '\t'))
    end
end

extract_translations(ARGS[1])