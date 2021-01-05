# Yawipa

A comprehensive and extensible Wiktionary parsing framework. If we don't have a parser for your edition of Wiktionary, please help contribute one!


## Usage

```
julia yawipa.jl --dump DUMP --out OUT --log LOG --parsers all
```

where DUMP is the Wiktionary XML dump (e.g. [this one](https://dumps.wikimedia.org/enwiktionary/latest/enwiktionary-latest-pages-articles.xml.bz2) for the English Wiktionary). 

The argument to `--parsers` is a comma-separated list of edition-specific parsing functions defined in the respective `parsers/{lang}.jl`, or "all" to use all available parsing functions.

For advanced filtering, you can specify `--skip SKIP` to skip page titles matching the specified regex.


## Writing your own parser

It is simple to write a new parser for a Wiktionary edition. The parser for the Italian Wiktionary at `src/parsers/it.jl` is a good example of a barebones parser. There are a few things to keep in mind:

- Each parser should be in its own module. The convention (which we might change in the future) is that the module name is the camelcased language code in Wiktionary (e.g. `module En` for the English edition). This module will be programatically imported based on the `--edition` argument.
- The parser must be called `{lang}Parser`, replacing `{lang}` with this language code. 
- The parser must have a `lang_from_heading` function which identifies the language from the heading of the entry. If the heading is not a language code, this function should return `nothing`. Some editions will need a table lookup to convert the language name to a language code.
- Then you can define a parsing function for whatever you want to parse! This function must take four arguments (language, page title, section heading, section text). It should return a list of parsed information to be written to the specified output file. This function should be added to the `parsing_functions` dictionary. Typically you will be parsing Wiktionary templates (e.g. `{{t|yue|字典|tr=zi6 din2}}`), and there are a variety of functions in `src/template.jl` that facilitate this parsing.


## Citation

If you found this software useful, please cite

```
@inproceedings{wu-yarowsky-2020-yawipa,
    title = "Computational Etymology and Word Emergence",
    author = "Wu, Winston and Yarowsky, David",
    booktitle = "Proceedings of The 12th Language Resources and Evaluation Conference",
    month = may,
    year = "2020",
    address = "Marseille, France",
    publisher = "European Language Resources Association",
    url = "https://www.aclweb.org/anthology/2020.lrec-1.397",
}
```

If you use the extracted morphological data or translations from etymology glosses, please also cite 

```
@inproceedings{wu-yarowsky-2020-wiktionary,
    title = "{W}iktionary Normalization of Translations and Morphological Information",
    author = "Wu, Winston and Yarowsky, David",
    booktitle = "Proceedings of the 28th International Conference on Computational Linguistics",
    month = dec,
    year = "2020",
    address = "Barcelona, Spain (Online)",
    publisher = "International Committee on Computational Linguistics",
    url = "https://www.aclweb.org/anthology/2020.coling-main.413",
}
```