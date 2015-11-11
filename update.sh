#!/bin/bash

realpath() {
	readlink -f "$1"
}

MYDIR=$(realpath $(dirname $0))
BACKUPDIR=$(realpath $MYDIR/backups)
REVERT_SCRIPT=$(realpath $BACKUPDIR/revert.sh)

add_revert_line() {
	echo "[ -e \"$2\" ] && cp -vf \"$2\" \"$1\"" >> $REVERT_SCRIPT
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
			mv "$FILE_FROM_BACKUP" "$FILE_TO_BACKUP$i"
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
		backup_file "$2"
	}
	ln -fs "$MYDIR/$FILE_FROM" "$FILE_TO"
}

LIST_IN=$MYDIR/list.in
[ -e $LIST_IN ] && source $MYDIR/list.in

