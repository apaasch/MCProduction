#!/bin/bash

# check that hadronizer fragment has subgridpack in the name instead of gridpack !!!

###
SUBMIT=true

### generic settings
CHHH=2p45
TAG=chhh${CHHH} # MYGRIDPACKSTUDIES
NJOBS=500   # irrelevant if input source lhe files     
NEVT=1000 
BASEDIR=/nfs/dust/cms/user/paaschal/WorkingArea/MCProduction/sgnl_production
TARBALLDIR=/nfs/dust/cms/user/paaschal/WorkingArea/MCProduction/tarballs/dihiggs/Run2UL
GRIDPACK=${TARBALLDIR}/ggHH_slc7_amd64_gcc700_CMSSW_10_6_31_chhh${CHHH}.tgz
FRAGMENT=HIG-RunIISummer20UL17wmLHEGEN-00209
OUTPUTFILE=chhh${CHHH}
OUTPUTDIR=dihiggs/chhh${CHHH}
DELETE=true

cd ${BASEDIR}
mkdir -p ${BASEDIR}/${OUTPUTDIR}/{logs,files}

cp step1_GEN.py ${OUTPUTDIR}
cp step2_SIM.py ${OUTPUTDIR}
cp step3_DIGI2RAW.py ${OUTPUTDIR}
cp step4_HLT.py ${OUTPUTDIR}
cp step5_RECO.py ${OUTPUTDIR}
cp step6_MiniAOD.py ${OUTPUTDIR}
cp step7_NanoAOD.py ${OUTPUTDIR}

### create job bash file 
cp template.sh ${TAG}.sh
sed -i -e "s|SUBGRIDPACK|${GRIDPACK}|g" ${TAG}.sh 
sed -i -e "s|SUBFRAGMENT|${FRAGMENT}|g" ${TAG}.sh 
sed -i -e "s|SUBBASEDIR|${BASEDIR}|g" ${TAG}.sh 
sed -i -e "s|<DELETE>|${DELETE}|g" ${TAG}.sh 
chmod +x ${TAG}.sh
mv ${TAG}.sh ${OUTPUTDIR}

### create file with job options 
cp condor.submit ${TAG}.submit 
sed -i -e "s|SUBTAG|${TAG}|g" ${TAG}.submit 
sed -i -e "s|SUBBASEDIR|${BASEDIR}|g" ${TAG}.submit 
sed -i -e "s|SUBDIR|${OUTPUTDIR}|g" ${TAG}.submit
sed -i -e "s|SUBNJOBS|${NJOBS}|g" ${TAG}.submit
sed -i -e "s|SUBNEVENTS|${NEVT}|g" ${TAG}.submit
sed -i -e "s|SUBRUNTIME|64800|g" ${TAG}.submit
sed -i -e "s|SUBCOUPLING|${CHHH}|g" ${TAG}.submit
mv ${TAG}.submit ${OUTPUTDIR}

cd ${OUTPUTDIR}

# submit job 
if [ "$SUBMIT" = true ]; then
    echo "condor_submit ${TAG}.submit"
    condor_submit ${TAG}.submit
else
    echo "Not submitting to conder."
    echo "Change settings in script if wanted"
fi
