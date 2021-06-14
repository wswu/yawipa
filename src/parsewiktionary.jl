using EzXML
using ProgressMeter

include("langcodes.jl")
include("template.jl")

abstract type WiktionaryParser end

mutable struct DictKey
    lang::String
    word::String
    pos::String
end

DictKey() = DictKey("", "", "")

for file in readdir(joinpath(@__DIR__, "parsers"))
    f = joinpath(@__DIR__, "parsers", file)
    if isfile(f)
        include(f)
    end
end

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
    # TODO: add switch
    text = replace(text, r"\[\[([^\]]+\|)?([^\]]+?)\]\]" => s"\2")

    # remove <!-- comments -->
    text = replace(text, r"<!--[^>]+-->" => "")  
    return text
end

"""
    function parse(fout::IO, title::String, content::String, edition::String, parsers)

Parses a single Wiktionary page. Refer to https://en.wiktionary.org/wiki/Wiktionary:Entry_layout for the page layout.

`parsers` is a list of parsing functions
"""
function parse_page(fout::IO, title::String, content::String, edition::String, parser::WiktionaryParser)
    dk = DictKey()
    dk.word = title

    for (heading, block) in splitblocks(strip(content))
        lang_code = parser.lang_from_heading(heading)
        if lang_code !== nothing
            dk.lang = iso639_2to3(lang_code)
            dk.pos = ""  # new language, so reset pos
        end

        heading = strip(heading, ['='])
        block = clean_wiki_markup(block)

        for (parse_name, parse_func) in parser.parsing_functions
            output = parse_func(dk, heading, block)
            for arr in output
                println(fout, join([dk.lang, dk.word, dk.pos, parse_name, strip.(arr)...], '\t'))
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

camelcase(s) = uppercase(s[1]) * lowercase(s[2:end])

function load_parser(lang)
    lang = camelcase(lang)
    eval(Meta.parse("import .$lang"))
    parser_name = "$lang.$(lang)Parser()"
    return eval(Meta.parse(parser_name))
end

function parse(dump::String, edition::String, outfile::String, logfile::String, skip_regex::String="", parsers=String[])
    reader = open(EzXML.StreamReader, dump)
    fout = open(outfile, "w")
    flog = open(logfile, "w")
    skip_regex = Regex(skip_regex)
    prog = ProgressUnknown("pages")

    parser = load_parser(edition)

    # filter parsing functions
    if length(parsers) > 0
        keep = Set(parsers)
        parser.parsing_functions = filter(x -> x[1] ∈ keep, parser.parsing_functions)
    end

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
        parse_page(fout, title, text, edition, parser)
        ProgressMeter.next!(prog)
    end

    close(reader)
    close(fout)
end