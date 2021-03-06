unit GSTypes;

interface
uses
  SysUtils, Windows, Messages, Classes, UProject;


type  TExptdTypeCodes = (gemNone, gemNumber, gemPosNumber, gemNoSpace); // Same as Lew L    TEditMask // Types of restrictions on an esEdit entry
 type PLRMLuse = record
      data : array[0..2] of double;
    end;

 type PLRMGridData = array of array of string;

 type PLRMGridDataDbl = array of array of Double;

 type dbReturnFields = array[0..1] of TStringList;
 type dbReturnFields2 = array[0..2] of TStringList;
 type dbReturnFields3 = array[0..3] of TStringList;

 type  TParcelCRCArray = array[0..11, 0..5] of String;

 type  TPLRMRdCondsData = record
    entity : Integer; // 0 - global, 1 - n for catchments as catchment ID
    //store input from pollutant potential combo boxes
    rdAppStgyHigh : String;
    rdAppStgyMod : String;
    rdAppStgyLow : String;

    rdSwprTypHigh : String;
    rdSwprTypMod : String;
    rdSwprTypLow : String;

    rdSwprFreqHigh : String;
    rdSwprFreqMod : String;
    rdSwprFreqLow : String;

    rdShouldr : PLRMGridData;// dynamic array of array of strings
    rdReportCard : PLRMGridData;// dynamic array of array of strings
    xtscsConcs : PLRMGridData;// dynamic array of array of strings
    pollDelFactors :PLRMGridData; // dynamic array of array of strings

    assigndWts :  array[0..2] of Double;

  end;

 type  TPLRMDrngXtcsData= record
    entity : Integer; // 0 - global, 1 - n for catchments as catchment ID
    //store input from pollutant potential combo boxes
    rdAppStgyHigh : String;
    rdAppStgyMod : String;
    rdAppStgyLow : String;

    rdSwprTypHigh : String;
    rdSwprTypMod : String;
    rdSwprTypLow : String;

    rdSwprFreqHigh : String;
    rdSwprFreqMod : String;
    rdSwprFreqLow : String;

    rdShouldr : PLRMGridData;// dynamic array of array of strings
    rdReportCard : PLRMGridData;// dynamic array of array of strings
    xtscsConcs : PLRMGridData;// dynamic array of array of strings
    pollDelFactors :PLRMGridData; // dynamic array of array of strings

    assigndWts :  array[0..2] of Double;
  end;

 type landUse = record
  name: string;
  data: array [0..2] of double;
 end;

 type TcatchResults = record
    catchName: String;
    annLoads: PLRMGridDataDbl; //average annual volume and load for each pollutant
 end;

 type TswtResults = record
    swtType:Integer;
    swtName: String;
    perCap: Double;
    swtLoads: PLRMGridDataDbl; //influent, treated, and bypassed volumes and loads
 end;

 type TPLRMResults = record
    scenarioName: String;
    projectName:String;
    numYrsSimulated: Integer;
    metGridNum: Integer;
    totPPT_in: Double;
    totPPT_cf: Double;
    runCoeff: Double;
    wrkDir:String;
    outfallLoads: PLRMGridDataDbl;
    totLoads: PLRMGridDataDbl;
    catchData: array of TcatchResults;
    swtData: array of TswtResults;
    nativeSWMMRpt:TStringList;
 end;

 //******CONSTANTS**************
const
 //  User inputPLRMGrid row and column pointers
USERVALCOL = 3;
 //Detention Basin Design Parameters Row Numbers
DETWQVROW = 1; //water quality volume row
DETAREAROW = 2;//footprint area row
DETINFROW = 3; //infiltration rate row
DETDDTROW = 4; //drawdown time row
 //Infiltration Basin Design Parameters Row Numbers
INFWQVROW = 1;  //water quality volume row
INFAREAROW = 2; //footprint area row
INFINFROW = 3;  //infiltration rate row
 //WetBasin Design Parameters Row Numbers
WETPPVROW = 1;  //permanent pool volume row
WETAREAROW = 2; //permanent pool footprint area row
WETHRTROW = 3;  //minimum hydraulic residence time row
WETSURVROW = 4; //surcharge volume row
WETDDTROW = 5;  //permanent pool drawdown time row

 //Bed Filter Design Parameters Row Numbers
GRNEQVROW = 1;  //equalization volume row
GRNAREAROW = 2; //footprint area row
GRNINFROW = 3;  //media filtration rate in/hr
 //Cartridge Filter Design Parameters Row Numbers
CRTFLOWROW = 1;  //maximum treatment flowrate row
 //  Hydrodynamic separator Filter Design Parameters Row Numbers
HYDFLOWROW = 1;  //maximum treatment flowrate row

//Conversion constants
CONVCUFT = 3630;
CONVACFT = 43560;
CONVKGLBS = 2.204623;
CONVMGALTOACFT = 3.06888;

//Fixed strings
//Format strings for rounding etc
ZERODP = '#0';
ONEDP = '#0.0';
TWODP = '#0.00';

//SWT names
SWTDETBASIN = 'DryBasin';
SWTINFBASIN = 'InfiltrationBasin';
SWTWETBASIN = 'WetBasin';
SWTGRNFILTR = 'BedFilter';
SWTCRTFILTR = 'CartridgeFilter';
SWTTRTVAULT = 'TreatmentVault';
//SWT Form names
SWTFORMHEADERS : array[0..8] of string = ( 'Detention Basin Editor','Infiltration Basin Editor','Wet Basin Editor','Bed Filter Editor','Cartridge Filter Editor','Treatment Vault Editor', 'Flow Divider Editor','Junction Editor','Outfall Editor');
FRMSWTINFBASIN = 'Infiltration Basin Editor';
FRMSWTWETBASIN = 'Wet Basin Editor';
FRMSWTGRNFILTR = 'Bed Filter Editor';
FRMSWTCRTFILTR = 'Cartridge Filter Editor';
FRMSWTTRTVAULT = 'Hydrodynamic Device Editor';
//Form titles
//PLRMVERSION = 'Tahoe Pollutant Load Reduction Model - v1.0';
PLRMVERSION = 'Lake Tahoe PLRM v1.1  ';
PLRM0_WIZTITLE = 'PLRM Wizard';
PLRM1_TITLE = 'Project and Scenario Manager';
PLRM2_TITLE = 'Scenario Editor';
PLRM2b_TITLE = 'Project Editor';
PLRM3_TITLE = 'Land Use Conditions Editor';
PLRM4_TITLE = 'Road Conditions Editor';
PLRM5_TITLE = 'Drainage Conditions Editor';
PLRM6_TITLE = 'Hydrologic Properties Editor';
PLRM6inf_TITLE = 'Infiltration Facility Editor';
PLRM6dsp_TITLE = 'Pervious Dispersion Area Editor';
PLRM7_TITLE = 'Storm Water Treatment BMPs';
PLRM8_TITLE = 'Scenario Comparisons';
PLRM9_TITLE = 'Scenario Comparisons';
//D-form titles
PLRMD1_TITLE = 'Land Use Editor';
PLRMD2_TITLE = 'Soil Editor';
PLRMD3_TITLE = 'Catchment Properties Editor';
PLRMD4_TITLE = 'Define Road Conditions';
PLRMD5_TITLE = 'Volume-Discharge Curve Editor';

PLRMD4Det_TITLE = 'Dry Basin Schematic Representation';
PLRMD4Inf_TITLE = 'Infiltration Basin Schematic Representation';
PLRMD4Wet_TITLE = 'Wet Basin Schematic Representation';
PLRMD4Gfl_TITLE = 'Bed Filter Schematic Representation';
PLRMD4Cfl_TITLE = 'Cartridge Filter Schematic Representation';
PLRMD4GHyd_TITLE = 'Hydrodynamic Device Schematic Representation';

SWTNames : array[0..5] of string = ( 'Dry Basins','Infiltration Basins','Wet Basins','Bed Filters','Cartridge Filters','Treatment Vaults');

//Scheme default names
RCSchmName = 'RoadConditions';
HSRdInfSchmName = 'RoadsInfProp.xml';
HSRdDspSchmName = 'RoadsPDAProp';
HSRdOthrSchmName = 'RoadsOtherProp';
HSPcInfSchmName = 'ParcelsInfProp';
HSPcOthrSchmName = 'ParcelsOtherProp';
//Scheme files default extensions
PRIMRCSCHEXT = 'pRdCondSchm';
SECRCSCHEXT = 'sRdCondSchm';

HSRDINFSCHMEXT = 'rdInfSchm';
HSRDDSPSCHMEXT = 'rdDspSchm';
HSRDOUTSCHMEXT = 'rdOutSchm';
HSPCINFSCHMEXT = 'pcInfSchm';
HSPCOTHRSCHMEXT = 'pcOutSchm';
HYDSCHMEXTS : array[0..4] of string = ( 'rdOutSchm','rdInfSchm','rdDspSchm','pcOutSchm','pcInfSchm');

//Grid to delimited text file column headers
SCNCOMPTXTFILEHDRS: array[0..7] of String = ('Scenario','Runoff Vol(ac-ft/yr)','TSS(lbs/yr)','FSP(lbs/yr)','TP(lbs/yr)','SRP(lbs/yr)','TN(lbs/yr)','DIN(lbs/yr)');

//Messages
CELLNOEDIT = 'This cell is not editable. Please select another cell!';
 implementation


end.
