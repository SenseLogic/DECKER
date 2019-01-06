![](https://github.com/senselogic/DECKER/blob/master/LOGO/decker.png)

# Decker

Anki deck converter.

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html).

Build the executable with the following command lines :

```bash
sudo apt install libsqlite3-dev
dmd -m64 decker.d -L-ldl -L/usr/lib/x86_64-linux-gnu/libsqlite3.a
```

## Command line

```bash
decker [options] apkg_file_path OUTPUT_FOLDER/
```

## Options

```
--filter "filter" : extract the card parameters using this filter
--trim : trim the card parameters
--csv "format" : export a CSV file using this format
```

### Examples

```bash
decker "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
```

Extract the Anki file content into the output folder.

```bash
decker --fields "<img src=\"{{image}}\">§{{spanish}}<br/><i>{{english}}</i>" --trim "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
```

Extract the Anki file content and its card parameters into the output folder.

```bash
decker --fields "<img src=\"{{image}}\">§{{spanish}}<br/><i>{{english}}</i>" --trim --csv "{{spanish}}|{{english}}|{{image}}" "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
```

Extract the Anki file content and its card parameters into the output folder, then generate a `collection.csv` file using the provided format.

## Version

0.1

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.

## Credits

The test files come from [ankiweb.net](http://www.ankiweb.net).
