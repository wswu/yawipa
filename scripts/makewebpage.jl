# make the table with size and line count in the webpage for downloading Yawipa data

sizes = Dict()

output = readchomp(`ls -lh`)
for line in split(output, "\n")[2:end]
    arr = split(line)
    size = arr[5]
    name = arr[end]
    sizes[name] = size
end

for name in sort(collect(keys(sizes)))
    wc = readchomp(`wc -l $name`)
    count, name = split(strip(wc))
    println("<tr><td><a href='yawipa-data/$name'>$name</a></td> <td>$(sizes[name])</td> <td>$count</td></tr>")
end