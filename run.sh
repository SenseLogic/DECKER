#!/bin/sh
set -x
cd TEST
../decker --read "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --write "{{front_word}}|{{back_word}}|{{front_image}}" --trim --csv --dump "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
read key
../decker --read "{{front_word}}|{{back_word}}|{{front_image}}" --trim --lxf --dump "spanish_vocabulary.csv" "SPANISH_VOCABULARY/"
hexdump -C SPANISH_VOCABULARY/collection.lxf > SPANISH_VOCABULARY/collection_lexilize_hexa.txt
cat SPANISH_VOCABULARY/collection.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/collection_lexilize_proto.txt
read key
../decker --read "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --trim --lxf --dump "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
hexdump -C SPANISH_VOCABULARY/collection.lxf > SPANISH_VOCABULARY/collection_lexilize_hexa.txt
cat SPANISH_VOCABULARY/collection.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >SPANISH_VOCABULARY/collection_lexilize_proto.txt
read key
../decker --dump "vocabulaire_espagnol.apkg" "VOCABULAIRE_ESPAGNOL/"
read key
../decker --dump  "spanish_verbs.apkg" "SPANISH_VERBS/"
read key
../decker --dump "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
read key
../decker --read "<img src=\"{{front_image}}\">§{{front_word}}<br/><i>{{back_word}}</i>" --trim --dump "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
read key
