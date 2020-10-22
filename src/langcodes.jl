"""
File from https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso-639-3.tab
"""
function read_iso639()
    d = Dict{String, String}()
    open(joinpath(@__DIR__, "iso-639-3.tab")) do fin
        readline(fin)
        for line in eachline(fin)
            arr = split(line, '\t')
            lang2 = arr[4]
            lang3 = arr[1]
            if lang2 != ""
                d[lang2] = lang3
            end
        end
    end
    return d
end

iso639_2to3_map = read_iso639()

iso639_2to3(lang) = get(iso639_2to3_map, lang, lang)