#!/bin/sh


if [ "$#" -ne "1" ];then
	echo $0 xxx.md
	exit
fi

pandoc_md.sh $1

html=${1%.*}.html

begin=`grep "id=\"main\"" $html -n`

if [ -n "$begin" ];then
	line=${begin%%:*}
	line=$(($line-1))
	sed -i "1, $line"d $html
fi

finish=`grep "</body" $html -n`

if [ -n "$finish%%:*" ];then
	line=${finish%%:*}
	sed -i "$line,"'$d' $html
fi

cat .head > $html-tmp
cat $html >> $html-tmp
cat .tail >> $html-tmp

cp $html-tmp $html

rm $html-tmp
