# export SCRAM_ARCH=slc6_amd64_gcc700
# The above ARCH is the OG, but running with that on cmsRun on cc7 crashes. Running on slc6
# is not recommended and also crashed eoscp commands. Therefore switched to the ARCH below, run on cc7.
export SCRAM_ARCH=slc7_amd64_gcc700
cmsrel CMSSW_10_2_5
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