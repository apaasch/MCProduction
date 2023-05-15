#!/bin/bash

function setup_local_cmsenv(){
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
