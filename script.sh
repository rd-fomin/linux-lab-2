#!/usr/bin/env bash
lockfile=/tmp/lockfile

#Удаление lockfile и выход из программы
#На вход принимает параметр $1 - код выхода из скрипта
function remove_lockfile() {
	rm -f "$lockfile"
	trap - INT TERM EXIT
	exit $1
}

if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
then
    trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
    if [ -z "$1" ]
	then
		remove_lockfile 10
	fi
	file=$1
	set -eu
	if [ -r "$file" ]
	then
		temp=/tmp/lab2.tmp
		tempLastLog=/tmp/lab2lastlog.tmp
		current_data=$(date "+%d/%b/%Y:%T")
		echo "Текущая дата: $current_data"
		
		#Узнаем когда в последний раз анализировали файл		
		if [ -f $temp ]
		then
			last_data=$(cat $temp | tail -n 1)
			echo "Прошлая дата анализа: $last_data"
		fi
		
		last_log=0
		
		#Узнаем до какой сточки проанализировали файл
		if [ -s $tempLastLog ]
		then
			last_log=$(cat $tempLastLog | tail -n 1)
			#last_log=$( tac $1 | awk '{  if ( $1!="logs") print 0 ; else print $2 }' )
			
		fi
		#Нахадим сколько логов добавилось после последнего анализа
		count_logs=$(cat $1 | wc -l)
		range=$(($count_logs-$last_log))
		echo "Новых записей: $range"
		
		if [ $range -le 0 ]
		then
			#echo "В файле $1 нет новых записей"
			echo $current_data >> $temp
			remove_lockfile 0
		fi
		
		FIRST=$(tail -n $range $1 | awk '{print $4}' | sort -r| head -n 1 | tail -c 21)
		SECOND=$(tail -n $range $1 | awk '{print $4}' | sort | head -n 1 | tail -c 21)
		echo "Обработанный временной диапазон:"
		echo "$FIRST - $SECOND"
		echo ""
		
		echo "Топ 15 IP-адерсов:"
		tail -n $range $1 | awk '{print $1}' | sort | uniq -c |sort -r -nk1 | head -n 15
		echo ""
		
		echo "Топ 15 Ресурсов сайта:"
		tail -n $range $1 | awk '{print $7}' | sort | uniq -c |sort -r -nk1 | head -n 15
		echo ""
		
		echo "Список всех кодов возврата:"
		tail -n $range $1 | awk '{print $9}' | sort | uniq -c |sort -r -nk1 | head -n 15
		
		echo "Список кодов возврата 4xx и 5xx:"
		tail -n $range $1 | awk '{print $9}' logs | awk '/[45]../{print $0}' | sort | uniq -c |sort -r -nk1 | head -n 15
	
		echo $current_data >> $temp
		echo "$count_logs" >> $tempLastLog
		#echo "$1 $count_logs" >> $tempLastLog
		
	else
		remove_lockfile 20
	fi
	set +eu
	remove_lockfile 0
else
   echo "Failed to acquire lockfile: $lockfile"
fi
