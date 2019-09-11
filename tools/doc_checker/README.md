Doc checker
===========

The present tool verifies the structure and content of documentation files.


## Features

This tool can generate a graph of the .md files in a given directory. It also
checks that HTTP links are valid and do not point to the same project (for which
relative links should be preferred). Lastly, it identifies documents which are
not connected to the rest of the documentation tree.


## Usage

In order to build this tool, add `topaz/packages/doc_checker` to your build
packages. The tool is then available at:
```
out/debug-x64/host_x64/dart-tools/doc_checker
```

See the tool's help for how to hold it right.

In order to view the generated graph, run:
```
dot -Tpng graph.dot -o tree.png && feh tree.png
```
