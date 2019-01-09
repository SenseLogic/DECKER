#!/bin/sh
set -x
cd TEST
#../decker --dump "vocabulaire_espagnol.apkg" "VOCABULAIRE_ESPAGNOL/"
#../decker --dump  "spanish_verbs.apkg" "SPANISH_VERBS/"
#../decker --dump "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
#../decker --filter "<img src=\"{{image}}\">§{{spanish}}<br/><i>{{english}}</i>" --trim --dump "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
#../decker --filter "<img src=\"{{image}}\">§{{spanish}}<br/><i>{{english}}</i>" --trim --csv "{{spanish}}|{{english}}|{{image}}" --dump "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
../decker --filter "<img src=\"{{image}}\">§{{spanish}}<br/><i>{{english}}</i>" --trim --lxf --dump "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
cd SPANISH_VOCABULARY
hexdump -C collection.lxf > collection_lexilize_hexa.txt
cat collection.lxf | ~/data/WORK/TOOL/PROTOC/bin/protoc --decode_raw >collection_lexilize_proto.txt
