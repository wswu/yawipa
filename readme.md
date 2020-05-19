# Yawipa

A comprehensive and extensible Wiktionary parser. This code accompanies our paper [Computational Etymology and Word Emergence](http://www.lrec-conf.org/proceedings/lrec2020/pdf/2020.lrec-1.396.pdf)

## Usage

```
julia yawipa.jl --dump DUMP --out OUT --log LOG
```

where DUMP is [the Wiktionary XML dump](https://dumps.wikimedia.org/enwiktionary/latest/enwiktionary-latest-pages-articles.xml.bz2).

For advanced filtering, you can specify `--skip SKIP` to skip titles matching the specified regex.

## Citation

If you found this software useful, please consider citing

```
@InProceedings{wu-yarowsky:2020:LREC,
  author    = {Wu, Winston  and  Yarowsky, David},
  title     = {Computational Etymology and Word Emergence},
  booktitle = {Proceedings of The 12th Language Resources and Evaluation Conference},
  month     = {May},
  year      = {2020},
  address   = {Marseille, France},
  publisher = {European Language Resources Association},
  pages     = {3245--3252},
  url       = {https://www.aclweb.org/anthology/2020.lrec-1.396}
}
```