#!/bin/bash

realpath() {
	readlink -f "$1"
}

MYDIR=$(realpath $(dirname $0))
BACKUPDIR=$(realpath $MYDIR/backups)
REVERT_SCRIPT=$(realpath $BACKUPDIR/revert.sh)

FAKE=""

run() {
	[ -n "$FAKE" ] && {
		echo "$1"
	}
	[ -n "$FAKE" ] || {
		echo "$1" | bash
	}
}

add_revert_line() {
	[ -n "$FAKE" ] && echo "[ -e \"$2\" ] && cp -vf \"$2\" \"$1\"" >> $REVERT_SCRIPT
}

backup_file() {
	local FILE_FROM_BACKUP="$1"
	local FILE_TO_BACKUP="$(basename $1)"
	FILE_TO_BACKUP="$(realpath $BACKUPDIR/${FILE_TO_BACKUP/./_})"

	[ -e "$FILE_FROM_BACKUP" ] || { return; }

	for i in '' $(seq 1 100) 
	do 
		[ -e "$FILE_TO_BACKUP$i" ] || {
			add_revert_line "$FILE_FROM_BACKUP" "$FILE_TO_BACKUP$i"
			${FAKE} mv "$FILE_FROM_BACKUP" "$FILE_TO_BACKUP$i"
			return
		} 
	done

	echo "too many backup files for $FILE_TO_BACKUP (>100)" >&2
	exit 1
}

install_file() {
	local FILE_FROM="$1"
	local FILE_TO="$2"

	echo "Update $2 configuration file"

	[ -L $FILE_TO ] || {
		echo "File $2 exists.... do backup to $MYDIR/backup/ folder."
		[ -n "$FAKE" ] && backup_file "$2"
	}
	${FAKE} ln -fs "$MYDIR/$FILE_FROM" "$FILE_TO"
}

patch_file() {
	local PATCHER="$MYDIR/$1"
	local INLINE="$MYDIR/$2"
	local FILE_TO="$3"

	echo "Update $3 configuration file"

	[ -e "$PATCHER" ] || {
		echo "Nothing to update. Patch functions are undefined"
		return
	}

	[ -e "$FILE_TO" ] || touch "$FILE_TO"

	# load scripts
	( 
		source "$PATCHER"

		need_update "$INLINE" "$FILE_TO" || {
			echo "File $3 exists and will be updated.... do backup to $MYDIR/backup/ folder."
			[ -n "$FAKE" ] && backup_file "$3"
		}

		update "$INLINE" "$FILE_TO"
	)
}

#
# TODO: add parse options
#

while getopts i OPT
do
	case "$OPT" in
	i)
		FAKE="echo "
	;;
	esac
done

LIST_IN=$MYDIR/list.in
[ -e $LIST_IN ] && source $MYDIR/list.in

