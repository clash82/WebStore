Unit ZMDefMsgs19;
 
(* Built by ZipHelper
   DO NOT MODIFY
  ZMDefMsgs19.pas - default messages and compressed tables
 
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
 
---------------------------------------------------------------------------*)
 
Interface
 
Uses
  ZMMsg19;

{$I '.\ZMConfig19.inc'}
 
{$IFNDEF USE_COMPRESSED_STRINGS}
 
type
  TZipResRec = packed record
    i: Word;
    s: pResStringRec;
  end;
 
ResourceString
  _DT_Language = 'US: default';
  _DT_Author = 'R.Peters';
  _DT_Desc = 'Language Neutral';
  _GE_FatalZip = 'Fatal Error in DLL: abort exception';
  _GE_NoZipSpecified = 'Error - no zip file specified!';
  _GE_NoMem = 'Requested memory not available';
  _GE_WrongPassword = 'Error - passwords do NOT match'#10'Password ignored';
  _GE_Except = 'Exception in Event handler ';
  _GE_Inactive = 'not Active';
  _GE_RangeError = 'Index (%d) outside range 0..%d';
  _GE_TempZip = 'Temporary zipfile: %s';
  _GE_WasBusy = 'Busy + %s';
  _GE_EventEx = 'Exception in Event ';
  _GE_DLLCritical = 'critical DLL Error %d';
  _GE_Unknown = ' Unknown error %d';
  _GE_Skipped = 'Skipped %s %d';
  _GE_Copying = 'Copying: %s';
  _GE_Abort = 'User Abort';
  _GE_ExceptErr = 'Error Exception: ';
  _GE_NoSkipping = 'Skipping not allowed';
  _GE_FileChanged = 'Zip file was changed!';
  _RN_InvalidDateTime = 'Invalid date/time argument for file: ';
  _PW_UnatAddPWMiss = 'Error - no add password given';
  _PW_UnatExtPWMiss = 'Error - no extract password given';
  _PW_Caption = 'Password';
  _PW_MessageEnter = 'Enter Password ';
  _PW_MessageConfirm = 'Confirm Password ';
  _CF_SourceIsDest = 'Source archive is the same as the destination archive!';
  _CF_OverwriteYN = 'Overwrite file ''%s'' in ''%s'' ?';
  _CF_CopyFailed = 'Copying a file from ''%s'' to ''%s'' failed';
  _CF_SFXCopyError = 'Error while copying the SFX data';
  _CF_NoDest = 'No destination specified';
  _LI_ReadZipError = 'Seek error reading Zip archive!';
  _LI_ErrorUnknown = 'Unknown error in List() function';
  _LI_WrongZipStruct = 'Warning - Error in zip structure!';
  _ZB_Yes = '&Yes';
  _ZB_No = '&No';
  _ZB_OK = '&OK';
  _ZB_Cancel = '&Cancel';
  _ZB_Abort = '&Abort';
  _ZB_Retry = '&Retry';
  _ZB_Ignore = '&Ignore';
  _ZB_CancelAll = 'CancelAll';
  _ZB_NoToAll = 'NoToAll';
  _ZB_YesToAll = 'YesToAll';
  _AD_NothingToZip = 'Error - no files to zip!';
  _AD_UnattPassword = 'Unattended action not possible without a password';
  _AD_AutoSFXWrong = 'Error %.1d occurred during Auto SFX creation.';
  _AD_InIsOutStream = 'Input stream may not be set to the output stream';
  _AD_InvalidName = 'Wildcards are not allowed in Filename or file specification';
  _AD_NoDestDir = 'Destination directory ''%s'' must exist!';
  _AD_BadFileName = 'Invalid Filename';
  _AD_InvalidEncode = 'Invalid encoding options';
  _AD_InvalidZip = 'Invalid zip file';
  _AZ_NothingToDo = 'Nothing to do';
  _AZ_SameAsSource = 'source and destination on same removable drive';
  _AZ_InternalError = 'Internal error';
  _DL_NothingToDel = 'Error - no files selected for deletion';
  _EX_UnAttPassword = 'Warning - Unattended Extract: possible not all files extracted';
  _EX_NoExtrDir = 'Extract directory ''%s'' must exist';
  _LD_NoDll = 'Failed to load %s';
  _LD_DllLoaded = 'Loaded %s';
  _LD_DllUnloaded = 'Unloaded %s';
  _LD_LoadErr = 'Error [%d %s] loading %s';
  _SF_StringTooLong = 'Error: Combined SFX strings unreasonably long!';
  _SF_NoZipSFXBin = 'Error: SFX stub ''%s'' not found!';
  _SF_DetachedHeaderTooBig = 'Detached SFX Header too large';
  _CZ_InputNotExe = 'Error: input file is not an .EXE file';
  _CZ_BrowseError = 'Error while browsing resources.';
  _CZ_NoExeResource = 'No resources found in executable.';
  _CZ_ExeSections = 'Error while reading executable sections.';
  _CZ_NoExeIcon = 'No icon resources found in executable.';
  _CZ_NoIcon = 'No icon found.';
  _CZ_NoCopyIcon = 'Cannot copy icon.';
  _CZ_NoIconFound = 'No matching icon found.';
  _DS_NoInFile = 'Input file does not exist';
  _DS_FileOpen = 'Zip file could not be opened';
  _DS_NotaDrive = 'Not a valid drive: %s';
  _DS_DriveNoMount = 'Drive %s is NOT defined';
  _DS_NoVolume = 'Volume label could not be set';
  _DS_NoMem = 'Not enough memory to display MsgBox';
  _DS_Canceled = 'User canceled operation';
  _DS_FailedSeek = 'Seek error in input file';
  _DS_NoOutFile = 'Creation of output file failed';
  _DS_NoWrite = 'Write error in output file';
  _DS_EOCBadRead = 'Error while reading the End Of Central Directory';
  _DS_LOHBadRead = 'Error while reading a local header';
  _DS_CEHBadRead = 'Error while reading a central header';
  _DS_CEHWrongSig = 'A central header signature is wrong';
  _DS_CENameLen = 'Error while reading a central file name';
  _DS_DataDesc = 'Error while reading/writing a data descriptor area';
  _DS_CECommentLen = 'Error while reading a file comment';
  _DS_ErrorUnknown = 'UnKnown error in function ReadSpan(), WriteSpan(), ChangeFileDetails() or CopyZippedFiles()'#10;
  _DS_NoUnattSpan = 'Unattended disk spanning not implemented';
  _DS_NoTempFile = 'Temporary file could not be created';
  _DS_LOHBadWrite = 'Error while writing a local header';
  _DS_CEHBadWrite = 'Error while writing a central header';
  _DS_EOCBadWrite = 'Error while writing the End Of Central Directory';
  _DS_NoDiskSpace = 'This disk has not enough free space available';
  _DS_InsertDisk = 'Please insert last disk';
  _DS_InsertVolume = 'Please insert disk volume %.1d of %.1d';
  _DS_InDrive = ''#10'in drive: %s';
  _DS_NoValidZip = 'This archive is not a valid Zip archive';
  _DS_AskDeleteFile = 'There is already a file %s'#10'Do you want to overwrite this file';
  _DS_AskPrevFile = 'ATTENTION: This is previous disk no %d!!!'#10'Are you sure you want to overwrite the contents';
  _DS_InsertAVolume = 'Please insert disk volume %.1d';
  _DS_CopyCentral = 'Central directory';
  _DS_NoDiskSpan = 'DiskSpanning not supported';
  _DS_UnknownError = 'Unknown Error';
  _DS_NoRenamePart = 'Last part left as : %s';
  _DS_NotChangeable = 'Cannot write to %s';
  _DS_Zip64FieldError = 'Error reading Zip64 field';
  _DS_Unsupported = 'Unsupported zip version';
  _DS_ReadError = 'Error reading file';
  _DS_WriteError = 'Error writing file';
  _DS_FileError = 'File Error';
  _DS_FileChanged = 'File changed';
  _DS_SFXBadRead = 'Error reading SFX';
  _DS_BadDrive = 'cannot use drive';
  _DS_LOHWrongName = 'Local and Central names different : %s';
  _DS_BadCRC = 'CRC error';
  _DS_NoEncrypt = 'encryption not supported';
  _DS_NoInStream = 'No input stream';
  _DS_NoOutStream = 'No output stream';
  _DS_SeekError = 'File seek error';
  _DS_DataCopy = 'Error copying compressed data';
  _DS_CopyError = 'File copy error';
  _DS_TooManyParts = 'More than 999 parts in multi volume archive';
  _DS_AnotherDisk = 'This disk is part of a backup set,'#10'please insert another disk';
  _FM_Erase = 'Erase %s';
  _FM_Confirm = 'Confirm';
  _CD_CEHDataSize = 'The combined length of CEH + FileName + FileComment + ExtraData exceeds 65535';
  _CD_DuplFileName = 'Duplicate Filename: %s';
  _CD_NoProtected = 'Cannot change details of Encrypted file';
  _CD_NoChangeDir = 'Cannot change path';
  _PR_Archive = '*Resetting Archive bit';
  _PR_CopyZipFile = '*Copying Zip File';
  _PR_SFX = '*SFX';
  _PR_Header = '*??';
  _PR_Finish = '*Finalising';
  _PR_Copying = '*Copying';
  _PR_CentrlDir = '*Central Directory';
  _PR_Checking = '*Checking';
  _PR_Loading = '*Loading Directory';
  _PR_Joining = '*Joining split zip file';
  _PR_Splitting = '*Splitting zip file';
  _PR_Writing = '*Writing zip file';
  _PR_PreCalc = '*Precalculating CRC';
  _DZ_Skipped = 'Filespec ''%s'' skipped';
  _DZ_InUse = 'Cannot open in-use file ''%s''';
  _DZ_Refused = 'not permitted to open ''%s''';
  _DZ_NoOpen = 'Can not open ''%s''';
  _DZ_NoFiles = 'no files found';
  _DZ_SizeChanged = 'size of ''%s'' changed';
  _TM_Erasing = 'EraseFloppy - Removing %s';
  _TM_Deleting = 'EraseFloppy - Deleting %s';
  _TM_GetNewDisk = 'Trace : GetNewDisk Opening: %s';
  _TM_SystemError = 'System error: %d';
  _TM_Trace = 'Trace: ';
  _TM_Verbose = 'info: ';
  _DZ_RES_GOOD = 'Good';
  _DZ_RES_CANCELLED = 'Cancelled';
  _DZ_RES_ABORT = 'Aborted by User!';
  _DZ_RES_CALLBACK = 'Callback exception';
  _DZ_RES_MEMORY = 'No memory';
  _DZ_RES_STRUCT = 'Invalid structure';
  _DZ_RES_ERROR = 'Fatal error';
  _DZ_RES_PASSWORD_FAIL = 'Password failed!';
  _DZ_RES_PASSWORD_CANCEL = 'Password cancelled!';
  _DZ_RES_INVAL_ZIP = 'Invalid zip structure!';
  _DZ_RES_NO_CENTRAL = 'No Central directory!';
  _DZ_RES_ZIP_EOF = 'Unexpected end of Zip file!';
  _DZ_RES_ZIP_END = 'Premature end of file!';
  _DZ_RES_ZIP_NOOPEN = 'Error opening Zip file!';
  _DZ_RES_ZIP_MULTI = 'Multi-part Zips not supported!';
  _DZ_RES_NOT_FOUND = 'File not found!';
  _DZ_RES_LOGIC_ERROR = 'Internal logic error!';
  _DZ_RES_NOTHING_TO_DO = 'Nothing to do!';
  _DZ_RES_BAD_OPTIONS = 'Bad Options specified!';
  _DZ_RES_TEMP_FAILED = 'Temporary file failure!';
  _DZ_RES_NO_FILE_OPEN = 'File not found or no permission!';
  _DZ_RES_ERROR_READ = 'Error reading file!';
  _DZ_RES_ERROR_CREATE = 'Error creating file!';
  _DZ_RES_ERROR_WRITE = 'Error writing file!';
  _DZ_RES_ERROR_SEEK = 'Error seeking in file!';
  _DZ_RES_EMPTY_ZIP = 'Missing or empty zip file!';
  _DZ_RES_INVAL_NAME = 'Invalid characters in filename!';
  _DZ_RES_GENERAL = 'Error ';
  _DZ_RES_MISS = 'Nothing found';
  _DZ_RES_WARNING = 'Warning: ';
  _DZ_ERR_ERROR_DELETE = 'Delete failed';
  _DZ_ERR_FATAL_IMPORT = 'Fatal Error - could not import symbol!';
  _DZ_ERR_SKIPPING = 'Skipping: ';
  _DZ_ERR_LOCKED = 'File locked';
  _DZ_ERR_DENIED = 'Access denied';
  _DZ_ERR_DUPNAME = 'Duplicate internal name';
 
const
ResTable: array [0..195] of TZipResRec = (
    (i: DT_Language; s: @_DT_Language),
    (i: DT_Author; s: @_DT_Author),
    (i: DT_Desc; s: @_DT_Desc),
    (i: GE_FatalZip; s: @_GE_FatalZip),
    (i: GE_NoZipSpecified; s: @_GE_NoZipSpecified),
    (i: GE_NoMem; s: @_GE_NoMem),
    (i: GE_WrongPassword; s: @_GE_WrongPassword),
    (i: GE_Except; s: @_GE_Except),
    (i: GE_Inactive; s: @_GE_Inactive),
    (i: GE_RangeError; s: @_GE_RangeError),
    (i: GE_TempZip; s: @_GE_TempZip),
    (i: GE_WasBusy; s: @_GE_WasBusy),
    (i: GE_EventEx; s: @_GE_EventEx),
    (i: GE_DLLCritical; s: @_GE_DLLCritical),
    (i: GE_Unknown; s: @_GE_Unknown),
    (i: GE_Skipped; s: @_GE_Skipped),
    (i: GE_Copying; s: @_GE_Copying),
    (i: GE_Abort; s: @_GE_Abort),
    (i: GE_ExceptErr; s: @_GE_ExceptErr),
    (i: GE_NoSkipping; s: @_GE_NoSkipping),
    (i: GE_FileChanged; s: @_GE_FileChanged),
    (i: RN_InvalidDateTime; s: @_RN_InvalidDateTime),
    (i: PW_UnatAddPWMiss; s: @_PW_UnatAddPWMiss),
    (i: PW_UnatExtPWMiss; s: @_PW_UnatExtPWMiss),
    (i: PW_Caption; s: @_PW_Caption),
    (i: PW_MessageEnter; s: @_PW_MessageEnter),
    (i: PW_MessageConfirm; s: @_PW_MessageConfirm),
    (i: CF_SourceIsDest; s: @_CF_SourceIsDest),
    (i: CF_OverwriteYN; s: @_CF_OverwriteYN),
    (i: CF_CopyFailed; s: @_CF_CopyFailed),
    (i: CF_SFXCopyError; s: @_CF_SFXCopyError),
    (i: CF_NoDest; s: @_CF_NoDest),
    (i: LI_ReadZipError; s: @_LI_ReadZipError),
    (i: LI_ErrorUnknown; s: @_LI_ErrorUnknown),
    (i: LI_WrongZipStruct; s: @_LI_WrongZipStruct),
    (i: ZB_Yes; s: @_ZB_Yes),
    (i: ZB_No; s: @_ZB_No),
    (i: ZB_OK; s: @_ZB_OK),
    (i: ZB_Cancel; s: @_ZB_Cancel),
    (i: ZB_Abort; s: @_ZB_Abort),
    (i: ZB_Retry; s: @_ZB_Retry),
    (i: ZB_Ignore; s: @_ZB_Ignore),
    (i: ZB_CancelAll; s: @_ZB_CancelAll),
    (i: ZB_NoToAll; s: @_ZB_NoToAll),
    (i: ZB_YesToAll; s: @_ZB_YesToAll),
    (i: AD_NothingToZip; s: @_AD_NothingToZip),
    (i: AD_UnattPassword; s: @_AD_UnattPassword),
    (i: AD_AutoSFXWrong; s: @_AD_AutoSFXWrong),
    (i: AD_InIsOutStream; s: @_AD_InIsOutStream),
    (i: AD_InvalidName; s: @_AD_InvalidName),
    (i: AD_NoDestDir; s: @_AD_NoDestDir),
    (i: AD_BadFileName; s: @_AD_BadFileName),
    (i: AD_InvalidEncode; s: @_AD_InvalidEncode),
    (i: AD_InvalidZip; s: @_AD_InvalidZip),
    (i: AZ_NothingToDo; s: @_AZ_NothingToDo),
    (i: AZ_SameAsSource; s: @_AZ_SameAsSource),
    (i: AZ_InternalError; s: @_AZ_InternalError),
    (i: DL_NothingToDel; s: @_DL_NothingToDel),
    (i: EX_UnAttPassword; s: @_EX_UnAttPassword),
    (i: EX_NoExtrDir; s: @_EX_NoExtrDir),
    (i: LD_NoDll; s: @_LD_NoDll),
    (i: LD_DllLoaded; s: @_LD_DllLoaded),
    (i: LD_DllUnloaded; s: @_LD_DllUnloaded),
    (i: LD_LoadErr; s: @_LD_LoadErr),
    (i: SF_StringTooLong; s: @_SF_StringTooLong),
    (i: SF_NoZipSFXBin; s: @_SF_NoZipSFXBin),
    (i: SF_DetachedHeaderTooBig; s: @_SF_DetachedHeaderTooBig),
    (i: CZ_InputNotExe; s: @_CZ_InputNotExe),
    (i: CZ_BrowseError; s: @_CZ_BrowseError),
    (i: CZ_NoExeResource; s: @_CZ_NoExeResource),
    (i: CZ_ExeSections; s: @_CZ_ExeSections),
    (i: CZ_NoExeIcon; s: @_CZ_NoExeIcon),
    (i: CZ_NoIcon; s: @_CZ_NoIcon),
    (i: CZ_NoCopyIcon; s: @_CZ_NoCopyIcon),
    (i: CZ_NoIconFound; s: @_CZ_NoIconFound),
    (i: DS_NoInFile; s: @_DS_NoInFile),
    (i: DS_FileOpen; s: @_DS_FileOpen),
    (i: DS_NotaDrive; s: @_DS_NotaDrive),
    (i: DS_DriveNoMount; s: @_DS_DriveNoMount),
    (i: DS_NoVolume; s: @_DS_NoVolume),
    (i: DS_NoMem; s: @_DS_NoMem),
    (i: DS_Canceled; s: @_DS_Canceled),
    (i: DS_FailedSeek; s: @_DS_FailedSeek),
    (i: DS_NoOutFile; s: @_DS_NoOutFile),
    (i: DS_NoWrite; s: @_DS_NoWrite),
    (i: DS_EOCBadRead; s: @_DS_EOCBadRead),
    (i: DS_LOHBadRead; s: @_DS_LOHBadRead),
    (i: DS_CEHBadRead; s: @_DS_CEHBadRead),
    (i: DS_CEHWrongSig; s: @_DS_CEHWrongSig),
    (i: DS_CENameLen; s: @_DS_CENameLen),
    (i: DS_DataDesc; s: @_DS_DataDesc),
    (i: DS_CECommentLen; s: @_DS_CECommentLen),
    (i: DS_ErrorUnknown; s: @_DS_ErrorUnknown),
    (i: DS_NoUnattSpan; s: @_DS_NoUnattSpan),
    (i: DS_NoTempFile; s: @_DS_NoTempFile),
    (i: DS_LOHBadWrite; s: @_DS_LOHBadWrite),
    (i: DS_CEHBadWrite; s: @_DS_CEHBadWrite),
    (i: DS_EOCBadWrite; s: @_DS_EOCBadWrite),
    (i: DS_NoDiskSpace; s: @_DS_NoDiskSpace),
    (i: DS_InsertDisk; s: @_DS_InsertDisk),
    (i: DS_InsertVolume; s: @_DS_InsertVolume),
    (i: DS_InDrive; s: @_DS_InDrive),
    (i: DS_NoValidZip; s: @_DS_NoValidZip),
    (i: DS_AskDeleteFile; s: @_DS_AskDeleteFile),
    (i: DS_AskPrevFile; s: @_DS_AskPrevFile),
    (i: DS_InsertAVolume; s: @_DS_InsertAVolume),
    (i: DS_CopyCentral; s: @_DS_CopyCentral),
    (i: DS_NoDiskSpan; s: @_DS_NoDiskSpan),
    (i: DS_UnknownError; s: @_DS_UnknownError),
    (i: DS_NoRenamePart; s: @_DS_NoRenamePart),
    (i: DS_NotChangeable; s: @_DS_NotChangeable),
    (i: DS_Zip64FieldError; s: @_DS_Zip64FieldError),
    (i: DS_Unsupported; s: @_DS_Unsupported),
    (i: DS_ReadError; s: @_DS_ReadError),
    (i: DS_WriteError; s: @_DS_WriteError),
    (i: DS_FileError; s: @_DS_FileError),
    (i: DS_FileChanged; s: @_DS_FileChanged),
    (i: DS_SFXBadRead; s: @_DS_SFXBadRead),
    (i: DS_BadDrive; s: @_DS_BadDrive),
    (i: DS_LOHWrongName; s: @_DS_LOHWrongName),
    (i: DS_BadCRC; s: @_DS_BadCRC),
    (i: DS_NoEncrypt; s: @_DS_NoEncrypt),
    (i: DS_NoInStream; s: @_DS_NoInStream),
    (i: DS_NoOutStream; s: @_DS_NoOutStream),
    (i: DS_SeekError; s: @_DS_SeekError),
    (i: DS_DataCopy; s: @_DS_DataCopy),
    (i: DS_CopyError; s: @_DS_CopyError),
    (i: DS_TooManyParts; s: @_DS_TooManyParts),
    (i: DS_AnotherDisk; s: @_DS_AnotherDisk),
    (i: FM_Erase; s: @_FM_Erase),
    (i: FM_Confirm; s: @_FM_Confirm),
    (i: CD_CEHDataSize; s: @_CD_CEHDataSize),
    (i: CD_DuplFileName; s: @_CD_DuplFileName),
    (i: CD_NoProtected; s: @_CD_NoProtected),
    (i: CD_NoChangeDir; s: @_CD_NoChangeDir),
    (i: PR_Archive; s: @_PR_Archive),
    (i: PR_CopyZipFile; s: @_PR_CopyZipFile),
    (i: PR_SFX; s: @_PR_SFX),
    (i: PR_Header; s: @_PR_Header),
    (i: PR_Finish; s: @_PR_Finish),
    (i: PR_Copying; s: @_PR_Copying),
    (i: PR_CentrlDir; s: @_PR_CentrlDir),
    (i: PR_Checking; s: @_PR_Checking),
    (i: PR_Loading; s: @_PR_Loading),
    (i: PR_Joining; s: @_PR_Joining),
    (i: PR_Splitting; s: @_PR_Splitting),
    (i: PR_Writing; s: @_PR_Writing),
    (i: PR_PreCalc; s: @_PR_PreCalc),
    (i: DZ_Skipped; s: @_DZ_Skipped),
    (i: DZ_InUse; s: @_DZ_InUse),
    (i: DZ_Refused; s: @_DZ_Refused),
    (i: DZ_NoOpen; s: @_DZ_NoOpen),
    (i: DZ_NoFiles; s: @_DZ_NoFiles),
    (i: DZ_SizeChanged; s: @_DZ_SizeChanged),
    (i: TM_Erasing; s: @_TM_Erasing),
    (i: TM_Deleting; s: @_TM_Deleting),
    (i: TM_GetNewDisk; s: @_TM_GetNewDisk),
    (i: TM_SystemError; s: @_TM_SystemError),
    (i: TM_Trace; s: @_TM_Trace),
    (i: TM_Verbose; s: @_TM_Verbose),
    (i: DZ_RES_GOOD; s: @_DZ_RES_GOOD),
    (i: DZ_RES_CANCELLED; s: @_DZ_RES_CANCELLED),
    (i: DZ_RES_ABORT; s: @_DZ_RES_ABORT),
    (i: DZ_RES_CALLBACK; s: @_DZ_RES_CALLBACK),
    (i: DZ_RES_MEMORY; s: @_DZ_RES_MEMORY),
    (i: DZ_RES_STRUCT; s: @_DZ_RES_STRUCT),
    (i: DZ_RES_ERROR; s: @_DZ_RES_ERROR),
    (i: DZ_RES_PASSWORD_FAIL; s: @_DZ_RES_PASSWORD_FAIL),
    (i: DZ_RES_PASSWORD_CANCEL; s: @_DZ_RES_PASSWORD_CANCEL),
    (i: DZ_RES_INVAL_ZIP; s: @_DZ_RES_INVAL_ZIP),
    (i: DZ_RES_NO_CENTRAL; s: @_DZ_RES_NO_CENTRAL),
    (i: DZ_RES_ZIP_EOF; s: @_DZ_RES_ZIP_EOF),
    (i: DZ_RES_ZIP_END; s: @_DZ_RES_ZIP_END),
    (i: DZ_RES_ZIP_NOOPEN; s: @_DZ_RES_ZIP_NOOPEN),
    (i: DZ_RES_ZIP_MULTI; s: @_DZ_RES_ZIP_MULTI),
    (i: DZ_RES_NOT_FOUND; s: @_DZ_RES_NOT_FOUND),
    (i: DZ_RES_LOGIC_ERROR; s: @_DZ_RES_LOGIC_ERROR),
    (i: DZ_RES_NOTHING_TO_DO; s: @_DZ_RES_NOTHING_TO_DO),
    (i: DZ_RES_BAD_OPTIONS; s: @_DZ_RES_BAD_OPTIONS),
    (i: DZ_RES_TEMP_FAILED; s: @_DZ_RES_TEMP_FAILED),
    (i: DZ_RES_NO_FILE_OPEN; s: @_DZ_RES_NO_FILE_OPEN),
    (i: DZ_RES_ERROR_READ; s: @_DZ_RES_ERROR_READ),
    (i: DZ_RES_ERROR_CREATE; s: @_DZ_RES_ERROR_CREATE),
    (i: DZ_RES_ERROR_WRITE; s: @_DZ_RES_ERROR_WRITE),
    (i: DZ_RES_ERROR_SEEK; s: @_DZ_RES_ERROR_SEEK),
    (i: DZ_RES_EMPTY_ZIP; s: @_DZ_RES_EMPTY_ZIP),
    (i: DZ_RES_INVAL_NAME; s: @_DZ_RES_INVAL_NAME),
    (i: DZ_RES_GENERAL; s: @_DZ_RES_GENERAL),
    (i: DZ_RES_MISS; s: @_DZ_RES_MISS),
    (i: DZ_RES_WARNING; s: @_DZ_RES_WARNING),
    (i: DZ_ERR_ERROR_DELETE; s: @_DZ_ERR_ERROR_DELETE),
    (i: DZ_ERR_FATAL_IMPORT; s: @_DZ_ERR_FATAL_IMPORT),
    (i: DZ_ERR_SKIPPING; s: @_DZ_ERR_SKIPPING),
    (i: DZ_ERR_LOCKED; s: @_DZ_ERR_LOCKED),
    (i: DZ_ERR_DENIED; s: @_DZ_ERR_DENIED),
    (i: DZ_ERR_DUPNAME; s: @_DZ_ERR_DUPNAME));
 
{$ELSE}
 
const
 CompBlok: array [0..945] of Cardinal = (
  $0EC00409, $53550002, $00002D4C, $F0F00035, $FFF0F020, $FFF3F6FF, 
  $0232ABFD, $F706F5F2, $001178F0, $3000DF00, $00040910, $DF000B05, 
  $00530055, $64F0F33A, $0065FF00, $00610066, $6CFF0075, $08007400, 
  $D7005200, $3B50002E, $003B7400, $73DF0072, $4C001000, $006E003F, 
  $00416755, $65006161, $3B4EF0F3, $4575D500, $003F7200, $2302006C, 
  $3F467500, $02777400, $55450020, $00727700, $2000556F, $005F6900, 
  $440020D7, $354C005B, $F5006102, $74029362, $0065F0F3, $63D50078, 
  $4570003B, $00936900, $1ED5006E, $F32D0A8D, $00936EF0, $7A550020, 
  $F3700099, $009966F0, $5502696C, $6500BD73, $E76900B9, $00396502, 
  $00C72155, $71003B52, $57650041, $0152AA00, $6DF0F364, $936D003B, 
  $D71C7902, $6101B204, $003F7600, $01AA01EA, $2F01ECD2, $00BD0DC9, 
  $73005761, $9377C500, $00576402, $01DC0138, $4FE7004E, $12195400, 
  $00630184, $0A00A368, $1B58004D, $D9670198, $FF8E7202, $1B000002, 
  $0DB8008D, $52450598, $5F651033, $6801B200, $EB64025D, $01961402, 
  $290AF1F0, $00B94116, $11C401C0, $49001EE7, $01B612D1, $AB280020, 
  $00392500, $6FF0F329, $44730271, $013A0099, $60027520, $30016A01, 
  $2EA5004B, $73152207, $70111E10, $D0610293, $03E01423, $013605E8, 
  $00005725, $F1D4E900, $79011AF6, $09000D1F, $41425500, $12257300, 
  $13245B2B, $B7501DA7, $BF14C71D, $15F1F02D, $997200B9, $01C04200, 
  $A0048763, $080B8C03, $F0F31121, $005F5515, $7702D96B, $0154029B, 
  $0D0529F4, $E16B0033, $1801F402, $FA215E11, $000B9723, $70009343, 
  $019A1025, $26594A67, $7A2A65A8, $10812D73, $8A005755, $AB4113D8, 
  $20FF0006, $2D9A098E, $0235226E, $4A382514, $6C192833, $310C0043, 
  $1511008E, $0DE15A00, $1158105D, $127D6020, $11022522, $43104D09, 
  $09120136, $3D677B21, $11FA2007, $176C1134, $20013822, $11420184, 
  $111C01C0, $617201A8, $22111C02, $936613C8, $10295204, $1D451D47, 
  $619104D9, $11180039, $61201D56, $6E13F200, $98100300, $B603DA4D, 
  $EE037401, $C44DB411, $F1F01A4B, $001D8308, $C8008D0F, $5213D811, 
  $FF205D1C, $6E314220, $1B7202E7, $5D382810, $45101118, $7D4A2184, 
  $47174D2F, $10003304, $02B97221, $117E4364, $019813F2, $74116612, 
  $03EE107F, $C2465F61, $A0013A59, $019A1112, $25A60184, $95215BB0, 
  $C3424F40, $105D7212, $016A23D8, $5D2707E8, $97270922, $3F672E06, 
  $3B42602D, $09E601A8, $02916611, $672E515A, $2E02DB74, $48013E67, 
  $11A203EA, $B5770B8C, $6303EC52, $C6AA6C4D, $00815355, $61464F58, 
  $80185290, $01DC006D, $25A65DE6, $11A20DF2, $A2E05390, $877E2A65, 
  $F07D3A5D, $00331FF0, $003B0265, $9E3C116B, $C041AE11, $FE35E035, 
  $3D02285D, $039A3B12, $7452BF4C, $210C2005, $004166E5, $C414ED6E, 
  $57002101, $6E224382, $01D636BF, $07DE0D8E, $A0721112, $11EE0041, 
  $610A51A6, $6542753E, $2BF87F2A, $448D3A7D, $26000486, $0FE25900, 
  $80550312, $815E61E4, $8B4B004F, $80550700, $BA025D43, $76017A01, 
  $802A651A, $06008D2B, $37848055, $085481A0, $79017411, $9749826D, 
  $8A710918, $32D14195, $5462E307, $83DA0093, $84575008, $9D0187E6, 
  $65B29308, $8D8F842A, $429D3604, $4DD31898, $05E804D9, $07DC53C2, 
  $31002107, $0184728F, $13FC0152, $F2201118, $2A25A643, $5A213E15, 
  $143D6911, $DA4231F0, $240F6821, $4DFA635A, $110CF1F0, $2785910A, 
  $F000D59D, $90832E2B, $826F1118, $A56300B9, $38139E52, $C051A601, 
  $71404135, $CE01DC02, $6821D665, $2E05C071, $F9020121, $94CD7012, 
  $71688300, $1178515A, $62011926, $015004ED, $55C6657C, $AD702310, 
  $3B0951D0, $01EA70D1, $6222DF64, $6A214415, $3DC80801, $059833D8, 
  $F004E946, $7A436051, $7D00084B, $05C021E0, $EC009F26, $6C23A86D, 
  $119E1071, $152211EE, $876D672E, $B405B222, $59211173, $084D4200, 
  $BD9318BD, $61B612C5, $44776C00, $5805C031, $E0BDB601, $18CD070D, 
  $FB86819B, $E430239D, $BE51C661, $6F63E667, $73004B02, $11D25CA3, 
  $27A46DE8, $55D065FC, $20119E90, $BC113411, $22D76495, $000E11C4, 
  $035212F9, $018A51F0, $CDCF3714, $017AC9DC, $8B071412, $F0F0CD27, 
  $639D5326, $00A4999D, $11EEB124, $45781316, $B124013A, $DD5B05C0, 
  $DED9684A, $FB912A65, $3EDA94CD, $D5007DD1, $169D8602, $EE319E13, 
  $B2013647, $00ADE89D, $4BEA9B68, $41D213A0, $BD5E4BEC, $BD7EBD6E, 
  $68318C14, $2A659AEB, $96DD879A, $81E29CED, $92028111, $D4657C65, 
  $5C41AE31, $5B100925, $30E3C400, $6E013037, $3730E6C1, $5B899B52, 
  $235C2207, $C0E8BF5D, $00235E35, $65F4004B, $ED87A42A, $E52EF0F0, 
  $01360478, $AB6D3142, $16019A00, $0065CE13, $334A0083, $71C21166, 
  $C1567366, $113E51F0, $D4441126, $21016031, $FB58704D, $AB75F978, 
  $692C0000, $4178152A, $4D0671C2, $B1464194, $7E040186, $48FB7211, 
  $13D87467, $E3BE617E, $064A4366, $4A21C4C9, $64FD43AA, $FC57250A, 
  $B8019A80, $C0B720A5, $B0172A53, $58F15621, $FE70E550, $A8F9B4BD, 
  $72A3626B, $28221577, $119E33C2, $5373C956, $64E321C0, $66800DF2, 
  $ACF7E811, $38210025, $9E2112D1, $05002EC5, $220DC820, $347D66B5, 
  $38B5241D, $01B5DED3, $AC845F2E, $B0B1CA21, $1E1D0E21, $121D2E1D, 
  $9D0E193E, $2EF8E71D, $2122524B, $B6A4A58E, $2E17A265, $29668061, 
  $000D57AB, $64E31709, $B374A186, $F233C254, $1423021D, $2D8B2D7B, 
  $B04A2190, $2DBA2D3B, $1981403C, $B720AA6B, $9370C150, $B786A58E, 
  $3DDF041C, $D17564B3, $44AD8CA2, $DA417031, $C33A4033, $4B46635A, 
  $D1DEC5AA, $4517F12C, $C5AA28B0, $55BEE3E0, $54600F4E, $B134D449, 
  $1DF3702E, $70A55600, $32446B6C, $A1961003, $3D16C1C2, $3D23AD92, 
  $A4417036, $FB678151, $96E15230, $4AE344C3, $7051C0C5, $8A023354, 
  $E0FB4DA1, $6F801B67, $170110D5, $A19CD0B9, $A1D671A8, $E3B68576, 
  $F0143330, $E855F441, $ABB19AED, $5060E12D, $79A6887D, $B1240D84, 
  $5880711E, $66A122AB, $5FADAF08, $1A67906A, $671AD0A5, $4DB64D78, 
  $30B52082, $1D5B1D4B, $70E56DBD, $A24FC366, $A94342B3, $C2D3D4B2, 
  $ED3744C1, $13220100, $535D235D, $D6A1F66A, $C8C1C2A1, $05220261, 
  $855D7524, $BA6A535D, $AE595611, $D3004559, $5DE54130, $B1285CAB, 
  $4882C169, $830CB152, $A3770598, $00F18872, $BC80E049, $DC5DCC5D, 
  $2059565D, $0AB510B7, $518832D1, $856D616D, $62432FF4, $599691C6, 
  $B2518064, $815A63DE, $3106A156, $A5E0E340, $D00A2061, $6DB45D74, 
  $3B0C5B94, $B632A16D, $0000A7C1, $20C02F10, $4D5BB287, $B95C4500, 
  $7D954BD2, $7DC07AA5, $EA82B120, $D753E1D8, $10496E92, $082C0029, 
  $47DE801F, $E7437DB2, $3A210C30, $04B5A401, $B1220504, $1872B973, 
  $1CF166B5, $12330421, $A3643132, $0A73FCB6, $DDBA1049, $0240A530, 
  $04417441, $D0230C41, $6935C0B5, $061030EF, $54C19641, $23E31E53, 
  $C19680F7, $D600D1E2, $0CE344D1, $9E3DBA3D, $B6A55883, $007D0CE1, 
  $6DCE771C, $5DAE5D9E, $8DDE8DCE, $6D126D74, $12032400, $D49D205D, 
  $4C5D3C67, $405D5C5D, $A10A02E5, $0C721B54, $DE8746E1, $E02BEC71, 
  $37660139, $0AB52662, $98C36001, $9EB122B1, $001707C5, $98B22350, 
  $E20396F1, $104122B1, $01343142, $8546E358, $2BAD1B26, $158746AA, 
  $253A9B76, $3531C053, $8041B444, $2B0D01A5, $56B30280, $C0E14E3D, 
  $5AA1D897, $33704023, $3B480D9A, $ABC03504, $BF3DD10A, $41228092, 
  $C1C0A7CC, $31F67526, $F12C7B36, $0003040A, $B379D122, $0C01D212, 
  $FAA1DA21, $C19A8033, $95744122, $C33EC160, $936C13BE, $4A4D5A76, 
  $007D63B3, $54600759, $45153085, $B35410EB, $10EB4FC0, $97C0D1DE, 
  $70A3D00A, $A9766237, $44E15642, $8AD32089, $F121F10E, $60070AB2, 
  $B5466338, $66350073, $BD56BD46, $859EBD66, $C1B6C3B6, $BE02F32E, 
  $AD4B1E23, $AD6BAD5B, $2108AA7B, $36029B9C, $40DB79ED, $814A91AA, 
  $8D5875CC, $1628C308, $1C718C81, $822F0DE3, $5C787B6B, $D3160197, 
  $CEA53AE0, $8CA53271, $0CA3DA31, $356022E1, $342C0912, $73B3EACB, 
  $995C20CD, $047D269C, $34003633, $41305407, $421B3864, $CDEA1196, 
  $057A0020, $04C32E34, $216A01E8, $29DD6B12, $CE05B87A, $0A9D74DB, 
  $4DA007B8, $BD93B44A, $851E802B, $0C01D90A, $010CE83D, $C19E75E0, 
  $792ADDD0, $1041F378, $05A04427, $23E2B1D8, $D326356C, $85FC40E2, 
  $4136210C, $6598CDA2, $B76695C6, $B30E2800, $3560C320, $52200909, 
  $79842009, $82391809, $F77961F2, $E045AA62, $21C7F0CD, $8C16EB0F, 
  $20F38047, $E08F6D01, $FC4413EC, $0FF95A4B, $31CEE83D, $5B1D4D72, 
  $2518109A, $734405EA, $CD73B3CC, $E4834232, $F9880863, $77862718, 
  $8C400F2B, $A8B56E71, $19392103, $78D72002, $6D71A633, $41A882A5, 
  $C0CD8800, $C4B308AB, $24B5C69D, $F443B2D5, $FF622581, $F2356B92, 
  $2B2C35CC, $80836E80, $A332CD6A, $31C2210C, $8744B30C, $223EE12C, 
  $2BB62A2D, $060DFAED, $925B0818, $FC2A05AA, $820907E1, $72E2116E, 
  $01ECF085, $2A9D3445, $5A0DEBC3, $4D14621D, $4282B409, $368F6275, 
  $614AD32A, $45B0B172, $905B4A43, $2B202F48, $851E202F, $9064994E, 
  $810A1BA8, $13A87748, $A020F945, $E3E04493, $2E21F866, $78D1B241, 
  $350036B1, $3320052A, $15002005, $F23544D0, $2800314E, $1E43E441, 
  $AC659885, $5EDB46A7, $4063EAE9, $45B077F4, $F71A918C, $E712D3B2, 
  $010ADD44, $431D4BC4, $CE2C4DDD, $D5B17271, $452BE42D, $C90ADDC6, 
  $3D122D9F, $A92A220D, $33CEA072, $B1FA67D4, $1182A9C4, $2AC09F74, 
  $80860948, $0417ACDB, $E38A3027, $05302703, $0B30853F, $811E3027, 
  $A1E66198, $4A82D1C6, $3D550861, $31A420AF, $CDB49D9C, $F2000B00, 
  $03CA0ADD, $A4E0FF3D, $A051F831, $37AE0190, $792AE1B4, $19793DC8, 
  $00032AA0, $9C708B4A, $FC957CA1, $DAA1E691, $D5B804A1, $7913E512, 
  $D4454C32, $544D5667, $45DE4831, $495E4D76, $8834CB50, $82A56361, 
  $7C8134A0, $D9F30295, $1C43E04D, $48CC1A3D, $5D0E3DEB, $1D155214, 
  $63811888, $27217057, $F132A4AF, $85164108, $0CDC451C, $813A4481, 
  $9F2D7390, $388798E6, $86AD1A55, $34811800, $B2437011, $62C526D3, 
  $A0553855, $031408C1, $57365D58, $12B4E70E, $D6B378E5, $918E0AB1, 
  $7AD2C514, $A38AA203, $EB5E5738, $0ADDFA45, $694DFFD6, $4603AAD4, 
  $161482F7, $2DB12881, $2B6D74A7, $66957CC2, $6D5240D7, $71F06562, 
  $67D4916E, $A91EE1FC, $31C0A8B0, $B1B8A302, $4E029B47, $A077F097, 
  $9192C6C5, $937C5362, $CB102536, $1B107970, $848186D2, $64233679, 
  $67B61027, $0641B1B8, $51F8A29B, $7D31B1B8, $854E7338, $3BD929BA, 
  $4730776D, $096F708B, $54F10090, $913EE194, $64926D6C, $B541E08F, 
  $D9AC2A80, $55B22762, $AF2104B5, $08717E24, $17F2058C, $4709F720, 
  $6EC192F4, $25819261, $6EB0B111, $F35AAAE1, $0C92B175, $1D0B21C3, 
  $4A13EC80, $10F7FA91, $A13AC063, $90677341, $2382E174, $D1B22362, 
  $08406521, $F1B48D20, $25217D76, $B87DE430, $457DF4D5, $15B0F565, 
  $3DB8F447, $F579CDB2, $FB1B01B0, $3011F4C2, $D6D5B053, $EEA78651, 
  $E51208A5, $43B68166, $0C221D6D, $F08BDAC5, $5B172187, $6055609A, 
  $1E87F03D, $05360005, $D8212D01, $99D8D388, $B1F0FD34, $25B8F988, 
  $2157F82A, $85B07058, $7D57DABA, $6A245023, $72C1F481, $A1363491, 
  $1A10936F, $F9F88221, $4850E321, $9CB372F1, $64D36043, $66E07304, 
  $42174281, $F52263DA, $552EB178, $96E1E608, $17B1F0D1, $71D8B0A9, 
  $D124C3EE, $30B12800, $8E8532B7, $A017AC85, $7685DC9D, $B3E800E1, 
  $F1D25794, $813EF324, $DDE0ED6E, $140183F4, $A3D0FCA9, $8192ED08, 
  $ED02ABC2, $162089F0, $9AF594B9, $F0032E45, $00051A87, $9CC8A5B4, 
  $54A3CA43, $F2F574A3, $00214DA2, $8D691F01, $63B8E45D, $072A93DE, 
  $252EE512, $70232149, $050DB916, $0958F7AD, $24444091, $0D69E2D1, 
  $A96C689D, $0726D1B2, $B916408A, $F1C66166, $D1B40136, $556925B8, 
  $937E72A6, $42127F79, $92002101, $DB090ADD, $E03B9DC7, $E4564353, 
  $56810667, $618E08E5, $C3F60190, $C0701B41, $5AF1D271, $41400423, 
  $1117D1B2, $DE06AD2D, $21252E9B, $D73100DD );
{$ENDIF}
 
implementation
 
end.
