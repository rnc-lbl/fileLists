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


gitBaseFolder=/global/homes/j/jthaeder/picoDstTransfer/fileLists/

fileTypes="picoList  picoD0List"

for fileType in $fileTypes ; do  

    if [ "${fileType}" = "picoList" ] ; then
	baseFolder=/project/projectdirs/starprod/picodsts/Run14/AuAu/200GeV/physics2/P15ic
	fileExtensionType=picoDst
    elif [ "${fileType}" = "picoD0List" ] ; then
        baseFolder=/project/projectdirs/starprod/hft/d0tree/Run14/AuAu/200GeV/physics2/P15ic
	fileExtensionType=picoD0
    else
	exit 0
    fi

    outFolder=/project/projectdirs/starprod/picodsts/Run14/AuAu/200GeV/fileLists/physics2/${fileType}s
    if [ ! -d $outFolder ] ; then
        mkdir -p $outFolder
    fi

    gitPath=Run14/AuAu/200GeV/physics2/${fileType}s
    outFolderGIT=${gitBaseFolder}/${gitPath}
    if [ ! -d  $outFolderGIT ] ; then
	mkdir -p $outFolderGIT
    fi

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
    
    # ------------------------------------------------------
    # -- Find / loop over files
    # ------------------------------------------------------
    for day in `ls ${baseFolder} | sort` ; do 
	
	if [[ "${day}" = "preview2" ||  "${day}" = "fileLists" ]] ; then
	    continue
	fi
	
	for run in `ls ${baseFolder}/${day} | sort` ; do 
	    nFiles=`ls ${baseFolder}/${day}/${run} | wc -l`
	    if [ $nFiles -eq 0 ] ; then 
		continue
	    fi
	    
	    tmpRun=${tmpFolder}/runs/${fileType}_${day}_${run}.list
	    runEntry=${outFolderGIT}/runs/${fileType}_${day}_${run}.list
	    echo ${runEntry} >> ${tmpRunList} 
	    
	    find ${baseFolder}/${day}/${run} -name "*.${fileExtensionType}.root" | sort > ${tmpRun}
	    cat ${tmpRun} >> ${tmpAll}
	done
    done
    
    # ------------------------------------------------------
    # -- Clean up 1
    # ------------------------------------------------------
    if [ "${fileType}" = "picoList" ] ; then
	cp -r ${tmpAll} ${outFolder}
	cp -r ${tmpRunList} ${outFolder}
	cp -r ${tmpFolder}/runs ${outFolder}
    fi

    cp -r ${tmpAll} ${outFolderGIT}
    cp -r ${tmpRunList} ${outFolderGIT}
    cp -r ${tmpFolder}/runs ${outFolderGIT}
    
    # ------------------------------------------------------
    # -- Create an extra list of new files : "daily"
    # ------------------------------------------------------
    if [ ! -f ${yesterdayFile} ] ; then
	
	if [ "${fileType}" = "picoList" ] ; then
	    if [ ! -d ${outFolder}/daily ] ; then
		mkdir -p ${outFolder}/daily
	    fi
	fi

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
	if [ "${fileType}" = "picoList" ] ; then
	    cp -r ${tmpYesterdayFile} ${outFolder}/daily
	fi
	cp -r ${tmpYesterdayFile} ${outFolderGIT}/daily
    fi
    
    # ------------------------------------------------------
    # -- Clean up 2
    # ----------------------------------------------------
    rm -rf ${tmpFolder}

    if [ "${fileType}" = "picoList" ] ; then
	chmod 644 ${outFolder}/*.* 
	chmod 755 ${outFolder}/runs
	chmod 644 ${outFolder}/runs/*.* 
    fi

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
