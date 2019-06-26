#!/bin/bash
PROJECT_ROOT=`git rev-parse --show-toplevel`
VERBOSE=y
#echo "It will get&update $PROJECT_ROOT"
function message(){
	[ "$VERBOSE" = y ] && echo $*
}


function git_svn_externals_clone() {
	[ $# -lt 3 ] && return 0
	#echo "=======clone $4$2 into $PROJECT_ROOT$1/$3 of $3======="
	#return 0
	SUB_REPO_URL="$4$2"
	SUB_REPO_NAME="$3"
	SUB_REPO_REL_PATH="$1/$3"
	SUB_REPO_ABS_ROOT="$PROJECT_ROOT$1"
	SUB_REPO_CTRL=""
	if echo "$SUB_REPO_URL" | grep "@" 
	then
		 SUB_REPO_REV="${SUB_REPO_URL##*@}"
		 SUB_REPO_URL="${SUB_REPO_URL%%@*}"
		 SUB_REPO_CTRL="-r $SUB_REPO_REV"
		 echo ">>>>>> REVISON  SUB_REPO_URL=$SUB_REPO_URL SUB_REPO_REV=$SUB_REPO_REV SUB_REPO_CTRL=$SUB_REPO_CTRL"
	fi

	[ -d "$SUB_REPO_ABS_ROOT" ] || (echo "$1$3" error;return -1;)
	while true
	do
		if [ -d "$SUB_REPO_ABS_ROOT/$SUB_REPO_NAME/.git" ] 
		then 
			echo ">>>>>> update $SUB_REPO_ABS_ROOT/$SUB_REPO_NAME"
			cd "$SUB_REPO_ABS_ROOT/$SUB_REPO_NAME"
			git svn fetch $SUB_REPO_CTRL
			if git svn rebase -l > /dev/null
			then
		 		echo "update $SUB_REPO_REL_PATH ok !!"
		 		break
			else
		 		echo '''
	update $SUB_REPO_REL_PATH error !!
	>>>>>====================================================>'''
				git status
				echo '''
	<<<<<====================================================>
here some suguestion:
 cl|clean it will do "git reset --hard"
 st|stash it will do "git stash"
 sk|skip  it will do nothing, then you can check it at late
 re|reinit & download, it same as "remove it clone from remote " 
please input:'''
				read cmd
				case "$cmd" in
				   	cl*) git reset --hard
						;;
				   	ig*) echo "$3" >> late.log
						break
						;;
				   	st*) git stash
						;;
					re*) cd "$SUB_REPO_ABS_ROOT" && rm -rf "$SUB_REPO_NAME"
						;;
				esac
				echo "contine after <$cmd>"
			fi
		else
			echo "++++++ clone  $SUB_REPO_ABS_ROOT/$SUB_REPO_NAME from $SUB_REPO_URL"
			[ -d "$SUB_REPO_ABS_ROOT" ] || mkdir -p "$SUB_REPO_ABS_ROOT"
			cd "$SUB_REPO_ABS_ROOT" && git svn clone "$SUB_REPO_URL" "$SUB_REPO_NAME" $SUB_REPO_CTRL && break
		fi
	done
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


set -- `getopt f:vl "$@"`

while [ $# -gt 0 ]
do
        echo $1
        shift
done
