module Yawipa

using ArgParse
using DelimitedFiles
using EzXML
using ProgressMeter
using Serialization
using Unicode

include("template.jl")
include("parsers.jl")

"""
List from https://en.wiktionary.org/wiki/Wiktionary:List_of_languages

See scripts/grab_wiktionary_language_list.jl
"""
function read_languages()
    name2code = Dict{String,String}()
    for line in eachline(joinpath(@__DIR__, "languages.tsv"))
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

"""
    splitblocks(content::String)

Splits content into blocks, where each block has a markdown heading
    
Returns a list of `[(heading, block_content), ...]`
"""
function splitblocks(content)
    arr = split(content, r"\n=")
    result = []
    for block in arr
        block = block * "\n"  # some blocks might have no content (e.g. ==English==)
        idx = findfirst('\n', block)

        # orig: heading = block[1:idx - 1], but do the following bc of non ascii strings
        heading = block[1:prevind(block, idx, 1)]

        if !startswith(heading, "=")
            continue
        end

        # orig: block_content = idx >= length(block) ? "" : block[idx + 1:end]
        block_content = idx >= length(block) ? "" : block[nextind(block, idx):end]
        push!(result, (heading, block_content))
    end
    return result
end

function clean_wiki_markup(text)
    # remove brackets from [[keepthis]] and [[blah|keepthis]]
    text = replace(text, r"\[\[([^\]]+\|)?([^\]]+?)\]\]" => s"\2")

    # remove <!-- comments -->
    text = replace(text, r"<!--[^>]+-->" => "")  
    return text
end

"""
    function parse(fout::IO, title::String, content::String, parsers)

Parses a single Wiktionary page.

`parsers` is a list of parsing functions
"""
function parse(fout::IO, title::String, content::String, parsers)
    """Refer to https://en.wiktionary.org/wiki/Wiktionary:Entry_layout"""
    lang = ""
    for (heading, block) in splitblocks(strip(content))
        # splitblocks() strips the beginning =, so look at the ending ones instead
        if match(r"[^=]==$", heading) !== nothing  
            lang = langcode_from_heading(heading)
            continue
        end

        heading = strip(heading, ['='])
        block = clean_wiki_markup(block)

        for (parse_name, parse_func) in parsers
            output = parse_func(lang, title, heading, block)
            for arr in output
                println(fout, join([lang, title, parse_name, arr...], '\t'))
            end
        end
    end
end

"""
Sample page structure:
```
    <page>
    <title>dictionary</title>
    <ns>0</ns>
    <id>16</id>
    <revision>
        <id>58595139</id>
        <parentid>58323363</parentid>
        <timestamp>2020-01-30T16:25:55Z</timestamp>
        <contributor>
            <ip>87.120.64.71</ip>
        </contributor>
        <comment>/* Translations */</comment>
        <model>wikitext</model>
        <format>text/x-wiki</format>
        <text xml:space="preserve">{{also|Dictionary}}
            ...(the content)
        </text>
        <sha1>...</sha1>
    </revision>
    </page>
```
Can't use XPath because it's an unmanaged XML node.
"""
function get_title_and_text(page)
    title = ""
    text = ""
    for elem in elements(page)
        if countelements(elem) > 0
            for c in elements(elem)
                if c.name == "text"
                    text = c.content
                end
            end
        else
            if elem.name == "title"
                title = elem.content
            end
        end
    end
    return (title, text)
end

function langcode_from_heading(heading)
    lang = strip(join(collect(graphemes(strip(heading, ['='])))))
    return get(langname2code, lang, lang)
end

function main(args)
    reader = open(EzXML.StreamReader, args["dump"])
    fout = open(args["out"], "w")
    flog = open(args["log"], "w")
    skip_regex = Regex(args["skip"])
    prog = ProgressUnknown("pages")

    parsers = [
        "pron" => parse_pronunciation,
        "pos" => parse_pos,

        "alter" => make_parser_col_l("Alternative forms"),
        "alt form" => simple_parser("alt form"),
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

        "tr" => parse_translations,
        "def tr" => parse_definition,

        "etym" => parse_etymology,
        "formof" => parse_form_of,
    ]

    while (item = iterate(reader)) !== nothing
        if reader.type != EzXML.READER_ELEMENT || reader.name != "page"
            continue
        end
        
        tree = EzXML.expandtree(reader)
        title, text = get_title_and_text(tree)
        
        if match(skip_regex, title) !== nothing
            continue
        end
        
        println(flog, title)
        parse(fout, title, text, parsers)
        ProgressMeter.next!(prog)
    end

    close(reader)
    close(fout)
end

end  # module