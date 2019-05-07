#!/bin/bash

# Written by Nanbo Sun and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

###########################################
# Usage and Reading in Parameters
###########################################

# Usage
usage() { echo "
Usage: $0 -i <inDir> -d <idList> -s <scriptDir> -p <spmDir> [-q <queue>]
    Compute grey matter volumne and intracranial volumne.
    - inDir         Input directory of T1 images
    - idList        Text file with each line being the id of a subject
    - scriptDir     Script directory of current script
    - spmDir        SPM installation directory
    - queue         (Optional) if you have a cluster, use it to specify the 
                    queue to which you want to qsub these jobs; if not provided,
                    jobs will run serially (potentially very slow!)
" 1>&2; exit 1; }

# Reading in parameters
while getopts ":i:d:s:p:q:" opt; do
    case "${opt}" in
            i) inDir=${OPTARG};;
            d) idList=${OPTARG};;
            s) scriptDir=${OPTARG};;
            p) spmDir=${OPTARG};;
            q) queue=${OPTARG};;
            *) usage;;
        esac
done
shift $((OPTIND-1))
if [ -z "${inDir}" ] || [ -z "${idList}" ] || [ -z "${scriptDir}" ] || [ -z "${spmDir}" ]; then
    echo Missing Parameters!
    usage
fi

###########################################
# Main
###########################################

echo 'Step 9: Compute grey matter volumne and ICV.'

mkdir -p ${inDir}
logDir=${inDir}/logs/step9_compute_GM_ICV
mkdir -p ${logDir}
progressFile=${logDir}/progress.txt
> ${progressFile}

id=gm_icv
logFile=${logDir}/${id}.log
if [ -z "${queue}" ]; then
    matlab -nodisplay -nosplash -r \
    "spm_dir='${spmDir}';script_dir='${scriptDir}';\
    id_list='${idList}';output_dir='${inDir}';CBIG_MMLDA_compute_GM_ICV;exit;" > ${logFile}
    echo "Done" >> ${progressFile}
else
        qsub -V -q ${queue} << EOJ

#!/bin/sh
#PBS -N 'step9_compute_GM_ICV'
#PBS -l walltime=1:00:0
#PBS -l mem=8gb   
#PBS -e ${logDir}/${id}.err
#PBS -o ${logDir}/${id}.out
    
    cd ${scriptDir}

    matlab -nodisplay -nosplash -r \
    "spm_dir='${spmDir}';script_dir='${scriptDir}';\
    id_list='${idList}';output_dir='${inDir}';CBIG_MMLDA_compute_GM_ICV;exit;" > ${logFile}
    echo "Done" >> ${progressFile}
EOJ
fi

./CBIG_MMLDA_waitUntilFinished.sh ${progressFile} 

echo 'Step 9: Compute grey matter volumne and ICV. -- Finished.'
