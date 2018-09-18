#!/bin/bash
PROJECT_ROOT=$PWD

#sed "s?\(^.*\)\(http.*\) \(.*\)?cd $PWD\1\; [ -d \3 ] || git svn clone \"\2\" \3 || exit \$\??g" 
#sed "s?\(^.*\)\(http.*\) \(.*\)?\1 \2 \3?g" externals.txt > tmp.txt

function git_svn_externals_clone() {
	[ $# -lt 3 ] && return 0
	#echo "=======clone $2 into $PROJECT_ROOT$1$3 ======="
	cd "$PROJECT_ROOT/$1" || (echo "$1$3" error;return -1;)
	if [ -d "$3/.git" ] 
	then 
		echo ".$1$3 already done"
		return 0
	else
		git svn clone "$2" "$3" 
	fi
}
 
git svn show-externals | sed 's?\(^.*\)\(http.*\) \(.*\)?\1 \2 \3?g' | while read line;
do 
	git_svn_externals_clone $line;
done
