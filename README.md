![](https://github.com/senselogic/DECKER/blob/master/LOGO/decker.png)

# Decker

Flashcard deck converter.

## Description

Decker converts both textual and illustrated flashcard decks from one format to another.

## Input formats

*   CSV (.csv)
*   Anki (.apkg)

## Output formats

*   CSV (.csv)
*   Lexilize (.lxf)

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html).

Build the executable with the following command lines :

```bash
sudo apt install libsqlite3-dev
dmd -m64 decker.d -L-ldl -L/usr/lib/x86_64-linux-gnu/libsqlite3.a
```

## Command line

```bash
decker [options] input_file_path output_file_path
```

## Options

```
--input_folder INPUT_FOLDER/ : read media files from this folder
--input_format "format" : read the cards using this input format
--output_folder OUTPUT_FOLDER/ : write media files into this folder
--output_format "format" : write the cards using this output format
--trim : trim the card parameters
--dump : dump the processing data
--verbose : show the processing messages
```

## Parameters

The following parameters can be exported into the LSF file :

```
{{front_image}}
{{front_word}}
{{front_transcription}}
{{front_sample}}
{{front_comment}}
{{front_gender}}

{{back_image}}
{{back_word}}
{{back_transcription}}
{{back_sample}}
{{back_comment}}
{{back_gender}}
```

### Examples

```bash
decker --output_folder "SPANISH_VOCABULARY/" --dump --verbose "spanish_vocabulary.apkg"
```

Extracts the Anki file content into the output folder.

```bash
decker --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --output_folder "SPANISH_VOCABULARY/" --trim --dump --verbose "spanish_vocabulary.apkg"
```

Extracts the Anki file content and dump its card parameters.

```bash
decker --read "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --trim --csv --write "{{front_word}}|{{back_word}}|{{front_image}}" --dump --verbose "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
```

Extracts the APKG file content, and generates a CSV file.

## Limitations

*   Only JPEG images can be used in Lexilize decks.

## Version

0.1

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.

## Credits

The test files come from [ankiweb.net](http://www.ankiweb.net).
