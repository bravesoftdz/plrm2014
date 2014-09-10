unit Uoutput;

{-------------------------------------------------------------------}
{                    Unit:    Uoutput.pas                           }
{                    Project: EPA SWMM                              }
{                    Version: 5.1                                   }
{                    Date:    12/2/13       (5.1.000)               }
{                    Author:  L. Rossman                            }
{                                                                   }
{   Delphi Pascal unit used for retrieving output results from      }
{   a simulation run by EPA SWMM.                                   }
{-------------------------------------------------------------------}


{    Routine           Purpose
    --------------    -----------------------------------------------
    CheckRunStatus    Checks if a successful simulation was made
    ClearOutput       Clears all output results
    CloseOutputFile   Closes binary output file
    FindAreaColor     Finds color to display subcatchment area value with
    FindLinkColor     Finds color to display a link value with
    FindNodeColor     Finds color to display a node value with
    GetAreaMinMax     Gets min and max value of a subcatch area variable
    GetAreaOutVal     Gets value of a subcatch area variable for a specific link
    GetAreaOutVals    Gets values at all subcatch areas at specific time period
    GetAreaValStr     Gets string value of a subcatch area variable
    GetBasicOutput    Stores basic information from output results file
    GetConduitSlope   Gets slope of a conduit
    GetFlowDir        Gets flow direction of each link
    GetLinkInputStr   Gets string value of a link's input property
    GetLinkMinMax     Gets min and max value of a link variable
    GetLinkOutVal     Gets value of a link variable for a specific link
    GetLinkOutVals    Gets values at all links for a specific time period
    GetLinkValStr     Gets string value of a link variable
    GetMeterLabel     Gets string value to display in a meter label
    GetNodeMinMax     Gets min and max value of a node variable
    GetNodeOutVal     Gets value of a node variable for a specific node
    GetNodeOutVals    Gets values at all nodes for a specific time period
    GetNodeValStr     Gets string value of a node variable
    GetRunFlag        Gets RunFlag value when previous output saved to file
    GetString         Reads a fixed-length string from a binary file
    OpenOutputFile    Opens binary output file
    SetAreaColor      Sets color of a subcatchment area's input value
    SetAreaColors     Sets colors for all subcatchment areas
    SetLinkColor      Sets color of a link's input value
    SetLinkColors     Sets colors for all links
    SetNodeColor      Sets color of a node's input value
    SetNodeColors     Sets colors for all nodes
    SetQueryColor     Sets node/link color based on query condition
}

interface

uses
  SysUtils, Dialogs, Classes, Consts, Graphics, Windows,
  Uglobals, Uproject, Ulid, Uutils, Swmm5;

function  CheckRunStatus(const Fname: String): TRunStatus;
procedure ClearOutput;
procedure CloseOutputFile;

function  FindSubcatchColor(const Z: Single): Integer;
function  FindLinkColor(const Z: Single): Integer;
function  FindNodeColor(const Z: Single): Integer;

procedure GetSubcatchMinMax(const SubcatchVar: Integer; const Period: LongInt;
          var Xmin: Single; var Xmax: Single);
function  GetSubcatchOutVal(const V: Integer; const Period: LongInt;
          const Zindex: Integer): Single;
procedure GetSubcatchOutVals(const SubcatchVar: Integer; const Period: LongInt;
          var Value: PSingleArray);
function  GetSubcatchValStr(const SubcatchVar: Integer; const Period: LongInt;
          const SubcatchIndex: Integer): String;

procedure GetBasicOutput;
function  GetConduitSlope(L: TLink): Extended;
procedure GetFlowDir(const TimePeriod: Integer);

procedure GetLinkFixedData(const K: Integer; var X: array of Single);
function  GetLinkInputStr(L: TLink; const Index: Integer): String;
procedure GetLinkMinMax(const LinkVar: Integer; const Period: LongInt;
          var Xmin: Single; var Xmax: Single);
function  GetLinkOutVal(const V: Integer; const Period: LongInt;
          const Zindex: Integer):Single;
procedure GetLinkOutVals(const LinkVar: Integer; const Period: LongInt;
          var Value: PSingleArray);
function  GetLinkValStr(const LinkVar: Integer; const Period: LongInt;
          const LinkType: Integer; const LinkIndex: Integer): String;

procedure GetMeterLabel(const ObjType, ObjIndex: Integer;
            var IDStr, ValStr: String);

procedure GetNodeFixedData(const K: Integer; var X: array of Single);
procedure GetNodeMinMax(const NodeVar: Integer; const Period: LongInt;
            var Xmin: Single; var Xmax: Single);
function  GetNodeOutVal(const V: Integer; const Period: LongInt;
          const Zindex: Integer):Single;
procedure GetNodeOutVals(const NodeVar: Integer; const Period: LongInt;
          var Value: PSingleArray);
function  GetNodeValStr(const NodeVar: Integer; const Period: LongInt;
          const NodeType: Integer; const NodeIndex: Integer): String;

function  GetObject(ObjType: Integer; const S: String): TObject;
function  GetRunFlag(const Fname: String): Boolean;
procedure GetString(var F: File; var S: ShortString);
function  GetSysOutVal(const V: Integer; const Period: LongInt):Single;
function  GetValue(const ObjType: Integer; const VarIndex: Integer;
          const Period: LongInt; theObject: TObject): Double;
function  GetVarIndex(const V: Integer; const ObjType: Integer): Integer;

function  OpenOutputFile(const Fname: String): TRunStatus;

procedure SetSubcatchColor(S: TSubcatch; const K: Integer);
procedure SetSubcatchColors;
procedure SetLinkColor(L: TLink; const K: Integer);
procedure SetLinkColors;
procedure SetNodeColor(N: TNode; const K: Integer);
procedure SetNodeColors;
function  SetQueryColor(const Z: Single): Integer;

implementation

uses
  Fmain, Ubrowser, Dreporting;

const
  MagicNumber = 516114522; //File signature
  RECORDSIZE  = 4;         //Byte size of each record

var
  Fout    : Integer;
  Offset0 : Int64;
  Offset1 : Int64;
  Offset2 : Int64;
  NsubcatchVars : Integer;
  NnodeVars : Integer;
  NlinkVars : Integer;
  NsysVars : Integer;

procedure SetSubcatchInColors(const SubcatchVar: Integer); forward;
procedure SetSubcatchOutColors(const SubcatchVar: Integer); forward;
procedure SetLinkInColors(const LinkVar: Integer); forward;
procedure SetLinkOutColors(const LinkVar: Integer); forward;
procedure SetNodeInColors(const NodeVar: Integer); forward;
procedure SetNodeOutColors(const NodeVar: Integer); forward;


function CheckRunStatus(const Fname: String): TRunStatus;
//-----------------------------------------------------------------------------
// Checks if a successful simulation run was made.
//-----------------------------------------------------------------------------
var
  Mfirst : Integer;
  Mlast  : Integer;
  Np     : Integer;
  V      : Integer;
  E      : Integer;
  Offset : Integer;
begin
  // Open binary output file
  Result := OpenOutputFile(Fname);
  if Result = rsError then Exit;

  try
    // Starting from end of file, read byte offsets of file's sections
    Offset0 := -6*RecordSize;
    FileSeek(Fout, Offset0, 2);
    FileRead(Fout, Offset, SizeOf(Offset));   // start of ID names (not used)
    FileRead(Fout, Offset, SizeOf(Offset));   // start of input data
    Offset0 := Offset;
    FileRead(Fout, Offset, SizeOf(Offset));   // start of output data
    Offset1 := Offset;

    // Read # time periods, error code & file signature
    FileRead(Fout, Np, SizeOf(Np));
    Nperiods := Np;
    FileRead(Fout, E, SizeOf(E));
    FileRead(Fout, Mlast, SizeOf(Mlast));

    // Read file signature & version number from start of file
    FileSeek(Fout, 0, 0);
    FileRead(Fout, Mfirst, SizeOf(Mfirst));
    FileRead(Fout, V, SizeOf(V));

    // Check if run was completed
    if Mlast <> MagicNumber then Result := rsError

    // Ckeck if results were saved for 1 or more time periods
    else if Np <= 0 then Result := rsError

    // Check if correct version was used
    else if (Mfirst <> MagicNumber)
    or (V < VERSIONID1)
    or (V > VERSIONID2)
    then Result := rsWrongVersion

    // Check if error messages were generated
    else if E <> 0 then Result := rsError
    else Result := rsSuccess;

  except
    Result := rsError;
  end;

  // Close file if run was unsuccessful
  if Result in [rsFailed, rsWrongVersion, rsError]
  then FileClose(Fout);
end;


procedure ClearOutput;
//-----------------------------------------------------------------------------
//  Closes binary output results file and frees all
//  memory allocated to hold simulation output values.
//-----------------------------------------------------------------------------
var
  I, J: Integer;
begin
  if RunFlag then
  begin
    // Close binary output file
    FileClose(Fout);

    // Free memory used for output values
    FreeMem(Zsubcatch, Nsubcatchs*SizeOf(Single));
    FreeMem(Znode, Nnodes*SizeOf(Single));
    FreeMem(Zlink, Nlinks*SizeOf(Single));
    FreeMem(FlowDir, Nlinks*SizeOf(Byte));

    // Re-set Zindex values
    for I := 0 to MAXCLASS do
    begin
      if Project.IsSubcatch(I)
      then for J := 0 to Project.Lists[I].Count - 1 do
        Project.GetSubcatch(SUBCATCH, J).Zindex := -1
      else if Project.IsNode(I)
      then for J := 0 to Project.Lists[I].Count - 1 do
        Project.GetNode(I, J).Zindex := -1
      else if Project.IsLink(I)
      then for J := 0 to Project.Lists[I].Count - 1 do
        Project.GetLink(I, J).Zindex := -1
      else continue;
    end;
  end;

  // Re-set status flags
  RunStatus := rsNone;
  RunFlag := False;
  UpdateFlag := False;
end;


procedure CloseOutputFile;
//-----------------------------------------------------------------------------
//  Closes binary output file.
//-----------------------------------------------------------------------------
begin
  FileClose(Fout);
end;


function FindLinkColor(const Z: Single): Integer;
//-----------------------------------------------------------------------------
//  Finds the color index of the value Z in the map legend for Links.
//-----------------------------------------------------------------------------
var
  I: Integer;
  K: Integer;
begin
  if (QueryFlag) then Result := SetQueryColor(Z)
  else
  begin
    if CurrentLinkVar >= LINKQUAL then K := LINKQUAL else K := CurrentLinkVar;
    with LinkLegend[K] do
      for I := Nintervals downto 1 do
        if Z >= Intervals[I] then
        begin
          Result := I;
          Exit;
        end;
    Result := 0;
  end;
end;


function FindNodeColor(const Z: Single): Integer;
//-----------------------------------------------------------------------------
//  Finds the color index of the value Z in the map legend for nodes.
//-----------------------------------------------------------------------------
var
  I: Integer;
  K: Integer;
begin
  if (QueryFlag) then Result := SetQueryColor(Z)
  else
  begin
    if CurrentNodeVar >= NODEQUAL then K := NODEQUAL else K := CurrentNodeVar;
    with NodeLegend[K] do
      for I := Nintervals downto 1 do
        if Z >= Intervals[I] then
        begin
          Result := I;
          Exit;
        end;
    Result := 0;
  end;
end;


function FindSubcatchColor(const Z: Single): Integer;
//-----------------------------------------------------------------------------
//  Finds the color index of the value Z in the map legend for subcatchments.
//-----------------------------------------------------------------------------
var
  I: Integer;
  K: Integer;
begin
  if (QueryFlag) then Result := SetQueryColor(Z)
  else
  begin
    if CurrentSubcatchVar >= SUBCATCHQUAL
    then K := SUBCATCHQUAL
    else K := CurrentSubcatchVar;
    with SubcatchLegend[K] do
      for I := Nintervals downto 1 do
        if Z >= Intervals[I] then
        begin
          Result := I;
          Exit;
        end;
    Result := 0;
  end;
end;


procedure GetBasicOutput;
//-----------------------------------------------------------------------------
//  Retrieves basic information from the binary output file.
//-----------------------------------------------------------------------------
var
  I, J, K       : Integer;
  Dummy         : Integer;
  ReportStep    : Integer;
  SkipBytes     : Int64;

begin
  // Read number of drainage system components
  FileSeek(Fout, 0, 0);
  FileRead(Fout, Dummy, SizeOf(Dummy));             // File signature
  FileRead(Fout, Dummy, SizeOf(Dummy));             // Version number
  FileRead(Fout, Qunits, SizeOf(Qunits));           // Flow units code
  FileRead(Fout, Nsubcatchs, SizeOf(Nsubcatchs));   // # Subcatchments
  FileRead(Fout, Nnodes, SizeOf(Nnodes));           // # Nodes
  FileRead(Fout, Nlinks, SizeOf(Nlinks));           // # Links
  FileRead(Fout, Npolluts, SizeOf(Npolluts));       // # Pollutants

  // Skip over saved subcatch/node/link input values
  SkipBytes := (Nsubcatchs+2) * RecordSize  // Subcatchment area
             + (3*Nnodes+4) * RecordSize  // Node type, invert & max depth
             + (5*Nlinks+6) * RecordSize; // Link type, z1, z2, max depth & length
  SkipBytes := Offset0 + SkipBytes;
  FileSeek(Fout, SkipBytes, 0);

  // Read number & codes of computed variables
  FileRead(Fout, NsubcatchVars, SizeOf(NSubcatchVars)); // # Subcatch variables
  for I := 1 to NSubcatchVars do FileRead(Fout, Dummy, Sizeof(Dummy));
  FileRead(Fout, NnodeVars, SizeOf(NnodeVars));     // # Node variables
  for I := 1 to NnodeVars do FileRead(Fout, Dummy, Sizeof(Dummy));
  FileRead(Fout, NlinkVars, SizeOf(NlinkVars));     // # Link variables
  for I := 1 to NlinkVars do FileRead(Fout, Dummy, Sizeof(Dummy));
  FileRead(Fout, NsysVars, SizeOf(NsysVars));       // # System variables
  for I := 1 to NsysVars do FileRead(Fout, Dummy, Sizeof(Dummy));

  // Make number of system view variables consistent with number available
  Uglobals.NsysViews := NsysVars;
  if NsysVars - 1 > Uglobals.SYSVIEWS
  then Uglobals.NsysViews := Uglobals.SYSVIEWS + 1;

  // Read starting date/time & reporting time step
  FileRead(Fout, StartDateTime, SizeOf(StartDateTime));
  FileRead(Fout, ReportStep, SizeOf(ReportStep));

  // Convert times to TDateTime objects
  DeltaDateTime := ReportStep/86400;
  StartDateTime := StartDateTime + DeltaDateTime;
  EndDateTime := StartDateTime + (Nperiods-1)*DeltaDateTime;

  // Save # bytes used to store results in each reporting period
  Offset2 := Sizeof(TDateTime) + RecordSize*(Nsubcatchs*NsubcatchVars +
             Nnodes*NnodeVars + Nlinks*NlinkVars + NsysVars);

  // Allocate memory for output results (per period) arrays
  GetMem(Zsubcatch, Nsubcatchs*SizeOf(Single));
  GetMem(Znode, Nnodes*SizeOf(Single));
  GetMem(Zlink, Nlinks*SizeOf(Single));
  GetMem(FlowDir, Nlinks*SizeOf(Byte));

  // For each subcatchment, assign an index into the results array
  ReportingForm.SetReportedItems(SUBCATCHMENTS);
  K := 0;
  for J := 0 to Project.Lists[SUBCATCH].Count - 1 do
  begin
    if Project.GetSubcatch(SUBCATCH, J).Zindex >= 0 then
    begin
      Project.GetSubcatch(SUBCATCH, J).Zindex := K;
      Inc(K);
    end;
  end;

  // For each JUNCTION, OUTFALL, DIVIDER, and STORAGE node
  // (in that order) assign an index into the results array
  ReportingForm.SetReportedItems(NODES);
  K := 0;
  for I := JUNCTION to STORAGE do
  begin
    for J := 0 to Project.Lists[I].Count - 1 do
    begin
      if Project.GetNode(I, J).Zindex >= 0 then
      begin
        Project.GetNode(I, J).Zindex := K;
        Inc(K);
      end;
    end;
  end;

  // For each CONDUIT, PUMP, ORIFICE, WEIR, and OUTLET (in that order)
  // assign an index into the results array
  ReportingForm.SetReportedItems(LINKS);
  K := 0;
  for I := CONDUIT to OUTLET do
  begin
    for J := 0 to Project.Lists[i].Count - 1 do
    begin
      if Project.GetLink(I, J).Zindex >= 0 then
      begin
        Project.GetLink(I, J).Zindex := K;
        Inc(K);
      end;
    end;
  end;

  // Check if run used dynamic wave routing
  DynWaveFlag := SameText(Project.Options.Data[ROUTING_MODEL_INDEX], 'DYNWAVE');
end;


function GetConduitSlope(L: TLink): Extended;
//-----------------------------------------------------------------------------
//  Computes the slope of a given conduit.
//-----------------------------------------------------------------------------
var
  E1, E2, Len: Extended;
  Delta: Extended;
begin
  try

    // Find elevation of link end points for ELEVATION offsets
    if SameText(Project.Options.Data[LINK_OFFSETS_INDEX], 'ELEVATION') then
    begin
      if L.Data[CONDUIT_INLET_HT_INDEX] = '*'
      then E1 := StrToFloat(L.Node1.Data[NODE_INVERT_INDEX])
      else E1 := StrToFloat(L.Data[CONDUIT_INLET_HT_INDEX]);
      if L.Data[CONDUIT_OUTLET_HT_INDEX] = '*'
      then E2 := StrToFloat(L.Node2.Data[NODE_INVERT_INDEX])
      else E2 := StrToFloat(L.Data[CONDUIT_OUTLET_HT_INDEX]);
    end

    // Find elevation of link end points for DEPTH offsets
    else
    begin
      E1 := StrToFloat(L.Node1.Data[NODE_INVERT_INDEX]) +
            StrToFloat(L.Data[CONDUIT_INLET_HT_INDEX]);
      E2 := StrToFloat(L.Node2.Data[NODE_INVERT_INDEX]) +
            StrToFloat(L.Data[CONDUIT_OUTLET_HT_INDEX]);
    end;

    // Use HEC-RAS definition of slope
    Len := StrToFloat(L.Data[CONDUIT_LENGTH_INDEX]);
    if Len > 0 then
    begin
      Delta := E1 - E2;
      if Abs(Delta) < Len then Len := Sqrt((Len*Len) - (Delta*Delta));
      Result := Delta/Len*100;
    end
    else Result := 0;

  except
    On EConvertError do Result := 0;
  end;
end;


procedure GetFlowDir(const TimePeriod: Integer);
//-----------------------------------------------------------------------------
//  Determines the flow direction in each link of the drainage network.
//-----------------------------------------------------------------------------
var
  I : Integer;
  D : Byte;          // Flow direction
  F : Single;        // Flow value
begin
  // Use original link orientation if no link theme view is active
  if Uglobals.CurrentLinkVar = NONE then
  begin
    for I := 0 to Nlinks-1 do FlowDir^[I] := PLUS;
    exit;
  end;

  // Retrieve link flows from the binary output file
  GetLinkOutVals(FLOW, TimePeriod, Zlink);

  // Establish the flow direction of each link.
  for I := 0 to Nlinks-1 do
  begin
    F := Zlink^[I];
    D := NONE;
    if F < -FLOWTOL then D := MINUS
    else if F > FLOWTOL then D := PLUS;
    FlowDir^[I] := D;
  end;
end;


procedure GetLinkFixedData(const K: Integer; var X: array of Single);
//-----------------------------------------------------------------------------
//  Retrieves the following design parameters for Link K that were saved to
//  the binary output file: type code, upstream and downstream invert
//  offsets, max. depth and length.
//-----------------------------------------------------------------------------
var
  BytePos: Integer;
  Y: array[0..3] of Single;
  I: Integer;
begin
  BytePos := Offset0 +                      // prolog records
             (2+Nsubcatchs)*RecordSize +    // subcatchment data
             (4+3*Nnodes)*RecordSize +      // node data
             (6+5*K)*RecordSize +           // link data prior to link K
             RecordSize;                    // link type code
  FileSeek(Fout, BytePos, 0);
  FileRead(Fout, Y, 4*Sizeof(Single));
  for I := 0 to 3 do X[I] := Y[I];
end;


function GetLinkInputStr(L: TLink; const Index: Integer): String;
//-----------------------------------------------------------------------------
//  Gets the string value of a link L's input property of given Index.
//-----------------------------------------------------------------------------
begin
  Result := L.Data[Index];
end;


procedure GetLinkMinMax(const LinkVar: Integer; const Period: LongInt;
  var Xmin: Single; var Xmax: Single);
//-----------------------------------------------------------------------------
//  Gets the min & max values of link variable LinkVar at time period Period.
//-----------------------------------------------------------------------------
var
  J, K, M, N : Integer;
  X : Single;
  Y : PSingleArray;
begin
  Xmin := -MISSING;
  Xmax := MISSING;
  if Nlinks = 0 then Exit;
  N := Project.Lists[CONDUIT].Count - 1;

  // This is for input design variables
  if (LinkVar < LINKOUTVAR1) then
  begin
    K := LinkVariable[LinkVar].SourceIndex;
    for J := 0 to N do
    begin
      if K = CONDUIT_SLOPE_INDEX
      then X := GetConduitSlope(Project.GetLink(CONDUIT, J))
      else if not Uutils.GetSingle(Project.GetLink(CONDUIT, J).Data[K], X)
      then continue;
      if (X < Xmin) then Xmin := X;
      if (X > Xmax) then Xmax := X;
    end
  end

  // This is for computed output variables
  else
  begin
    if (Period = CurrentPeriod) then Y := Zlink
    else GetMem(Y, Nlinks*SizeOf(Single));
    try
      if (Period <> CurrentPeriod)
      then GetLinkOutVals(LinkVar, Period, Y);
      for J := 0 to N do
      begin
        M := Project.GetLink(CONDUIT, J).Zindex;
        if (M < 0) then continue;
        X := Abs(Y^[M]);
        if (X < Xmin) then Xmin := X;
        if (X > Xmax) then Xmax := X;
      end;
    finally
      if (Period <> CurrentPeriod) then FreeMem(Y, Nlinks*SizeOf(Single));
    end;
  end;
end;


function GetLinkOutVal(const V: Integer; const Period: LongInt;
  const Zindex: Integer):Single;
//-----------------------------------------------------------------------------
//  Returns the computed value for variable V at time period Period
//  for link LinkIndex.
//-----------------------------------------------------------------------------
var
  P: Int64;
begin
  Result := MISSING;
  if (Zindex < 0) or (V >= NnodeVars) then Exit;
  P := Offset1 + Period*Offset2 + SizeOf(TDateTime) +
       RecordSize*(Nsubcatchs*NsubcatchVars + Nnodes*NnodeVars +
       Zindex*NlinkVars + V);
  FileSeek(Fout, P, 0);
  FileRead(Fout, Result, SizeOf(Single));
end;


procedure GetLinkOutVals(const LinkVar: Integer; const Period: LongInt;
  var Value: PSingleArray);
//-----------------------------------------------------------------------------
//  Gets computed results for all links from the output file where:
//  LinkVar = link variable code
//  Period  = time period index
//  Value   = array that stores the retrieved values
//-----------------------------------------------------------------------------
var
  P1, P2: Int64;
  I, K : Integer;
begin
  if (Nlinks > 0) and (LinkVar <> NONE) and (Period < Nperiods) then
  begin
    K := GetVarIndex(LinkVar, LINKS);
    P1 := Offset1 + Period*Offset2 + SizeOf(TDateTime) +
          RecordSize*(Nsubcatchs*NSubcatchVars + Nnodes*NnodeVars + K);
    FileSeek(Fout, P1, 0);
    FileRead(Fout, Value^[0], SizeOf(Single));
    P2 := RecordSize*(NlinkVars - 1);
    for I := 1 to Nlinks-1 do
    begin
      FileSeek(Fout, P2, 1);
      FileRead(Fout, Value^[I], SizeOf(Single));
    end;
  end;
end;


function  GetLinkValStr(const LinkVar: Integer; const Period: LongInt;
  const LinkType: Integer; const LinkIndex: Integer): String;
//-----------------------------------------------------------------------------
//  Gets the string value of variable LinkVar at time period Period for
//  link of type LinkType with index LinkIndex.
//-----------------------------------------------------------------------------
var
  K: Integer;
  Z: Single;
begin
  // Default result is N/A
  Result := NA;
  if (LinkVar = NOVIEW) then Exit;

  // LinkVar is an input variable
  if LinkVar >= LINKQUAL then K := LINKQUAL else K := LinkVar;
  if (LinkVar < LINKOUTVAR1) then
  begin
    // Exit if link is not a conduit
    if LinkType <> CONDUIT then Exit;

    // Find index of variable V in property list
    K := LinkVariable[K].SourceIndex;
    if (K >= 0) then
    begin
      if K = CONDUIT_SLOPE_INDEX then
        Result := Format('%.2f',
                  [GetConduitSlope(Project.GetLink(LinkType, LinkIndex))])
      else
        Result := GetLinkInputStr(Project.GetLink(LinkType, LinkIndex), K);
    end;
  end

  // LinkVar is an output variable
  else
  begin
    // Make sure output results exist
    if (RunFlag) and (Period < Nperiods) then
    begin
      // Get numerical value & convert to string
      Z := GetLinkOutVal(GetVarIndex(LinkVar, LINKS), Period,
           Project.GetLink(LinkType, LinkIndex).Zindex);
      if (Z <> MISSING) then
      begin
        Result := FloatToStrF(Z, ffFixed, 7, LinkUnits[K].Digits);
      end;
    end;
  end;
end;


procedure GetMeterLabel(const ObjType, ObjIndex: Integer;
  var IDStr, ValStr: String);
//-----------------------------------------------------------------------------
//  Retrieves an object's ID label and value of its map view variable.
//  This procedure is used to supply text for flyover map labeling.
//-----------------------------------------------------------------------------
var
  Units: String;
begin
  IDStr := ' ' + ObjectLabels[ObjType] + ' ' +
           Project.GetID(ObjType,ObjIndex) + ' ';
  ValStr := '';
  Units := '';

  if (ObjType = SUBCATCH) and (CurrentSubcatchVar <> NOVIEW) then
  begin
    ValStr := GetSubcatchValStr(CurrentSubcatchVar, CurrentPeriod, ObjIndex);
    if CurrentSubcatchVar < SUBCATCHQUAL
    then Units := ' ' + SubcatchUnits[CurrentSubcatchVar].Units
    else Units := ' ' + Project.PollutUnits[CurrentSubcatchVar - SUBCATCHQUAL];
  end;

  if (Project.IsNode(ObjType)) and (CurrentNodeVar <> NOVIEW) then
  begin
    ValStr := GetNodeValStr(CurrentNodeVar, CurrentPeriod, ObjType, ObjIndex);
    if CurrentNodeVar < NODEQUAL
    then Units := ' ' + NodeUnits[CurrentNodeVar].Units
    else Units := ' ' + Project.PollutUnits[CurrentNodeVar - NODEQUAL];
  end;

  if (Project.IsLink(ObjType)) and (CurrentLinkVar <> NOVIEW) then
  begin
    ValStr := GetLinkValStr(CurrentLinkVar, CurrentPeriod, ObjType, ObjIndex);
    if CurrentLinkVar < LINKQUAL
    then Units := ' ' + LinkUnits[CurrentLinkVar].Units
    else Units := ' ' + Project.PollutUnits[CurrentLinkVar - LINKQUAL];
  end;
  ValStr := ValStr + Units;
end;


procedure GetNodeFixedData(const K: Integer; var X: array of Single);
//-----------------------------------------------------------------------------
//  Retrieves the following design parameters for Node K that were saved to
//  the binary output file: invert elev. and max. depth.
//-----------------------------------------------------------------------------
var
  BytePos: Integer;
  Y: array[0..1] of Single;
  I: Integer;
begin
  BytePos := Offset0 +                      // prolog records
             (2+Nsubcatchs)*RecordSize +    // subcatchment data
             (4+3*K)*RecordSize +           // node data prior to node K
             RecordSize;                    // node type code
  FileSeek(Fout, BytePos, 0);
  FileRead(Fout, Y, 2*Sizeof(Single));
  for I := 0 to 1 do X[I] := Y[I];
end;


procedure GetNodeMinMax(const NodeVar: Integer; const Period: LongInt;
            var Xmin: Single; var Xmax: Single);
//-----------------------------------------------------------------------------
//  Gets the min & max values of node variable NodeVar at time period Period.
//-----------------------------------------------------------------------------
var
  I, J ,K   : Integer;
  X         : Single;
  Y         : PSingleArray;
begin
  Xmin := -MISSING;
  Xmax := MISSING;

  // This is for input design variables
  if (NodeVar < NODEOUTVAR1) then
  begin
    K := NodeVariable[NodeVar].SourceIndex;
    for I := JUNCTION to STORAGE do
    begin
      for J := 0 to Project.Lists[I].Count - 1 do
      begin
        if not Uutils.GetSingle(Project.GetNode(I, J).Data[K], X)
        then continue;
        X := Abs(X);
        if (X < Xmin) then Xmin := X;
        if (X > Xmax) then Xmax := X;
      end;
    end;
  end

  // This is for computed output variables
  else
  begin
    if (Period = CurrentPeriod) then Y := Znode
    else GetMem(Y, Nnodes*SizeOf(Single));
    try
      if (Period <> CurrentPeriod)
      then GetNodeOutVals(NodeVar, Period, Y);
      for J := 0 to Nnodes - 1 do
      begin
        X := Abs(Y^[J]);
        if (X < Xmin) then Xmin := X;
        if (X > Xmax) then Xmax := X;
      end;
    finally
      if (Period <> CurrentPeriod) then FreeMem(Y, Nnodes*SizeOf(Single));
    end;
  end;
end;


function  GetNodeOutVal(const V: Integer; const Period: LongInt;
  const Zindex: Integer):Single;
//-----------------------------------------------------------------------------
//  Returns the computed value for variable V at time period Period
//  for node NodeIndex.
//-----------------------------------------------------------------------------
var
  P: Int64;
begin
  Result := MISSING;
  if (Zindex < 0) or (V >= NnodeVars) then Exit;
  P := Offset1 + Period*Offset2 + SizeOf(TDateTime) +
       RecordSize*(Nsubcatchs*NsubcatchVars + Zindex*NnodeVars + V);
  FileSeek(Fout, P, 0);
  FileRead(Fout, Result, SizeOf(Single));
end;


procedure GetNodeOutVals(const NodeVar: LongInt; const Period: Integer;
  var Value: PSingleArray);
//-----------------------------------------------------------------------------
//  Gets computed results for all nodes from the output file where:
//  NodeVar = node variable code
//  Period  = time period index
//  Value   = array that stores the retrieved values
//-----------------------------------------------------------------------------
var
  P1, P2: Int64;
  I, K: Integer;
begin
  if (Nnodes > 0) and (NodeVar <> NONE) and (Period < Nperiods) then
  begin
    K := GetVarIndex(NodeVar, NODES);
    P1 := Offset1 + Period*Offset2 + SizeOf(TDateTime) +
          RecordSize*(Nsubcatchs*NsubcatchVars + K);
    FileSeek(Fout, P1, 0);
    FileRead(Fout, Value^[0], SizeOf(Single));
    P2 := RecordSize*(NnodeVars-1);
    for I := 1 to Nnodes-1 do
    begin
      FileSeek(Fout, P2, 1);
      FileRead(Fout, Value^[I], SizeOf(Single));
    end;
  end;
end;


function  GetNodeValStr(const NodeVar: Integer; const Period: LongInt;
  const NodeType: Integer; const NodeIndex: Integer): String;
//-----------------------------------------------------------------------------
//  Gets the string value of variable NodeVar at time period Period for
//  node of type NodeType with index NodeIndex.
//-----------------------------------------------------------------------------
var
  K: Integer;
  Z: Single;
begin
  // Default result is N/A
  Result := NA;
  if (NodeVar = NOVIEW) then Exit;

  // NodeVar is an input design variable
  if NodeVar >= NODEQUAL then K := NODEQUAL else K := NodeVar;
  if (NodeVar < NODEOUTVAR1) then
  begin
    // Find index of variable NodeVar in property list
    K := NodeVariable[NodeVar].SourceIndex;
    if (K >= 0) then Result := Project.GetNode(NodeType, NodeIndex).Data[K];
  end

  // NodeVar is a computed output variable
  else
  begin
    // Make sure output results exist
    if (RunFlag) and (Period < Nperiods) then
    begin
      // Get numerical value & convert to string
      Z := GetNodeOutVal(GetVarIndex(NodeVar, NODES), Period,
           Project.GetNode(NodeType, NodeIndex).Zindex);
      if (Z <> MISSING) then
        Result := FloatToStrF(Z, ffFixed, 7, NodeUnits[K].Digits);
    end;
  end;
end;


function GetObject(ObjType: Integer; const S: String): TObject;
//-----------------------------------------------------------------------------
//  Returns a reference to an object of type ObjType with ID name S.
//-----------------------------------------------------------------------------
var
  ObjIndex: Integer;
begin
  Result := nil;
  case ObjType of
    SUBCATCHMENTS:
      if Project.FindSubcatch(S, ObjType, ObjIndex)
      then Result := Project.GetSubcatch(ObjType, ObjIndex);
    NODES:
      if Project.FindNode(S, ObjType, ObjIndex)
      then Result := Project.GetNode(ObjType, ObjIndex);
    LINKS:
      if Project.FindLink(S, ObjType, ObjIndex)
      then Result := Project.GetLink(ObjType, ObjIndex);
  end;
end;


function GetRunFlag(const Fname: String): Boolean;
//-----------------------------------------------------------------------------
//  Activates a previously saved set of results files for the project
//  whose file name is Fname.
//-----------------------------------------------------------------------------
var
  F1: String;
  F2: String;
begin
  // Derive the report and output file names from the input file Fname
  Result := False;
  F1 := ChangeFileExt(Fname, '.rpt');
  F2 := ChangeFileExt(Fname, '.out');

  // Make sure that these file names are not same as the input file name
  // and that the files exist
  if (SameText(F1, Fname)) or (SameText(F1, Fname)) then Exit;
  if not FileExists(F1) or not FileExists(F2) then Exit;

  // See if these files contain valid results
  Uglobals.RunStatus := rsNone;
  if GetFileSize(F1) <= 0
  then Uglobals.RunStatus := rsFailed
  else Uglobals.RunStatus := CheckRunStatus(F2);

  // If the files are valid then rename the current temporary files
  // that are normally used to store results
  if RunStatus in [rsSuccess, rsWarning] then
  begin
    Result := True;
    Uglobals.ResultsSaved := True;
    Uglobals.TempReportFile := F1;
    Uglobals.TempOutputFile := F2;
  end
  else ResultsSaved := False;
end;


procedure GetString(var F: File; var S: ShortString);
//-----------------------------------------------------------------------------
//  Reads a fixed-size string from the current position of file F.
//  (F must be declared as 'var' because BlockRead is used.)
//-----------------------------------------------------------------------------
var
  Buf: PAnsiChar;
  Size: Word;
begin
  Size := SizeOf(S);
  Buf := AnsiStrAlloc(Size);
  BlockRead(F, Buf^, Size-1);
  S := StrPas(Buf);
  StrDispose(Buf);
end;


procedure GetSubcatchMinMax(const SubcatchVar: Integer; const Period: LongInt;
  var Xmin: Single; var Xmax: Single);
//-----------------------------------------------------------------------------
// Gets the min & max values of a given subcatchment variable.
//-----------------------------------------------------------------------------
var
  J, K : Integer;
  X : Single;
  Y : PSingleArray;
begin
  Xmin := -MISSING;
  Xmax := MISSING;
  if Nsubcatchs = 0 then Exit;

  // This is for input property variables
  if (SubcatchVar < SUBCATCHOUTVAR1) then
  begin
      K := SubcatchVariable[SubcatchVar].SourceIndex;
      for J := 0 to Project.Lists[SUBCATCH].Count - 1 do
      begin
        if not Uutils.GetSingle(Project.GetSubcatch(SUBCATCH, J).Data[K], X)
        then continue;
        X := Abs(X);
        if (X < Xmin) then Xmin := X;
        if (X > Xmax) then Xmax := X;
      end;
  end

  // This is for computed variables
  else
  begin
    if (Period = CurrentPeriod) then Y := Zsubcatch
    else GetMem(Y, Nsubcatchs*SizeOf(Single));
    try
      if (Period <> CurrentPeriod)
      then GetSubcatchOutVals(SubcatchVar, Period, Y);
      for J := 0 to Nsubcatchs - 1 do
      begin
        X := Abs(Y^[J]);
        if (X < Xmin) then Xmin := X;
        if (X > Xmax) then Xmax := X;
      end;
    finally
      if (Period <> CurrentPeriod)
      then FreeMem(Y, Nsubcatchs*SizeOf(Single));
    end;
  end;
end;


function GetSubcatchOutVal(const V: Integer; const Period: LongInt;
  const Zindex: Integer): Single;
//-----------------------------------------------------------------------------
//  Returns the computed value for variable V at time period Period
//  for subcatchment with position Zindex in list of reported subcatchments.
//-----------------------------------------------------------------------------
var
  P: Int64;
begin
  Result := MISSING;
  if (Zindex < 0) or (V >= NsubcatchVars) then Exit;
  P := Offset1 + Period*Offset2 + SizeOf(TDateTime) +
       RecordSize*(Zindex*NsubcatchVars + V);
  FileSeek(Fout, P, 0);
  FileRead(Fout, Result, SizeOf(Single));
end;


procedure GetSubcatchOutVals(const SubcatchVar: Integer; const Period: LongInt;
  var Value: PSingleArray);
//-----------------------------------------------------------------------------
//  Gets computed results for all subcatchments from the output file where:
//  SubcatchVar = subcatchment variable code
//  Period  = time period index
//  Value   = array that stores the retrieved values
//-----------------------------------------------------------------------------
var
  P1, P2: Int64;
  I, K: Integer;
begin
  if (Nsubcatchs > 0) and (SubcatchVar <> NONE) and (Period < Nperiods) then
  begin
    K := GetVarIndex(SubcatchVar, SUBCATCHMENTS);
    P1 := Offset1 + Period*Offset2 + SizeOf(TDateTime) + K*RecordSize;
    FileSeek(Fout, P1, 0);
    FileRead(Fout, Value^[0], SizeOf(Single));
    P2 := RecordSize*(NsubcatchVars-1);
    for I := 1 to Nsubcatchs - 1 do
    begin
      FileSeek(Fout, P2, 1);
      FileRead(Fout, Value^[I], SizeOf(Single));
    end;
  end;
end;


function GetSubcatchValStr(const SubcatchVar: Integer; const Period: LongInt;
  const SubcatchIndex: Integer): String;
//-----------------------------------------------------------------------------
//  Gets the string value of variable SubcatchVar at time period Period for
//  subcatchment with index SubcatchIndex.
//-----------------------------------------------------------------------------
var
  K:  Integer;
  Z: Single;
begin
  // Default result is N/A
  Result := NA;
  if (SubcatchVar = NOVIEW) then Exit;

  // Adjust the variable index if its for a pollutant
  if SubcatchVar >= SUBCATCHQUAL
  then K := SUBCATCHQUAL
  else K := SubcatchVar;

  // SubcatchVar is an input variable
  if (SubcatchVar < SUBCATCHOUTVAR1) then
  begin
    // Find index of variable V in property list
    K := SubcatchVariable[K].SourceIndex;
    if (K >= 0) then
    begin
      if K = SUBCATCH_LID_INDEX
      then Result := Format('%0.2f', [Ulid.GetPcntLidArea(SubcatchIndex)])
      else Result := Project.GetSubcatch(SUBCATCH, SubcatchIndex).Data[K];
    end;
  end

  // SubcatchVar is an output variable
  else
  begin
    // Make sure output results exist
    if (RunFlag) and (Period < Nperiods) then
    begin
      // Get numerical value & convert to string
      Z := GetSubcatchOutVal(GetVarIndex(SubcatchVar, SUBCATCHMENTS),
             Period, Project.GetSubcatch(SUBCATCH, SubcatchIndex).Zindex);
      if (Z <> MISSING)
      then Result := FloatToStrF(Z, ffFixed, 7, SubcatchUnits[K].Digits);
    end;
  end;
end;


function  GetSysOutVal(const V: Integer; const Period: LongInt):Single;
//-----------------------------------------------------------------------------
//  Returns the computed value for system variable V at time period Period.
//-----------------------------------------------------------------------------
var
  P: Int64;
begin
  P := Offset1 + Period*Offset2 + SizeOf(TDateTime) +
       RecordSize*(Nsubcatchs*NsubcatchVars + Nnodes*NnodeVars +
       NLinks*NlinkVars + V);
  FileSeek(Fout, P, 0);
  FileRead(Fout, Result, SizeOf(Single));
end;


function GetValue(const ObjType: Integer; const VarIndex: Integer;
  const Period: LongInt; theObject: TObject): Double;
//-----------------------------------------------------------------------------
//  Returns the value of variable VarIndex at time period Period for
//  an object of type ObjType.
//-----------------------------------------------------------------------------
begin
  Result := MISSING;
  case ObjType of
    SUBCATCHMENTS:
      Result := Uoutput.GetSubcatchOutVal(VarIndex, Period,
                  TSubcatch(theObject).Zindex);
    NODES:
      Result := Uoutput.GetNodeOutVal(VarIndex, Period,
                  TNode(theObject).Zindex);
    LINKS:
      Result := Uoutput.GetLinkOutVal(VarIndex, Period,
                  TLink(theObject).Zindex);
    SYS:
      Result := Uoutput.GetSysOutVal(VarIndex, Period);
  end;
end;


function GetVarIndex(const V: Integer; const ObjType: Integer): Integer;
//-----------------------------------------------------------------------------
//  Gets a lookup index for variable V associated with an object of
//  type ObjType.
//-----------------------------------------------------------------------------
begin
  case ObjType of

  SUBCATCHMENTS:
  begin
    if V < SUBCATCHQUAL
    then Result := SubcatchVariable[V].SourceIndex
    else Result := SubcatchVariable[SUBCATCHQUAL].SourceIndex +
                   V - SUBCATCHQUAL;
  end;

  LINKS:
  begin
    if V < LINKQUAL
    then Result := LinkVariable[V].SourceIndex
    else Result := LinkVariable[LINKQUAL].SourceIndex + V - LINKQUAL;
  end;

  NODES:
  begin
    if V < NODEQUAL
    then Result := NodeVariable[V].SourceIndex
    else Result := NodeVariable[NODEQUAL].SourceIndex + V - NODEQUAL;
  end;

  SYS:
   Result := V;

  else Result := 0;
  end;
end;


function OpenOutputFile(const Fname: String): TRunStatus;
//-----------------------------------------------------------------------------
//  Opens the project's binary output file.
//-----------------------------------------------------------------------------
//var
//  StrFname: String;
begin
  Result := rsSuccess;
  Fout := FileOpen(Fname, fmOpenRead);
  if Fout < 0 then Result := rsError;
end;


procedure SetLinkColor(L: TLink; const K: Integer);
//-----------------------------------------------------------------------------
//  Sets the map color code for input property K of Link L.
//-----------------------------------------------------------------------------
var
  X : Single;
begin
  L.ColorIndex := -1;
  if K >= 0 then
  begin
    if K = CONDUIT_SLOPE_INDEX
    then L.ColorIndex := FindLinkColor(Abs(GetConduitSlope(L)))
    else if Uutils.GetSingle(L.Data[K], X)
    then L.ColorIndex := FindLinkColor(Abs(X));
  end;
end;


procedure SetLinkColors;
//-----------------------------------------------------------------------------
//  Sets the map color coding for all links.
//-----------------------------------------------------------------------------
begin
  if CurrentLinkVar >= LINKOUTVAR1 then
  begin
    if (RunFlag = False)
    then SetLinkInColors(NOVIEW)
    else SetLinkOutColors(CurrentLinkVar);
  end
  else SetLinkInColors(CurrentLinkVar);
end;


procedure SetLinkInColors(const LinkVar: Integer);
//-----------------------------------------------------------------------------
//  Sets the map color coding for all links displaying input
//  variable LinkVar.
//-----------------------------------------------------------------------------
var
  I, J, K : Integer;
begin
  for I := 0 to MAXCLASS do
  begin
    if not Project.IsLink(I) then continue;
    if LinkVar = NOVIEW then K := -1
    else if I = CONDUIT then K := LinkVariable[LinkVar].SourceIndex
    else K := -1;
    for J := 0 to Project.Lists[I].Count-1 do
      SetLinkColor(Project.GetLink(I, J), K);
  end;
end;


procedure SetLinkOutColors(const LinkVar: Integer);
//-----------------------------------------------------------------------------
//  Sets the map color coding for all links displaying output
//  variable LinkVar.
//-----------------------------------------------------------------------------
var
  I, J, K : Integer;
  L : TLink;
begin
    GetLinkOutVals(LinkVar, CurrentPeriod, Zlink);
    for I := 0 to MAXCLASS do
    begin
      if not Project.IsLink(I) then continue;
      for J := 0 to Project.Lists[I].Count-1 do
      begin
        L := Project.GetLink(I, J);
        K := L.Zindex;
        if K >= 0
        then L.ColorIndex := FindLinkColor(abs(Zlink^[K]))
        else L.ColorIndex := -1;
      end;
    end;
end;


procedure SetNodeColor(N: TNode; const K: Integer);
//-----------------------------------------------------------------------------
//  Sets the map color code for input property K of node N.
//-----------------------------------------------------------------------------
var
  X : Single;
begin
  N.ColorIndex := -1;
  if K >= 0 then
  begin
    if Uutils.GetSingle(N.Data[K], X)
    then N.ColorIndex := FindNodeColor(X);
  end;
end;


procedure SetNodeColors;
//-----------------------------------------------------------------------------
//  Sets the map color coding for all nodes.
//-----------------------------------------------------------------------------
begin
  if CurrentNodeVar >= NODEOUTVAR1 then
  begin
    if (RunFlag = False)
    then SetNodeInColors(NOVIEW)
    else SetNodeOutColors(CurrentNodeVar);
  end
  else SetNodeInColors(CurrentNodeVar);
end;


procedure SetNodeInColors(const NodeVar: Integer);
//-----------------------------------------------------------------------------
//  Sets the map color coding for all nodes displaying input
//  variable NodeVar.
//-----------------------------------------------------------------------------
var
  I, J, K : Integer;
begin
  for I := 0 to MAXCLASS do
  begin
    if not Project.IsNode(I) then continue;
    if NodeVar = NOVIEW
    then K := -1
    else K := NodeVariable[NodeVar].SourceIndex;
    for J := 0 to Project.Lists[I].Count-1 do
      SetNodeColor(Project.GetNode(I, J), K);
  end;
end;

procedure SetNodeOutColors(const NodeVar: Integer);
//-----------------------------------------------------------------------------
//  Sets the map color coding for all nodes displaying output
//  variable NodeVar.
//-----------------------------------------------------------------------------
var
  I, J ,K : Integer;
  N : TNode;
begin
    GetNodeOutVals(NodeVar, CurrentPeriod, Znode);
    for I := 0 to MAXCLASS do
    begin
      if not Project.IsNode(I) then continue;
      for J := 0 to Project.Lists[I].Count-1 do
      begin
        N := Project.GetNode(I, J);
        K := N.Zindex;
        if K >= 0
        then N.ColorIndex := FindNodeColor(Znode^[K])
        else N.ColorIndex := -1;
      end;
    end;
end;


function SetQueryColor(const Z: Single): Integer;
//-----------------------------------------------------------------------------
//  Sets the color code in a map query for a value Z.
//-----------------------------------------------------------------------------
begin
  Result := -1;
  case QueryRelation of
  rtBelow: if Z < QueryValue then Result := 1;
  rtEquals: if Z = QueryValue then Result := 1;
  rtAbove: if Z > QueryValue then Result := 1;
  end;
end;


procedure SetSubcatchColor(S: TSubcatch; const K: Integer);
//-----------------------------------------------------------------------------
//  Sets the map color code for input property K of subcatchment S.
//-----------------------------------------------------------------------------
var
  X : Single;
begin
  S.ColorIndex := -1;
  if K >= 0 then
  begin
    if Uutils.GetSingle(S.Data[K], X)
    then S.ColorIndex := FindSubcatchColor(Abs(X));
  end;
end;


procedure SetSubcatchColors;
//-----------------------------------------------------------------------------
//  Sets the map color coding for all subcatchments.
//-----------------------------------------------------------------------------
begin
  if CurrentSubcatchVar >= SUBCATCHOUTVAR1 then
  begin
    if RunFlag = False then SetSubcatchInColors(NOVIEW)
    else SetSubcatchOutColors(CurrentSubcatchVar);
  end
  else SetSubcatchInColors(CurrentSubcatchVar);
end;


procedure SetSubcatchInColors(const SubcatchVar: Integer);
//-----------------------------------------------------------------------------
//  Sets the map color coding for all subcatchments displaying input
//  variable SubcatchVar.
//-----------------------------------------------------------------------------
var
  J, K : Integer;
  S: TSubcatch;
begin
  if SubcatchVar = NOVIEW
  then K := -1
  else K := SubcatchVariable[SubcatchVar].SourceIndex;
  for J := 0 to Project.Lists[SUBCATCH].Count-1 do
  begin
    S := Project.GetSubcatch(SUBCATCH, J);
    if K = SUBCATCH_LID_INDEX
    then S.ColorIndex := FindSubcatchColor(Ulid.GetPcntLidArea(J))
    else SetSubcatchColor(S, K);
  end;
end;


procedure SetSubcatchOutColors(const SubcatchVar: Integer);
//-----------------------------------------------------------------------------
//  Sets the map color coding for all subcatchments displaying output
//  variable SubcatchVar.
//-----------------------------------------------------------------------------
var
  J, K : Integer;
  S : TSubcatch;
begin
  GetSubcatchOutVals(SubcatchVar, CurrentPeriod, Zsubcatch);
  for J := 0 to Project.Lists[SUBCATCH].Count-1 do
  begin
    S := Project.GetSubcatch(SUBCATCH, j);
    K := S.Zindex;
    if K >= 0
    then S.ColorIndex := FindSubcatchColor(abs(Zsubcatch^[K]))
    else S.ColorIndex := -1;
  end;
end;

end.
