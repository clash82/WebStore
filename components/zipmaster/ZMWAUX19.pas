unit ZMWAUX19;

(*
  ZMWAUX19.pas - SFX and Span support
  Derived from
  * SFX for DelZip v1.7
  * Copyright 2002-2005
  * written by Markus Stephany
    Copyright (C) 2009, 2010  by Russell J. Peters, Roger Aelbrecht,
      Eric W. Engler and Chris Vleghert.

	This file is part of TZipMaster Version 1.9.

    TZipMaster is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TZipMaster is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with TZipMaster.  If not, see <http://www.gnu.org/licenses/>.

    contact: problems@delphizip.org (include ZipMaster in the subject).
    updates: http://www.delphizip.org
    DelphiZip maillist subscribe at http://www.freelists.org/list/delphizip 

  modified 2010-06-19
  --------------------------------------------------------------------------- *)
{$I '.\ZipVers19.inc'}

interface

uses
  Windows, SysUtils, Classes, Graphics, ZipMstr19, ZMSFXInt19,
  ZMStructs19, ZMCompat19, ZMZipFile19, ZMCore19, ZMCendir19;

type
  TZMWAux = class(TZMCore)
  private
    Detached: Boolean;
    FAuxChanged: Boolean;
    fCentralDir: TZMCenDir;
    FNoReadAux: Boolean;
    fRegFailPath: String;
    fSFXCaption: String;
    fSFXCommandLine: String;
    fSFXDefaultDir: String;
    fSFXIcon: TIcon;
    fSFXMessage: String;
    fSFXMessageFlags: Word;
    fSFXOptions: TZMSFXOpts;
    fSFXOverwriteMode: TZMOvrOpts;
    fSFXPath: String;
    fSuccessCnt: Integer;
    fUseDelphiBin: Boolean;
    FZipComment: AnsiString;
    fZipFileName: String;
    OutSize: Integer;
    function MapSFXSettings17(pheder: PByte; stub: TMemoryStream): Integer;
    function MapSFXSettings19(pheder: PByte; stub: TMemoryStream): Integer;
    function RecreateSingle(Intermed, theZip: TZMZipFile): Integer;
    procedure SetSFXCommandLine(const Value: String);
  protected
    fSFXBinStream: TMemoryStream;
    function BrowseResDir(ResStart, Dir: PIRD; Depth: Integer): PIRDatE;
    function CreateStubStream: Boolean;
  procedure EncodingChanged(New_Enc: TZMEncodingOpts); override;
  procedure Encoding_CPChanged(New_CP: Cardinal); override;
    function LoadFromBinFile(var stub: TStream; var Specified: Boolean)
      : Integer;
    function LoadFromResource(var stub: TStream; const sfxtyp: String): Integer;
    function LoadSFXStr(ptbl: pByte; ident: Byte): String;
    function MapOptionsFromStub(opts: Word): TZMSFXOpts;
    function MapOptionsFrom17(opts: Word): TZMSFXOpts;
    function MapOptionsToStub(opts: TZMSFXOpts): Word;
    function MapOverwriteModeFromStub(ovr: Word): TZMOvrOpts;
    function MapOverwriteModeToStub(mode: TZMOvrOpts): Word;
    function PrepareStub: Integer;
    function RecreateMVArchive(const TmpZipName: String; Recreate: Boolean):
        Boolean;
    function ReleaseSFXBin: TMemoryStream;
    function SearchResDirEntry(ResStart: PIRD; entry: PIRDirE; Depth: Integer)
      : PIRDatE;
    procedure StartUp; override;
    // 1 return true if it was there
    function TrimDetached(stub: TMemoryStream): Boolean;
    // 1 return true if it was there
    function MapSFXSettings(stub: TMemoryStream): Integer;
    function WriteEOC(Current: TZMZipFile; OutFile: Integer): Integer;
  public
    constructor Create(AMaster: TCustomZipMaster19);
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Clear; override;
    function ConvertToSFX(const OutName: string; theZip: TZMZipFile): Integer;
    function ConvertToSpanSFX(const OutFileName: String; theZip: TZMZipFile):
        Integer;
    function ConvertToZIP: Integer;
    function CopyBuffer(InFile, OutFile: Integer; ReadLen: Int64): Integer;
    function Copy_File(const InFileName, OutFileName: String): Integer;
    function CurrentZip(MustExist: Boolean; SafePart: Boolean = false)
      : TZMZipFile;
    procedure Deflate(OutStream, InStream: TStream; Length: Int64; var Method:
        TZMDeflates; var crc: Cardinal); virtual; abstract;
    function DetachedSize(zf: TZMZipFile): Integer;
    procedure Done(Good: Boolean = true); override;
    function GetAuxProperties: Boolean;
    function IsDetachSFX(zfile: TZMZipFile): Boolean;
    function IsZipSFX(const SFXExeName: String): Integer;
    procedure LoadZip(const ZipName: String; NoEvent: Boolean);
    function NewSFXFile(const ExeName: String): Integer;
    function NewSFXStub: TMemoryStream;
    function ReadSpan(const InFileName: String; var OutFilePath: String;
      UseXProgress: Boolean): Integer;
    //1 Remake Intermed using parameters of theZip
    function Recreate(Intermed, theZip: TZMZipFile): Integer;
    function RejoinMVArchive(var TmpZipName: String): Integer;
    function RemakeTemp(temp: TZMZipFile; Recreate, detach: Boolean): Integer;
    procedure Set_ZipFileName(const zname: String; Load: TZLoadOpts);
    procedure Undeflate(OutStream, InStream: TStream; Length: Int64; var Method:
        TZMDeflates; var crc: Cardinal); virtual; abstract;
    function WriteDetached(zf: TZMZipFile): Integer;
    function WriteMulti(Src: TZMZipFile; Dest: TZMZipCopy;
      UseXProgress: Boolean): Integer;
    function WriteSpan(const InFileName, OutFileName: String;
      UseXProgress: Boolean): Integer;
    property AuxChanged: Boolean read FAuxChanged write FAuxChanged;
    property CentralDir: TZMCenDir Read fCentralDir;
    property NoReadAux: Boolean read FNoReadAux write FNoReadAux;
    property RegFailPath: String read fRegFailPath write fRegFailPath;
    property SFXCaption: String read fSFXCaption write fSFXCaption;
    property SFXCommandLine
      : String Read fSFXCommandLine Write SetSFXCommandLine;
    property SFXDefaultDir: String read fSFXDefaultDir write fSFXDefaultDir;
    property SFXIcon: TIcon Read fSFXIcon;
    property SFXMessage: String read fSFXMessage write fSFXMessage;
    property SFXOptions: TZMSFXOpts Read fSFXOptions Write fSFXOptions;
    (* This value controls the behaviour of the SFX when a file to be extracted
      would overwrite an existing file on disk:<br><br>
      - <u>somOverwrite</u>:<br> Always overwrite existing files<br><br>
      - <u>somSkip</u>:<br> Never overwrite existing files<br><br>
      - <u>somAsk</u>:<br> Let the user confirm overwriting.<br><br><br><br>
      *)
    property SFXOverwriteMode
      : TZMOvrOpts Read fSFXOverwriteMode Write fSFXOverwriteMode default
      ovrConfirm;
    property SFXPath: String read fSFXPath write fSFXPath;
    property SuccessCnt: Integer Read fSuccessCnt Write fSuccessCnt;
    property ZipComment: AnsiString read FZipComment write FZipComment;
    property ZipFileName: String Read fZipFileName;
  end;

implementation

uses
  Dialogs, ZMMsg19, ZMDrv19, ZMDelZip19,
  ZMUtils19, ZMXcpt19, ZMMsgStr19, ZMEOC19, ZMWorkFile19,
  ZMIRec19, ZMUTF819, ZMMatch19, ShellAPI;

const
  SPKBACK001 = 'PKBACK#001';
  { File Extensions }
  ExtZip = 'zip';
  DotExtZip = '.' + ExtZip;
  ExtExe = 'exe';
  DotExtExe = '.' + ExtExe;
  ExtBin = 'bin';
  ExtZSX = 'zsx';
  { Identifiers }
  DzSfxID = 'DZSFX';

const
  MinStubSize = 12000;
  MaxStubSize = 80000;
  BufSize = 10240;
  // 8192;   // Keep under 12K to avoid Winsock problems on Win95.
  // If chunks are too large, the Winsock stack can
  // lose bytes being sent or received.

function WriteCommand(Dest: TMemoryStream; const cmd: string; ident: Integer)
  : Integer; Forward;

type
  TZMLoader = class(TZMZipFile)
  private
    fForZip: TZMZipFile;
    fname: String;
    fSFXWorker: TZMWAux;
    procedure SetForZip(const Value: TZMZipFile);
  protected
    function AddStripped(const rec: TZMIRec): Integer;
    function BeforeCommit: Integer; override;
    function PrepareDetached: Integer;
    function StripEntries: Integer;
  public
    constructor Create(Wrkr: TZMCore); override;
    procedure AfterConstruction; override;
    property ForZip: TZMZipFile Read fForZip Write SetForZip;
    property SFXWorker: TZMWAux Read fSFXWorker;
  end;

type
  TFileNameIs = (fiExe, fiZip, fiOther, fiEmpty);

const
  SFXBinDefault: string = 'ZMSFX19.bin';
//  SFXBufSize: Word = $2000;

const
  SE_CreateError = -1;    // Error in open or creation of OutFile.
  SE_CopyError = -2;      // Write error or no memory during copy.
  SE_OpenReadError = -3;  // Error in open or Seek of InFile.
  SE_SetDateError = -4;   // Error setting date/time of OutFile.
  SE_GeneralError = -9;

function WriteIconToStream(Stream: Classes.TStream; Icon: HICON;
  Width, Height, Depth: Integer): Integer; forward;

// get the kind of filename
function GetFileNameKind(const sFile: TFileName): TFileNameIs;
var
  sExt: String;
begin
  if sFile = '' then
    Result := fiEmpty
  else
  begin
    sExt := LowerCase(ExtractFileExt(sFile));
    if sExt = DotExtZip then
      Result := fiZip
    else if sExt = DotExtExe then
      Result := fiExe
    else
      Result := fiOther;
  end;
end;

function FindFirstIcon(var rec: TImageResourceDataEntry; const iLevel: Integer;
  const PointerToRawData: Cardinal; str: TStream): Boolean;
var
  i: Integer;
  iPos: Integer;
  RecDir: TImageResourceDirectory;
  RecEnt: TImageResourceDirectoryEntry;
begin
  // position must be correct
  Result := false;
  if (str.Read(RecDir, sizeof(RecDir)) <> sizeof(RecDir)) then
    raise EZipMaster.CreateResDisp(CZ_BrowseError, true);

  for i := 0 to Pred(RecDir.NumberOfNamedEntries + RecDir.NumberOfIdEntries) do
  begin
    if (str.Read(RecEnt, sizeof(RecEnt)) <> sizeof(RecEnt)) then
      raise EZipMaster.CreateResDisp(CZ_BrowseError, true);

    // check if a directory or a resource
    iPos := str.Position;
    try
      if (RecEnt.un2.DataIsDirectory and IMAGE_RESOURCE_DATA_IS_DIRECTORY)
        = IMAGE_RESOURCE_DATA_IS_DIRECTORY then
      begin
        if ((iLevel = 0) and (MakeIntResource(RecEnt.un1.Name) <> RT_ICON)) or
          ((iLevel = 1) and (RecEnt.un1.Id <> 1)) then
          Continue; // not an icon of id 1

        str.Seek(RecEnt.un2.OffsetToDirectory and
            (not IMAGE_RESOURCE_DATA_IS_DIRECTORY) + PointerToRawData,
          soFromBeginning);
        Result := FindFirstIcon(rec, iLevel + 1, PointerToRawData, str);
        if Result then
          Break;
      end
      else
      begin
        // is resource bin data
        str.Seek(RecEnt.un2.OffsetToData + PointerToRawData, soFromBeginning);
        if str.Read(rec, sizeof(rec)) <> sizeof(rec) then
          raise EZipMaster.CreateResDisp(CZ_BrowseError, true);
        Result := true;
        Break;
      end;
    finally
      str.Position := iPos;
    end;
  end;
end;

procedure LocateFirstIconHeader(str: TStream;
  var hdrSection: TImageSectionHeader; var recIcon: TImageResourceDataEntry);
var
  bFound: Boolean;
  cAddress: Cardinal;
  hdrDos: TImageDosHeader;
  hdrNT: TImageNTHeaders;
  i: Integer;
begin
  bFound := false;
  // check if we have an executable
  str.Seek(0, soFromBeginning);
  if (str.Read(hdrDos, sizeof(hdrDos)) <> sizeof(hdrDos)) or
    (hdrDos.e_magic <> IMAGE_DOS_SIGNATURE) then
    raise EZipMaster.CreateResDisp(CZ_InputNotExe, true);

  str.Seek(hdrDos._lfanew, soFromBeginning);
  if (str.Read(hdrNT, sizeof(hdrNT)) <> sizeof(hdrNT)) or
    (hdrNT.Signature <> IMAGE_NT_SIGNATURE) then
    raise EZipMaster.CreateResDisp(CZ_InputNotExe, true);

  // check if we have a resource section
  with hdrNT.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_RESOURCE] do
    if (VirtualAddress = 0) or (Size = 0) then
      raise EZipMaster.CreateResDisp(CZ_NoExeResource, true)
    else
      cAddress := VirtualAddress; // store address

  // iterate over sections
  for i := 0 to Pred(hdrNT.FileHeader.NumberOfSections) do
  begin
    if (str.Read(hdrSection, sizeof(hdrSection)) <> sizeof(hdrSection)) then
      raise EZipMaster.CreateResDisp(CZ_ExeSections, true);

    // with hdrSection do
    if hdrSection.VirtualAddress = cAddress then
    begin
      bFound := true;
      Break;
    end;
  end;

  if not bFound then
    raise EZipMaster.CreateResDisp(CZ_NoExeResource, true);

  // go to resource data
  str.Seek(hdrSection.PointerToRawData, soFromBeginning);

  // recourse through the resource dirs to find an icon
  if not FindFirstIcon(recIcon, 0, hdrSection.PointerToRawData, str) then
    raise EZipMaster.CreateResDisp(CZ_NoExeIcon, true);
end;

// replaces an icon in an executable file (stream)
function GetFirstIcon(str: TMemoryStream): TIcon;
var
  bad: Boolean;
  delta: Cardinal;
  handle: HIcon;
  hdrSection: TImageSectionHeader;
  icoData: PByte;
  icoSize: Cardinal;
  recIcon: TImageResourceDataEntry;
begin
  bad := true;
  Result := nil;
  LocateFirstIconHeader(str, hdrSection, recIcon);
  delta := Integer(hdrSection.PointerToRawData) - Integer
    (hdrSection.VirtualAddress) + Integer(recIcon.OffsetToData);
  icoData := PByte(str.Memory);
  Inc(icoData, delta);
  icoSize := hdrSection.SizeOfRawData;
  handle := CreateIconFromResource(icoData, icoSize, true, $30000);
  if handle <> 0 then
  begin
    Result := TIcon.Create;
    Result.handle := handle;
    bad := false;
  end;
  if bad then
    // no icon copied, so none of matching size found
    raise EZipMaster.CreateResDisp(CZ_NoIconFound, true);
end;

// returns size or 0 on error or wrong dimensions
function WriteIconToStream(Stream: Classes.TStream; Icon: HIcon;
  Width, Height, Depth: Integer): Integer;
type
  PIconRec = ^TIconRec;

  TIconRec = packed record
    IDir: TIconDir;
    IEntry: TIconDirEntry;
  end;
const
  RC3_ICON = 1;
var
  BI: PBITMAPINFO;
  BIsize: Integer;
  CBits: PByte;
  cbm: Bitmap;
  cofs: Integer;
  colors: Integer;
  dc: HDC;
  Ico: TIconRec;
  IconInfo: TIconInfo;
  MBI: BitMapInfo;
  MBits: PByte;
  mofs: Integer;
begin
  Result := 0;

  if (Depth <= 4) then
    Depth := 4
  else if (Depth <= 8) then
    Depth := 8
  else if (Depth <= 16) then
    Depth := 16
  else if (Depth <= 24) then
    Depth := 24
  else
    exit;
  colors := 1 shl Depth;

  BI := nil;
  dc := 0;
  if GetIconInfo(Icon, IconInfo) then
  begin
    try
      ZeroMemory(@Ico, sizeof(TIconRec));
      if GetObject(IconInfo.hbmColor, sizeof(Bitmap), @cbm) = 0 then
        exit;
      if (Width <> cbm.bmWidth) or (Height <> cbm.bmHeight) then
        exit;

      // ok should be acceptable
      BIsize := sizeof(BitmapInfoHeader);
      if (Depth <> 24) then
        Inc(BIsize, colors * sizeof(RGBQUAD)); // pallet

      cofs := BIsize; // offset to colorbits
      Inc(BIsize, (Width * Height * Depth) div 8); // bits
      mofs := BIsize; // offset to maskbits
      Inc(BIsize, (Width * Height) div 8);

      // allocate memory for it
      GetMem(BI, BIsize);

      ZeroMemory(BI, BIsize);
      // set required attributes for colour bitmap
      BI^.bmiHeader.BIsize := sizeof(BitmapInfoHeader);
      BI^.bmiHeader.biWidth := Width;
      BI^.bmiHeader.biHeight := Height;
      BI^.bmiHeader.biPlanes := 1;
      BI^.bmiHeader.biBitCount := Depth;
      BI^.bmiHeader.biCompression := BI_RGB;

      CBits := PByte(BI);
      Inc(CBits, cofs);

      // prepare for mono mask bits
      ZeroMemory(@MBI, sizeof(BitMapInfo));
      MBI.bmiHeader.BIsize := sizeof(BitmapInfoHeader);
      MBI.bmiHeader.biWidth := Width;
      MBI.bmiHeader.biHeight := Height;
      MBI.bmiHeader.biPlanes := 1;
      MBI.bmiHeader.biBitCount := 1;

      MBits := PByte(BI);
      Inc(MBits, mofs);

      dc := CreateCompatibleDC(0);
      if dc <> 0 then
      begin
        if GetDIBits(dc, IconInfo.hbmColor, 0, Height, CBits, BI^,
          DIB_RGB_COLORS) > 0 then
        begin
          // ok get mask bits
          if GetDIBits(dc, IconInfo.hbmMask, 0, Height, MBits, MBI,
            DIB_RGB_COLORS) > 0 then
          begin
            // good we have both
            DeleteDC(dc); // release it quick before anything can go wrong
            dc := 0;
            Ico.IDir.ResType := RC3_ICON;
            Ico.IDir.ResCount := 1;
            Ico.IEntry.bWidth := Width;
            Ico.IEntry.bHeight := Height;
            Ico.IEntry.bColorCount := Depth;
            Ico.IEntry.dwBytesInRes := BIsize;
            Ico.IEntry.dwImageOffset := sizeof(TIconRec);
            BI^.bmiHeader.biHeight := Height * 2;
            // color height includes mask bits
            Inc(BI^.bmiHeader.biSizeImage, MBI.bmiHeader.biSizeImage);
            if (Stream <> nil) then
            begin
              Stream.Write(Ico, sizeof(TIconRec));
              Stream.Write(BI^, BIsize);
            end;
            Result := BIsize + sizeof(TIconRec);
          end;
        end;
      end;
    finally
      if dc <> 0 then
        DeleteDC(dc);
      DeleteObject(IconInfo.hbmColor);
      DeleteObject(IconInfo.hbmMask);
      if BI <> nil then
        FreeMem(BI);
    end;
  end
  else
    RaiseLastOSError;
end;

// replaces an icon in an executable file (stream)
procedure ReplaceIcon(str: TMemoryStream; oIcon: TIcon);
var
  bad: Boolean;
  hdrSection: TImageSectionHeader;
  i: Integer;
  oriInfo: BitmapInfoHeader;
  pIDE: PIconDirEntry;
  recIcon: TImageResourceDataEntry;
  strIco: TMemoryStream;
begin
  bad := true;
  LocateFirstIconHeader(str, hdrSection, recIcon);
  str.Seek(Integer(hdrSection.PointerToRawData) - Integer
      (hdrSection.VirtualAddress) + Integer(recIcon.OffsetToData),
    soFromBeginning);
  if (str.Read(oriInfo, sizeof(BitmapInfoHeader)) <> sizeof(BitmapInfoHeader)) then
    raise EZipMaster.CreateResDisp(CZ_NoCopyIcon, true);

  // now check the icon
  strIco := TMemoryStream.Create;
  try
    if WriteIconToStream(strIco, oIcon.handle, oriInfo.biWidth,
      oriInfo.biHeight div 2, oriInfo.biBitCount) <= 0 then
      raise EZipMaster.CreateResDisp(CZ_NoIcon, true);

    // now search for matching icon
    with PIconDir(strIco.Memory)^ do
    begin
      if (ResType <> RES_ICON) or (ResCount < 1) or (Reserved <> 0) then
        raise EZipMaster.CreateResDisp(CZ_NoIcon, true);

      for i := 0 to Pred(ResCount) do
      begin
        pIDE := PIconDirEntry(PAnsiChar(strIco.Memory) + sizeof(TIconDir) +
            (i * sizeof(TIconDirEntry)));
        if (pIDE^.dwBytesInRes = recIcon.Size) and (pIDE^.bReserved = 0) then
        begin
          // matching icon found, replace
          strIco.Seek(pIDE^.dwImageOffset, soFromBeginning);
          str.Seek(Integer(hdrSection.PointerToRawData) - Integer
              (hdrSection.VirtualAddress) + Integer(recIcon.OffsetToData),
            soFromBeginning);
          if str.CopyFrom(strIco, recIcon.Size) <> Integer(recIcon.Size) then
            raise EZipMaster.CreateResDisp(CZ_NoCopyIcon, true);

          // ok and out
          bad := false;
        end;
      end;
    end;
  finally
    strIco.Free;
  end;
  if bad then
    // no icon copied, so none of matching size found
    raise EZipMaster.CreateResDisp(CZ_NoIconFound, true);
end;

{ TZMWAux }

constructor TZMWAux.Create(AMaster: TCustomZipMaster19);
begin
  inherited Create(AMaster);
end;

function TZMWAux.BrowseResDir(ResStart, Dir: PIRD; Depth: Integer): PIRDatE;
var
  i: Integer;
  SingleRes: PIRDirE;
  x: PByte;
begin
  Result := nil;
  x := PByte(Dir);
  Inc(x, sizeof(IMAGE_RESOURCE_DIRECTORY));
  SingleRes := PIRDirE(x);

  for i := 1 to Dir.NumberOfNamedEntries + Dir.NumberOfIdEntries do
  begin
    Result := SearchResDirEntry(ResStart, SingleRes, Depth);
    if Result <> nil then
      Break; // Found the one w're looking for.
  end;
end;

procedure TZMWAux.Clear;
begin
  fZipFileName := '';
  fSuccessCnt := 0;
  FZipComment := '';
  CentralDir.Clear;
  Detached := false;
  SFXOverwriteMode := ovrConfirm;
  fSFXCaption := 'Self-extracting Archive';
  fSFXDefaultDir := '';
  fSFXCommandLine := '';
  inherited;
end;

function TZMWAux.ConvertToSFX(const OutName: string; theZip: TZMZipFile):
    Integer;
var
  nn: String;
  oz: TZMZipCopy;
  useTemp: Boolean;
begin
  Diag('ConvertToSFX');
  if theZip = nil then
    theZip := CurrentZip(True); // use Current
  Detached := false;
  Result := PrepareStub;
  if (Result < 0) or not assigned(fSFXBinStream) then
  begin
    // result:= some error;
    exit;
  end;
  if OutName = '' then
    nn := ChangeFileExt(theZip.FileName, DotExtExe)
  else
    nn := OutName;
  useTemp := FileExists(nn);
  oz := TZMZipCopy.Create(self);
  try
    if useTemp then
      oz.File_CreateTemp(ExtZSX, '')
    else
      oz.File_Create(nn);
    oz.stub := fSFXBinStream;
    fSFXBinStream := nil;
    oz.UseSFX := true;
    Result := oz.WriteFile(theZip, true);
    theZip.File_Close;
    if (Result >= 0) then
    begin
      if useTemp and not oz.File_Rename(nn, HowToDelete <> htdFinal) then
        raise EZipMaster.CreateRes2Str(CF_CopyFailed, oz.FileName, nn);
      Result := 0;
      Set_ZipFileName(nn, zloFull);
    end;
  finally
    oz.Free;
  end;
end;

function TZMWAux.ConvertToSpanSFX(const OutFileName: String; theZip:
    TZMZipFile): Integer;
var
  DiskFile: String;
  DiskSerial: Cardinal;
  Dummy1: Cardinal;
  Dummy2: Cardinal;
  FileListSize: Cardinal;
  FreeOnDisk1: Cardinal;
  KeepFree: Cardinal;
  LDiskFree: Cardinal;
  MsgStr: String;
  OrgKeepFree: Cardinal;
  OutDrv: TZMWorkDrive;
  PartFileName: String;
  RightDiskInserted: Boolean;
  SFXName: String;
  SplitZip: TZMZipCopy;
  VolName: array [0 .. MAX_PATH - 1] of Char;
begin
  Detached := true;
  // prepare stub
  Result := PrepareStub;
  if (Result >= 0) and assigned(fSFXBinStream) then
  begin
    SplitZip := nil;
    if theZip = nil then
      theZip := CentralDir.Current; // use Current
    PartFileName := ChangeFileExt(OutFileName, DotExtZip);
    // delete the existing sfx stub
    if FileExists(OutFileName) then
      DeleteFile(OutFileName);
    SFXName := ExtractFileName(ChangeFileExt(OutFileName, DotExtZip));
    FileListSize := DetachedSize(theZip);//Current);
    OrgKeepFree := KeepFreeOnDisk1;
    OutDrv := TZMWorkDrive.Create;
    try
      // get output parameters
      OutDrv.DriveStr := OutFileName;
      OutDrv.HasMedia(true); // set media details

      // calulate the size of the sfx stub
      Result := 0; // is good (at least until it goes bad)

      if (not OutDrv.DriveIsFixed) and (MaxVolumeSize = 0) then
      begin
        MaxVolumeSize := OutDrv.VolumeSize;
      end;
      // first test if multiple parts are really needed
      if (MaxVolumeSize <= 0) or ((theZip.File_Size + fSFXBinStream.Size)
          < MaxVolumeSize) then
      begin
        Diag('Too small for span sfx');
        Detached := false;
        Result := ConvertToSFX(OutFileName, theZip);
      end
      else
      begin
        FileListSize := FileListSize + sizeof(Integer) + sizeof
          (TZipEndOfCentral);
        if KeepFreeOnDisk1 <= 0 then
          KeepFree := 0
        else
          KeepFree := KeepFreeOnDisk1;
        KeepFree := KeepFree + FileListSize;
        if OutDrv.VolumeSize > MAXINT then
          LDiskFree := MAXINT
        else
          LDiskFree := Cardinal(OutDrv.VolumeSize);
        { only one set of ' span' params }
        if (MaxVolumeSize > 0) and (MaxVolumeSize < LDiskFree) then
          LDiskFree := MaxVolumeSize;
        if (FileListSize > LDiskFree) then
          Result := -SF_DetachedHeaderTooBig;

        if Result = 0 then // << moved
        begin
          if (KeepFree mod OutDrv.VolumeSecSize) <> 0 then
            FreeOnDisk1 := ((KeepFree div OutDrv.VolumeSecSize) + 1)
              * OutDrv.VolumeSecSize
          else
            FreeOnDisk1 := KeepFree;

          // let the spanslave of the Worker do the spanning <<< bad comment - remove
          KeepFreeOnDisk1 := FreeOnDisk1;
          SplitZip := TZMZipCopy.Create(self);
          SplitZip.FileName := PartFileName;
          Result := WriteMulti(theZip, SplitZip, true);
          // if all went well - rewrite the loader correctly
          if (Result = 0) and not OutDrv.DriveIsFixed then
          begin
            // for removable disk we need to insert the first again
            RightDiskInserted := false;
            while not RightDiskInserted do
            begin // ask to insert the first disk
              MsgStr := ZipFmtLoadStr(DS_InsertAVolume, [1]) + ZipFmtLoadStr
                (DS_InDrive, [OutDrv.DriveStr]);

              MessageDlg(MsgStr, mtInformation, [mbOK], 0);
              // check if right disk is inserted
              if SplitZip.Numbering = znsVolume then
              begin
                GetVolumeInformation(PChar(@OutDrv.DriveStr), VolName, MAX_PATH,
                  @DiskSerial, Dummy1, Dummy2, nil, 0);
                if (StrComp(VolName, SPKBACK001) = 0) then
                  RightDiskInserted := true;
              end
              else
              begin
                DiskFile := Copy(PartFileName, 1, Length(PartFileName)
                    - Length(ExtractFileExt(PartFileName))) + '001.zip';
                if FileExists(DiskFile) then
                  RightDiskInserted := true;
              end;
            end;
          end;
          // write the loader
          if Result = 0 then
            Result := WriteDetached(SplitZip);
        end;
      end;
    finally
      FreeAndNil(SplitZip);
      FreeAndNil(OutDrv);
      // restore original value
      KeepFreeOnDisk1 := OrgKeepFree;
    end;
  end;
  if Result < 0 then
    CleanupFiles(true);
end;

function TZMWAux.ConvertToZIP: Integer;
var
  cz: TZMZipFile;
  nn: String;
  oz: TZMZipCopy;
  useTemp: Boolean;
begin
  Diag('ConvertToZip');
  cz := CurrentZip(true);
  nn := ChangeFileExt(cz.FileName, DotExtZip);
  useTemp := FileExists(nn);
  oz := TZMZipCopy.Create(self);
  try
    if useTemp then
      oz.File_CreateTemp(ExtZSX, '')
    else
      oz.File_Create(nn);
    Result := oz.WriteFile(cz, true);
    cz.File_Close;
    if (Result >= 0) then
    begin
      if useTemp and not oz.File_Rename(nn, HowToDelete <> htdFinal) then
        raise EZipMaster.CreateRes2Str(CF_CopyFailed, oz.FileName, nn);
      Result := 0;
      Set_ZipFileName(nn, zloFull);
    end;
  finally
    oz.Free;
  end;
end;

function TZMWAux.CopyBuffer(InFile, OutFile: Integer; ReadLen: Int64)
  : Integer;
var
  Buffer: array of Byte;
  SizeR: Integer;
  ToRead: Cardinal;
begin
  // both files are already open
  Result := 0;
  if ReadLen = 0 then
    exit;
  ToRead := BufSize;
  try
    SetLength(Buffer, BufSize);
    repeat
      if ReadLen >= 0 then
      begin
        ToRead := BufSize;
        if ReadLen < ToRead then
          ToRead := ReadLen;
      end;
      SizeR := FileRead(InFile, Buffer[0], ToRead);
      if (SizeR < 0) or (FileWrite(OutFile, Buffer[0], SizeR) <> SizeR) then
      begin
        Result := SE_CopyError;
        Break;
      end;
      if (ReadLen > 0) then
        ReadLen := ReadLen - Cardinal(SizeR);
      case ShowProgress of
        zspFull:
          ReportProgress(zacProgress, 0, '', SizeR);
        zspExtra:
          ReportProgress(zacXProgress, 0, '', SizeR);
      else
        KeepAlive; // Mostly for winsock.
      end;
    until ((ReadLen = 0) or (SizeR <> Integer(ToRead)));
  except
    Result := SE_CopyError;
  end;
  // leave both files open
end;

function TZMWAux.Copy_File(const InFileName, OutFileName: String): Integer;
var
  InFile: Integer;
  In_Size: Int64;
  OutFile: Integer;
  Out_Size: Int64;
begin
  In_Size := -1;
  Out_Size := -1;
  Result := SE_OpenReadError;
  ShowProgress := zspNone;

  if not FileExists(InFileName) then
    exit;
  InFile := FileOpen(InFileName, fmOpenRead or fmShareDenyWrite);
  if InFile <> -1 then
  begin
    if FileExists(OutFileName) then
    begin
      OutFile := FileOpen(OutFileName, fmOpenWrite or fmShareExclusive);
      if OutFile = -1 then
      begin
        Result := SE_CreateError; // might be read-only or source
        File_Close(InFile);
        exit;
      end;
      File_Close(OutFile);
      EraseFile(OutFileName, HowToDelete = htdFinal);
    end;
    OutFile := FileCreate(OutFileName);
    if OutFile <> -1 then
    begin
      Result := CopyBuffer(InFile, OutFile, -1);
      if (Result = 0) and (FileSetDate(OutFile, FileGetDate(InFile)) <> 0)
        then
        Result := SE_SetDateError;
      Out_Size := FileSeek64(OutFile, Int64(0), soFromEnd);
      File_Close(OutFile);
    end
    else
      Result := SE_CreateError;
    In_Size := FileSeek64(InFile, Int64(0), soFromEnd);
    File_Close(InFile);
  end;
  // An extra check if the filesizes are the same.
  if (Result = 0) and ((In_Size = -1) or (Out_Size = -1) or (In_Size <> Out_Size)
    ) then
    Result := SE_GeneralError;
  // Don't leave a corrupted outfile lying around. (SetDateError is not fatal!)
  if (Result <> 0) and (Result <> SE_SetDateError) then
    SysUtils.DeleteFile(OutFileName);
end;

function TZMWAux.CreateStubStream: Boolean;
const
  MinVers = 1900000;
var
  binname: string;
  BinStub: TStream;
  BinVers: Integer;
  err: Boolean;
  ResStub: TStream;
  ResVers: Integer;
  stub: TStream;
  stubname: string;
  UseBin: Boolean;
begin
  // what type of bin will be used
  stub := nil;
  ResStub := nil;
  BinStub := nil;
  BinVers := -1;
  FreeAndNil(fSFXBinStream); // dispose of existing (if any)
  try
    // load it either from resource (if bcsfx##.res has been linked to the executable)
    // or by loading from file in SFXPath and check both versions if available
    // ResVersion := '';
    stubname := DZRES_SFX;
    binname := SFXBinDefault;
    err := false; // resource stub not found
    if (Length(SFXPath) > 1) and (SFXPath[1] = '>') and
      (SFXPath[Length(SFXPath)] = '<') then
    begin
      // must use from resource
      stubname := Copy(SFXPath, 2, Length(SFXPath) - 2);
      if stubname = '' then
        stubname := DZRES_SFX;
      ResVers := LoadFromResource(ResStub, stubname);
      if ResVers < MinVers then
        err := true;
    end
    else
    begin
      // get from resource if it exists
      ResVers := LoadFromResource(ResStub, DZRES_SFX);
      // load if exists from file
      BinVers := LoadFromBinFile(BinStub, UseBin);
      if UseBin then
        ResVers := 0;
    end;
    if not err then
    begin
      // decide which will be used
      if (BinVers >= MinVers) and (BinVers >= ResVers) then
        stub := BinStub
      else
      begin
        if ResVers >= MinVers then
          stub := ResStub
        else
          err := true;
      end;
    end;
    if stub <> nil then
    begin
      fSFXBinStream := TMemoryStream.Create();
      try
        if fSFXBinStream.CopyFrom(stub, stub.Size - sizeof(Integer)) <>
          (stub.Size - sizeof(Integer)) then
          raise EZipMaster.CreateResDisp(DS_CopyError, true);
        fSFXBinStream.Position := 0;
        if assigned(SFXIcon) then
          ReplaceIcon(fSFXBinStream, SFXIcon);
        fSFXBinStream.Position := 0;
      except
        FreeAndNil(fSFXBinStream);
      end;
    end;
  finally
    FreeAndNil(ResStub);
    FreeAndNil(BinStub);
  end;
  if err then
    raise EZipMaster.CreateResStr(SF_NoZipSFXBin, stubname);
  Result := fSFXBinStream <> nil;
end;

function TZMWAux.CurrentZip(MustExist: Boolean; SafePart: Boolean = false)
  : TZMZipFile;
begin
  if ZipFileName = '' then
    raise EZipMaster.CreateResDisp(GE_NoZipSpecified, true);
  Result := CentralDir.Current;
  if MustExist and ((zfi_Loaded and Result.info) = 0) then
    raise EZipMaster.CreateResDisp(DS_NoValidZip, true);
  if SafePart and ((zfi_Cancelled and Result.info) <> 0) then
  begin
    if Result.AskAnotherDisk(ZipFileName) = idCancel then
      raise EZipMaster.CreateResDisp(GE_Abort, false);
    Result.info := 0; // clear error
  end;

  if Result.FileName = '' then
  begin
    // creating new file
    Result.FileName := ZipFileName;
    Result.ReqFileName := ZipFileName;
  end;
end;

function TZMWAux.DetachedSize(zf: TZMZipFile): Integer;
var
  Data: TZMRawBytes;
  Has64: Boolean;
  i: Integer;
  ix: Integer;
  rec: TZMIRec;
  sz: Integer;
begin
  Result := -1;
  ASSERT(assigned(zf), 'no input');
  // Diag('Write file');
  if not assigned(zf) then
    exit;
  if fSFXBinStream = nil then
  begin
    Result := PrepareStub;
    if Result < 0 then
      exit;
  end;
  Result := fSFXBinStream.Size;

  Has64 := false;
  // add approximate central directory size
  for i := 0 to zf.Count - 1 do
  begin
    rec := zf[i];
    Result := Result + sizeof(TZipCentralHeader) + rec.FileNameLength;
    if rec.ExtraFieldLength > 4 then
    begin
      ix := 0;
      sz := 0;
      Data := rec.ExtraField;
      if XData(Data, Zip64_data_tag, ix, sz) then
      begin
        Result := Result + sz;
        Has64 := true;
      end;
      if XData(Data, UPath_Data_Tag, ix, sz) then
        Result := Result + sz;
      if XData(Data, NTFS_data_tag, ix, sz) and (sz >= 36) then
        Result := Result + sz;
    end;
  end;
  Result := Result + sizeof(TZipEndOfCentral);
  if Has64 then
  begin
    // also has EOC64
    Inc(Result, sizeof(TZip64EOCLocator));
    Inc(Result, zf.Z64VSize);
  end;
end;

procedure TZMWAux.Done(Good: Boolean = true);
var
  czip: TZMZipFile;
begin
  if not Good then
  begin
    czip := CentralDir.Current;
    if czip.info <> 0 then
    begin
      czip.info := (czip.info and zfi_Cancelled) or zfi_Error;
    end;
  end;
  inherited;
end;

procedure TZMWAux.EncodingChanged(New_Enc: TZMEncodingOpts);
var
  cz: TZMZipFile;
begin
  cz := CentralDir.Current;
  cz.Encoding := New_Enc;
end;

procedure TZMWAux.Encoding_CPChanged(New_CP: Cardinal);
var
  cz: TZMZipFile;
begin
  cz := CentralDir.Current;
  cz.Encoding_CP := New_CP;
end;

function TZMWAux.GetAuxProperties: Boolean;
var
  r: Integer;
  czip: TZMZipFile;
begin
  Result := False; // don't clear
  czip := CentralDir.Current;
  if (czip.info and zfi_DidLoad) <> 0 then
  begin
    if czip.stub <> nil then
    begin
      // read Aux Settings from stub into component
      r := MapSFXSettings(czip.stub);
      if r <> 0 then
        exit;   // not easy to show warning
    end;
    if czip.MultiDisk then
    begin
      Master.SpanOptions := czip.MapNumbering(Master.SpanOptions);
      // set multi-disk
      Master.WriteOptions := Master.WriteOptions + [zwoDiskSpan];
    end
    else
      Master.WriteOptions := Master.WriteOptions - [zwoDiskSpan];
    Result := True;   // clear AuxChanged
    czip.info := czip.info and (not zfi_DidLoad);  // don't clear again
  end;
end;

// if is detached sfx - set stub excluding the detached header
function TZMWAux.IsDetachSFX(zfile: TZMZipFile): Boolean;
var
  cstt: Integer;
  ms: TMemoryStream;
begin
  Result := false;
  try
    zfile.stub := nil; // remove old
    ms := nil;
    if (zfile.IsOpen) and (zfile.DiskNr = 0) and (zfile.Sig = zfsDOS) then
    begin
      // check invalid values
      if (zfile.EOCOffset <= zfile.CentralSize) or
        (zfile.CentralSize < sizeof(TZipCentralHeader)) then
        exit;
      cstt := zfile.EOCOffset - zfile.CentralSize;
      // must have SFX stub but we only check for biggest practical header
      if (cstt < MinStubSize) or (cstt > MaxStubSize) then
        exit;
      if zfile.Seek(0, 0) <> 0 then
        exit;
      ms := TMemoryStream.Create;
      try
        if zfile.ReadTo(ms, cstt + 4) = (cstt + 4) then
        begin
          Result := TrimDetached(ms);
        end;
      finally
        ms.Free;
      end;
    end;
  except
    Result := false;
    FreeAndNil(ms);
  end;
end;

(* ? TZMWAux.IsZipSFX
Return value:
0 = The specified file is not a SFX
>0 = It is one
-7  = Open, read or seek error
-8  = memory error
-9  = exception error
-10 = all other exceptions
*)
function TZMWAux.IsZipSFX(const SFXExeName: String): Integer;
const
  SFXsig = zqbStartEXE or zqbHasCentral or zqbHasEOC;
var
  n: string;
  r: Integer;
  sz: Integer;
begin
  r := QueryZip(SFXExeName);
  // SFX = 1 + 128 + 64
  Result := 0;
  if (r and SFXsig) = SFXsig then
    Result := CheckSFXType(SFXExeName, n, sz);
end;

function TZMWAux.LoadFromBinFile(var stub: TStream; var Specified: Boolean)
  : Integer;
var
  BinExists: Boolean;
  binpath: String;
  path: string;
begin
  Result := -1;
  Specified := false;
  path := SFXPath;
  // if no name specified use default
  if ExtractFileName(SFXPath) = '' then
    path := path + SFXBinDefault;
  binpath := path;
  if (Length(SFXPath) > 1) and
    ((SFXPath[1] = '.') or (ExtractFilePath(SFXPath) <> '')) then
  begin
    // use specified
    Specified := true;
    if SFXPath[1] = '.' then // relative to program
      binpath := PathConcat(ExtractFilePath(ParamStr(0)), path);
    BinExists := FileExists(binpath);
  end
  else
  begin
    // Try the application directory.
    binpath := DelimitPath(ExtractFilePath(ParamStr(0)), true) + path;
    BinExists := FileExists(binpath);
    if not BinExists then
    begin
      // Try the current directory.
      binpath := path;
      BinExists := FileExists(binpath);
    end;
  end;
  if BinExists then
  begin
    try
      stub := TFileStream.Create(binpath, fmOpenRead);
      if (stub.Size > MinStubSize) and (stub.Size < MaxStubSize) then
      begin
        stub.ReadBuffer(Result, sizeof(Integer));
      end;
      Diag('found stub: ' + SFXPath + ' ' + VersStr(Result));
    except
      Result := -5;
    end;
  end;
end;

function TZMWAux.LoadFromResource(var stub: TStream; const sfxtyp: String)
  : Integer;
var
  rname: String;
begin
  Result := -2;
  rname := sfxtyp;
  stub := OpenResStream(rname, RT_RCDATA);
  if (stub <> nil) and (stub.Size > MinStubSize) and
    (stub.Size < MaxStubSize) then
  begin
    stub.ReadBuffer(Result, sizeof(Integer));
    Diag('resource stub: ' + VersStr(Result));
  end;
end;

procedure TZMWAux.LoadZip(const ZipName: String; NoEvent: Boolean);
{ all work is local - no DLL calls }
var
  r: Integer;
  tmpDirUpdate: TNotifyEvent;
begin
  ClearErr;
  CentralDir.Current := nil; // close and remove any old file
  if ZipName <> '' then
  begin
    CentralDir.Current.FileName := ZipName;
    r := CentralDir.Current.Open(false, false);
    if r >= 0 then
    begin
      CentralDir.Current.File_Close;
      FZipComment := CentralDir.ZipComment;
    end
    else
    begin
      if r = -DS_NoInFile then
      begin
        // just report no file - may be intentional
        ErrCode := DS_NoInFile;
        ErrMessage := ZipLoadStr(DS_NoInFile);
      end
      else
        ShowZipMsg(-r, true);
    end;
  end;
  if not NoEvent then
  begin
    tmpDirUpdate := Master.OnDirUpdate;
    if assigned(tmpDirUpdate) then
      tmpDirUpdate(Master);
  end;
end;

function TZMWAux.MapOptionsFromStub(opts: Word): TZMSFXOpts;
begin
  Result := [];
  if (so_AskCmdLine and opts) <> 0 then
    Result := Result + [soAskCmdLine];
  if (so_AskFiles and opts) <> 0 then
    Result := Result + [soAskFiles];
  if (so_HideOverWriteBox and opts) <> 0 then
    Result := Result + [soHideOverWriteBox];
  if (so_AutoRun and opts) <> 0 then
    Result := Result + [soAutoRun];
  if (so_NoSuccessMsg and opts) <> 0 then
    Result := Result + [soNoSuccessMsg];
  if (so_ExpandVariables and opts) <> 0 then
    Result := Result + [soExpandVariables];
  if (so_InitiallyHideFiles and opts) <> 0 then
    Result := Result + [soInitiallyHideFiles];
  if (so_ForceHideFiles and opts) <> 0 then
    Result := Result + [soForceHideFiles];
  if (so_CheckAutoRunFileName and opts) <> 0 then
    Result := Result + [soCheckAutoRunFileName];
  if (so_CanBeCancelled and opts) <> 0 then
    Result := Result + [soCanBeCancelled];
  if (so_CreateEmptyDirs and opts) <> 0 then
    Result := Result + [soCreateEmptyDirs];
  if (so_SuccessAlways and opts) <> 0 then
    Result := Result + [soSuccessAlways];
end;

function TZMWAux.MapOptionsToStub(opts: TZMSFXOpts): Word;
begin
  Result := 0;
  if soAskCmdLine in opts then
    Result := Result or so_AskCmdLine;
  if soAskFiles in opts then
    Result := Result or so_AskFiles;
  if soHideOverWriteBox in opts then
    Result := Result or so_HideOverWriteBox;
  if soAutoRun in opts then
    Result := Result or so_AutoRun;
  if soNoSuccessMsg in opts then
    Result := Result or so_NoSuccessMsg;
  if soExpandVariables in opts then
    Result := Result or so_ExpandVariables;
  if soInitiallyHideFiles in opts then
    Result := Result or so_InitiallyHideFiles;
  if soForceHideFiles in opts then
    Result := Result or so_ForceHideFiles;
  if soCheckAutoRunFileName in opts then
    Result := Result or so_CheckAutoRunFileName;
  if soCanBeCancelled in opts then
    Result := Result or so_CanBeCancelled;
  if soCreateEmptyDirs in opts then
    Result := Result or so_CreateEmptyDirs;
  if soSuccessAlways in opts then
    Result := Result or so_SuccessAlways;
end;

function TZMWAux.MapOverwriteModeFromStub(ovr: Word): TZMOvrOpts;
begin
  case ovr of
    som_Overwrite:
      Result := ovrAlways;
    som_Skip:
      Result := ovrNever;
  else
    Result := ovrConfirm;
  end;
end;

function TZMWAux.MapOverwriteModeToStub(mode: TZMOvrOpts): Word;
begin
  case mode of
    ovrAlways:
      Result := som_Overwrite;
    ovrNever:
      Result := som_Skip;
  else
    Result := som_Ask;
  end;
end;

function TZMWAux.NewSFXFile(const ExeName: String): Integer;
var
  eoc: TZipEndOfCentral;
  fs: TFileStream;
begin
  Diag('Write empty SFX');
  fs := nil;
  Result := PrepareStub;
  if Result <> 0 then
    exit;
  try
    Result := -DS_FileError;
    eoc.HeaderSig := EndCentralDirSig;
    eoc.ThisDiskNo := 0;
    eoc.CentralDiskNo := 0;
    eoc.CentralEntries := 0;
    eoc.TotalEntries := 0;
    eoc.CentralSize := 0;
    eoc.CentralOffset := 0;
    eoc.ZipCommentLen := 0;
    fSFXBinStream.WriteBuffer(eoc, sizeof(eoc));
    Result := 0;
    fSFXBinStream.Position := 0;
    fs := TFileStream.Create(ExeName, fmCreate);
    Result := fs.CopyFrom(fSFXBinStream, fSFXBinStream.Size);
    if Result <> fSFXBinStream.Size then
      Result := -DS_WriteError
    else
      Result := 0;
    Diag('finished write empty SFX');
  finally
    FreeAndNil(fs);
    FreeAndNil(fSFXBinStream);
  end;
end;

function TZMWAux.NewSFXStub: TMemoryStream;
begin
  Result := nil;
  if PrepareStub = 0 then
    Result := ReleaseSFXBin;
end;

function TZMWAux.PrepareStub: Integer;
var
  cdata: TSFXStringsData;
  dflt: TZMDeflates;
  ds: TMemoryStream;
  i: Integer;
  l: Integer;
  ms: TMemoryStream;
  SFXBlkSize: Integer;
  SFXHead: TSFXFileHeader;
begin
  Result := -GE_Unknown;
  if not CreateStubStream then
    exit;
  try
    // create header
    SFXHead.Signature := SFX_HEADER_SIG;
    SFXHead.Options := MapOptionsToStub(SFXOptions);
    SFXHead.DefOVW := MapOverwriteModeToStub(SFXOverwriteMode);
    SFXHead.StartMsgType := fSFXMessageFlags;
    ds := nil;
    ms := TMemoryStream.Create;
    try
      WriteCommand(ms, SFXCaption, sc_Caption);
      WriteCommand(ms, SFXCommandLine, sc_CmdLine);
      WriteCommand(ms, SFXDefaultDir, sc_Path);
      WriteCommand(ms, SFXMessage, sc_StartMsg);
      WriteCommand(ms, RegFailPath, sc_RegFailPath);
      l := 0;
      ms.WriteBuffer(l, 1);
      // check string lengths
      if ms.Size > 4000 then
        raise EZipMaster.CreateResDisp(SF_StringTooLong, true);

      if ms.Size > 100 then
      begin
        cdata.USize := ms.Size;
        ms.Position := 0;
        ds := TMemoryStream.Create;
        dflt := ZMDeflate;
        Deflate(ds, ms, ms.Size, dflt, cdata.crc);
        cdata.CSize := ds.Size;
        if (dflt = ZMDeflate) and (ms.Size > (cdata.CSize + sizeof(cdata))) then
        begin
          // use compressed
          ms.Size := 0;
          ds.Position := 0;
          ms.WriteBuffer(cdata, sizeof(cdata));
          ms.CopyFrom(ds, ds.Size);
          SFXHead.Options := SFXHead.Options or so_CompressedCmd;
        end;
      end;
      // DWord Alignment.
      i := ms.Size and 3;
      if i <> 0 then
        ms.WriteBuffer(l, 4 - i); // dword align
      SFXBlkSize := sizeof(TSFXFileHeader) + ms.Size;
      // // create header
      SFXHead.Size := Word(SFXBlkSize);

      fSFXBinStream.Seek(0, soFromEnd);
      fSFXBinStream.WriteBuffer(SFXHead, sizeof(SFXHead));
      l := SFXBlkSize - sizeof(SFXHead);
      i := ms.Size;
      if i > 0 then
      begin
        ms.Position := 0;
        fSFXBinStream.CopyFrom(ms, i);
        Dec(l, i);
      end;
      // check DWORD align
      if l <> 0 then
        raise EZipMaster.CreateResDisp(AZ_InternalError, true);

      Result := 0;
    finally
      ms.Free;
      ds.Free;
    end;
  except
    on E: EZipMaster do
    begin
      FreeAndNil(fSFXBinStream);
      ShowExceptionError(E);
      Result := -E.ResId;
    end
    else
    begin
      FreeAndNil(fSFXBinStream);
      Result := -GE_Unknown;
    end;
  end;
end;

function TZMWAux.ReadSpan(const InFileName: String; var OutFilePath: String;
  UseXProgress: Boolean): Integer;
var
  fd: TZMZipCopy;
  fs: TZMZipFile;
begin
  ClearErr;
  ShowProgress := zspNone;
  fd := nil;
  fs := nil;
  Result := 0;

  try
    try
      // If we don't have a filename we make one first.
      if ExtractFileName(OutFilePath) = '' then
      begin
        OutFilePath := MakeTempFileName('', '');
        if OutFilePath = '' then
          Result := -DS_NoTempFile;
      end
      else
      begin
        EraseFile(OutFilePath, HowToDelete = htdFinal);
        OutFilePath := ChangeFileExt(OutFilePath, EXT_ZIP);
      end;

      if Result = 0 then
      begin
        fs := TZMZipFile.Create(self);
        // Try to get the last disk from the user if part of Volume numbered set
        fs.FileName := InFileName;
        Result := fs.Open(false, false);
      end;
      if Result >= 0 then
      begin
        // InFileName opened successfully
        Result := -DS_NoOutFile;
        fd := TZMZipCopy.Create(self);
        if fd.File_Create(OutFilePath) then
        begin
          if UseXProgress then
            fd.ShowProgress := zspExtra
          else
            fd.ShowProgress := zspFull;
          if UseXProgress then
            fd.EncodeAs := zeoUTF8; // preserve file names for internal operations
          Result := fd.WriteFile(fs, true);
        end;
      end;
      if Result < 0 then
        ShowZipMessage(-Result, '');
    except
      on ers: EZipMaster do
      begin
        // All ReadSpan specific errors.
        ShowExceptionError(ers);
        Result := -7;
      end;
      on E: Exception do
      begin
        // The remaining errors, should not occur.
        ShowZipMessage(DS_ErrorUnknown, E.Message);
        Result := -9;
      end;
    end;
  finally
    FreeAndNil(fs);
    if (fd <> nil) and (fd.IsOpen) then
    begin
      fd.File_Close;
      if Result <> 0 then
      begin
        // An error somewhere, OutFile is not reliable.
        SysUtils.DeleteFile(OutFilePath);
        OutFilePath := '';
      end;
    end;
    FreeAndNil(fd);
  end;
end;

(* ? TZMWAux.Recreate
recreate the 'theZip' file from the intermediate result
to make as SFX
- theZip.UseSFX is set
- theZip.Stub must hold the stub to use
*)
function TZMWAux.Recreate(Intermed, theZip: TZMZipFile): Integer;
var
  czip: TZMZipFile;
  DestZip: TZMZipCopy;
  detchSFX: Boolean;
  detchsz: Integer;
  existed: Boolean;
  r: Integer;
  tmp: String;
  wantNewDisk: Boolean;
begin
  detchsz := 0;
  detchSFX := false;
  existed := (zfi_Loaded and theZip.info) <> 0;
  if theZip.MultiDisk or ((not existed) and (zwoDiskSpan in theZip.WriteOptions)) then
  begin
    if Verbosity >= zvVerbose then
      Diag('Recreate multi-part: ' + theZip.ReqFileName);
    if theZip.UseSFX then
      detchSFX := true;
    Result := -GE_Unknown;
    Intermed.File_Close;
    czip := theZip;
    // theZip must have proper stub
    if detchSFX and not assigned(czip.stub) then
    begin
      Result := -CF_SFXCopyError; // no stub available - cannot convert
      exit;
    end;
    wantNewDisk := true; // assume need to ask for new disk
    if existed then
    begin
      czip.GetNewDisk(0, true); // ask to enter the first disk again
      czip.File_Close;
      wantNewDisk := false;
    end;
    tmp := theZip.ReqFileName;
    if detchSFX then
    begin
      if Verbosity >= zvVerbose then // Verbose or Trace then
        Diag('Recreate detached SFX');
      // allow room detchSFX stub
      detchsz := DetachedSize(Intermed);
      tmp := ChangeFileExt(tmp, EXT_ZIP); // name of the zip files
    end;
    // now create the spanned archive similar to theZip from Intermed
    DestZip := TZMZipCopy.Create(self);
    try
      DestZip.Boss := theZip.Boss;
      DestZip.WriteOptions := theZip.WriteOptions;
      DestZip.FileName := tmp;
      DestZip.ReqFileName := theZip.ReqFileName;
      DestZip.KeepFreeOnDisk1 := DestZip.KeepFreeOnDisk1 + Cardinal(detchsz);
      DestZip.ShowProgress := zspExtra;
      DestZip.TotalDisks := 0;
      if detchSFX and (DestZip.Numbering = znsExt) then
        DestZip.Numbering := znsName//;
      else
        DestZip.Numbering := theZip.Numbering;  // number same as source
      DestZip.PrepareWrite(zwMultiple);
      DestZip.NewDisk := wantNewDisk;
//      DestZip.DiskNr := 0;
      DestZip.File_Size := Intermed.File_Size; // to calc TotalDisks
      Intermed.File_Open(fmOpenRead);
      DestZip.StampDate := Intermed.FileDate;
      AnswerAll := AnswerAll + [zaaYesOvrwrt];
      r := DestZip.WriteFile(Intermed, true);
      DestZip.File_Close;
      if r < 0 then
        raise EZipMaster.CreateResDisp(-r, true);
      if detchSFX then
      begin
        DestZip.FileName := DestZip.CreateMVFileNameEx(tmp, false, false);
        DestZip.GetNewDisk(0, false);
        DestZip.AssignStub(czip);
        DestZip.FileName := tmp; // restore base name
        if WriteDetached(DestZip) >= 0 then
          Result := 0;
      end
      else
        Result := 0;
    finally
      Intermed.File_Close;
      DestZip.Free;
    end;
    theZip.Invalidate;  // must reload
  end
  else
    // not split
    Result := RecreateSingle(Intermed, theZip); // just copy it
end;

// recreate main file (ZipFileName) from temporary file (TmpZipName)
function TZMWAux.RecreateMVArchive(const TmpZipName: String; Recreate:
    Boolean): Boolean;
var
  OutPath: String;
  r: Integer;
  tmp: String;
  tzip: TZMZipFile;
begin
  Result := false;
  try
    tzip := TZMZipFile.Create(self);

    tzip.FileName := CentralDir.Current.FileName;
    tzip.DiskNr := -1;
    tzip.IsMultiPart := true;
    if Recreate then
    begin
      try
        tzip.GetNewDisk(0, true); // ask to enter the first disk again
        tzip.File_Close;
      except
        on E: Exception do
        begin
          SysUtils.DeleteFile(TmpZipName); // delete the temp file
          raise ; // throw last exception again
        end;
      end;
    end;

    if AnsiSameText('.exe', ExtractFileExt(ZipFileName)) then
    begin // make 'detached' SFX
      OutPath := ZipFileName; // remember it
      Set_ZipFileName(TmpZipName, zloFull); // reload
      // create an header first to now its size
      tmp := ExtractFileName(OutPath);
      r := ConvertToSpanSFX(OutPath, CentralDir.Current);
      if r >= 0 then
      begin
        SysUtils.DeleteFile(TmpZipName);
        Set_ZipFileName(OutPath, zloNoLoad); // restore it
      end
      else
      begin
        SuccessCnt := 0; // failed
        ShowZipMessage(DS_NoOutFile, 'Error ' + IntToStr(r));
      end;
    end { if SameText(...) }
    else
    begin
      if Recreate then
        // reproduce orig numbering
        SpanOptions := CentralDir.Current.MapNumbering(SpanOptions);
      if WriteSpan(TmpZipName, ZipFileName, true) <> 0 then
        SuccessCnt := 0;
      SysUtils.DeleteFile(TmpZipName);
    end;
  finally
    FreeAndNil(tzip);
  end;
end;

(* ? TZMWAux.RecreateSingle
Recreate the 'current' file from the intermediate result
to make as SFX
- Current.UseSFX is set
- Current.Stub must hold the stub to use
*)
function TZMWAux.RecreateSingle(Intermed, theZip: TZMZipFile): Integer;
var
  DestZip: TZMZipCopy;
begin
  theZip.File_Close;
  if Verbosity >= zvVerbose then
    Diag('Replacing: ' + theZip.ReqFileName);
  Result := EraseFile(theZip.ReqFileName, theZip.Worker.HowToDelete = htdAllowUndo);
  if Result > 0 then
    raise EZipMaster.CreateResDisp(DS_WriteError, true);
  // rename/copy Intermed
  AnswerAll := AnswerAll + [zaaYesOvrwrt];
  if assigned(theZip.stub) and theZip.UseSFX and (Intermed.Sig <> zfsDOS)
    then
  begin // rebuild with sfx
    if Verbosity >= zvVerbose then
      Diag('Rebuild with SFX');
    Intermed.File_Close;
    Intermed.File_Open(fmOpenRead);
    Result := Intermed.Open(false, false);
    if Result < 0 then
      exit;
    DestZip := TZMZipCopy.Create(self);
    try
      DestZip.Boss := theZip.Boss;
      DestZip.WriteOptions := theZip.WriteOptions;
      DestZip.AssignStub(theZip);
      DestZip.UseSFX := true;
      DestZip.StampDate := Intermed.StampDate; // will be 'orig' or now
      DestZip.DiskNr := 0;
      DestZip.ZipComment := theZip.ZipComment; // keep orig
      DestZip.ShowProgress := zspExtra;
      DestZip.File_Create(theZip.ReqFileName);
      Result := DestZip.WriteFile(Intermed, true);
      Intermed.File_Close;
      DestZip.File_Close;
      if Result < 0 then
        raise EZipMaster.CreateResDisp(-Result, true);
    finally
      DestZip.Free;
    end;
  end
  else
  begin
    theZip.File_Close;
    Result := -DS_FileError;
    if Intermed.File_Rename(theZip.ReqFileName) then
      Result := 0;
  end;
  theZip.Invalidate; // changed - must reload
end;

function TZMWAux.RejoinMVArchive(var TmpZipName: String): Integer;
var
  Attrs: Integer;
  curz: TZMZipFile;
  drt: Integer;
  tempzip: TZMZipCopy;
  tmpMessage: TZMMessageEvent;
  zname: String;
begin
  zname := ZipFileName;
  TmpZipName := MakeTempFileName('', '');
  if Verbosity >= zvVerbose then
  begin
    tmpMessage := Master.OnMessage;
    if assigned(tmpMessage) then
      tmpMessage(Master, 0, ZipFmtLoadStr(GE_TempZip, [TmpZipName]));
  end;
  Result := 0;
  if CentralDir.Current.TotalEntries > 0 then
  begin
    if (AddFreshen in AddOptions) or (AddUpdate in AddOptions) then
    begin
      // is it detached SFX
      if CentralDir.Current.MultiDisk and (CentralDir.Current.Sig = zfsDOS)
        then
        // load the actual zip instead of the loader (without events)
        LoadZip(ChangeFileExt(zname, EXT_ZIPL), true);

      curz := CentralDir.Current;
      // test if output can eventually be produced
      drt := curz.WorkDrive.DriveType;
      // we can't re-write on a CD-ROM

      if (drt = DRIVE_CDROM) then
      begin
        Attrs := FileGetAttr(zname);
        if Attrs and faReadOnly <> 0 then
        begin
          ShowZipFmtMsg(DS_NotChangeable, [zname], true);
          Result := -7;
          exit;
        end;
      end;
      // rebuild a temp archive
      Result := DS_FileError;
      tempzip := TZMZipCopy.Create(self);
      try
        if tempzip.File_Create(TmpZipName) then
        begin
          tempzip.ShowProgress := zspExtra;
          if curz.File_Open(fmOpenRead) then
          begin
            // tempzip.AddOptions := [];
            tempzip.EncodeAs := zeoUTF8;
            Result := tempzip.WriteFile(curz, true);
          end;
        end;
      finally
        tempzip.Free;
        curz.File_Close;
      end;
    end;
    if Result <> 0 then
    begin
      ErrCode := Result;
      Result := ErrCode;
      exit;
    end;
    AnswerAll := AnswerAll + [zaaYesOvrwrt];
  end;
  Result := 0;
end;

function TZMWAux.ReleaseSFXBin: TMemoryStream;
begin
  Result := fSFXBinStream;
  fSFXBinStream := nil;
end;

function TZMWAux.RemakeTemp(temp: TZMZipFile; Recreate, detach: Boolean)
  : Integer;
var
  czip: TZMZipFile;
  fd: TZMZipCopy;
  r: Integer;
  tmp: String;
  wantNewDisk: Boolean;
begin
  Result := -GE_Unknown;
  temp.File_Close;
  try
    czip := CentralDir.Current;
    // Current must have proper stub
    if detach and not assigned(czip.stub) then
    begin
      Result := -CF_SFXCopyError; // no stub available - cannot convert
      exit;
    end;
    wantNewDisk := true; // assume need to ask for new disk
    if (zfi_Loaded and czip.info) = 0 then
      Recreate := false; // was no file
    if Recreate then
    begin
      czip.GetNewDisk(0, true); // ask to enter the first disk again
      czip.File_Close;
      wantNewDisk := false;
    end;
    tmp := ZipFileName;
    // now create the spanned archive
    fd := TZMZipCopy.Create(self);
    try
      if detach then
      begin
        // allow room detached stub
        tmp := ExtractFileName(tmp);
        fd.KeepFreeOnDisk1 := KeepFreeOnDisk1 + Cardinal(DetachedSize(temp));
        // write the temp zipfile to the right target:
        tmp := ChangeFileExt(ZipFileName, EXT_ZIP); // name of the zip files
      end;
      fd.FileName := tmp;
      fd.NewDisk := wantNewDisk;
      fd.StampDate := temp.StampDate;
      fd.ShowProgress := zspExtra;
      fd.TotalDisks := 0;
      fd.PrepareWrite(zwMultiple);
      fd.DiskNr := 0;
      fd.File_Size := temp.File_Size; // to calc TotalDisks
      temp.File_Open(fmOpenRead);
      AnswerAll := AnswerAll + [zaaYesOvrwrt];
      r := fd.WriteFile(temp, true);
      if r < 0 then
        raise EZipMaster.CreateResDisp(-r, true);
      fd.File_Close;
      if detach then
      begin
        fd.GetNewDisk(0, false);
        if WriteDetached(fd) >= 0 then
          Result := 0;
      end
      else
        Result := 0;
    finally
      fd.Free;
    end;
    CentralDir.Current := nil;  // force reload
  except
    on z: EZipMaster do
    begin
      Result := -z.ResId;
    end;
    on E: Exception do
    begin
      Result := -GE_Unknown;
    end;
  end;
end;

function TZMWAux.SearchResDirEntry(ResStart: PIRD; entry: PIRDirE;
  Depth: Integer): PIRDatE;
var
  x: PByte;
begin
  Result := nil;
  if entry.un1.NameIsString <> 0 then
    exit; // No named resources.
  if (Depth = 0) and (entry.un1.Id <> 3) then
    exit; // Only icon resources.
  if (Depth = 1) and (entry.un1.Id <> 1) then
    exit; // Only icon with ID 0x1.
  if entry.un2.DataIsDirectory = 0 then
  begin
    x := PByte(ResStart);
    Inc(x, entry.un2.OffsetToData);
    Result := PIRDatE(x);
  end
  else
  begin
    x := PByte(ResStart);
    Inc(x, entry.un2.OffsetToDirectory);
    Result := BrowseResDir(ResStart, PIRD(x), Depth + 1);
  end;
end;

procedure TZMWAux.SetSFXCommandLine(const Value: String);
begin
  if fSFXCommandLine <> Value then
    fSFXCommandLine := Value;
end;

procedure TZMWAux.Set_ZipFileName(const zname: String; Load: TZLoadOpts);
begin
  fZipFileName := zname;
  if Load <> zloNoLoad then
    LoadZip(zname, Load = zloSilent); // automatically load the file
end;

procedure TZMWAux.StartUp;
var
  Want: Integer;
begin
  inherited;
  SFXOverwriteMode := Master.SFXOverwriteMode;
  RegFailPath := Master.SFXRegFailPath;
  SFXCaption := Master.SFXCaption;
  SFXCommandLine := Master.SFXCommandLine;
  SFXDefaultDir := Master.SFXDefaultDir;
  if assigned(Master.SFXIcon) then
  begin
    fSFXIcon := TIcon.Create;
    fSFXIcon.Assign(Master.SFXIcon);
  end;
  SFXMessage := Master.SFXMessage;
  fSFXMessageFlags := MB_OK;
  if (Length(SFXMessage) >= 1) then
  begin
    Want := 1; // want the lot
    if (Length(SFXMessage) > 1) and (SFXMessage[2] = '|') then
    begin
      case SFXMessage[1] of
        '1':
          fSFXMessageFlags := MB_OKCANCEL or MB_ICONINFORMATION;
        '2':
          fSFXMessageFlags := MB_YESNO or MB_ICONQUESTION;
        '|': Want := 2;
      end;
      if fSFXMessageFlags <> MB_OK then
        Want := 3;
    end;
    if Want > 1 then
      SFXMessage := Copy(SFXMessage, Want, 2048);
  end;
  SFXOptions := Master.SFXOptions;
  SFXPath := Master.SFXPath;
end;

function TZMWAux.TrimDetached(stub: TMemoryStream): Boolean;
type
  T_header = packed record
    Sig: DWORD;
    Size: Word;
    x: Word;
  end;
  P_header = ^T_header;
var
  i: Integer;
  NumSections: Integer;
  p: PByte;
  phed: P_header;
  sz: Cardinal;
begin
  Result := false;
  if (stub <> nil) and (stub.Size > MinStubSize) then
  begin
    sz := 0;
    p := stub.Memory;
    if (PImageDosHeader(p).e_magic <> IMAGE_DOS_SIGNATURE) then
      exit;
    Inc(p, PImageDosHeader(p)._lfanew);
    if PCardinal(p)^ <> IMAGE_PE_SIGNATURE then
      exit; // not exe
    Inc(p, sizeof(Cardinal));
    NumSections := PImageFileHeader(p).NumberOfSections;
    Inc(p, sizeof(TImageFileHeader) + sizeof(TImageOptionalHeader));
    for i := 1 to NumSections do
    begin
      with PImageSectionHeader(p)^ do
        if PointerToRawData + SizeOfRawData > sz then
          sz := PointerToRawData + SizeOfRawData;
      Inc(p, sizeof(TImageSectionHeader));
    end;
    // sz = end of stub
    p := stub.Memory;
    Inc(p, sz);
    phed := P_header(p);
    if phed.Sig <> SFX_HEADER_SIG then
      exit; // bad
    sz := sz + phed.Size;
    // posn := sz;
    Inc(p, phed.Size);
    phed := P_header(p);
    if (phed.Sig = CentralFileHeaderSig) then
    begin
      stub.Size := sz; // remove file header
      Result := true;
    end;
  end;
end;

function TZMWAux.MapSFXSettings(stub: TMemoryStream): Integer;
type
  T_header = packed record
    Sig: DWORD;
    Size: Word;
    x: Word;
  end;
  P_header = ^T_header;
var
  i: Integer;
  NumSections: Integer;
  p: PByte;
  phed: P_header;
  sz: Cardinal;
begin
  Result := 0;
  if (stub <> nil) and (stub.Size > MinStubSize) then
  begin
    sz := 0;
    p := stub.Memory;
    if (PImageDosHeader(p).e_magic <> IMAGE_DOS_SIGNATURE) then
      exit;
    Result := -DS_SFXBadRead; //  'unknown sfx'
    Inc(p, PImageDosHeader(p)._lfanew);
    if PCardinal(p)^ <> IMAGE_PE_SIGNATURE then
      exit; // not exe
    Inc(p, sizeof(Cardinal));
    NumSections := PImageFileHeader(p).NumberOfSections;
    Inc(p, sizeof(TImageFileHeader) + sizeof(TImageOptionalHeader));
    for i := 1 to NumSections do
    begin
      with PImageSectionHeader(p)^ do
        if PointerToRawData + SizeOfRawData > sz then
          sz := PointerToRawData + SizeOfRawData;
      Inc(p, sizeof(TImageSectionHeader));
    end;
    // sz = end of stub
    p := stub.Memory;
    Inc(p, sz);
    phed := P_header(p);
    if phed.Sig = SFX_HEADER_SIG then
    begin
      Result := MapSFXSettings19(p, stub);
    end
    else if phed.Sig = SFX_HEADER_SIG_17 then
    begin
      Result := MapSFXSettings17(p, stub);
    end;
  end;
end;

function ReadSFXStr17(var p: PByte; len: Byte): Ansistring;
var
  i: Integer;
begin
  Result := '';
  if len > 0 then
  begin
    SetLength(Result, len);
    for I := 1 to len do
    begin
      Result[i] := AnsiChar(P^);
      inc(p);
    end;
  end;
end;

procedure TZMWAux.AfterConstruction;
begin
  inherited;
  fSuccessCnt := 0;
  fCentralDir := TZMCenDir.Create(self);
  FZipComment := '';
  fZipFileName := '';
  fSFXIcon := nil;
  fUseDelphiBin := true;
  fSFXBinStream := nil;
end;

procedure TZMWAux.BeforeDestruction;
begin
  FreeAndNil(fCentralDir);
  FreeAndNil(fSFXIcon);
  FreeAndNil(fSFXBinStream);
  inherited;
end;

function TZMWAux.MapSFXSettings17(pheder: PByte; stub: TMemoryStream): Integer;
type
  T_header = packed record
    Sig: DWORD;
    Size: Word;
    x: Word;
  end;
  P_header = ^T_header;
var
  ico: TIcon;
  p: PByte;
  PSFXHeader: PSFXFileHeader_17;
  X_Caption, X_Path, X_CmdLine, X_RegFailPath, X_StartMsg: AnsiString;
begin
  Result := -DS_SFXBadRead;
  PSFXHeader := PSFXFileHeader_17(pheder);
  p := pheder;
  Inc(p, Sizeof(TSFXFileHeader_17));   // point to strings
  X_Caption := ReadSFXStr17(p, PSFXHeader^.CaptionSize);
  X_Path := ReadSFXStr17(p, PSFXHeader^.PathSize);
  X_CmdLine := ReadSFXStr17(p, PSFXHeader^.CmdLineSize);
  X_RegFailPath := ReadSFXStr17(p, PSFXHeader^.RegFailPathSize);
  X_StartMsg := ReadSFXStr17(p, PSFXHeader^.StartMsgSize);

  // read icon
  try
    ico := GetFirstIcon(stub);
    // should test valid
    Master.SFXIcon := ico;
    ico.Free;
  except
    On E: EZMException do
    begin
      Result := -E.ResId;
      exit;
    end
    else
      exit;
  end;
  Master.SFXOptions := MapOptionsFrom17(PSFXHeader^.Options);
  Master.SFXOverwriteMode := MapOverwriteModeFromStub(PSFXHeader^.DefOVW);
  if (PSFXHeader^.StartMsgType and (MB_OKCANCEL or MB_YESNO)) <> 0 then
  begin
    if (PSFXHeader^.StartMsgType and MB_OKCANCEL) <> 0 then
      X_StartMsg := '1|' + X_StartMsg
    else if (PSFXHeader^.StartMsgType and MB_YESNO) <> 0 then
      X_StartMsg := '2|' + X_StartMsg;
  end;
  Master.SFXMessage := String(X_StartMsg);
  Master.SFXCaption := String(X_Caption);
  Master.SFXDefaultDir := String(X_Path);
  Master.SFXCommandLine := String(X_CmdLine);
  Master.SFXRegFailPath := String(X_RegFailPath);
  Result := 0;  // all is well
end;

// table format - ident: byte, strng[]: byte, 0: byte; ...;0
function TZMWAux.LoadSFXStr(ptbl: pByte; ident: Byte): String;
var
  id: Byte;
begin
  Result := '';
  if (ptbl = nil) or (ident = 0) then
    exit;
  id := ptbl^;
  while (id <> 0) and (id <> ident) do
  begin
    while ptbl^ <> 0 do
      inc(ptbl);
    inc(ptbl);
    id := ptbl^;
  end;
  if id = ident then
  begin
    inc(ptbl);
{$ifdef UNICODE}
    Result := PUTF8ToStr(pAnsiChar(ptbl), -1);
{$else}
    if UseUTF8 then
      Result := UTF8String(pAnsiChar(ptbl))
    else
      Result := PUTF8ToStr(pAnsiChar(ptbl), -1);
{$endif}
  end;
end;

function TZMWAux.MapOptionsFrom17(opts: Word): TZMSFXOpts;
begin
  Result := [];
  if (so_AskCmdLine_17 and opts) <> 0 then
    Result := Result + [soAskCmdLine];
  if (so_AskFiles_17 and opts) <> 0 then
    Result := Result + [soAskFiles];
  if (so_HideOverWriteBox_17 and opts) <> 0 then
    Result := Result + [soHideOverWriteBox];
  if (so_AutoRun_17 and opts) <> 0 then
    Result := Result + [soAutoRun];
  if (so_NoSuccessMsg_17 and opts) <> 0 then
    Result := Result + [soNoSuccessMsg];
  if (so_ExpandVariables_17 and opts) <> 0 then
    Result := Result + [soExpandVariables];
  if (so_InitiallyHideFiles_17 and opts) <> 0 then
    Result := Result + [soInitiallyHideFiles];
  if (so_ForceHideFiles_17 and opts) <> 0 then
    Result := Result + [soForceHideFiles];
  if (so_CheckAutoRunFileName_17 and opts) <> 0 then
    Result := Result + [soCheckAutoRunFileName];
  if (so_CanBeCancelled_17 and opts) <> 0 then
    Result := Result + [soCanBeCancelled];
  if (so_CreateEmptyDirs_17 and opts) <> 0 then
    Result := Result + [soCreateEmptyDirs];
end;

function TZMWAux.MapSFXSettings19(pheder: PByte; stub: TMemoryStream): Integer;
var
  cmnds: PByte;
  CRC: Cardinal;
  cstream: TMemoryStream;
  ico: TIcon;
  msg: string;
  method: TZMDeflates;
  delta: Integer;
  p: PByte;
  phed: PSFXFileHeader;
  psdat: PSFXStringsData;
begin
  Result := -DS_SFXBadRead;
  phed := PSFXFileHeader(pheder);
  cstream := nil;
  cmnds := PByte(@phed^.StartMsgType);
  inc(cmnds, sizeof(WORD));
  try
    // get command strings
    if (so_CompressedCmd and phed^.Options) <> 0 then
    begin
      // needs dll!!!!
      p := cmnds;
      cmnds := nil;
      psdat := PSFXStringsData(p);
      Inc(p, sizeof(TSFXStringsData));  // point to compressed data
      delta := Cardinal(p) - Cardinal(stub.Memory);
      if stub.Seek(delta, soFromBeginning) = delta then
      begin
        cstream := TMemoryStream.Create;
        method := ZMDeflate; // deflated
        Undeflate(cstream, stub, psdat.CSize, method, CRC);
        if (cstream.Size = psdat.USize) and (CRC = psdat.CRC) then
          cmnds := cstream.Memory;  // ok
      end;
    end;
    if cmnds <> nil then
    begin
      // read icon
      try
        ico := GetFirstIcon(stub);
        // should test valid
        Master.SFXIcon := ico;
        ico.Free;
      except
        On E: EZMException do
        begin
          Result := -E.ResId;
          exit;
        end
        else
          exit;
      end;
      // we have strings
      Master.SFXCaption := LoadSFXStr(cmnds, sc_Caption);
      Master.SFXDefaultDir := LoadSFXStr(cmnds, sc_Path);
      Master.SFXCommandLine := LoadSFXStr(cmnds, sc_CmdLine);
      Master.SFXRegFailPath := LoadSFXStr(cmnds, sc_RegFailPath);
      msg := LoadSFXStr(cmnds, sc_StartMsg);
      Master.SFXOptions := MapOptionsFromStub(phed^.Options);
      Master.SFXOverwriteMode := MapOverwriteModeFromStub(phed^.DefOVW);
      if (phed^.StartMsgType and (MB_OKCANCEL or MB_YESNO)) <> 0 then
      begin
        if (phed^.StartMsgType and MB_OKCANCEL) <> 0 then
          msg := '1|' + msg
        else if (phed^.StartMsgType and MB_YESNO) <> 0 then
          msg := '2|' + msg;
      end;
      Master.SFXMessage := msg;
      Result := 0;  // all is well
    end;
  finally
    if cstream <> nil then
      cstream.Free;
  end;
end;

function TZMWAux.WriteDetached(zf: TZMZipFile): Integer;
var
  xf: TZMLoader;
begin
  Diag('Write detached SFX stub');
  Result := -DS_FileError;
  xf := TZMLoader.Create(self);
  try
    xf.ForZip := zf;
    if xf.File_Create(ChangeFileExt(zf.FileName, DotExtExe)) then
      Result := xf.Commit(false);
  finally
    xf.Free;
  end;
end;

function TZMWAux.WriteEOC(Current: TZMZipFile; OutFile: Integer): Integer;
var
  r: Integer;
begin
  Current.Handle := OutFile;
  Current.Position := FileSeek(OutFile, 0, soFromCurrent);
  r := Current.WriteEOC();
  OutSize := FileSeek(OutFile, 0, soFromEnd);
  Current.Handle := -1; // closes OutFile
  Result := r;
end;

function TZMWAux.WriteMulti(Src: TZMZipFile; Dest: TZMZipCopy;
  UseXProgress: Boolean): Integer;
begin
  try
    if ExtractFileName(Src.FileName) = '' then
      raise EZipMaster.CreateResDisp(DS_NoInFile, true);
    if ExtractFileName(Dest.FileName) = '' then
      raise EZipMaster.CreateResDisp(DS_NoOutFile, true);
    Result := Src.Open(false, false);
    if Result < 0 then
      raise EZipMaster.CreateResDisp(-Result, true);
    Dest.StampDate := Src.StampDate;
    if UseXProgress then
      Dest.ShowProgress := zspExtra
    else
      Dest.ShowProgress := zspFull;
    Dest.TotalDisks := 0;
    Dest.PrepareWrite(zwMultiple);
//    Dest.DiskNr := 0;
    Dest.File_Size := Src.File_Size; // to calc TotalDisks
    Result := Dest.WriteFile(Src, true);
    Dest.File_Close;
    Src.File_Close;
    if Result < 0 then
      raise EZipMaster.CreateResDisp(-Result, true);
  except
    on ews: EZipMaster do // All WriteSpan specific errors.
    begin
      ShowExceptionError(ews);
      Result := -7;
    end;
    on EOutOfMemory do // All memory allocation errors.
    begin
      ShowZipMessage(GE_NoMem, '');
      Result := -8;
    end;
    on E: Exception do
    begin
      // The remaining errors, should not occur.
      ShowZipMessage(DS_ErrorUnknown, E.Message);
      Result := -9;
    end;
  end;
end;

function TZMWAux.WriteSpan(const InFileName, OutFileName: String;
  UseXProgress: Boolean): Integer;
var
  fd: TZMZipCopy;
  fs: TZMZipFile;
begin
  ClearErr;
  Result := -1;
  fd := nil;
  fs := TZMZipFile.Create(self);
  try
    fs.FileName := InFileName;
    fd := TZMZipCopy.Create(self);
    fd.FileName := OutFileName;
    if Unattended and not fd.WorkDrive.DriveIsFixed then
      raise EZipMaster.CreateResDisp(DS_NoUnattSpan, true);
    Result := WriteMulti(fs, fd, UseXProgress);
  finally
    fs.Free;
    if fd <> nil then
      fd.Free;
  end;
end;

function WriteCommand(Dest: TMemoryStream; const cmd: string; ident: Integer)
  : Integer;
var
  ucmd: UTF8String;
  z: Byte;
begin
  Result := 0;
  if Length(cmd) > 0 then
  begin
    ucmd := AsUTF8Str(cmd);
    Dest.Write(ident, 1);
    Result := Dest.Write(PAnsiChar(ucmd)^, Length(ucmd)) + 2;
    z := 0;
    Dest.Write(z, 1);
  end;
end;

constructor TZMLoader.Create(Wrkr: TZMCore);
begin
  inherited Create(Wrkr);
  fSFXWorker := Wrkr as TZMWAux;
end;

function TZMLoader.AddStripped(const rec: TZMIRec): Integer;
var
  Data: TZMRawBytes;
  idx: Integer;
  ixN: Integer;
  ixU: Integer;
  ixZ: Integer;
  ndata: TZMRawBytes;
  ni: TZMRawBytes;
  nrec: TZMIRec;
  siz: Integer;
  szN: Integer;
  szU: Integer;
  szZ: Integer;
begin
  ixZ := 0;
  szZ := 0;
  ixU := 0;
  szU := 0;
  ixN := 0;
  szN := 0;
  nrec := TZMIRec.Create(self);
  nrec.VersionMadeBy := rec.VersionMadeBy;
  nrec.VersionNeeded := rec.VersionNeeded;
  nrec.Flag := rec.Flag;
  nrec.ComprMethod := rec.ComprMethod;
  nrec.ModifDateTime := rec.ModifDateTime;
  nrec.CRC32 := rec.CRC32;
  nrec.CompressedSize := rec.CompressedSize;
  nrec.UncompressedSize := rec.UncompressedSize;
  nrec.FileCommentLen := 0;
  nrec.DiskStart := rec.DiskStart;
  nrec.IntFileAttrib := rec.IntFileAttrib;
  nrec.ExtFileAttrib := rec.ExtFileAttrib;
  nrec.RelOffLocal := rec.RelOffLocal;
  nrec.StatusBits := rec.StatusBits;
  ndata := '';
  siz := 0;
  ni := rec.HeaderName;
  if rec.ExtraFieldLength > 4 then
  begin
    Data := rec.ExtraField;
    if XData(Data, Zip64_data_tag, ixZ, szZ) then
      siz := siz + szZ;
    if XData(Data, UPath_Data_Tag, ixU, szU) then
      siz := siz + szU;
    if XData(Data, NTFS_data_tag, ixN, szN) and (szN >= 36) then
      siz := siz + szN;
  end;
  nrec.HeaderName := ni;
  nrec.FileNameLength := Length(ni);
  if siz > 0 then
  begin
    // copy required extra data fields
    SetLength(ndata, siz);
    idx := 1;
    if szZ > 0 then
      move(Data[ixZ], ndata[idx], szZ);
    Inc(idx, szZ);
    if szU > 0 then
      move(Data[ixU], ndata[idx], szU);
    Inc(idx, szU);
    if szN >= 36 then
      move(Data[ixN], ndata[idx], szN);
    nrec.ExtraField := ndata;
    ndata := '';
  end;
  Result := Add(nrec);
  if Result < 0 then
  begin
    nrec.Free; // could not add it
    Result := -AZ_InternalError;
  end;
end;

procedure TZMLoader.AfterConstruction;
begin
  inherited;
  ForZip := nil;
  fname := '';
  DiskNr := MAX_WORD - 1;
end;

function TZMLoader.BeforeCommit: Integer;
begin
  Result := inherited BeforeCommit;
  // Prepare detached header
  if Result = 0 then
  begin
    if Entries.Count < 0 then
      raise EZipMaster.CreateResDisp(AZ_NothingToDo, true);
    StampDate := ForZip.StampDate;
    Result := PrepareDetached;
  end;
end;

function TZMLoader.PrepareDetached: Integer;
begin
  if not assigned(stub) then
  begin
    Result := SFXWorker.PrepareStub;
    if Result < 0 then
      exit; // something went wrong
    stub := SFXWorker.ReleaseSFXBin; // we now own it
  end;
  UseSFX := true;
  Result := 0;
end;

procedure TZMLoader.SetForZip(const Value: TZMZipFile);
begin
  if ForZip <> Value then
  begin
    fForZip := Value;
    ClearEntries;
    StripEntries;
    DiskNr := ForZip.DiskNr + 1;
  end;
end;

function TZMLoader.StripEntries: Integer;
var
  i: Integer;
begin
  Result := -AZ_NothingToDo;
  // fill list from ForFile
  for i := 0 to ForZip.Count - 1 do
  begin
    Result := AddStripped(ForZip[i]);
    if Result < 0 then
      Break;
  end;
end;

end.
