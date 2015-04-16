
unit ZMDllLoad19;

(*
  ZMDLLLoad19.pas - Dynamically load the DLL
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

  modified 2010-10-10
  --------------------------------------------------------------------------- *)

interface

uses
  Classes, Windows, ZMDelZip19, ZMWrkr19;

procedure _DLL_Abort(worker: TZMWorker; key: Cardinal);
function _DLL_Banner: String;
function _DLL_Build: Integer;
function _DLL_Exec(worker: TZMWorker; const Rec: pDLLCommands;
  var key: Cardinal): Integer;
function _DLL_Load(worker: TZMWorker): Integer;
function _DLL_Loaded(worker: TZMWorker): Boolean;
function _DLL_Path: String;
procedure _DLL_Remove(worker: TZMWorker);
procedure _DLL_Unload(worker: TZMWorker);

implementation

{$I '.\ZipVers19.inc'}
{$I '.\ZMConfig19.inc'}

uses

  SysUtils, ZipMstr19, ZMCompat19, ZMXcpt19,
{$IFNDEF STATIC_LOAD_DELZIP_DLL}

  ZMCore19, ZMExtrLZ7719, ZMUtils19, ZMDLLOpr19, ComObj, ActiveX,
{$IFNDEF VERD4}
  SyncObjs,
{$ENDIF}

{$ENDIF}
  ZMMsg19;

procedure CheckExec(RetVal: Integer);
var
  x: Integer;
begin
  if RetVal < 0 then
  begin
    x := -RetVal;
    if x > _DZ_ERR_MAX then
      raise EZipMaster.CreateResInt(GE_DLLCritical, x);
    if (x = _DZ_ERR_CANCELLED) or (x = _DZ_ERR_ABORT) then
      x := DS_Canceled
    else
      x := x + DZ_RES_GOOD;
    raise EZipMaster.CreateResDisp(x, True);
  end;
end;

{$IFDEF STATIC_LOAD_DELZIP_DLL}
// 'static' loaded dll functions
function DZ_Abort(C: Cardinal): Integer; STDCALL; EXTERNAL DelZipDLL_Name
{$IFDEF VERD2010up} Delayed {$ENDIF};
function DZ_Path: pChar; STDCALL; EXTERNAL DelZipDLL_Name
{$IFDEF VERD2010up} Delayed {$ENDIF};
function DZ_PrivVersion: Integer; STDCALL; EXTERNAL DelZipDLL_Name
{$IFDEF VERD2010up} Delayed {$ENDIF};
function DZ_Exec(C: pDLLCommands): Integer; STDCALL; EXTERNAL DelZipDLL_Name
{$IFDEF VERD2010up} Delayed {$ENDIF};
function DZ_Version: Integer; STDCALL; EXTERNAL DelZipDLL_Name
{$IFDEF VERD2010up} Delayed {$ENDIF};
function DZ_Banner: pChar; STDCALL; EXTERNAL DelZipDLL_Name
{$IFDEF VERD2010up} Delayed {$ENDIF};
function DZ_Name(var buf; bufsiz: Integer; wide: Boolean): Integer; STDCALL;
external DelZipDLL_Name {$IFDEF VERD2010up} Delayed {$ENDIF};
{$ELSE}

type
  TZMCount = record
    worker: TZMWorker;
    Count: Integer;
  end;

type
  TZMDLLLoader = class(TObject)
  private
    AbortFunc: TAbortOperationFunc;
    BannerFunc: TDLLBannerFunc;
    Counts: array of TZMCount;
    ExecFunc: TDLLExecFunc;
    fBanner: String;
    fHasResDLL: Integer;
    fKillTemp: Boolean;
    fLoadErr: Integer;
    fLoading: Integer;
    fLoadPath: String;
    fPath: String;
    fVer: Integer;
    // guard data for access by several threads
{$IFDEF VERD4}
    CSection: TRTLCriticalSection;
{$ELSE}
    Guard: TCriticalSection;
{$ENDIF}
    hndl: HWND;
    NameFunc: TDLLNameFunc;
    PathFunc: TDLLPathFunc;
    Priv: Integer;
    PrivFunc: TDLLPrivVersionFunc;
    TmpFileName: String;
    VersFunc: TDLLVersionFunc;
    function GetIsLoaded: Boolean;
    function LoadLib(worker: TZMWorker; FullPath: String; MustExist: Boolean)
      : Integer;
    procedure ReleaseLib;
    procedure RemoveTempDLL;
  protected
    function Counts_Dec(worker: TZMWorker): Integer;
    function Counts_Find(worker: TZMWorker): Integer;
    function Counts_Inc(worker: TZMWorker): Integer;
    procedure Empty;
    function ExtractResDLL(worker: TZMWorker; OnlyVersion: Boolean): Integer;
    function LoadDLL(worker: TZMWorker): Integer;
    function UnloadDLL: Integer;
    property IsLoaded: Boolean Read GetIsLoaded;
  public
    procedure Abort(worker: TZMWorker; key: Cardinal);
    procedure AfterConstruction; override;
    function Banner: String;
    procedure BeforeDestruction; override;
    function Build: Integer;
    function Exec(worker: TZMWorker; const Rec: pDLLCommands; var key: Cardinal)
      : Integer;
    function Load(worker: TZMWorker): Integer;
    function Loaded(worker: TZMWorker): Boolean;
    function Path: String;
    procedure Remove(worker: TZMWorker);
    procedure Unload(worker: TZMWorker);
    property Ver: Integer Read fVer;
  end;

const
  MINDLLBUILD = DELZIPVERSION * 10000;
  RESVER_UNTRIED = -99; // have not looked for resdll yet
  RESVER_NONE = -1; // not available
  RESVER_BAD = 0; // was bad copy/version
  // const
  MIN_RESDLL_SIZE = 50000;
  MAX_RESDLL_SIZE = 600000;

var
  G_LoadedDLL: TZMDLLLoader = nil;

procedure TZMDLLLoader.Abort(worker: TZMWorker; key: Cardinal);
begin
  if Loaded(worker) and (hndl <> 0) then
    AbortFunc(key);
end;

procedure TZMDLLLoader.AfterConstruction;
begin
  inherited;
{$IFDEF VERD4}
  InitializeCriticalSection(CSection);
{$ELSE}
  Guard := TCriticalSection.Create;
{$ENDIF}
  fKillTemp := False;
  Empty;
  fPath := DelZipDLL_Name;
  TmpFileName := '';
  fLoading := 0;
  fBanner := '';
  fHasResDLL := RESVER_UNTRIED; // unknown
end;

function TZMDLLLoader.Banner: String;
var
  tmp: AnsiString;
begin
  Result := '';
  if IsLoaded then
  begin
    tmp := BannerFunc;
    Result := String(tmp);
  end;
end;

procedure TZMDLLLoader.BeforeDestruction;
begin
  if hndl <> 0 then
    FreeLibrary(hndl);
  Counts := nil;
{$IFDEF VERD4}
  DeleteCriticalSection(CSection);
{$ELSE}
  FreeAndNil(Guard);
{$ENDIF}
  hndl := 0;
  RemoveTempDLL;
  inherited;
end;

function TZMDLLLoader.Build: Integer;
begin
  Result := 0;
  if IsLoaded then
    Result := Priv;
end;

{ TZMDLLLoader }

function TZMDLLLoader.Counts_Dec(worker: TZMWorker): Integer;
var
  p: string;
  keepLoaded: Boolean;
  i: Integer;
begin
  Result := -1;
{$IFDEF VERD4}
  EnterCriticalSection(CSection);
{$ELSE}
  Guard.Enter;
{$ENDIF}
  try
    // find worker
    i := Counts_Find(worker);
    if i >= 0 then
    begin
      // found
      Dec(Counts[i].Count);
      Result := Counts[i].Count;
      if Result < 1 then
      begin
        // not wanted - remove from list
        Counts[i].worker := nil;
        Counts[i].Count := 0;
      end;
    end;
    // ignore unload if loading
    if fLoading = 0 then
    begin
      keepLoaded := False;
      for i := 0 to HIGH(Counts) do
        if (Counts[i].worker <> nil) and (Counts[i].Count > 0) then
        begin
          keepLoaded := True;
          break;
        end;

      if not keepLoaded then
      begin
        p := fPath;
        UnloadDLL;
        if worker.Verbosity >= zvVerbose then
          worker.ReportMsg(LD_DLLUnloaded, [p]);
      end;
    end;
  finally
{$IFDEF VERD4}
  LeaveCriticalSection(CSection);
{$ELSE}
    Guard.Leave;
{$ENDIF}
  end;
end;

function TZMDLLLoader.Counts_Find(worker: TZMWorker): Integer;
var
  i: Integer;
begin
  Result := -1;
  if Counts <> nil then
  begin
    for i := 0 to HIGH(Counts) do
    begin
      if Counts[i].worker = worker then
      begin
        // found
        Result := i;
        break;
      end;
    end;
  end;
end;

function TZMDLLLoader.Counts_Inc(worker: TZMWorker): Integer;
var
  len: Integer;
  i: Integer;
  loadVer: Integer;
begin
{$IFDEF VERD4}
  EnterCriticalSection(CSection);
{$ELSE}
  Guard.Enter;
{$ENDIF}
  try
    // find worker
    i := Counts_Find(worker);
    if i >= 0 then
    begin
      // found
      Inc(Counts[i].Count);
      Result := Counts[i].Count;
    end
    else
    begin
      // need new one - any empty
      i := Counts_Find(nil);
      if i >= 0 then
      begin
        // have empty position - use it
        Counts[i].worker := worker;
        Counts[i].Count := 1;
        Result := 1;
      end
      else
      begin
        // need to extend
        len := HIGH(Counts);
        if len > 0 then
          Inc(len)
        else
          len := 0;
        SetLength(Counts, len + 4);
        // clear the rest
        for i := len + 3 downto len + 1 do
        begin
          Counts[i].worker := nil;
          Counts[i].Count := 0;
        end;
        i := len;
        Counts[i].worker := worker;
        Counts[i].Count := 1;
        Result := 1;
      end;
    end;
    if not IsLoaded then
    begin
      // avoid re-entry
      Inc(fLoading);
      try
        if fLoading = 1 then
        begin
          try
            loadVer := LoadDLL(worker);
          except
            on Ers: EZipMaster do
            begin
              loadVer := -1;
              worker.ShowExceptionError(Ers);
            end;
            on E: Exception do
            begin
              loadVer := -1;
              worker.ShowExceptionError(E);
            end;
          end;
          if loadVer < DELZIPVERSION then
          begin // could not load it - empty it (i is index for this worker)
            Counts[i].worker := nil;
            Counts[i].Count := 0;

            if worker.Verbosity >= zvVerbose then
              worker.ReportMsg(LD_LoadErr, [fLoadErr, SysErrorMessage(fLoadErr)
                  , fLoadPath]);
            Result := -1;
          end
          else
          begin
            if worker.Verbosity >= zvVerbose then
              worker.ReportMsg(LD_DLLLoaded, [fPath]);
          end;
        end;
      finally
        Dec(fLoading);
      end;
    end;
  finally
{$IFDEF VERD4}
  LeaveCriticalSection(CSection);
{$ELSE}
    Guard.Leave;
{$ENDIF}
  end;
end;

procedure TZMDLLLoader.Empty;
begin
  hndl := 0;
  ExecFunc := nil;
  VersFunc := nil;
  PrivFunc := nil;
  AbortFunc := nil;
  NameFunc := nil;
  PathFunc := nil;
  BannerFunc := nil;
  fVer := 0;
  Priv := 0;
  fBanner := '';
end;

function TZMDLLLoader.Exec(worker: TZMWorker; const Rec: pDLLCommands;
  var key: Cardinal): Integer;
begin
  Result := -1; // what error
  if Counts_Inc(worker) > 0 then
  begin
    try
      Result := ExecFunc(Rec);
    finally
      Counts_Dec(worker);
      key := 0;
    end;
  end;
end;

function TZMDLLLoader.ExtractResDLL(worker: TZMWorker; OnlyVersion: Boolean):
    Integer;
var
  done: Boolean;
  uid: TGUID;
  fs: TFileStream;
  len: Integer;
  rs: TResourceStream;
  temppath: String;
  w: Word;
begin
  done := False;
  Result := -1;
  fs := nil;
  rs := nil;
  try
    // only check if unknown or know exists
    if (fHasResDLL = RESVER_UNTRIED) or (fHasResDLL > MINDLLBUILD) then
      rs := OpenResStream(DZRES_DLL, RT_RCDATA);
    if fHasResDLL = RESVER_UNTRIED then
      fHasResDLL := RESVER_NONE; // in case of exception
    // read the dll version if it exists
    if (rs <> nil) and (rs.Size > MIN_RESDLL_SIZE) and
      (rs.Size < MAX_RESDLL_SIZE) then
    begin
      rs.Position := 0;
      rs.ReadBuffer(Result, sizeof(Integer));
      fHasResDLL := Result;   // the dll version
      if (Result > MINDLLBUILD) and not OnlyVersion then
      begin
        rs.ReadBuffer(w, sizeof(Word));
        rs.Position := sizeof(Integer);
        temppath := worker.TempDir;
        if Length(temppath) = 0 then // Get the system temp dir
        begin
          len := GetTempPath(0, PChar(temppath));
          SetLength(temppath, len);
          GetTempPath(len, PChar(temppath));
        end
        else // Use Temp dir provided by ZipMaster
          temppath := DelimitPath(worker.TempDir, True);
        if CoCreateGuid(uid) = S_OK then
          TmpFileName := temppath + GUIDToString(uid) + '.dll'
        else
          TmpFileName := worker.MakeTempFileName('DZ_', '.dll');
        if TmpFileName = '' then
            raise EZipMaster.CreateResDisp(DS_NoTempFile, True);
        fs := TFileStream.Create(TmpFileName, fmCreate);
        if w = IMAGE_DOS_SIGNATURE then
          done := fs.CopyFrom(rs, rs.Size - sizeof(Integer)) =
            (rs.Size - sizeof(Integer))
        else
          done := LZ77Extract(fs, rs, rs.Size - sizeof(Integer)) = 0;

        if not done then
          fHasResDLL := RESVER_BAD; // could not extract
      end;
    end;
  finally
    FreeAndNil(fs);
    FreeAndNil(rs);
    if not OnlyVersion then
    begin
      if (not done) and FileExists(TmpFileName) then
        DeleteFile(TmpFileName);
      if not FileExists(TmpFileName) then
        TmpFileName := '';
    end;
  end;
end;

function TZMDLLLoader.GetIsLoaded: Boolean;
begin
  Result := hndl <> 0;
end;

function TZMDLLLoader.Load(worker: TZMWorker): Integer;
begin
  Result := 0;
  if Counts_Inc(worker) > 0 then
    Result := G_LoadedDLL.Ver;
end;

function TZMDLLLoader.LoadDLL(worker: TZMWorker): Integer;
var
  AllowResDLL: Boolean;
  FullPath: String;
  DBuild: Integer;
  DLLDirectory: String;
  dpth: string;
begin
  if hndl = 0 then
  begin
    fVer := 0;
    FullPath := '';
    DLLDirectory := DelimitPath(TZMDLLOpr(worker).DLLDirectory, False);
    if DLLDirectory = '><' then
    begin
      // use res dll (or else)
      if (TmpFileName <> '') or (ExtractResDLL(worker, False) > MINDLLBUILD{MIN_RESDLL_SIZE}) then
        LoadLib(worker, TmpFileName, True);
      Result := fVer;
      exit;
    end;
    if DLLDirectory <> '' then
    begin
      // check relative?
      if DLLDirectory[1] = '.' then
        FullPath := PathConcat(ExtractFilePath(ParamStr(0)), DLLDirectory)
      else
        FullPath := DLLDirectory;
      if (ExtractNameOfFile(DLLDirectory) <> '') and
        (CompareText(ExtractFileExt(DLLDirectory), '.DLL') = 0) then
      begin
        // must load the named dll
        LoadLib(worker, FullPath, True);
        Result := fVer;
        exit;
      end;
      dpth := ExtractFilePath(FullPath);
      if (dpth <> '') and not DirExists(dpth) then
        FullPath := '';
    end;
    AllowResDLL := DLLDirectory = ''; // only if no path specified
//    DBuild := MINDLLBUILD;//0;
    if AllowResDLL then
    begin
      // check for res dll once only
      if fHasResDLL = RESVER_UNTRIED then
        ExtractResDLL(worker, True);  // read the res dll version if it exists
      if fHasResDLL < MINDLLBUILD then
        AllowResDLL := False;  // none or bad version
    end;
    DBuild := LoadLib(worker, PathConcat(FullPath, DelZipDLL_Name), not AllowResDLL);
    // if not loaded we only get here if allowResDLL is true;
    if DBuild < MINDLLBUILD then
    begin
      // use resdll if no other available
      if (TmpFileName <> '') or (ExtractResDLL(worker, False) > 0) then
      begin
        if LoadLib(worker, TmpFileName, False) < MINDLLBUILD then
        begin
          // could not load the res dll
          fHasResDLL := RESVER_BAD; // is bad version
        end;
      end;
    end;
  end;
  Result := fVer;
  // if (Result > 0) and (worker.Verbosity >= zvVerbose) then
  // worker.ReportMsg(LD_DLLLoaded,[fPath]);
end;

function TZMDLLLoader.Loaded(worker: TZMWorker): Boolean;
var
  i: Integer;
begin
  Result := False;
  i := Counts_Find(worker);
  if (i >= 0) and (Counts[i].Count > 0) then
    Result := True;
end;

// returns build
function TZMDLLLoader.LoadLib(worker: TZMWorker; FullPath: String;
  MustExist: Boolean): Integer;
var
  oldMode: Cardinal;
  tmp: AnsiString;
begin
  if hndl > 0 then
    FreeLibrary(hndl);
  Empty;
  fLoadErr := 0;
  fLoadPath := FullPath;
  oldMode := SetErrorMode(SEM_FAILCRITICALERRORS or SEM_NOGPFAULTERRORBOX);
  try
    hndl := LoadLibrary(pChar(FullPath));
    if hndl > HInstance_Error then
    begin
      @ExecFunc := GetProcAddress(hndl, DelZipDLL_Execfunc);
      if (@ExecFunc <> nil) then
        @VersFunc := GetProcAddress(hndl, DelZipDLL_Versfunc);
      if (@VersFunc <> nil) then
        @PrivFunc := GetProcAddress(hndl, DelZipDLL_Privfunc);
      if (@PrivFunc <> nil) then
        @AbortFunc := GetProcAddress(hndl, DelZipDLL_Abortfunc);
      if (@AbortFunc <> nil) then
        @NameFunc := GetProcAddress(hndl, DelZipDLL_Namefunc);
      if (@NameFunc <> nil) then
        @BannerFunc := GetProcAddress(hndl, DelZipDLL_Bannerfunc);
      if (@BannerFunc <> nil) then
        @PathFunc := GetProcAddress(hndl, DelZipDLL_Pathfunc);
    end
    else
      fLoadErr := GetLastError;
  finally
    SetErrorMode(oldMode);
  end;
  if hndl <= HInstance_Error then
  begin
    Empty;
    if MustExist then
    begin
      if worker.Verbosity >= zvVerbose then
        worker.ReportMsg(LD_LoadErr, [fLoadErr, SysErrorMessage(fLoadErr),
          fLoadPath]);
      raise EZipMaster.CreateResStr(LD_NoDLL, FullPath);
    end;
    Result := 0;
    exit;
  end;
  if (@BannerFunc <> nil) then
  begin
    Priv := PrivFunc;
    fVer := VersFunc;
    SetLength(fPath, MAX_PATH + 1);
{$IFDEF UNICODE}
    NameFunc(fPath[1], MAX_PATH, True);
{$ELSE}
    NameFunc(fPath[1], MAX_PATH, False);
{$ENDIF}
    fPath := String(pChar(fPath));
    tmp := BannerFunc;
    fBanner := String(tmp);
  end;
  if (fVer < DELZIPVERSION) or (fVer > 300) then
  begin
    FullPath := fPath;
    FreeLibrary(hndl);
    Empty;
    if MustExist then
    begin
      if worker.Verbosity >= zvVerbose then
        worker.ReportMsg(LD_LoadErr, [fLoadErr, SysErrorMessage(fLoadErr),
          fLoadPath]);
      raise EZipMaster.CreateResStr(LD_NoDLL, FullPath);
    end;
  end;
  Result := Priv;
end;

function TZMDLLLoader.Path: String;
begin
  Result := '';
  if IsLoaded then
    Result := fPath;
end;

procedure TZMDLLLoader.ReleaseLib;
begin
  if hndl <> 0 then
  begin
    FreeLibrary(hndl);
    hndl := 0;
  end;
  if hndl = 0 then
  begin
    Empty;
    fPath := '';
    if fKillTemp then
      RemoveTempDLL;
  end;
end;

procedure TZMDLLLoader.Remove(worker: TZMWorker);
var
  i: Integer;
begin
{$IFDEF VERD4}
  EnterCriticalSection(CSection);
{$ELSE}
  Guard.Enter;
{$ENDIF}
  try
    i := Counts_Find(worker);
    if i >= 0 then
    begin
      // found - remove it
      Counts[i].worker := nil;
      Counts[i].Count := 0;
    end;
  finally
{$IFDEF VERD4}
  LeaveCriticalSection(CSection);
{$ELSE}
    Guard.Leave;
{$ENDIF}
  end;
end;

procedure TZMDLLLoader.RemoveTempDLL;
var
  t: String;
begin
  t := TmpFileName;
  TmpFileName := '';
  fKillTemp := False;
  if (t <> '') and FileExists(t) then
    SysUtils.DeleteFile(t);
end;

procedure TZMDLLLoader.Unload(worker: TZMWorker);
begin
  Counts_Dec(worker);
end;

function TZMDLLLoader.UnloadDLL: Integer;
begin
  ReleaseLib;
  Result := fVer;
end;
{$ENDIF}
{ public functions }

procedure _DLL_Abort(worker: TZMWorker; key: Cardinal);
begin
  if key <> 0 then
{$IFDEF STATIC_LOAD_DELZIP_DLL}
    DZ_Abort(key);
{$ELSE}
  G_LoadedDLL.Abort(worker, key);
{$ENDIF}
end;

function _DLL_Banner: String;
begin
{$IFDEF STATIC_LOAD_DELZIP_DLL}
  Result := DZ_Banner;
{$ELSE}
  Result := G_LoadedDLL.Banner;
{$ENDIF}
end;

function _DLL_Build: Integer;
begin
{$IFDEF STATIC_LOAD_DELZIP_DLL}
  Result := DZ_PrivVersion;
{$ELSE}
  Result := G_LoadedDLL.Build;
{$ENDIF}
end;

function _DLL_Exec(worker: TZMWorker; const Rec: pDLLCommands;
  var key: Cardinal): Integer;
begin
  try
{$IFDEF STATIC_LOAD_DELZIP_DLL}
    Result := DZ_Exec(Rec);
{$ELSE}
    Result := G_LoadedDLL.Exec(worker, Rec, key);
{$ENDIF}
    key := 0;
  except
    Result := -6; // -7;
    key := 0;
  end;
  CheckExec(Result);
end;

function _DLL_Load(worker: TZMWorker): Integer;
begin
{$IFDEF STATIC_LOAD_DELZIP_DLL}
  Result := DZ_Version;
{$ELSE}
  Result := G_LoadedDLL.Load(worker);
{$ENDIF}
end;

function _DLL_Loaded(worker: TZMWorker): Boolean;
begin
{$IFDEF STATIC_LOAD_DELZIP_DLL}
  Result := True;
{$ELSE}
  Result := G_LoadedDLL.Loaded(worker);
{$ENDIF}
end;

function _DLL_Path: String;
begin
{$IFDEF STATIC_LOAD_DELZIP_DLL}
  Result := DZ_Path;
{$ELSE}
  Result := G_LoadedDLL.Path;
{$ENDIF}
end;

// remove from list
procedure _DLL_Remove(worker: TZMWorker);
begin
{$IFDEF STATIC_LOAD_DELZIP_DLL}
  // nothing to do
{$ELSE}
  G_LoadedDLL.Remove(worker);
{$ENDIF}
end;

procedure _DLL_Unload(worker: TZMWorker);
begin
{$IFNDEF STATIC_LOAD_DELZIP_DLL}
  G_LoadedDLL.Unload(worker);
{$ENDIF}
end;
{$IFNDEF STATIC_LOAD_DELZIP_DLL}

initialization

G_LoadedDLL := TZMDLLLoader.Create;

finalization

FreeAndNil(G_LoadedDLL);
{$ENDIF}

end.
