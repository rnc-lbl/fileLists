#!/bin/bash


while read -r line ; do

  infile=` grep -l $line daily/*.list`
  if [ $? -eq 0 ] ; then
      echo "rm from $infile : $line"
      grep -v $line $infile > tmp.x
      mv tmp.x $infile
  fi

  infile=` grep -l $line runs/*.list`
  if [ $? -eq 0 ] ; then
      echo "rm from $infile : $line"
      grep -v $line $infile > tmp.x
      mv tmp.x $infile
  fi

  infile=` grep -l $line picoList_all.list`
  if [ $? -eq 0 ] ; then
      echo "rm from $infile : $line"
      grep -v $line $infile > tmp.x
      mv tmp.x $infile
  fi

done < <(cat faulty.txt)







exit


touch faulty.txt

while read -r line ; do

    if [ ! -s $line ] ; then 
#	echo $line
	echo $line >> faulty.txt
	rm $line
   fi
done < <(cat picoList_all.list)
