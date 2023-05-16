#!/bin/bash

function setup_cmsenv(){
  source /cvmfs/cms.cern.ch/cmsset_default.sh
  if [ -r $1/src ] ; then
    echo release $1 already exists
  else
    scram p CMSSW $1
  fi
  cd $1/src
  eval `scram runtime -sh`
  scram b
  cd ../..
}

delete=<DELETE>
function delete_files() {
  local file=$1
  if [ -f "$file" ]; then
    if [ "$delete" = true ]; then
      echo "Delete $file"
      rm "$file"
    fi
  else
    echo "Error: $file is missing."
    exit 1
  fi
}

CHHH=$1
EVENTS=$2
PROCESS=$3

module use -a /afs/desy.de/group/cms/modulefiles/
source /cvmfs/cms.cern.ch/cmsset_default.sh
source /cvmfs/grid.desy.de/etc/profile.d/grid-ui-env.sh

export HOME="/afs/desy.de/user/a/paaschal"

GRIDPACKS="SUBGRIDPACK"
FRAGMENT="SUBFRAGMENT"
BASEDIR="SUBBASEDIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SECONDS=$(date +"%S%N")
SEED=`echo "526719+${PROCESS}" | bc`

echo "Start with"
echo "Coupling chhh"${CHHH}
echo "Events "${EVENTS}
echo "Fragment "${FRAGMENT}
echo "SEED "${SEED}

# Get x509up:
# Setup voms proxy and get info with `voms-proxy-info`
# Copie file to basedir
export X509_USER_PROXY=${BASEDIR}"/x509up_u30916"

echo $X509_USER_PROXY
voms-proxy-info || return 1

RUNDIR=files/run_$PROCESS
mkdir ${RUNDIR}
cd ${RUNDIR}

# Copy and prepare .py cfg files
cp ../../step1_GEN.py .
cp ../../step2_SIM.py .
cp ../../step3_DIGI2RAW.py .
cp ../../step4_HLT.py .
cp ../../step5_RECO.py .
cp ../../step6_MiniAOD.py .
cp ../../step7_NanoAOD.py .

export SCRAM_ARCH=slc7_amd64_gcc700
setup_cmsenv CMSSW_10_6_31

# Prepare Fragment
# * copy fragment to Configuration/GenProduction/python
# * replace the path with the path to the gridpack
mkdir -p CMSSW_10_6_31/src/Configuration/GenProduction/python/
cp ${BASEDIR}/fragment_template.py CMSSW_10_6_31/src/Configuration/GenProduction/python/${FRAGMENT}-fragment.py
sed -i -e 's@<GRIDPACKS>@'\'$GRIDPACKS\''@g' CMSSW_10_6_31/src/Configuration/GenProduction/python/${FRAGMENT}-fragment.py
sed -i -e 's/<CHHH>/'$CHHH'/g' CMSSW_10_6_31/src/Configuration/GenProduction/python/${FRAGMENT}-fragment.py
sed -i -e 's/<NEVENTS>/'$EVENTS'/g' CMSSW_10_6_31/src/Configuration/GenProduction/python/${FRAGMENT}-fragment.py
sed -i -e 's@<GRIDPACKS>@'\'$GRIDPACKS\''@g' step1_GEN.py
sed -i -e 's/<CHHH>/'$CHHH'/g' step1_GEN.py
sed -i -e 's/<NEVENTS>/'$EVENTS'/g' step1_GEN.py
sed -i -e 's/<RANDOMSEED>/'$SEED'/g' step1_GEN.py

cmsRun step1_GEN.py
cmsRun step2_SIM.py
cmsRun step3_DIGI2RAW.py

delete_files HIG-RunIISummer20UL17wmLHEGEN-00209_inLHE.root
delete_files HIG-RunIISummer20UL17wmLHEGEN-00209.root
delete_files HIG-RunIISummer20UL17SIM-00057.root

export SCRAM_ARCH=slc7_amd64_gcc630
setup_cmsenv CMSSW_9_4_14_UL_patch1

cmsRun step4_HLT.py
delete_files HIG-RunIISummer20UL17DIGIPremix-00057.root

export SCRAM_ARCH=slc7_amd64_gcc700
setup_cmsenv CMSSW_10_6_31

cmsRun step5_RECO.py
delete_files HIG-RunIISummer20UL17HLT-00057.root

cmsRun step6_MiniAOD.py
delete_files HIG-RunIISummer20UL17RECO-00057.root

cmsRun step7_NanoAOD.py
delete_files HIG-RunIISummer20UL17MiniAODv2-00225.root
