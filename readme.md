# Yawipa

A comprehensive and extensible Wiktionary parser. This code accompanies our paper [Computational Etymology and Word Emergence](https://www.aclweb.org/anthology/2020.lrec-1.397/)

## Usage

```
julia yawipa.jl --dump DUMP --out OUT --log LOG
```

where DUMP is [the Wiktionary XML dump](https://dumps.wikimedia.org/enwiktionary/latest/enwiktionary-latest-pages-articles.xml.bz2).

For advanced filtering, you can specify `--skip SKIP` to skip titles matching the specified regex.

## Citation

If you found this software useful, please consider citing

```
@inproceedings{wu-yarowsky-2020-yawipa,
    title = "Computational Etymology and Word Emergence",
    author = "Wu, Winston  and
      Yarowsky, David",
    booktitle = "Proceedings of The 12th Language Resources and Evaluation Conference",
    month = May,
    year = "2020",
    address = "Marseille, France",
    publisher = "European Language Resources Association",
    url = "https://www.aclweb.org/anthology/2020.lrec-1.397",
}
```