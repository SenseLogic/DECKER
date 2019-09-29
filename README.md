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

Install the [DMD 2 compiler](https://dlang.org/download.html) (choosing the MinGW setup option on Windows).

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
--front_title : front title
--back_title : back title
--front_language : front language
--back_language : back language
--input_format "format" : parses the card parameters with this format
--output_format "format" : exports the card parameters with this format
--media_folder : use this folder read and write media files
--dump_folder : use this folder to write dump files
--trim : trim the card parameters
--verbose : show the processing messages
```

## LXF export

Valid deck parameters :

*   front_title
*   back_title
*   front_language
*   back_language

Valid card parameters :

*   front_word
*   back_word
*   front_transcription
*   back_transcription
*   front_sample
*   back_sample
*   front_comment
*   back_comment
*   front_gender
*   back_gender
*   front_image
*   back_image
*   image

Valid genders :

*   n
*   neuter
*   neutral
*   m
*   male
*   masculine
*   f
*   female
*   feminine

Valid languages :

*   english
*   french
*   german
*   italian
*   dutch
*   swedish
*   spanish
*   danish
*   portuguese
*   norwegian
*   hebrew
*   japanese-kanji
*   arabic
*   finnish
*   greek
*   icelandic
*   maltese
*   turkish
*   croatian
*   chinese-traditional
*   urdu
*   hindi
*   thai
*   korean
*   lithuanian
*   polish
*   hungarian
*   estonian
*   latvian
*   sami
*   faroese
*   farsi
*   russian
*   chinese-simplified
*   flemish
*   irish-gaelic
*   albanian
*   romanian
*   czech
*   slovak
*   slovenian
*   yiddish
*   serbian
*   macedonian
*   bulgarian
*   ukrainian
*   belarusian
*   uzbek
*   kazakh
*   azerbaijani-cyrillic
*   azerbaijani-arabic
*   armenian
*   georgian
*   moldavian
*   kyrgyz
*   tajik
*   turkmen
*   mongolian
*   mongolian-cyrillic
*   pashto
*   kurdish
*   kashmiri
*   sindhi
*   tibetan
*   nepali
*   sanskrit
*   marathi
*   bengali
*   assamese
*   gujarati
*   punjabi
*   oriya
*   malayalam
*   kannada
*   tamil
*   telugu
*   sinhalese
*   burmese
*   khmer
*   lao
*   vietnamese
*   indonesian
*   tagalog
*   malay-roman
*   malay-arabic
*   amharic
*   tigrinya
*   galla
*   somali
*   swahili
*   kinyarwanda
*   rundi
*   nyanja-chewa
*   malagasy
*   esperanto
*   welsh
*   basque
*   catalan
*   latin
*   quenchua
*   guarani
*   aymara
*   tatar
*   uighur
*   dzongkha
*   javanese-roman
*   sundanese-roman
*   galician
*   afrikaans
*   breton
*   inuktitut
*   scottish-gaelic
*   manx-gaelic
*   irish-gaelic-dot-above
*   tongan
*   greek-polytonic
*   greenlandic
*   azerbaijani-roman
*   japanese-kana
*   bosnian
*   chess
*   history
*   dates
*   mathematics
*   music
*   physics
*   geography
*   medicine

### Examples

```bash
decker --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --verbose "spanish_vocabulary.apkg"
```

Write the Anki deck files into the output folder.

```bash
decker --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --trim --verbose "spanish_vocabulary.apkg"
```

Write the Anki deck files into the output folder, and parses the Anki card parameters.

```bash
decker --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --media_folder "SPANISH_VOCABULARY/" --trim "spanish_vocabulary.apkg" "spanish_vocabulary.lxf"
```

Write the Anki deck files into the output folder, parses the Anki card parameters and generates a Lexilize deck.

```bash
decker --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --output_format "{{front_word}}|{{back_word}}|{{front_image}}" --trim "spanish_vocabulary.apkg" "spanish_vocabulary.csv"
```

Write the Anki deck files into the output folder, parses the Anki card parameters and generates a CSV deck.

```bash
decker --input_format "{{front_word}}|{{back_word}}|{{front_image}}" --media_folder "SPANISH_VOCABULARY/" --trim "spanish_vocabulary.csv" "spanish_vocabulary.lxf"
```

Parses the CSV card parameters and generates a CSV deck.


## Limitations

*   Only JPEG images can be used in Lexilize decks.

## Version

1.0

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.

## Credits

The test files come from [ankiweb.net](http://www.ankiweb.net).
