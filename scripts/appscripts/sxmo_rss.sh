#!/usr/bin/env sh
SFEEDCONF=/usr/share/sxmo/sxmo_sfeedrc

tflt() {
  # Date with feature like "1 day ago" etc main reason
  # coreutils is a dep...
  TIME=$(eval date -d \""$TIMESPAN"\" +%s)
  cat | gawk "\$1 > $TIME"
}

prep_temp_folder_with_items() {
    mkdir -p $FOLDER
    rm -rf $FOLDER/*
    cd ~/.sfeed/feeds/
    for f in $(ls)
    do
      cat $f | tflt $@ > $FOLDER/$f
      [ -s $FOLDER/$f ] || rm $FOLDER/$f
    done
}

list_items() {
    cd $FOLDER
    gawk -F'\t' '{print $1 " " FILENAME " | " $2 ": " $3}' * |\
    grep -E '^[0-9]{5}' |\
    sort -nk1 |\
    sort -r |\
    gawk -F' ' '{printf strftime("%y/%m/%d %H:%M",$1); $1=""; print $0}'
}

# Update Sfeed
st -e sh -c "echo Syncing Feeds && sfeed_update $SFEEDCONF"

# Dmenu prompt for timespan
TIMESPAN=$(
echo "1 hour ago
3 hours ago
12 hours ago
1 day ago
2 day ago
1970-01-01" | dmenu -p "RSS Timespan" -c -l 10 -fn Terminus-20
)

# Make folder like /tmp/sfeed_1_day_ago
FOLDER="/tmp/sfeed_$(echo "$TIMESPAN" | sed 's/ /_/g')"
prep_temp_folder_with_items

# Show list of items
PICKED=$(list_items | dmenu -p "RSS" -c -l 20 -fn Terminus-15)

# Handle picked item
URL="$(echo "$PICKED" | gawk -F " " '{print $NF}')"
sxmo_urlhandler.sh "$URL"
