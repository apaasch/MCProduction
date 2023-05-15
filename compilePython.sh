#!/bin/bash

# Based on from https://cms-pdmv.cern.ch/mcm/requests?member_of_chain=HIG-chain_RunIISummer20UL17wmLHEGEN_flowRunIISummer20UL17SIM_flowRunIISummer20UL17DIGIPremix_flowRunIISummer20UL17HLT_flowRunIISummer20UL17RECO_flowRunIISummer20UL17MiniAODv2_flowRunIISummer20UL17NanoAODv9-00212&page=0&shown=127

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

##########################
### setup CMSSW enviorment

BASEDIR=$(pwd)
FRAGMENT="HIG-RunIISummer20UL17wmLHEGEN-00209"
GRIDPACK="/nfs/dust/cms/user/paaschal/WorkingArea/MCproduction/tarballs/ggHH_slc7_amd64_gcc700_CMSSW_10_6_31_chhh1.tgz" 
EVENTS=12345 # Unique number
export SCRAM_ARCH=slc7_amd64_gcc700

setup_cmsenv CMSSW_10_6_31

mkdir -p CMSSW_10_6_31/src/Configuration/GenProduction/python
cp ${BASEDIR}/fragment_template.py CMSSW_10_6_31/src/Configuration/GenProduction/python/${FRAGMENT}-fragment.py

sed -i -e 's@<GRIDPACKS>@'\'$GRIDPACK\''@g' CMSSW_10_6_31/src/Configuration/GenProduction/python/${FRAGMENT}-fragment.py
sed -i -e 's/<NEVENTS>/'$EVENTS'/g' CMSSW_10_6_31/src/Configuration/GenProduction/python/${FRAGMENT}-fragment.py

CONDITION="106X_mc2017_realistic_v9"
BEAMSPOT="Realistic25ns13TeVEarly2017Collision"
ERA="Run2_2017"
SEED=98765 # Unique number

FILE_GEN="HIG-RunIISummer20UL17wmLHEGEN-00209"
FILE_SIM="HIG-RunIISummer20UL17SIM-00057"
FILE_DRPremix="HIG-RunIISummer20UL17DIGIPremix-00057"
FILE_HLT="HIG-RunIISummer20UL17HLT-00057"
FILE_Reco="HIG-RunIISummer20UL17RECO-00057"
FILE_Mini="HIG-RunIISummer20UL17MiniAODv2-00225"
FILE_Nano="HIG-RunIISummer20UL17NanoAODv9-00217"

# ##############################################
# ### Step 1 - Gen

# Random seed between 1 and 100 for externalLHEProducer

# In original --condition 106X_mc2017_realistic_v6 - Impact?
# cmsDriver.py Configuration/GenProduction/python/${FILE_GEN}-fragment.py --python_filename ${FILE_GEN}_1_cfg.py --eventcontent RAWSIM,LHE --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN,LHE --fileout file:${FILE_GEN}.root --conditions ${CONDITION} --beamspot ${BEAMSPOT} --step LHE,GEN --geometry DB:Extended --era ${ERA} --no_exec --mc -n $EVENTS || return $? ;
compile_step1() {
  cmsDriver.py Configuration/GenProduction/python/${FILE_GEN}-fragment.py --python_filename ${FILE_GEN}_1_cfg.py --eventcontent RAWSIM,LHE --customise Configuration/DataProcessing/Utils.addMonitoring --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${SEED})" --datatier GEN,LHE --fileout file:${FILE_GEN}.root --conditions ${CONDITION} --beamspot ${BEAMSPOT} --step LHE,GEN --geometry DB:Extended --era ${ERA} --no_exec --mc -n $EVENTS || return $? ;
  # Build template
  mv ${FILE_GEN}_1_cfg.py step1_GEN.py
  sed -i -e 's@'\'$GRIDPACK\''@<GRIDPACKS>@g' step1_GEN.py # @ for \' - necessary?
  sed -i -e 's/'$EVENTS'/<NEVENTS>/g' step1_GEN.py
  sed -i -e 's/'${SEED}'/<RANDOMSEED>/g' step1_GEN.py
}

# ##############################################
# ### Step 2 - SIM

# Name changes due to step
# Changing number ? (00209 - 00057)
# In original --condition 106X_mc2017_realistic_v6 - Impact?
compile_step2() {
  cmsDriver.py  --python_filename ${FILE_SIM}_1_cfg.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --fileout file:${FILE_SIM}.root --conditions ${CONDITION} --beamspot ${BEAMSPOT} --step SIM --geometry DB:Extended --filein file:${FRAGMENT}.root --era ${ERA} --runUnscheduled --no_exec --mc -n $EVENTS || return $? ;
  mv ${FILE_SIM}_1_cfg.py step2_SIM.py
}
# ###############################################
# ### Step 3 - DIGI2RAW

# In original --condition 106X_mc2017_realistic_v6 - Impact?
compile_step3() {
  cmsDriver.py  --python_filename ${FILE_DRPremix}_1_cfg.py --eventcontent PREMIXRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-DIGI --fileout file:${FILE_DRPremix}.root --pileup_input dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL17_106X_mc2017_realistic_v6-v3/PREMIX --conditions ${CONDITION}             --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --geometry DB:Extended --filein file:${FILE_SIM}.root --datamix PreMix --era ${ERA} --runUnscheduled --no_exec --mc -n $EVENTS || return $? ;
  mv ${FILE_DRPremix}_1_cfg.py step3_DIGI2RAW.py
}

# ###############################################
# ### Step 4 - HLT

# --step HLT:2e34v40
# 94X_mc2017_realistic_v15
# In original --condition 94X_mc2017_realistic_v15 - Impact?
compile_step4() {
  cmsDriver.py  --python_filename ${FILE_HLT}_1_cfg.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-RAW --fileout file:${FILE_HLT}.root --conditions 94X_mc2017_realistic_v15 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' --step HLT:2e34v40 --geometry DB:Extended --filein file:${FILE_DRPremix}.root --era ${ERA} --no_exec --mc -n $EVENTS || return $? ;
  mv ${FILE_HLT}_1_cfg.py step4_HLT.py
}

# ###############################################
# ### Step 5 - Reco

setup_cmsenv CMSSW_10_6_31
scram b
cd ../..

# In original --condition 106X_mc2017_realistic_v6 - Impact?
compile_step5() {
  cmsDriver.py  --python_filename ${FILE_Reco}_1_cfg.py --eventcontent AODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier AODSIM --fileout file:${FILE_Reco}.root --conditions ${CONDITION} --step RAW2DIGI,L1Reco,RECO,RECOSIM --geometry DB:Extended --filein file:${FILE_HLT}.root --era ${ERA} --runUnscheduled --no_exec --mc -n $EVENTS || return $? ;
  mv ${FILE_Reco}_1_cfg.py step5_RECO.py
}
# ###############################################
# ### Step 6 - MiniAOD

# In original --condition ${CONDITION} - Impact?
compile_step6() {
  cmsDriver.py  --python_filename ${FILE_Mini}_1_cfg.py --eventcontent MINIAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier MINIAODSIM --fileout file:${FILE_Mini}.root --conditions ${CONDITION} --step PAT --procModifiers run2_miniAOD_UL --geometry DB:Extended --filein file:${FILE_Reco}.root --era ${ERA} --runUnscheduled --no_exec --mc -n $EVENTS || return $? ;
  mv ${FILE_Mini}_1_cfg.py step6_MiniAOD.py
}

# ###############################################
# ### Step 7 - NanoAOD

# In original --condition ${CONDITION} - Impact?
compile_step7() {
  # cmsDriver.py  --python_filename ${FILE_Nano}_1_cfg.py --eventcontent NANOEDMAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier NANOAODSIM --fileout file:${FILE_Nano}.root --conditions ${CONDITION} --step NANO --filein file:${FILE_Mini}.root --era ${ERA},run2_nanoAOD_106Xv2 --no_exec --mc -n $EVENTS || return $? ;
  cmsDriver.py  --python_filename ${FILE_Nano}_1_cfg.py --eventcontent NANOAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier NANOAODSIM --fileout file:${FILE_Nano}.root --conditions ${CONDITION} --step NANO --filein file:${FILE_Mini}.root --era ${ERA},run2_nanoAOD_106Xv2 --no_exec --mc -n $EVENTS || return $? ;
  mv ${FILE_Nano}_1_cfg.py step7_NanoAOD.py
}

compile_all() {
  compile_step1
  compile_step2
  compile_step3
  setup_cmsenv CMSSW_9_4_14_UL_patch1
  scram b
  cd ../..
  compile_step4
  setup_cmsenv CMSSW_10_6_31
  scram b
  cd ../..
  compile_step5
  compile_step6
  compile_step7
}
