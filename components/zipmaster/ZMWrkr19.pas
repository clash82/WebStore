unit ZMWrkr19;

(*
  ZMWrkr19.pas - Does most of the work
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

  modified 2010-06-20
---------------------------------------------------------------------------*)

{$I '.\ZipVers19.inc'}
{$IFDEF VER180}
{$WARN SYMBOL_DEPRECATED OFF}
{$ENDIF}

interface

uses
  SysUtils, Windows, Classes, Graphics,
  ZipMstr19, ZMCompat19, ZMCore19, ZMWAUX19, ZMZipFile19;

//------------------------------------------------------------------------

type
  TSFXOps = (sfoNew, sfoZip, sfoExe);

type
  TZMWorker = class(TZMWAux)
  private
    function AddZippedFilesWrite(DstZip: TZMZipFile; DstCnt: Integer; SrcZip:
        TZMZipFile; SrcCnt: Integer): integer;
    function Prepare(MustExist: Boolean; SafePart: boolean = false): TZMZipFile;
  protected
    function Delete1: integer;
    function IsDetachedSFX(const fn: String): Boolean;
    //1 Rewrite via an intermediate
    function Remake(CurZip: TZMZipFile; ReqCnt: Integer; All: boolean): Integer;
    procedure ResolveMerge(Merge: TZMMergeOpts; SrcZip, DstZip: TZMZipFile; var
        SrcCnt, DstCnt: Integer);
    procedure VerifySource(SrcZip: TZMZipFile);
  public
    procedure AddZippedFiles(SrcWorker: TZMWorker; Merge: TZMMergeOpts);
    function AddZippedFilesAppend(DstZip, SrcZip: TZMZipFile; Last: Integer):
        integer;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function ChangeFileDetails(func: TZMChangeFunction; var data): Integer;
    procedure Clear; override;
    procedure CopyZippedFiles(DestWorker: TZMWorker; DeleteFromSource: boolean;
        OverwriteDest: TZMMergeOpts); overload;
    procedure Delete;
    function ForEach(func: TZMForEachFunction; var data): Integer;
    function IsDestWritable(const fname: String; AllowEmpty: Boolean): Boolean;
    procedure List;
    procedure Rename(RenameList: TList; NewDateTime: Integer; How: TZMRenameOpts =
        htrDefault);
    procedure Set_ZipComment(const zComment: AnsiString);
    procedure StartUp; override;
    property TotalSizeToProcess: Int64 read GetTotalSizeToProcess;
  end;

implementation

uses
  Dialogs, ZMStructs19, ZMDelZip19, ZMXcpt19, ZMUtils19, ZMDlg19, ZMCtx19,
  ZMMsgStr19, ZMMsg19, ZMWorkFile19, ZMDrv19, ZMMatch19, ZMIRec19, ZMEOC19;

const
  BufSize = 10240;
  //8192;   // Keep under 12K to avoid Winsock problems on Win95.
  // If chunks are too large, the Winsock stack can
  // lose bytes being sent or received.

type
  pRenData = ^TRenData;

  TRenData = record
    Owner: TZMCore;
    RenList: TList;
    DTime:   Integer;
    How:  TZMRenameOpts;
    cnt:     Integer;
  end;

// 'ForEach' function to rename files
function RenFunc(rec: TZMDirRec; var data): Integer;
var
  ChangeName: boolean;
  FileName: String;
  How:  TZMRenameOpts;
  i: Integer;
  k: Integer;
  ncomment: String;
  newname: String;
  newStamp: integer;
  pData: pRenData;
  pRenRec: PZMRenameRec;
  RenSource: TZMString;
begin
  filename := rec.FileName;
  pData := @data;
  How := pData.How;
  Result := 0;
  for i := 0 to pData^.RenList.Count - 1 do
  begin
    pRenRec := PZMRenameRec(pData^.RenList[i]);
    RenSource := pRenRec.Source;
    newname := pRenRec.Dest;
    ncomment := pRenRec.Comment;
    newStamp := pRenRec.DateTime;
    ChangeName := (newname <> '|') and (CompareStr(filename, newname) <> 0);
    if How = htrFull then
    begin
      if pData^.Owner.FNMatch(pRenRec.Source, FileName) then
        k := -1
      else
        k := 0;
    end
    else
    begin
      k := Pos(UpperCase(RenSource), UpperCase(FileName));
    end;
    if k <> 0 then
    begin
      inc(pData^.cnt);   // I am selected
      if not ChangeName then
        Result := 0
      else
      begin
        if k > 0 then
        begin
          newname := FileName;
          System.Delete(newname, k, Length(RenSource));
          Insert(pRenRec.Dest, newname, k);
        end;
        Result := rec.ChangeName(newname);
        if Result = 0 then
          filename := rec.FileName;
      end;
      if Result = 0 then
      begin
        if ncomment <> '' then
        begin
          if ncomment[1] = #0 then
            ncomment := '';
          Result := rec.ChangeComment(ncomment);
        end;
      end;
      if Result = 0 then
      begin
        if newStamp = 0 then
          newStamp := pData^.DTime;
        if newStamp <> 0 then
          Result := rec.ChangeDate(newStamp);
      end;
      if How <> htrDefault then
        break;
    end;
  end;
end;

(* TZMWorker.AddZippedFiles
  Add zipped files from source ZipMaster selected from source FSpecArgs
  When finished
    FSpecArgs will contain source files copied
    FSpecArgsExcl will contain source files skipped
*)
procedure TZMWorker.AddZippedFiles(SrcWorker: TZMWorker; Merge: TZMMergeOpts);
var
  BadSkip: Boolean;
  DstCnt: Integer;
  DstZip: TZMZipFile;
  idx: Integer;
  res: Integer;
  SrcCnt: Integer;
  SrcZip: TZMZipFile;
begin
  ShowProgress := zspNone;
  ClearErr;
  // Are source and destination different?
  SrcZip := SrcWorker.CentralDir.Current;
  VerifySource(SrcZip); // make sure we have some valid
  DstZip := Prepare(false, true);
  if (SrcWorker = Self) or IsSameFile(ZipFileName, SrcWorker.ZipFileName) then
    raise EZipMaster.CreateResDisp(CF_SourceIsDest, true);

  if (SrcZip.WorkDrive.DriveLetter = DstZip.WorkDrive.DriveLetter) and
    (not DstZip.WorkDrive.DriveIsFixed) and
    (DstZip.MultiDisk or SrcZip.MultiDisk or (zwoDiskSpan in WriteOptions))
    then
    raise EZipMaster.CreateResDisp(AZ_SameAsSource, true);

  BadSkip := false;
  FSpecArgs.Clear;
  SrcCnt := SrcZip.SelectFiles(SrcWorker.FSpecArgs, SrcWorker.FSpecArgsExcl,
    FSpecArgs);
  FSpecArgsExcl.Clear; // will contain source files not copied
  if SrcCnt > 0 then
  begin
    // copy the list of not found specs adding the correct error
    for idx := 0 to FSpecArgs.Count - 1 do
    begin
      FSpecArgsExcl.AddObject(FSpecArgs[idx], pointer(stNotFound));
      if ReportSkipping(FSpecArgs[idx], 0, stNotFound) then
        BadSkip := true;
    end;
  end;
  FSpecArgs.Clear; // will contain files copied from source
  if BadSkip then
    raise EZipMaster.CreateResDisp(GE_NoSkipping, true);
  if SrcCnt < 1 then
    raise EZipMaster.CreateResDisp(AZ_NothingToDo, true);

  DstCnt := DstZip.Select('*', zzsSet); // initial want all
  if DstCnt > 0 then
  begin
    //  Resolve merge conflicts
    //  Src files to be copied are appended to FSpecArgs
    //  Dst files to be copied instead of Src files appended to FSpecArgsExcl
    ResolveMerge(Merge, SrcZip, DstZip, SrcCnt, DstCnt);
  end;
  if SrcCnt < 1 then
    raise EZipMaster.CreateResDisp(AZ_NothingToDo, true);
  // write the results
  res := AddZippedFilesWrite(DstZip, DstCnt, SrcZip, SrcCnt);
  CentralDir.Current := nil; // must reload
  if res < 0 then
    raise EZipMaster.CreateResDisp(-res, res <> -GE_Abort);
  // Update the Zip Directory by calling List method
  // for spanned exe avoid swapping to last disk
  if not IsDetachedSFX(ZipFileName) then
    List;
end;

function TZMWorker.AddZippedFilesAppend(DstZip, SrcZip: TZMZipFile; Last:
    Integer): integer;
var
  r: Integer;
  Zip: TZMZipCopy;
  TruncPosn: Int64;
begin
  DstZip.File_Close;
  Zip := TZMZipCopy.Create(Self);
  try
    Zip.Replicate(DstZip, Last);
    Zip.DiskNr := 0;
    Zip.ShowProgress := zspFull;
    Result := 0;
    r := Zip.Count;
    // add copied entries
    r := r + Zip.AffixZippedFiles(SrcZip, false);
    if r > 0 then
    begin
      Result := SrcZip.Reopen(fmOpenRead);
      if (Result >= 0) then
      begin
        if Last >= 0 then
        begin
          // we must append
          Result := Zip.Reopen(fmOpenReadWrite);
          if Result >= 0 then
          begin
            // get truncate position
            if (Last + 1) >= DstZip.Count then
              TruncPosn := DstZip.CentralOffset  // at SOC
            else
              TruncPosn := DstZip[Last + 1].RelOffLocal; // at start of next local
            if Zip.Seek(TruncPosn, 0) <> TruncPosn then
              Result := -DS_SeekError
            else
            if not Zip.SetEndOfFile then
              Result := -DS_SeekError;
          end;
          if Result >= 0 then
          begin
            Diag('Append to zip');
            Result := Zip.CommitAppend(Last, zwoZipTime in WriteOptions);
          end;
        end
        else
        begin
          // new zip
          Diag('Write new zip');
          if not Zip.File_Create(Zip.FileName) then
            Result := -DS_FileError
          else
            Result := Zip.Commit(zwoZipTime in WriteOptions);
        end;
      end;
    end;
    SrcZip.File_Close;
    Zip.File_Close;
    if Result >= 0 then
    begin
      if Zip.Count <> r then
        Result := AZ_InternalError;
      SuccessCnt := Zip.Count; // number of remaining files
    end;
  finally
    FreeAndNil(Zip);
  end;
end;

function TZMWorker.AddZippedFilesWrite(DstZip: TZMZipFile; DstCnt: Integer;
    SrcZip: TZMZipFile; SrcCnt: Integer): integer;
var
  CanAppend: boolean;
  existed: boolean;
  FirstReplaced: Integer;
  Intermed: TZMZipCopy;
  LastKept: Integer;
  r: Integer;
  WillSpilt: boolean;
  I: Integer;
begin
  existed := (zfi_Loaded and DstZip.info) <> 0;
  WillSpilt := DstZip.MultiDisk or ((not existed) and (zwoDiskSpan in DstZip.WriteOptions));

  if (not WillSpilt) and not (existed and (AddSafe in DstZip.AddOptions)) then
  begin
    // check can append
    LastKept := -1;
    FirstReplaced := -1;
    for I := 0 to DstZip.Count - 1 do
    begin
      if DstZip[I].Selected then
      begin
        LastKept := I;
        if FirstReplaced >= 0 then
          Break;  // cannot append
      end
      else
      if FirstReplaced < 0 then
        FirstReplaced := I;
    end;
    CanAppend :=(FirstReplaced < 0) or (LastKept < FirstReplaced);
    if (Verbosity >= zvVerbose) and CanAppend then
      Diag('Should be able to append starting after index: '+ IntToStr(LastKept));
    if CanAppend then
    begin
      Result := AddZippedFilesAppend(DstZip, SrcZip, LastKept);
      Exit;
    end;
  end;
  // write to intermediate
  Intermed := TZMZipCopy.Create(self);
  try
    if WillSpilt then
      Intermed.File_CreateTemp(PRE_INTER, '')
    else
      Intermed.File_CreateTemp(PRE_INTER, DstZip.FileName); // initial temporary destination
    if not WillSpilt then
    begin
      if assigned(DstZip.stub) and DstZip.UseSFX then
      begin
        Intermed.AssignStub(DstZip);
        Intermed.UseSFX := true;
      end;
      Intermed.DiskNr := 0;
      Intermed.ZipComment := DstZip.ZipComment; // keep orig
    end;
    Intermed.ShowProgress := zspFull;
    Result := 0;
    r := 0;
    if DstCnt > 0 then
      r := Intermed.AffixZippedFiles(DstZip, false);
    r := r + Intermed.AffixZippedFiles(SrcZip, false);
    if r > 0 then
    begin
      Result := SrcZip.Reopen(fmOpenRead);
      if (Result >= 0) and (DstCnt > 0) then
        Result := DstZip.Reopen(fmOpenRead);
      if Result >= 0 then
        Result := Intermed.Commit(zwoZipTime in DstZip.WriteOptions);
    end;
    SrcZip.File_Close;
    DstZip.File_Close;
    Intermed.File_Close;
    if Result >= 0 then
    begin
      if Intermed.Count <> r then
        Result := -AZ_InternalError
      else
      begin
        SuccessCnt := Intermed.Count; // number of remaining files
        // all correct so Recreate source
        Result := Recreate(Intermed, DstZip);
      end;
    end;
  finally
    FreeAndNil(Intermed);
  end;
end;

procedure TZMWorker.AfterConstruction;
begin
  inherited;
  fIsDestructing := False;
end;

(*? TZMWorker.BeforeDestruction
1.73 3 July 2003 RP stop callbacks
*)
procedure TZMWorker.BeforeDestruction;
begin
  fIsDestructing := True;                   // stop callbacks
  inherited;
end;

(* TZMWorker.ChangeFileDetails
  Add zipped files from source ZipMaster selected from source FSpecArgs
  When finished
    FSpecArgs will contain source files copied
    FSpecArgsExcl will contain source files skipped  (data = error code)
*)
function TZMWorker.ChangeFileDetails(func: TZMChangeFunction; var data):
    Integer;
var
  Changes: Integer;
  CurZip: TZMZipFile;
  idx: Integer;
  rec: TZMIRec;
  SelCnt: Integer;
  SkipCnt: Integer;
  SkippedFiles: TStringList;
begin
  ClearErr;
  Result := 0;
  SuccessCnt := 0;
  SkippedFiles := TStringList.Create;
  try
    if Verbosity >= zvVerbose then
      Diag('StartUp ChangeFileDetails');
    CurZip := Prepare(true);  // prepare the current zip
    SelCnt := CurZip.SelectFiles(FSpecArgs, FSpecArgsExcl, SkippedFiles);
    FSpecArgs.Clear; // will contain files processed
    FSpecArgsExcl.Clear; // will contain source files skipped
    SkipCnt := SkippedFiles.Count;
    for idx := 0 to SkippedFiles.Count - 1 do
    begin
      FSpecArgsExcl.AddObject(SkippedFiles[idx], pointer(stNotFound));
      if ReportSkipping(SkippedFiles[idx], 0, stNotFound) then
        Result := -GE_NoSkipping
      else
        Dec(SkipCnt);  // user chose to ignore
    end;
    if (Result = 0) and ((SelCnt <= 0) or (SkipCnt <> 0)) then
    begin
      if Verbosity >= zvVerbose then
        Diag('nothing selected');
      ShowZipMessage(AZ_NothingToDo, '');
      Result := -AZ_NothingToDo;
    end;
  finally
    SkippedFiles.Free;
  end;
  // process selected files
  Changes := 0;
  idx := -1;  // from beginning
  try
    while Result = 0 do
    begin
      idx := CurZip.NextSelected(idx);
      if idx < 0 then
        break; // no more - finished
      rec := CurZip[idx];
      if Verbosity >= zvVerbose then
        Diag('Changing: ' + rec.FileName);
      Result := func(rec, data);
      if Result <> 0 then
      begin
        if Verbosity >= zvVerbose then
          Diag(Format('error [%d] for: %s',[Result, rec.FileName]));

        FSpecArgsExcl.AddObject(rec.FileName, pointer(Result));
        if ReportSkipping(rec.FileName, Result, stCannotDo) then
          Result := -GE_NoSkipping
        else
          Result := 0;   // ignore error
      end;
      if Result = 0 then
      begin
        FSpecArgs.Add(rec.FileName);
        if rec.HasChanges then
        begin
          if Verbosity >= zvVerbose then
            Diag('Changed: ' + rec.FileName);
          inc(Changes);
        end;
        CheckCancel;
      end;
    end;
  except
    on E: EZipMaster do
    begin
      Result := -E.ResId;
    end;
    on E: Exception do
      Result := -GE_ExceptErr;
  end;
  if (Result = 0) and (Changes > 0) then
  begin
    if Verbosity >= zvVerbose then
      Diag('saving changes');
    Remake(CurZip, -1, True);
    SuccessCnt := Changes;
    CentralDir.Current := nil;
    // Update the Zip Directory by calling List method
    // for spanned exe avoid swapping to last disk
    if not IsDetachedSFX(ZipFileName) then
      List;
  end;
  if Verbosity >= zvVerbose then
    Diag('finished ChangeFileDetails');
end;

(*? TZMWorker.Clear
 Clears lists and strings
*)
procedure TZMWorker.Clear;
begin
  Cancel := -1;
  SuccessCnt := 0;
  inherited;
end;

(*
  Enter FSpecArgs and FSpecArgsExcl specify files to be copied
  Exit FSpecArgs = files copied
       FSpecArgsExcl = files skipped
*)
procedure TZMWorker.CopyZippedFiles(DestWorker: TZMWorker; DeleteFromSource:
    boolean; OverwriteDest: TZMMergeOpts);
var
  DestName: string;
  DstZip: TZMZipFile;
  DstCnt: Integer;
  I: Integer;
  idx: Integer;
  SavedDone: TStringList;
  res: integer;
  Skipped: TStringList;
  SrcCnt: Integer;
  SrcZip: TZMZipFile;
begin
  ShowProgress := zspNone;
  ClearErr;
  res := 0;
  SrcZip := CurrentZip(True, False);
  // validate dest
  DestName := DestWorker.ZipFileName;
  if DestName = '' then
    raise EZipMaster.CreateResDisp(GE_NoZipSpecified, true);
  // Are source and destination different?
  if IsSameFile(ZipFileName, DestName) then
    raise EZipMaster.CreateResDisp(CF_SourceIsDest, true);
  DstZip := DestWorker.CentralDir.Current;
  if DstZip.FileName = '' then
  begin
    // creating new file
    DstZip.FileName := DestName;
    DstZip.ReqFileName := DestName;
  end;
  if (zfi_Cancelled and DstZip.info) <> 0 then
  begin
    if DstZip.AskAnotherDisk(DestName) = idCancel then
      raise EZipMaster.CreateResDisp(GE_Abort, false);
    DstZip.info := 0; // clear error
  end;

  VerifySource(SrcZip); // make sure we have some valid
  Skipped := TStringList.Create;
  try
    SrcCnt := SrcZip.SelectFiles(FSpecArgs, FSpecArgsExcl, Skipped);
    FSpecArgsExcl.Clear; // will contain source files not copied
    if SrcCnt > 0 then
    begin
      // copy the list of not found specs adding the correct error
      for idx := 0 to Skipped.Count - 1 do
      begin
        FSpecArgsExcl.AddObject(Skipped[idx], pointer(stNotFound));
        if ReportSkipping(FSpecArgs[idx], 0, stNotFound) then
          res := -GE_NoSkipping;
      end;
    end;
  finally
    Skipped.Free;
  end;
  FSpecArgs.Clear; // will contain files copied from source
  if (res = 0) and (SrcCnt < 1) then
    res := -AZ_NothingToDo;
  // we now know what files are selected to be merged
  if res = 0 then
  begin
    DstZip.Boss := Self;
    if res >= 0 then
    begin
      DstCnt := DstZip.Select('*', zzsSet); // initial want all
      if DstCnt > 0 then
      begin
        //  Resolve merge conflicts
        //  Src files to be copied are appended to FSpecArgs
        //  Dst files to be copied instead of Src files appended to FSpecArgsExcl
        ResolveMerge(OverwriteDest, SrcZip, DstZip, SrcCnt, DstCnt);
      end;
      // Write the resulting zip
      if SrcCnt < 1 then
        res := -AZ_NothingToDo
      else
        res :=  AddZippedFilesWrite(DstZip, DstCnt, SrcZip, SrcCnt);
      // did it work?
      if res = 0 then
      begin
        if not IsDetachedSFX(DestName) then
        begin
          // try to load the destination
          DstZip.FileName := DestName;
          res := DstZip.Open(False, False);
        end;
      end;
    end;
  end;
  if (res = 0) and DeleteFromSource then
  begin
    // delete the copied files
    Skipped := nil;
    SavedDone := TStringList.Create;
    try
      // save done and skipped files
      SavedDone.AddStrings(FSpecArgs);
      Skipped := TStringList.Create;
      for I := 0 to FSpecArgsExcl.Count - 1 do
        Skipped.AddObject(FSpecArgsExcl.Strings[I], FSpecArgsExcl.Objects[i]);
      FSpecArgsExcl.Clear;
      res := Delete1;  // delete from current zip
      FSpecArgs.Assign(SavedDone);  // restore done files
      for I := 0 to Skipped.Count - 1 do
        FSpecArgsExcl.AddObject(Skipped.Strings[I], Skipped.Objects[i]);
    finally
      SavedDone.Free;
      if Skipped <> nil then
        Skipped.Free;
    end;
    CentralDir.Current := nil; // must reload
    // Update the Zip Directory by calling List method
    // for spanned exe avoid swapping to last disk
    if not IsDetachedSFX(ZipFileName) then
      List;
  end;
  if res < 0 then
    raise EZipMaster.CreateResDisp(-res, res <> -GE_Abort);
  SuccessCnt := FSpecArgs.Count;
end;

(*? TZMWorker.Delete
  Deletes files specified in FSpecArgs from current Zip
  exit: FSpecArgs = files deleted,
        FSpecArgsExcl = files skipped
        SuccessCnt = number of files deleted
*)
procedure TZMWorker.Delete;
var
  res: integer;
begin
  ClearErr;
  if {(not assigned(CentralDir.Current)) or} (CentralDir.Current.Count < 1) or
    (FSpecArgs.Count = 0) then
    res := -DL_NothingToDel
  else
    res := Delete1;
  if res < 0 then
    ShowZipMessage(-res, '')
  else
    SuccessCnt := res;
  // Update the Zip Directory by calling List method
  // for spanned exe avoid swapping to last disk
  if (res <> -DL_NothingToDel) and not IsDetachedSFX(ZipFileName) then
    List;
end;

(*? TZMWorker.Delete1
  Deletes files specified in FSpecArgs from current Zip
  exit: FSpecArgs = files deleted,
        FSpecArgsExcl = files skipped
        Result = >=0 number of files deleted, <0 error
*)
function TZMWorker.Delete1: integer;
var
  BeforeCnt: Integer;
  CurZip: TZMZipFile;
  DelCnt: Integer;
  idx: Integer;
  SkippedFiles: TStringList;
begin
  CurZip := Prepare(true);  // prepare the Current zip
  Result := 0;
  SkippedFiles := TStringList.Create;
  try
    DelCnt := CurZip.SelectFiles(FSpecArgs, FSpecArgsExcl, SkippedFiles);
    FSpecArgs.Clear;     // will contain files deleted
    FSpecArgsExcl.Clear; // will contain files skipped
    for idx := 0 to SkippedFiles.Count - 1 do
    begin
      FSpecArgsExcl.AddObject(SkippedFiles[idx], pointer(stNotFound));
      if ReportSkipping(SkippedFiles[idx], 0, stNotFound) then
        Result := - GE_NoSkipping;
    end;
  finally
    SkippedFiles.Free;
  end;
  if (Result = 0) and (DelCnt <= 0) then
    Result := -DL_NothingToDel;
  if Result = 0 then
  begin
    ASSERT(DelCnt = CurZip.SelCount, 'selcount wrong 1');
//    DelCnt := CurZip.Count - DelCnt;
//    if DelCnt < 1 then
    if (CurZip.Count - DelCnt) < 1 then
    begin
      // no files left
      CurZip.File_Close;
      SysUtils.DeleteFile(CurZip.FileName);
      Result := DelCnt; // number of files deleted
    end
    else
    begin
      idx := -1;  // from beginning
      while true do
      begin
        idx := CurZip.NextSelected(idx);
        if idx < 0 then
          break; // no more - finished
        FSpecArgs.Add(CurZip[idx].FileName);
      end;
      BeforeCnt := CurZip.Count;
      CurZip.Select('*', zzsToggle); // select entries to keep
      ASSERT((CurZip.Count - DelCnt) = CurZip.SelCount, 'selcount wrong 2');
//      ASSERT(DelCnt = CurZip.SelCount, 'selcount wrong 2');
      // write the result
      Result := Remake(CurZip, CurZip.Count - DelCnt, False);
      if Result >= 0 then
        Result := BeforeCnt - Result;   // if no error
    end;
  end;
  CurZip.Invalidate;
  CentralDir.Current := nil;   // force reload
end;

function TZMWorker.ForEach(func: TZMForEachFunction; var data): Integer;
var
  BadSkip: Boolean;
  CurZip: TZMZipFile;
  good: Integer;
  i: Integer;
  idx: Integer;
  rec: TZMDirEntry;
  SelCnt: Integer;
  SkippedFiles: TStringList;
begin
  ClearErr;
  Result := 0;
  SuccessCnt := 0;
  good := 0;
  SkippedFiles := TStringList.Create;
  try
    if Verbosity >= zvVerbose then
      Diag('StartUp ForEach');
    CurZip := CurrentZip(True);
    SelCnt := CurZip.SelectFiles(FSpecArgs, FSpecArgsExcl, SkippedFiles);
    if SelCnt <= 0 then
    begin
      if Verbosity >= zvVerbose then
        Diag('nothing selected');
      ShowZipMessage(AZ_NothingToDo, '');
      Exit;
    end;
    FSpecArgs.Clear;      // will contain files processed
    FSpecArgsExcl.Clear;  // will contain files skipped
    BadSkip := False;
    for idx := 0 to SkippedFiles.Count - 1 do
    begin
      FSpecArgsExcl.AddObject(SkippedFiles[idx], pointer(stNotFound));
      if ReportSkipping(SkippedFiles[idx], 0, stNotFound) then
        BadSkip := True;
    end;
  finally
    SkippedFiles.Free;
  end;
  if BadSkip then
  begin
    ShowZipMessage(GE_NoSkipping, '');
    Exit;
  end;
  i := -1;
  while True do
  begin
    i := CurZip.NextSelected(i);
    if i < 0 then
      break;
    rec := CurZip[i];
    if Verbosity >= zvVerbose then
      Diag('Processing: ' + rec.FileName);
    Result := func(rec, data);
    if Result <> 0 then
    begin
      FSpecArgsExcl.Add(rec.FileName);
      break;
    end;
    inc(good);
    FSpecArgs.Add(rec.FileName);
    CheckCancel;
  end;
  SuccessCnt := good;
  if Verbosity >= zvVerbose then
    Diag('finished ForEach');
end;

(*? TZMWorker.IsDestWritable
1.79  2005 Jul 9
*)
function TZMWorker.IsDestWritable(const fname: String; AllowEmpty: Boolean):
    Boolean;
var
  hFile: Integer;
  sr: TSearchRec;
  wd: TZMWorkDrive;
  xname: String;
begin
  Result := False;
  wd := TZMWorkDrive.Create;
  try
    xname := ExpandUNCFileName(fname);
    // test if destination can be written
    wd.DriveStr := xname;
    if not wd.HasMedia(false) then
    begin
      Result := AllowEmpty and (wd.DriveType = DRIVE_REMOVABLE);
      // assume can put in writable disk
      exit;
    end;
    if WinXP or (wd.DriveType <> DRIVE_CDROM) then
    begin
      if sysUtils.FindFirst(xname, faAnyFile, sr) = 0 then
      begin
        Result := (sr.Attr and faReadOnly) = 0;
        sysUtils.FindClose(sr);
        if Result then
        begin
          // exists and is not read-only - test locked
          hFile := SysUtils.FileOpen(xname, fmOpenWrite);
          Result := hFile > -1;
          if Result then
            SysUtils.FileClose(hFile);
        end;
        exit;
      end;
      // file did not exist - try to create it
      hFile := FileCreate(xname);
      if hFile > -1 then
      begin
        Result := True;
        FileClose(hFile);
        SysUtils.DeleteFile(xname);
      end;
    end;
  finally
    wd.Free;
  end;
end;

function TZMWorker.IsDetachedSFX(const fn: String): Boolean;
var
  ext: String;
  wz: TZMZipFile;
begin
  Result := False;
  ext := ExtractFileExt(fn);
  if AnsiSameText(ext, '.exe') then
  begin
    wz := TZMZipFile.Create(self);
    try
      wz.FileName := fn;
      if (wz.OpenEOC(true) >= 0) and IsDetachSFX(wz) then
        Result := true;
    finally
      wz.Free;
    end;
  end;
end;

procedure TZMWorker.List;
begin
  LoadZip(ZipFileName, false);
end;

(* TZMWorker.Prepare
  Prepare destination and get SFX stub as needed
*)
function TZMWorker.Prepare(MustExist: Boolean; SafePart: boolean = false):
    TZMZipFile;
begin
  Result := CurrentZip(MustExist, SafePart);
  if Unattended and not Result.WorkDrive.DriveIsFixed then
    raise EZipMaster.CreateResDisp(DS_NoUnattSpan, true);
  if (Uppercase(ExtractFileExt(Result.ReqFileName)) = EXT_EXE) then
  begin
    Result.UseSFX := true;
    Result.Stub := NewSFXStub;
    Result.UseSFX := true;
  end;
end;

// write to intermediate then recreate as original
function TZMWorker.Remake(CurZip: TZMZipFile; ReqCnt: Integer; All: boolean):
    Integer;
var
  Intermed: TZMZipCopy;
  Res: Integer;
begin
  Result := 0;
  Intermed := TZMZipCopy.Create(self);
  try
    if not Intermed.File_CreateTemp(PRE_INTER, '') then
      raise EZipMaster.CreateResDisp(DS_NoOutFile, True);
    Intermed.ShowProgress := zspFull;
    Intermed.ZipComment := CurZip.ZipComment;
    CurZip.Reopen(fmOpenRead);
    Res := Intermed.WriteFile(CurZip, All);
    CurZip.File_Close;
    Intermed.File_Close;
    if Res < 0 then
      raise EZipMaster.CreateResDisp(-Res, true);
    Result := Intermed.Count; // number of remaining files
    if (ReqCnt >= 0) and (Result <> ReqCnt) then
      raise EZipMaster.CreateResDisp(AZ_InternalError, true);
    // Recreate like orig
    Res := Recreate(Intermed, CurZip);
    if Res < 0 then
      raise EZipMaster.CreateResDisp(-Res, true);
  finally
    Intermed.Free; // also delete temp file
  end;
end;

(*? TZMWorker.Rename
 Function to read a Zip archive and change one or more file specifications.
 Source and Destination should be of the same type. (path or file)
 If NewDateTime is 0 then no change is made in the date/time fields.
*)
procedure TZMWorker.Rename(RenameList: TList; NewDateTime: Integer; How:
    TZMRenameOpts = htrDefault);
var
  i: Integer;
  RenDat: TRenData;
  RenRec: PZMRenameRec;
  res: Integer;
begin
  for i := 0 to RenameList.Count - 1 do
  begin
    RenRec := RenameList.Items[i];
    if IsWild(RenRec.Source) then
       raise EZipMaster.CreateResDisp(AD_InvalidName, true);
    RenRec^.Source := SetSlash(RenRec^.Source, psdExternal);
    RenRec^.Dest := SetSlash(RenRec^.Dest, psdExternal);
  end;
  RenDat.Owner := Self;
  RenDat.RenList := RenameList;
  RenDat.DTime := NewDateTime;
  RenDat.How := How;
  RenDat.cnt := 0;
  if FSpecArgs.Count < 1 then
    FSpecArgs.Add('*.*');
  res := ChangeFileDetails(TZMChangeFunction(@RenFunc), RenDat);
  if res < 0 then
    raise EZipMaster.CreateResDisp(-res, true);
  SuccessCnt := RenDat.cnt;
end;

(*
  Resolve merge conflicts
  Src files to be copied are appended to FSpecArgs
  Dst files to be copied instead of Src files appended to FSpecArgsExcl
*)
procedure TZMWorker.ResolveMerge(Merge: TZMMergeOpts; SrcZip, DstZip:
    TZMZipFile; var SrcCnt, DstCnt: Integer);
var
  DstRec: TZMIRec;
  i: Integer;
  idx: Integer;
  k: Cardinal;
  SrcRec: TZMIRec;
  tmpCopyZippedOverwrite: TZMCopyZippedOverwriteEvent;
  WantSrc: Boolean;
begin
  i := -1; // from beginning
  k := 0;
  while true do
  begin
    i := SrcZip.NextSelected(i);
    if i < 0 then
      break;
    Inc(k);
    if (k and 127) = 0 then
      CheckCancel;
    SrcRec := SrcZip[i];
    // check conflicts
    idx := -1;
    DstRec := nil; // keep compiler happy
    if DstCnt > 0 then
      DstRec := DstZip.FindName(SrcRec.FileName, idx);
    if idx < 0 then
    begin
      FSpecArgs.Add(SrcRec.FileName); // ext name
      continue;
    end;
    if Verbosity >= zvVerbose then
      Diag('file conflict: ' + SrcRec.FileName);
    // file exists in both
    WantSrc := false;
    case Merge of
      zmoConfirm:
        begin
          // Do we have a event assigned for this then don't ask.
          tmpCopyZippedOverwrite := Master.OnCopyZippedOverwrite;
          if Assigned(tmpCopyZippedOverwrite) then
            tmpCopyZippedOverwrite(Master, SrcRec, DstRec, WantSrc)
          else if ZipMessageDlgEx('', Format(ZipLoadStr(CF_OverwriteYN),
              [SrcZip.FileName, DstZip.FileName]),
            zmtConfirmation + DHC_CpyZipOvr, [mbYes, mbNo]) = idYes then
            WantSrc := true;
        end;
      zmoAlways:
        WantSrc := true;
      zmoNewer:
        WantSrc := SrcRec.ModifDateTime > DstRec.ModifDateTime;
      zmoOlder:
        WantSrc := SrcRec.ModifDateTime < DstRec.ModifDateTime;
      zmoNever:
        WantSrc := false;
    end;
    if WantSrc then
    begin
      if Verbosity >= zvVerbose then
        Diag('to copy source');
      DstRec.ClearStatusBit(zsbSelected);
      dec(DstCnt);
      FSpecArgs.Add(SrcRec.FileName);
    end
    else
    begin
      if Verbosity >= zvVerbose then
        Diag('to copy destination');
      SrcRec.ClearStatusBit(zsbSelected);
      dec(SrcCnt);
      FSpecArgsExcl.Add(SrcRec.FileName);
    end;
  end;
end;

procedure TZMWorker.Set_ZipComment(const zComment: AnsiString);
var
  EOC: TZipEndOfCentral;
  len: Integer;
  wz: TZMZipFile;
  zcom: AnsiString;
begin
  wz := TZMZipFile.Create(self);
  try
    try
      if Length(ZipFileName) <> 0 then
      begin
        wz.SpanOptions := wz.SpanOptions - [spExactName];
        wz.FileName := ZipFileName;
        wz.Open(true, true);// ignore errors
      end
      else
        raise EZipMaster.CreateResDisp(GE_NoZipSpecified, true);
      ZipComment := zComment;
      // opened by OpenEOC() only for Read
      if wz.IsOpen then     // file exists
      begin
        wz.File_Close;
        if wz.ZipComment <> zComment then
        begin     // change it
          // must reopen for read/write
          zcom := zComment;
          len := Length(zCom);
          wz.File_Open(fmShareDenyWrite or fmOpenReadWrite);
          if not wz.IsOpen then
            raise EZipMaster.CreateResDisp(DS_FileOpen, True);
          if wz.MultiDisk and (wz.StampDate = 0) then
            wz.StampDate := wz.LastWritten;  // keep date of set
          wz.CheckSeek(wz.EOCOffset, 0, DS_FailedSeek);
          wz.CheckRead(EOC, SizeOf(EOC), DS_EOCBadRead);
          if (EOC.HeaderSig <> EndCentralDirSig) then
            raise EZipMaster.CreateResDisp(DS_EOCBadRead, True);
          EOC.ZipCommentLen := len;
          wz.CheckSeek(-Sizeof(EOC), 1, DS_FailedSeek);
          wz.CheckWrite(EOC, sizeof(EOC), DS_EOCBadWrite);
          if len > 0 then
            wz.CheckWrite(zCom[1], len, DS_EOCBadWrite);
          // if SetEOF fails we get garbage at the end of the file, not nice but
          // also not important.
          wz.SetEndOfFile;
        end;
      end;
    except
      on ews: EZipMaster do
      begin
        ShowExceptionError(ews);
        ZipComment := '';
      end;
      on EOutOfMemory do
      begin
        ShowZipMessage(GE_NoMem, '');
        ZipComment := '';
      end;
    end;
  finally
    wz.Free;
  end;
  // Update the Zip Directory by calling List method
  // for spanned exe avoid swapping to last disk
  if not IsDetachedSFX(ZipFileName) then
    List
end;

(*? TZMWorker.StartUp
*)
procedure TZMWorker.StartUp;
var
  CurZip: TZMZipFile;
begin
  SuccessCnt := 0;
  CentralDir.IgnoreDirOnly := not Master.UseDirOnlyEntries;
  inherited;
  // update values that may have changed since CurZip was made
  CurZip := CentralDir.Current;
  CurZip.AddOptions := AddOptions;
  CurZip.SpanOptions := SpanOptions;
  CurZip.WriteOptions := WriteOptions;
  CurZip.IgnoreDirOnly := IgnoreDirOnly;
  CurZip.Encoding := Encoding;
  CurZip.EncodeAs := EncodeAs;
  CurZip.Encoding_CP := Encoding_CP;
end;

procedure TZMWorker.VerifySource(SrcZip: TZMZipFile);
begin
  if not assigned(SrcZip) then
    raise EZipMaster.CreateResDisp(AZ_NothingToDo, true);
  if (SrcZip.info and zfi_Cancelled) <> 0 then
    raise EZipMaster.CreateResDisp(DS_Canceled, true);
  if (SrcZip.info and zfi_loaded) = 0 then
    raise EZipMaster.CreateResDisp(AD_InvalidZip, true);
end;

end.
