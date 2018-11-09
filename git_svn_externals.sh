#!/bin/bash
PROJECT_ROOT=$PWD
VERBOSE=y
#echo "It will get&update $PROJECT_ROOT"

function git_svn_update() {

	cd "$1" || return 1
	while true
	do
		if git svn rebase > /dev/null
		then
	 		echo "update $1 ok !!"
	 		break
		else
	 		echo "update $1 error !!"
			git st
			echo " re|reset for git reset"
			echo " la|late for do nothing"
			echo " st|stash git stash"
			echo " how you choose:"
			read cmd
			case "$cmd" in
			   	re*) git reset --hard
					;;
			   	la*) echo "$3" >> late.log
					break
				;;
			   	st*) git stash
				;;
			esac
			echo "contine after <$cmd>"
		fi
	done
	return 0
}

function git_svn_externals_clone() {
	[ $# -lt 3 ] && return 0
	#echo "=======clone $4$2 into $PROJECT_ROOT$1/$3 of $3======="
	#return 0
	cd "$PROJECT_ROOT/$1" || (echo "$1$3" error;return -1;)
	if [ -d "$3/.git" ] 
	then 
		echo ">>>>>> update $1/$3 from $4$2"
		git_svn_update "$3"
	else
		echo "++++++ clone  $1/$3 from $4$2"
		git svn clone "$4$2" "$3" 
	fi
}

function parse_args_execute() {
	SCHEME=`echo "$1" | grep -oE '\w*://|\^/|//'`
	case "$SCHEME" in
		*://)
			#echo "://"
			git_svn_externals_clone `echo "$1" | sed 's#\(^.*\)/\(.\{2,4\}://.*\) \(.*\)#\1 \2 \3#'`
			;;
		^/) 
			#echo "^^^^"
			git_svn_externals_clone `echo "$1" | sed 's#\(^.*\)/\^\(/.*\) \(.*\)#\1 \2 \3#'` "$REPOSITORY_ROOT"
			
			;;
		*) 
			echo "**** $1"
			;;
	esac
}


REPOSITORY_ROOT=`git svn info 2>&1 | grep  "Repository Root: " | sed "s#Repository Root: \(.*\)#\1#"`
if [ -z "$REPOSITORY_ROOT" ]
then
	echo "It's not a git on svn, please check it"
	exit 1
fi

I=0
while read line;
do 
	#echo "$I ==> $line"
	AS[$I]="$line"
	let I++
done < <(git svn show-externals| grep "^/")

#echo "TOTAL $I ==> ${AS[*]}"
i=0
while [ $i -lt $I ]
do
	#echo "$i = ${AS[$i]}"
	let i++
	parse_args_execute "${AS[$i]}"
done
