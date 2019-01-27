#!/bin/sh
set -x
cd TEST

../decker --media_folder "SPANISH_CORE/" --dump_folder "SPANISH_CORE/" --verbose "spanish_core.apkg"
read key

../decker --front_title "Core" --back_title "Núcleo" --front_language "english" --back_language "spanish" --input_format "{{back_word}}[sound:{{back_sound}}]§<img src='{{front_image}}'><br><br>{{front_word}}" --input_format "<img src='{{front_image}}'><br><br>{{front_word}}§{{back_word}}[sound:{{back_sound}}]" --media_folder "SPANISH_CORE/" --dump_folder "SPANISH_CORE/" --trim --verbose "spanish_core.apkg" "SPANISH_CORE/spanish_core.lxf"
hexdump -C SPANISH_CORE/spanish_core.lxf > SPANISH_CORE/dump_lexilize_hexa.txt
cat SPANISH_CORE/spanish_core.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_CORE/dump_lexilize_proto.txt

../decker --front_title "Animals" --back_title "Animales" --front_language "english" --back_language "spanish" --input_format "{{front_word}}|{{back_word}}|{{front_transcription}}|{{back_transcription}}|{{front_sample}}|{{back_sample}}|{{front_comment}}|{{back_comment}}|{{front_gender}}|{{back_gender}}|{{image}}" --media_folder "SPANISH_ANIMALS/" --dump_folder "SPANISH_ANIMALS/" --verbose "spanish_animals.csv" "SPANISH_ANIMALS/spanish_animals.lxf"
hexdump -C SPANISH_ANIMALS/spanish_animals.lxf > SPANISH_ANIMALS/dump_lexilize_hexa.txt
cat SPANISH_ANIMALS/spanish_animals.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_ANIMALS/dump_lexilize_proto.txt
read key

../decker --media_folder "SPANISH_VERBS/" --dump_folder "SPANISH_VERBS/" --verbose "spanish_verbs.apkg"
read key

../decker --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --verbose "spanish_vocabulary.apkg"
read key

../decker --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --trim --verbose "spanish_vocabulary.apkg"
read key

../decker --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --output_format "{{front_word}}|{{back_word}}|{{front_image}}" --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --trim --verbose "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/spanish_vocabulary.csv"
read key

../decker --front_title "Vocabulary" --back_title "Vocabulario" --front_language "english" --back_language "spanish" --input_format "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --media_folder "SPANISH_VOCABULARY/" --dump_folder "SPANISH_VOCABULARY/" --trim --verbose "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/spanish_vocabulary.lxf"
hexdump -C SPANISH_VOCABULARY/spanish_vocabulary.lxf > SPANISH_VOCABULARY/dump_lexilize_hexa.txt
cat SPANISH_VOCABULARY/spanish_vocabulary.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/dump_lexilize_proto.txt

../decker --media_folder "VOCABULAIRE_ESPAGNOL/" --dump_folder "VOCABULAIRE_ESPAGNOL/" --verbose "vocabulaire_espagnol.apkg"
read key
