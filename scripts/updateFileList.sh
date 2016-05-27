#!/bin/bash

# Make fileLists for picoDsts and picoD0trees
#
# #############################################
#  Authors:
#
#    Mustafa Mustafa (mmustafa@lbl.gov),
#    Jochen Thaeder  (jmthader@lbl.gov)
#
# #############################################


if [ -f /project/projectdirs/starprod/picodsts/Run14/AuAu/200GeV/physics2/${prodId}/st_physics_15140004_raw_1000016.picoDst.root ] ; then 
    rm /project/projectdirs/starprod/picodsts/Run14/AuAu/200GeV/physics2/${prodId}/st_physics_15140004_raw_1000016.picoDst.root
fi

gitBaseFolder=/global/homes/j/jthaeder/picoDstTransfer/fileLists/

prodTypes="picoList_14_200 picoList_14_14.5 picoD0List picoNpeList"


for prodType in $prodTypes ; do  
    echo "Processing: $prodType"

    if [ "${prodType}" = "picoList_14_200" ] ; then
	fileType=picoList
	fileExtensionType=picoDst
 	prodId=P16id
	picoId=physics2
	energy=200GeV
	baseFolder=/project/projectdirs/starprod/picodsts/Run14/AuAu/${energy}/${picoId}/${prodId}

    elif [ "${prodType}" = "picoList_14_14.5" ] ; then
	fileType=picoList
	fileExtensionType=picoDst
 	prodId=P14ii
	picoId=Pico16b
	energy=15GeV
	baseFolder=/project/projectdirs/starprod/picodsts/Run14/AuAu/${energy}/${picoId}/${prodId}
    elif [ "${prodType}" = "picoD0List" ] ; then
	fileType=picoD0List
	fileExtensionType=picoD0
 	prodId=P16id
	picoId=Pico16a
	energy=200GeV
        baseFolder=/project/projectdirs/starprod/hft/Run14/AuAu/${energy}/${picoId}/${prodId}/D0

    elif [ "${prodType}" = "picoNpeList" ] ; then
	fileType=picoNpeList
	fileExtensionType=picoNpe
 	prodId=P16id
	picoId=Pico16a
	energy=200GeV
        baseFolder=/project/projectdirs/starprod/hft/Run14/AuAu/${energy}/${picoId}/${prodId}/NPE
    else
	exit 0
    fi

    gitPath=Run14/AuAu/${energy}/${picoId}/${prodId}/${fileType}s
    outFolderGIT=${gitBaseFolder}/${gitPath}
    if [ ! -d  $outFolderGIT ] ; then
	mkdir -p $outFolderGIT
    fi

    touch faulty_files.txt

    # ------------------------------------------------------
    # -- Create temporary files
    # ------------------------------------------------------
    tmpFolder=`mktemp -d`
    mkdir -p ${tmpFolder}/runs

    tmpAll=${tmpFolder}/${fileType}_all.list
    touch $tmpAll
    
    tmpRunList=${tmpFolder}/${fileType}_runList.list
    touch $tmpRunList
    
    yesterday=`date --date="1 days ago" '+%F'`
    yesterdayFile=${outFolderGIT}/daily/${fileType}_${yesterday}.list
    
    tmpYesterdayFile=${tmpFolder}/${fileType}_${yesterday}.list
    touch  $tmpYesterdayFile

    tmpFaultyFiles=${tmpFolder}/${fileType}_faulty.list
    touch  $tmpFaultyFiles
    
    # ------------------------------------------------------
    # -- Find / loop over files
    # ------------------------------------------------------
    for day in `ls ${baseFolder} | sort` ; do 
	for run in `ls ${baseFolder}/${day} | sort` ; do 
	    nFiles=`ls ${baseFolder}/${day}/${run} | wc -l`
	    if [ $nFiles -eq 0 ] ; then 
		continue
	    fi
	    
	    tmpRun=${tmpFolder}/runs/${fileType}_${day}_${run}.list
	    runEntry=${outFolderGIT}/runs/${fileType}_${day}_${run}.list
	    echo ${runEntry} >> ${tmpRunList} 
	    
	    find ${baseFolder}/${day}/${run} -name "*.${fileExtensionType}.root" -type f ! -size 0 | sort > ${tmpRun}
	    find ${baseFolder}/${day}/${run} -name "*.${fileExtensionType}.root" -type f -size 0 | sort >> ${tmpFaultyFiles}

	    cat ${tmpRun} >> ${tmpAll}
	done
    done
    
    # ------------------------------------------------------
    # -- Clean up 1
    # ------------------------------------------------------
    cat  ${tmpFaultyFiles} >> faulty_files.txt

    cp -r ${tmpAll} ${outFolderGIT}
    cp -r ${tmpRunList} ${outFolderGIT}
    cp -r ${tmpFolder}/runs ${outFolderGIT}
    
    # ------------------------------------------------------
    # -- Create an extra list of new files : "daily"
    # ------------------------------------------------------
    if [ ! -f ${yesterdayFile} ] ; then
	
	if [ ! -d ${outFolderGIT}/daily ] ; then
	    mkdir -p ${outFolderGIT}/daily
	fi
	
	cat ${outFolderGIT}/daily/${fileType}_*.list > ${tmpFolder}/${fileType}UpToYesterday.list
	
	while read -r line ; do 
	    grep ${line} ${tmpFolder}/${fileType}UpToYesterday.list > /dev/null
	    ret=$?
	    
	    if [ ${ret} -eq 0 ] ; then
		continue
	    fi
	    echo $line  >> ${tmpYesterdayFile}
	    
	done < <(cat ${tmpAll})

	nNewFiles=`cat ${tmpYesterdayFile} | wc -l`
	if [ $nNewFiles -ne 0 ] ; then
	    cp -r ${tmpYesterdayFile} ${outFolderGIT}/daily
	fi
    fi
    
    # ------------------------------------------------------
    # -- Clean up 2
    # ----------------------------------------------------
    rm -rf ${tmpFolder}

    chmod 644 ${outFolderGIT}/*.* 
    chmod 755 ${outFolderGIT}/runs
    chmod 644 ${outFolderGIT}/runs/*.* 
    
    # ------------------------------------------------------
    # -- Commit changes to git
    # ------------------------------------------------------
    now=`date '+%F %H-%M'`
    
    pushd ${gitBaseFolder}  > /dev/null
    /usr/bin/git add ${gitPath}
    /usr/bin/git commit ${gitPath} -m "automatic update ${fileType}s - ${now}"
    popd > /dev/null
done

pushd ${gitBaseFolder}  > /dev/null
/usr/bin/git pull origin master
/usr/bin/git push
popd > /dev/null
