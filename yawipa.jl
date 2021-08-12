import Pkg
Pkg.activate(".")

using Yawipa
using ArgParse

function get_args()
    s = ArgParseSettings("Yawipa")
    @add_arg_table! s begin
        "--edition"
            help = "language code indicating the edition of Wiktionary (e.g. 'en' or fr')"
            arg_type = String
            required = true
        "--dump"
            help = "wiktionary xml dump (enwiktionary-latest-pages-articles.xml.bz2)"
            arg_type = String
            required = true
        "--out"
            help = "output file"
            arg_type = String
            required = true
        "--log"
            help = "log file"
            arg_type = String
            default = "yawipa.log"
        "--skip"
            help = "skip pages where the title matches this regex"
            arg_type = String
            default = ".*:.*"
        "--parsers"
            help = "template parsers to use, separated with commas (e.g. 'pron,pos')"
            arg_type = String
            default = ""
    end
    return parse_args(s)
end

function main()
    args = get_args()
    parsers = split(args["parsers"], ',')
    parsers = parsers == [""] ? [] : parsers
    Yawipa.parse(args["dump"], args["edition"], args["out"], args["log"], args["skip"], parsers)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end