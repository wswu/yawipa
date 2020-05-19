using Gadfly
using Cairo
using CSV

# th = Theme(default_color="black", panel_stroke="black", plot_padding=[2mm], bar_spacing=1mm)
th = Theme(panel_stroke="black", plot_padding=[2mm], bar_spacing=1mm)
Gadfly.push_theme(th)


df = CSV.read("langcounts.tsv", header=["lang", "count", "etym_count"])

plot(x=df.lang[1:40], y=[df.count[1:40] ./ 100000; df.etym_count[1:40] ./ 100000], Geom.bar(position=:stacked),
        Guide.yticks(ticks=[0:10;]),
        # Guide.yticks(ticks=[0:400:2000;]),
        Guide.title("Wiktionary Entries"),
        Guide.xlabel(""),
        Guide.ylabel("# of entries (100k)"),
    ) |> PDF("etymlangs2.pdf", 6inch, 3inch)

# grep -P "\tetym\t" extracted.out | sort -u > etym.out

lang type count
eng  etym 3
eng  noetym 4

df = df[1:40, :]
noetym = df.count .- df.etym_count
newdf = DataFrame(
lang = repeat(df, inner=2).lang,
has = repeat(["no etym", "etym"], size(df)[1]),
count = reshape([noetym df.etym_count]', size(df)[1] * 2, 1) |> vec
)

newdf = newdf[1:80, :]

plot(x=newdf.lang, color=newdf.has, y=newdf.count ./ 100000, Geom.bar(position=:stack),
        Guide.yticks(ticks=[0:10;]),
        Guide.title("Wiktionary Entries with Etymology"),
        Guide.xlabel(nothing),
        Guide.ylabel("# of entries (100k)"),
        Guide.colorkey(title=""),
    ) |> PDF("noetym.pdf", 6inch, 3inch)