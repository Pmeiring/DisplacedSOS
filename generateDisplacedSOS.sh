#!/bin/bash
#
#  usage: $0 nEvents /store/path/output_file.root fragment.py[TChiWZ_ZToLL_Disp_fragment.py,SMS-N2N1-higgsino_Disp_fragment.py] mN2 mLSP cTau0 LUMIBLOCK
#  ./generateDisplacedSOS.sh 10 /eos/cms/store/user/pmeiring/DisplacedSOS/Test_mN2_100_mN1_95_ctau_10/events.root customized_fragment.py 100 95 10 1
TMPDIR=$PWD
#### ENV
# SRC71=/afs/cern.ch/work/p/pmeiring/private/CMS/DisplacedSOSproduction/CMSSW_7_1_30/src
SRC1027X=/afs/cern.ch/work/p/pmeiring/private/CMS/DisplacedSOSproduction/CMSSW_10_2_7/src
SRC1025X=/afs/cern.ch/work/p/pmeiring/private/CMS/DisplacedSOSproduction/CMSSW_10_2_5/src

STEP1=step1_cfg.py
STEP2=step2_cfg.py
STEP3=step3_cfg.py

EVENTS="process.maxEvents.input = cms.untracked.int32($1)"
NEVENTS=$1
echo "Will produce $1 events"
shift;

OUTFILE=$1
OUTBASE=$(basename $OUTFILE .root)
echo "Will write to $OUTFILE";
shift;

FRAGMENT=$1; shift
MN2=$1; shift
MLSP=$1; shift
CTAU0=$1; shift
LUMIBLOCK=$1; shift

## Create output directories
OUTDIR=$(dirname $OUTFILE)
eos ls $OUTDIR || eos mkdir -p $OUTDIR
OUTAOD=${OUTDIR/MINIAODSIM/AODSIM};
eos ls $OUTAOD || eos mkdir -p $OUTAOD

# ##############################################################   STEP 0 (0/1) ##############################################################
cd $SRC1027X; 
mkdir jobs
export SCRAM_ARCH=slc7_amd64_gcc700
eval $(scramv1 runtime -sh)
cd $TMPDIR;

echo "${MN2},${MLSP},${CTAU0}" > masspoint.txt 
# cp ${FRAGMENT} Configuration/GenProduction/python/${FRAGMENT}
# # cmsDriver.py Configuration/GenProduction/python/${FRAGMENT} --fileout file:step0.root --mc --eventcontent RAWSIM --customise SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1,Configuration/DataProcessing/Utils.addMonitoring --datatier GEN --conditions MCRUN2_71_V1::All --beamspot Realistic50ns13TeVCollision --step LHE,GEN --magField 38T_PostLS1 --python_filename $TMPDIR/$OUTBASE.step0_cfg.py --no_exec -n ${NEVENTS}
cmsDriver.py GenProduction/Configuration/${FRAGMENT} --python_filename $TMPDIR/$OUTBASE.step0_cfg.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --fileout file:step0.root --conditions 102X_upgrade2018_realistic_v11 --beamspot Realistic25ns13TeVEarly2018Collision --customise_commands "process.source.numberEventsInLuminosityBlock = cms.untracked.uint32(10)" --step GEN,SIM --geometry DB:Extended --era Run2_2018 --mc --no_exec -n ${NEVENTS}

cat >> $OUTBASE.step0_cfg.py <<_EOF_
## If needed, select events to process
process.MessageLogger.cerr.FwkReport.reportEvery = 100
$EVENTS
process.source.firstLuminosityBlock = cms.untracked.uint32(${LUMIBLOCK})
## Scramble
import random
rnd = random.SystemRandom()
for X in process.RandomNumberGeneratorService.parameterNames_(): 
   if X != 'saveFileName': getattr(process.RandomNumberGeneratorService,X).initialSeed = rnd.randint(1,99999999)
_EOF_

cmsRun $OUTBASE.step0_cfg.py
gzip $OUTBASE.step0_log && cp -v $OUTBASE.step0_log.gz $SRC1027X/jobs/
test -f $TMPDIR/step0.root || exit 11
edmFileUtil --ls file:$TMPDIR/step0.root | grep events        || exit 12
edmFileUtil --ls file:$TMPDIR/step0.root | grep ', 0 events'  && exit 13

# # copy, and retry on failure
echo $TMPDIR/step0.root
eos cp $TMPDIR/step0.root $OUTDIR/$OUTBASE.step0.root
if eos ls $OUTDIR/$OUTBASE.step0.root; then
    echo "Copied ok"
else
    eos cp $TMPDIR/step0.root $OUTDIR/$OUTBASE.step0.root
fi;

# ##############################################################   STEP 0 (1/1) ##############################################################



# ##############################################################   STEP 1 (0/1) ##############################################################
cd $SRC1025X; 
mkdir jobs
export SCRAM_ARCH=slc7_amd64_gcc700
eval $(scramv1 runtime -sh)
cd $TMPDIR;

# To be added when doing pu mixing: "--pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW"
# To be added when doing pu mixing: "--pileup_input "dbs:myPrePremixList.txt"
# To be added when doing pu mixing: "--pileup_input "filelist:/eos/cms/store/user/pmeiring/DisplacedSOS/PUmix/1C56C5CD-24BC-A841-A5D5-FD70C468F890.root"
# cmsDriver.py --python_filename $TMPDIR/$OUTBASE.step1_cfg.py --eventcontent PREMIXRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-RAW --fileout file:step1.root --conditions 102X_upgrade2018_realistic_v15 --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:@relval2018 --procModifiers premix_stage2 --geometry DB:Extended --filein file:step0.root --datamix PreMix --era Run2_2018 --no_exec --mc -n ${NEVENTS}
# cmsDriver.py --python_filename $TMPDIR/$OUTBASE.step1_cfg.py --eventcontent PREMIXRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-RAW --fileout file:step1.root --pileup_input "filelist:/eos/cms/store/user/pmeiring/DisplacedSOS/PUmix/1C56C5CD-24BC-A841-A5D5-FD70C468F890.root" --conditions 102X_upgrade2018_realistic_v15 --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:@relval2018 --procModifiers premix_stage2 --geometry DB:Extended --filein file:step0.root --datamix PreMix --era Run2_2018 --no_exec --mc -n ${NEVENTS}

cat $SRC1025X/$STEP1 > $TMPDIR/$OUTBASE.step1_cfg.py

echo "process.source.fileNames = [ 'file:step0.root' ]" >> $OUTBASE.step1_cfg.py
cat >> $OUTBASE.step1_cfg.py <<_EOF_
## If needed, select events to process
$EVENTS
## Scramble
import random
rnd = random.SystemRandom()
for X in process.RandomNumberGeneratorService.parameterNames_(): 
   if X != 'saveFileName': getattr(process.RandomNumberGeneratorService,X).initialSeed = rnd.randint(1,99999999)
_EOF_
echo running
cmsRun -e -j $OUTBASE.step1_report.xml $OUTBASE.step1_cfg.py | tee $OUTBASE.step1_log
# cmsRun $OUTBASE.step1_cfg.py 2>&1 | tee $OUTBASE.step1_log
gzip $OUTBASE.step1_log && cp -v $OUTBASE.step1_log.gz $SRC1025X/jobs/
echo zipping
test -f $TMPDIR/step1.root || exit 11
edmFileUtil --ls file:$TMPDIR/step1.root | grep events        || exit 12
echo listing
edmFileUtil --ls file:$TMPDIR/step1.root | grep ', 0 events'  && exit 13
# ##############################################################   STEP 1 (1/1) ##############################################################




# ##############################################################   STEP 2 (0/1) | ##############################################################
# cmsDriver.py  --python_filename $TMPDIR/$OUTBASE.step2_cfg.py --eventcontent AODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier AODSIM --fileout file:step2.root --conditions 102X_upgrade2018_realistic_v15 --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI --procModifiers premix_stage2 --filein file:step1.root --era Run2_2018 --runUnscheduled --no_exec --mc -n ${NEVENTS}
cat $SRC1025X/$STEP2 > $TMPDIR/$OUTBASE.step2_cfg.py

cat >> $OUTBASE.step2_cfg.py <<_EOF_
## If needed, select events to process
$EVENTS
## Scramble
import random
rnd = random.SystemRandom()
for X in process.RandomNumberGeneratorService.parameterNames_(): 
   if X != 'saveFileName': getattr(process.RandomNumberGeneratorService,X).initialSeed = rnd.randint(1,99999999)
_EOF_

# test -f $TMPDIR/step2.root || cmsRun -e -j $OUTBASE.step2_report.xml $OUTBASE.step2_cfg.py
cmsRun -e -j $OUTBASE.step2_report.xml $OUTBASE.step2_cfg.py
# ##############################################################   STEP 2 (1/1) ##############################################################





# ##############################################################   STEP 3 (0/1) | ##############################################################
# cmsDriver.py  --python_filename $TMPDIR/$OUTBASE.step3_cfg.py --eventcontent MINIAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier MINIAODSIM --fileout file:step3.root --conditions 102X_upgrade2018_realistic_v15 --step PAT --geometry DB:Extended --filein file:step2.root --era Run2_2018 --runUnscheduled --no_exec --mc -n ${NEVENTS}
cat $SRC1025X/$STEP3 > $TMPDIR/$OUTBASE.step3_cfg.py

cat >> $OUTBASE.step3_cfg.py <<_EOF_
## If needed, select events to process
$EVENTS
## Scramble
import random
rnd = random.SystemRandom()
for X in process.RandomNumberGeneratorService.parameterNames_(): 
   if X != 'saveFileName': getattr(process.RandomNumberGeneratorService,X).initialSeed = rnd.randint(1,99999999)
_EOF_

cmsRun -e -j $OUTBASE.step3_report.xml $OUTBASE.step3_cfg.py
# ##############################################################   STEP 3 (1/1) ##############################################################


# # copy, and retry on failure
echo $TMPDIR/step3.root
eos cp $TMPDIR/step3.root $OUTDIR/$OUTBASE.step3.root
if eos ls $OUTDIR/$OUTBASE.step3.root; then
    echo "Copied ok"
else
    eos cp $TMPDIR/step3.root $OUTDIR/$OUTBASE.step3.root
fi;