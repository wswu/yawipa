function make_lfe()
    translations = []

    for line in eachline(ARGS[1])
        arr = split(line, '\t')
        
        if length(arr) < 6
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
            for temp in arr[6:end]
                items = split(temp, '|')
                
                if items[1] != "en" && length(items) >= 3
                    lang = items[1]
                    word = items[2]
                    has_t = false
                    
                    # t=xxx in attrs
                    for elem in items
                        if startswith(elem, "t=") || startswith(elem, "gloss=") ||
                        startswith(elem, "gloss1=") ||
                        startswith(elem, "gloss2=")
                            push!(translations, Translation(lang, word, elem[findfirst('=', elem):end], "", "e"))
                            has_t = true
                        end
                    end

                    # fourth item is tr slot
                    if length(items) >= 4 && items[4] != "" && !has_t
                        push!(translations, Translation(lang, word, items[4], "", "e"))
                    end
                end
            end
        end
    end

    for tr in translations
        println(join([tr.english, tr.sense, tr.lang, tr.word, tr.source], '\t'))
    end
end

make_lfe()