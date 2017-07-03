SOX=/usr/local/bin/sox

if [ "$3" == "" ]; then
  echo ""
  echo "Usage: ./cross.sh crossfade_amount_in_seconds output_file file1 file2 file3 ..."
  echo ""
  exit 1
fi

if [ "$4" == "" ]; then
  cp "$3" "$2"
  exit 0
fi

fade_length=$1
fade="fade t $fade_length"

shift

output_file=$1

shift

$SOX $1 builder.wav

shift

index=0
for filename in "$@"
do
  $SOX builder.wav fadeout1.wav reverse trim 0 $fade_length
  $SOX fadeout1.wav fadeout2.wav $fade reverse

  $SOX "$filename" fadein1.wav trim 0 $fade_length
  $SOX fadein1.wav fadein2.wav $fade

  $SOX -m -v 1.0 fadeout2.wav -v 1.0 fadein2.wav crossfade.wav

  $SOX builder.wav song1.wav reverse trim $fade_length reverse
  $SOX "$filename" song2.wav trim $fade_length

  $SOX song1.wav crossfade.wav song2.wav mix.wav

  cp mix.wav builder.wav
  rm fadeout1.wav fadeout2.wav fadein1.wav fadein2.wav crossfade.wav song1.wav song2.wav mix.wav

  echo ""
  current_length=`$SOX builder.wav 2>&1 -n stat | grep Length | cut -d : -f 2 | cut -f 1 | xargs`
  echo "still working, current length is $current_length"
done

old_fade_length=$fade_length
fade_length=`echo "scale=3; $fade_length / 2" | bc`
echo "fading beginning and end of final file, with $old_fade_length / 2 duration, or $fade_length"
$SOX builder.wav builder2.wav fade t $fade_length
$SOX builder2.wav builder3.wav reverse fade t $fade_length reverse

echo ""
echo "copying to requested output file $output_file"
$SOX builder3.wav $output_file
rm builder.wav builder2.wav builder3.wav

echo ""
echo "done and done, all files have been crossfaded."

echo ""
total_length=`$SOX "$output_file" 2>&1 -n stat | grep Length | cut -d : -f 2 | cut -f 1 | xargs`
echo "total length is $total_length"
echo ""
