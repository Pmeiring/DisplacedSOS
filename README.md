# Setup instructions

We'll duplicate the setup used to produce central Higgsino N2N1 samples, but adding a displacement ctau. The production chain is found here:
https://cms-pdmv.cern.ch/mcm/requests?prepid=SUS-RunIIAutumn18NanoAODv7-00066
The same setup can be used for displaced TChiWZ. The central TChiWZ (prompt) production chain is found here:
https://cms-pdmv.cern.ch/mcm/requests?prepid=SUS-RunIIAutumn18NanoAODv7-00068


### Commands

```
export SCRAM_ARCH=slc6_amd64_gcc700
```
The above ARCH is the original, but running with that on cmsRun on cc7 crashes. Running on slc6 is not recommended and also crashed eoscp commands. Therefore switched to the ARCH below, run on cc7.

```
export SCRAM_ARCH=slc7_amd64_gcc700
cmsrel CMSSW_10_2_5
cp step*_cfg.py CMSSW_10_2_5/src/
cd CMSSW_10_2_5/src
cmsenv
scram b -j 8
cd ../..
cmsrel CMSSW_10_2_7
mkdir -p CMSSW_10_2_7/GenProduction/Configuration/python
mkdir -p CMSSW_10_2_7/src/GenProduction/Configuration/python
cp customized_fragment.py CMSSW_10_2_7/src/GenProduction/Configuration/python/customized_fragment.py
cd CMSSW_10_2_7/src
cmsenv
scram b -j 8
cd ../..
mkdir output
mkdir log
mkdir error
```