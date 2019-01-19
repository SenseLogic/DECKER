#!/bin/sh
set -x
cd TEST

#../decker --parameter "front_title" "Animals" --parameter "back_title" "Animales" --parameter "front_language" "English" --parameter "back_language" "Spanish"--media_folder "SPANISH_ANIMALS/" --input_format "{{front_word}}|{{back_word}}|{{front_image}}" --dump --verbose "spanish_animals.csv" "spanish_animals.lxf"
#read key

../decker --media_folder "SPANISH_VERBS/" --dump --verbose "spanish_verbs.apkg"
read key

../decker --media_folder "SPANISH_VOCABULARY/" --dump --verbose "spanish_vocabulary.apkg"
read key

../decker --media_folder "VOCABULAIRE_ESPAGNOL/" --dump --verbose "vocabulaire_espagnol.apkg"
read key

../decker --media_folder "SPANISH_VOCABULARY/" --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --trim --dump --verbose "spanish_vocabulary.apkg"
read key

../decker --front_title "Vocabulary" --back_title "Vocabulario" --front_language "english" --back_language "spanish" --media_folder "SPANISH_VOCABULARY/" --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --trim --dump --verbose "spanish_vocabulary.apkg" "spanish_vocabulary.lxf"
hexdump -C spanish_vocabulary.lxf > SPANISH_VOCABULARY/dump_lexilize_hexa.txt
cat spanish_vocabulary.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/dump_lexilize_proto.txt
read key

../decker --front_title "Vocabulary" --back_title "Vocabulario" --front_language "english" --back_language "spanish" --media_folder "SPANISH_VOCABULARY/" --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --trim "spanish_vocabulary.apkg" "spanish_vocabulary.lxf"
hexdump -C spanish_vocabulary.lxf > SPANISH_VOCABULARY/dump_lexilize_hexa.txt
cat spanish_vocabulary.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/dump_lexilize_proto.txt
read key

../decker --media_folder "SPANISH_VOCABULARY/" --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --output_format "{{front_word}}|{{back_word}}|{{front_image}}" --trim --dump --verbose "spanish_vocabulary.apkg" "spanish_vocabulary.csv"
read key

../decker --media_folder "SPANISH_VOCABULARY/" --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --output_format "{{front_word}}|{{back_word}}|{{front_image}}" --trim "spanish_vocabulary.apkg" "spanish_vocabulary.csv"
read key

../decker --front_title "Vocabulary" --back_title "Vocabulario" --front_language "english" --back_language "spanish" --media_folder "SPANISH_VOCABULARY/" --input_format "{{front_word}}|{{back_word}}|{{front_image}}" --trim --dump --verbose "spanish_vocabulary.csv" "spanish_vocabulary.lxf"
hexdump -C spanish_vocabulary.lxf > SPANISH_VOCABULARY/dump_lexilize_hexa.txt
cat spanish_vocabulary.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/dump_lexilize_proto.txt
read key

../decker --front_title "Vocabulary" --back_title "Vocabulario" --front_language "english" --back_language "spanish" --media_folder "SPANISH_VOCABULARY/" --input_format "{{front_word}}|{{back_word}}|{{front_image}}" --trim "spanish_vocabulary.csv" "spanish_vocabulary.lxf"
hexdump -C spanish_vocabulary.lxf > SPANISH_VOCABULARY/dump_lexilize_hexa.txt
cat spanish_vocabulary.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/dump_lexilize_proto.txt
