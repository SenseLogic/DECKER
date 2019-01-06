#!/bin/sh
set -x
cd TEST
../decker "vocabulaire_espagnol.apkg" "VOCABULAIRE_ESPAGNOL/"
read key
../decker "spanish_verbs.apkg" "SPANISH_VERBS/"
read key
../decker "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
read key
../decker --filter "<img src=\"{{image}}\">§{{spanish}}<br/><i>{{english}}</i>" --trim "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
read key
../decker --filter "<img src=\"{{image}}\">§{{spanish}}<br/><i>{{english}}</i>" --trim --csv "{{spanish}}|{{english}}|{{image}}" "spanish_vocabulary.apkg" "SPANISH_VOCABULARY/"
