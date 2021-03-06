#! /bin/bash

cd "$(dirname "$0")"
if [ "$#" -eq 0 ]; then
	echo "$0": usage: getMposter.sh ID
	exit 1
fi

dMoImg=false
dMoFolder=../MoImg/
imgResizeMo="-resize 500x"
tinyPNGapi=""
TMDBapi=""
compressImgMo=false
. config.cfg

id=${1};
if [[ ! -z "$TMDBapi" ]]; then
	myUrl="https://api.themoviedb.org/3/movie/tt"${id}"/images?include_image_language=en&api_key="$TMDBapi
	output=$(curl -s --request GET --url $myUrl --data '{}' | jq -r '.posters | map(select((.width | contains(1000)) and (.height | contains(1500))) | .file_path) | .[]' | head -n1)
	if [[ $output == *".jpg"* ]]; then
		output="https://image.tmdb.org/t/p/original"$output;
	else
		myUrl="https://api.themoviedb.org/3/movie/tt"${id}"/images?api_key="$TMDBapi
		output=$(curl -s --request GET --url $myUrl --data '{}' | jq -r '.posters[0] | .file_path')
		output="https://image.tmdb.org/t/p/original"$output;
	fi
	if $dMoImg; then
		if [ ! -d "$dMoFolder" ]; then
			mkdir $dMoFolder
		fi
		wget -q -N -P $dMoFolder $output;
		output=$(basename $output)
		if [ ! -z "$imgResizeMo" ]; then
			convert $imgResizeMo $dMoFolder$output $dMoFolder$output
		fi
		if $compressImgMo; then
			convert -strip -interlace Plane -gaussian-blur 0.05 -quality 90% $dMoFolder$output $dMoFolder$output
		fi
		if [[ ! -z "$tinyPNGapi" ]]; then
			imgUrl=$(curl -s --user api:$tinyPNGapi  --data-binary @$dMoFolder$output https://api.tinify.com/shrink | jq -r '.output.url')
			curl -s --user api:$tinyPNGapi --output $dMoFolder$output $imgUrl
		fi
		chmod 755 -R $dMoFolder
		tempFolder=$(basename $dMoFolder)
		echo $tempFolder"/"$output;
	else
		echo $output
	fi
else    
	echo "null"
fi
