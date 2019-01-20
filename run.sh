#!/bin/sh
set -x
cd TEST

../decker --front_title "Animals" --back_title "Animales" --front_language "english" --back_language "spanish" --input_format "{{front_word}}|{{back_word}}|{{front_transcription}}|{{back_transcription}}|{{front_sample}}|{{back_sample}}|{{front_image}}|{{back_image}}" --media_folder "SPANISH_ANIMALS/" --dump_folder "SPANISH_ANIMALS/" --verbose "spanish_animals.csv" "spanish_animals.lxf"
read key

../decker --media_folder "SPANISH_VERBS/" --dump_folder "SPANISH_VERBS/" --verbose "spanish_verbs.apkg"
read key

../decker --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --verbose "spanish_vocabulary.apkg"
read key

../decker --media_folder "VOCABULAIRE_ESPAGNOL/" --dump_folder "VOCABULAIRE_ESPAGNOL/" --verbose "vocabulaire_espagnol.apkg"
read key

../decker --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --trim --verbose "spanish_vocabulary.apkg"
read key

../decker --front_title "Vocabulary" --back_title "Vocabulario" --front_language "english" --back_language "spanish" --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --trim --verbose "spanish_vocabulary.apkg" "spanish_vocabulary.lxf"
hexdump -C spanish_vocabulary.lxf > SPANISH_VOCABULARY/dump_lexilize_hexa.txt
cat spanish_vocabulary.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/dump_lexilize_proto.txt
read key

../decker --front_title "Vocabulary" --back_title "Vocabulario" --front_language "english" --back_language "spanish" --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --media_folder "SPANISH_VOCABULARY/" --trim "spanish_vocabulary.apkg" "spanish_vocabulary.lxf"
hexdump -C spanish_vocabulary.lxf > SPANISH_VOCABULARY/dump_lexilize_hexa.txt
cat spanish_vocabulary.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/dump_lexilize_proto.txt
read key

../decker --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --output_format "{{front_word}}|{{back_word}}|{{front_image}}" --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --trim --verbose "spanish_vocabulary.apkg" "spanish_vocabulary.csv"
read key

../decker --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --output_format "{{front_word}}|{{back_word}}|{{front_image}}" --media_folder "SPANISH_VOCABULARY/" --trim "spanish_vocabulary.apkg" "spanish_vocabulary.csv"
read key

../decker --front_title "Vocabulary" --back_title "Vocabulario" --front_language "english" --back_language "spanish" --input_format "{{front_word}}|{{back_word}}|{{front_image}}" --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --trim --verbose "spanish_vocabulary.csv" "spanish_vocabulary.lxf"
hexdump -C spanish_vocabulary.lxf > SPANISH_VOCABULARY/dump_lexilize_hexa.txt
cat spanish_vocabulary.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/dump_lexilize_proto.txt
read key

../decker --front_title "Vocabulary" --back_title "Vocabulario" --front_language "english" --back_language "spanish" --input_format "{{front_word}}|{{back_word}}|{{front_image}}" --media_folder "SPANISH_VOCABULARY/" --trim "spanish_vocabulary.csv" "spanish_vocabulary.lxf"
hexdump -C spanish_vocabulary.lxf > SPANISH_VOCABULARY/dump_lexilize_hexa.txt
cat spanish_vocabulary.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/dump_lexilize_proto.txt
