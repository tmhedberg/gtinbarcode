#!/bin/bash

IFS=$(echo -en '\n\b')

echo 'Generating barcodes...'
for line in $(cat $1); do
	
	GTIN=$(echo $line | cut -d'|' -f1)
	PACK_CONFIG=$(echo $line | cut -d'|' -f5)

	echo $GTIN - $PACK_CONFIG

	barcode -E -e 128 -t 1x1 -b $GTIN -n -u in -g 3x1 |
	convert -density 600 eps:- png:- |
	convert -gravity north -extent 1808x750 - - |
	convert -gravity south -weight Bold -pointsize 72 -annotate 0 "$GTIN" - - |
	convert -gravity east -splice 300x0 - - |
	convert -gravity east -extent 4200x750 - - |
	convert -gravity west -weight Bold -pointsize 96 -annotate 0 "$PACK_CONFIG" - - |
	convert -gravity east -extent 5100x750 - generated_$GTIN.png

done

echo 'Composing pages...'
montage -tile 1x8 -geometry 5100x750 generated_*.png mont.png

echo 'Vectorizing...'
for mont in $(ls mont*.png); do
	convert -density 600 $mont $(basename $mont .png).pdf
done

echo 'Merging pages into one document...'
gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=barcodes.pdf -dBATCH mont*.pdf

echo 'Cleaning up...'
rm generated_*.png mont*.png mont*.pdf

echo 'Done!'
