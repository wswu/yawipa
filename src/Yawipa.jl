module Yawipa

using Downloads

function download(lang, output)
    Downloads.download("https://dumps.wikimedia.org/$(lang)wiktionary/latest/$(lang)wiktionary-latest-pages-articles.xml.bz2", output)
end

include("parsewiktionary.jl")

end