#!/bin/bash

FIELD_SEPARATOR='|'
GTIN_FIELD='1'
DESCRIPTION_FIELD='2'
PACK_CONFIG_FIELD='3'

IFS=$(echo -en '\n\b')

echo 'Generating barcodes...'
for line in $(cat $1); do
	
	GTIN=$(echo $line | cut -d"$FIELD_SEPARATOR" -f"$GTIN_FIELD")
	DESCRIPTION=$(echo $line | cut -d"$FIELD_SEPARATOR" -f"$DESCRIPTION_FIELD")
	PACK_CONFIG=$(echo $line | cut -d"$FIELD_SEPARATOR" -f"$PACK_CONFIG_FIELD")
	SAFE_PACK_CONFIG=$(echo $PACK_CONFIG | sed 's/\///g')

	echo -n $GTIN - $PACK_CONFIG
	if [[ "$SAFE_PACK_CONFIG" != "$PACK_CONFIG" ]]; then
		echo " ($SAFE_PACK_CONFIG)"
	else
		echo
	fi

	barcode -E -e 128 -t 1x1 -b $GTIN -n -u in -g 3x1 |
	convert -density 600 eps:- png:- |
	convert -gravity North -extent 1808x700 - - |
	convert -gravity South -weight Bold -pointsize 72 -annotate 0 "$GTIN" - - |
	convert -gravity SouthEast -splice 300x50 - - |
	convert -gravity East -extent 4200x750 - - |
	convert -gravity West -weight Bold -pointsize 96 -annotate 0 "$DESCRIPTION, $PACK_CONFIG" - - |
	convert -gravity East -extent 5100x750 - "generated_${SAFE_PACK_CONFIG}_${GTIN}.png"

done

echo 'Composing pages...'
montage -tile 1x8 -geometry 5100x750 generated_*.png mont.png

echo 'Adding margins & vectorizing...'
for mont in $(ls mont*.png); do
	mogrify -bordercolor white -border 0x300 $mont
	convert -density 600 $mont $(basename $mont .png).pdf
done

echo 'Merging pages into one document...'
gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=barcodes.pdf -dBATCH mont*.pdf

echo 'Cleaning up...'
rm generated_*.png mont*.png mont*.pdf

echo 'Done!'
