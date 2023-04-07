#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] ; then
  echo  "usage: cgamo.sh cookie-file book-url [номер дела]"
  exit  1
fi

if [[ "$1" =~ ^http ]] ; then
  echo  "usage: cgamo.sh cookie-file book-url [номер дела]"
  exit  1
fi

if [[ "$2" =~ ^http ]] ; then
  #shortened format
  if [[ "$2" =~ ^.*oid= ]] ; then
    BOOKID=$(echo $2 | grep -oP 'oid=\K.+')
  else
    BOOKID=$(echo $2 | grep -oP 'case\/\K.+')
  fi
else
  BOOKID="$2"
fi

if [ -n "$3" ] ; then
  FKEY="./cgamo-key.txt"
  if [ -f "$FKEY" ] ; then
    if [ -s "$FKEY" ] ; then
      FKEY=$(cat $FKEY)
    else
      echo  "Ключ-файл пустой. Использую шифр \"2510-1\" по умолчанию"
      FKEY="2510-1"
    fi
      DELO=$FKEY-$3-file
      DPATH="$FKEY-$3"
      mkdir -p "$DPATH"
  else
    echo  "Нет ключ-файла! Пожалуйста, добавьте файл с именем \"cgamo-key.txt\" без кавычек. Файл должен содержать номер фонда и номер описи в формате \"фонд-опись\" без кавычек"
    exit  1
  fi
else
  DELO="file"
  DPATH="cgamo-$BOOKID"
  mkdir -p "$DPATH"
fi

URL="https://arch.mosreg.ru/srv/private/imageViewer/show?objectId=${BOOKID}&attributeId=5908&serial=1&group=4688&ext=.jpg"

#complete format
#BOOKID=$(echo $URL | grep -oP 'objectId\=\K.+?(?=\&)')

#FOND=$(echo $URL | grep -oP 'attributeId\=\K.+?(?=\&)')
#OPIS=$(echo $URL | grep -oP 'serial\=\K.+?(?=\&)')
#DELO=$(echo $URL | grep -oP 'group=\K.+?(?=\&)')
#mkdir -p "cgamo-$FOND-$OPIS-$DELO"

wget --load-cookies $1 --quiet -O ./$DPATH/$BOOKID-show.js $URL

#find correct #ID of the image list
key1=$(grep -oP 'curPage = \K.*?\.' ./$DPATH/$BOOKID-show.js | tr -d '.')
#find line number with image list
key2=$(awk "/${key1}/ {print FNR}" ./$DPATH/$BOOKID-show.js | head -1)
#format image list as single image per line + truncate unneeded symbols
CLEANL="./$DPATH/$BOOKID-image_list.txt"
tail -n +$key2 ./$DPATH/$BOOKID-show.js | head -n 1 | grep -oP '\x27\K.*?\x27,' | tr -d "', " > $CLEANL

NPAGES=`wc -l < $CLEANL`
echo  "Количество файлов: $NPAGES"

PAGEIDS=`cat $CLEANL`
PAGE=1
for  ID  in  $PAGEIDS ; do
  echo  "Загружаю файл $PAGE (из $NPAGES) ..."
  URL="https://arch.mosreg.ru/srv/private/imageViewer/image?url=$ID"
#  wget -U "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/112.0" --load-cookies $1 --quiet -O ./cgamo-$FOND-$OPIS-$DELO/cgamo-$FOND-$OPIS-$DELO-file-$(printf '%04d' "$PAGE").jpg  $URL
  wget -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:111.0) Gecko/20100101 Firefox/111.0" --load-cookies $1 --quiet -O ./$DPATH/cgamo-$BOOKID-$DELO-$(printf '%04d' "$PAGE").jpg  $URL
  if [ "$?" -ne  0 ]; then
  echo  "Unable to load the page ($URL)"
  exit  1
  fi
  let  PAGE=PAGE+1
done

rm "./$DPATH/$BOOKID-show.js"
rm "./$DPATH/$BOOKID-image_list.txt"
