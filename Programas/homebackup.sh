#!/bin/bash
MAQUINA=$(hostname)
YO=$(whoami)
ITER=$(($(date +"%-V") % 3))
HOY=$(date +"%Y%m%d")
if [ ! -f /home/$YO/mybackup.ini ]
then
  echo UltimaEjecucion=0 > /home/$YO/mybackup.ini
fi
ULTIMO=$(awk -F "=" '/UltimaEjecucion/ {print $2}' /home/$YO/mybackup.ini)
if [ ! -d /media/$YO/adata/Backup/$MAQUINA ]
then
  mkdir /media/$YO/adata/Backup/$MAQUINA
fi
if [ ! -d /media/$YO/adata/Backup/$MAQUINA/$ITER ]
then
  mkdir /media/$YO/adata/Backup/$MAQUINA/$ITER
fi
if [ -d /media/$YO/adata/Backup/$MAQUINA/$ITER ]
then
  if [ $HOY != $ULTIMO ] 
  then
    until [[ -z $(ps --no-headers -C rsync) ]]; do
      sleep 60
    done
    export DISPLAY=:0 && notify-send MyBackup "Iniciando Backup."
    echo UltimaEjecucion=$HOY > /home/$YO/mybackup.ini
    num_files=$(rsync -ni -az --max-size=1g --delete-delay --exclude=".*" /home/ /media/$YO/adata/Backup/$MAQUINA/$ITER/ 2>&1 | wc -l)
    num_files=$((num_files-3))
    echo $num_files
rsync_progress_awk="{
	if (\$0 ~ /:/) {
		last_speed=\$(NF-3)
	}
	else {
		print \"#Ejecutando... \" files \"/\" $num_files \" - \" last_speed;
		files++;
		print files/$num_files*100 \"%\";
	}
	fflush();
}
END {
	print \"#Done, \" files \" changes, \" last_speed
}"
    #print \"#\" \" - \" files \"/\" $num_files \" - \" last_speed;
    #print \"#\" \" - \" files \"/\" $num_files;
    #print \"#\" \$0 \" - \" files \"/\" $num_files \" - \" last_speed;
    rsync -az --max-size=1g --delete-delay --progress --exclude=".*" /home/ /media/$YO/adata/Backup/$MAQUINA/$ITER/ | awk "$rsync_progress_awk" | zenity --no-cancel --progress --auto-close --width=350 --title="MyBackup" || exit 4
    #rsync $rsync_opts --delete-delay --progress "$source" "$dest" 
    echo Completado $(date) > /media/$YO/adata/Backup/$MAQUINA/$ITER/mybackup.log
    export DISPLAY=:0 && notify-send MyBackup "Backup terminado."  
  fi  
fi  
