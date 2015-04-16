unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls, ShlObj, ZipMstr19, jpeg;

type
  TMainForm = class(TForm)
    NoteBook: TNotebook;
    ButtonsPanel: TPanel;
    Bevel2: TBevel;
    LogoPanel: TPanel;
    Logo: TImage;
    CloseButton: TButton;
    BackButton: TButton;
    WelcomeCaption: TLabel;
    WelcomeCaption2: TLabel;
    ForwardButton: TButton;
    ChoiceCaption: TLabel;
    CompleteBox: TRadioButton;
    ZipBox: TRadioButton;
    SourceCaption: TLabel;
    SourceName: TEdit;
    SourceNameCaption: TLabel;
    BrowseButton: TButton;
    OpenZipDialog: TOpenDialog;
    DestinationCaption: TLabel;
    Destination: TLabel;
    DestinationName: TEdit;
    BrowseDestinationButton: TButton;
    SaveExeDialog: TSaveDialog;
    SummaryCaption: TLabel;
    ProgressCaption: TLabel;
    ProgressBar: TProgressBar;
    Progress: TLabel;
    FinishCaption: TLabel;
    ExecuteButton: TButton;
    NewButton: TButton;
    ExploreDestButton: TButton;
    Button1: TButton;
    ErrorCaption: TLabel;
    AboutButton: TButton;
    DirectoryCaption: TLabel;
    Directory: TLabel;
    DirectoryName: TEdit;
    DirectoryButton: TButton;
    Button3: TButton;
    TitlePanel: TPanel;
    Bevel1: TBevel;
    TitleCaption: TLabel;
    IconImage: TImage;
    ZipMaster: TZipMaster19;
    procedure CloseButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ForwardButtonClick(Sender: TObject);
    procedure BrowseButtonClick(Sender: TObject);
    procedure BrowseDestinationButtonClick(Sender: TObject);
    procedure ExecuteButtonClick(Sender: TObject);
    procedure NewButtonClick(Sender: TObject);
    procedure ExploreDestButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure AboutButtonClick(Sender: TObject);
    procedure DirectoryButtonClick(Sender: TObject);
    procedure ZipMasterProgress(Sender: TObject;
      details: TZMProgressDetails);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  Tab: Byte = 0;
  Directoria : String;
  Title: String = 'Select path where your web content is stored';
  FBrowseInfo: TBrowseInfo;

implementation

uses About;

{$R *.DFM}

function BrowseCallback(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
begin
  Result := 0;
end;

Function Execute ( Form : TForm ): String;
var
  Buffer: PChar;
  List: PItemIDList;
begin
  GetMem(Buffer, MAX_PATH);
  with FBrowseInfo do
    begin
      hwndOwner:= Form.Handle;
      pidlRoot:= nil;
      lpszTitle:= PChar( Title );
      ulFlags:= BIF_RETURNONLYFSDIRS;
      lpfn:= BrowseCallback;
      lParam:= Longint( 0 );
    end;
  list := ShBrowseForFolder( FBrowseInfo );
  if not ( List = nil ) then
    begin
      SHGetPathFromIDList( List , Buffer );
      Directoria := Buffer;
    end;
  FreeMem(Buffer);
  Result:= Directoria;
end;

function DirExists(Name: string): Boolean;
{$IFDEF WIN32}
var
  Code: Integer;
begin
  Code := GetFileAttributes(PChar(Name));
  Result := (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;
{$ELSE}
var
  SR: TSearchRec;
begin
  if Name[Length(Name)] = '\' then Dec(Name[0]);
  if (Length(Name) = 2) and (Name[2] = ':') then
    Name := Name + '\*.*';
  Result := FindFirst(Name, faDirectory, SR) = 0;
  Result := Result and (SR.Attr and faDirectory <> 0);
end;
{$ENDIF}

Function GetTempDir: String;
var
  Dir: Array[0..255] Of Char;
  Size: Integer;
begin
  Size:= SizeOf(Dir) - 1;
  GetTempPath(Size, Dir);
  Result:= Dir;
end;

function Slash(Value: String): String;
begin
  if (value='') then result:='' else
  begin
    if (value[length(value)]<>'\') then result:=value+'\' else result:=value;
  end;
end;

procedure PauseMe;
var
  dtNow: TDateTime;
begin
  dtNow := Now;
  repeat
    Application.ProcessMessages;
  until dtNow + 0.1 / SecsPerDay < Now;
end;

procedure TMainForm.CloseButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Application.Title:= MainForm.Caption;
  if FileExists(ChangeFileExt(ParamStr(0), '.hdr')) then
  begin
    Notebook.ActivePage:= 'Welcome';
    TitleCaption.Caption:= 'Web Store Wizard - Welcome';
  end
  else
  begin
    TitleCaption.Caption:= 'Critical error';
    Notebook.ActivePage:= 'Error';
    ForwardButton.Enabled:= False;
    CloseButton.Caption:= 'Close';
    CloseButton.Tag:= 1;
  end;
end;

procedure TMainForm.ForwardButtonClick(Sender: TObject);
var
  File_Dest, File_Src: File of Byte;
  bReaded, bWrited: Integer;
  Buffer: array[1..2048] of Char;
begin
  if Sender = ForwardButton Then
  begin
    Tab:= Tab+1;
  end
  else
  begin
    Tab:= Tab-1;
  end;

  if Tab = 0 then
  begin
    BackButton.Enabled:= False;
    ForwardButton.SetFocus;
  end
  else
    BackButton.Enabled:= True;

  Case Tab Of
  0: Begin
      TitleCaption.Caption:= 'Web Store Wizard - Welcome';
      Notebook.ActivePage:= 'Welcome';
     End;
  1: Begin
      TitleCaption.Caption:= 'What do you want to do?';
      Notebook.ActivePage:= 'Choice';
     End;
  2: Begin
     If ZipBox.Checked Then
       Begin
        TitleCaption.Caption:= 'Select source file';
        Notebook.ActivePage:= 'Source';
       End
      Else
       Begin
         TitleCaption.Caption:= 'Select source directory';
         NoteBook.ActivePage:= 'Directory';
       End;
     End;
  3: Begin
      If ZipBox.Checked Then If Not FileExists(SourceName.Text) Then
       Begin
        MessageBox(MainForm.Handle, 'Make sure the file exists', 'File not found', MB_OK or MB_ICONINFORMATION);
        Tab:= Tab-1;
       End Else
        Begin
         TitleCaption.Caption:= 'Select destination file';
         NoteBook.ActivePage:= 'Destination';
        End;

      If CompleteBox.Checked Then If Not DirExists(DirectoryName.Text) Then
       Begin
        MessageBox(MainForm.Handle, 'Select existing directory', 'Directory not exists', MB_OK or MB_ICONINFORMATION);
        Tab:= Tab-1;
       End Else
        Begin
           TitleCaption.Caption:= 'Select destination file';
           NoteBook.ActivePage:= 'Destination';
        End;
     End;
  4: Begin
      If DestinationName.Text = '' Then
       Begin
        MessageBox(MainForm.Handle, 'Select destination file name', 'Missing file name', MB_OK or MB_ICONINFORMATION);
        Tab:= Tab-1;
       End
      Else
       Begin
        TitleCaption.Caption:= 'Ready';
        NoteBook.ActivePage:= 'Summary';
       End;
     End;
  5: Begin

      TitleCaption.Caption:= 'Operation in progress';

      If ZipBox.Checked Then
       Begin
        NoteBook.ActivePage:= 'Progress';
        BackButton.Enabled:= False;
        ForwardButton.Enabled:= False;
        CloseButton.Enabled:= False;
        AboutButton.Enabled:= False;

        Progress.Caption:= 'Creating header file...';
        ProgressBar.Position:= 0;
        PauseMe;
        AssignFile(File_src, ChangeFileExt(ParamStr(0), '.hdr'));
        Reset(File_src);
        AssignFile(File_dest, DestinationName.Text);
        ReWrite(File_dest);
        ProgressBar.Max:= FileSize(File_src);
        Repeat
         BlockRead(File_src, Buffer, SizeOf(Buffer), bReaded);
         BlockWrite(File_dest, Buffer, bReaded, bWrited);
         ProgressBar.StepBy(bReaded);
        Until (bReaded = 0) or (bWrited <> bReaded);
        CloseFile(File_src);

        Progress.Caption:= 'Merging archive...';
        ProgressBar.Position:= 0;
        PauseMe;
        AssignFile(File_src, SourceName.Text);
        Reset(File_src);
        ProgressBar.Max:= FileSize(File_src);
        Repeat
         BlockRead(File_src, Buffer, SizeOf(Buffer), bReaded);
         BlockWrite(File_dest, Buffer, bReaded, bWrited);
         ProgressBar.StepBy(bReaded);
        Until (bReaded = 0) or (bWrited <> bReaded);
        CloseFile(File_src);
        CloseFile(File_dest);

        CloseButton.Enabled:= True;
        AboutButton.Enabled:= True;
        Notebook.ActivePage:= 'Finish';
       End;

      If CompleteBox.Checked Then
       Begin
        NoteBook.ActivePage:= 'Progress';
        BackButton.Enabled:= False;
        ForwardButton.Enabled:= False;
        CloseButton.Enabled:= False;
        AboutButton.Enabled:= False;

        Progress.Caption:= 'Preparing files...';
        ProgressBar.Position:= 0;
        PauseMe;

        ZipMaster.ZipFilename:= Slash(GetTempDir)+'ws.tmp';
        ZipMaster.ZipComment:= 'This archive was created using Web Store Wizard. For more information visit authors home page at http://toborek.info';
        ChDir(DirectoryName.Text);
        ZipMaster.FSpecArgs.Add('*.*');
        ZipMaster.Add;

        Progress.Caption:= 'Creating header file...';
        ProgressBar.Position:= 0;
        PauseMe;
        AssignFile(File_src, ChangeFileExt(ParamStr(0), '.hdr'));
        Reset(File_src);
        AssignFile(File_dest, DestinationName.Text);
        ReWrite(File_dest);
        ProgressBar.Max:= FileSize(File_src);
        Repeat
         BlockRead(File_src, Buffer, SizeOf(Buffer), bReaded);
         BlockWrite(File_dest, Buffer, bReaded, bWrited);
         ProgressBar.StepBy(bReaded);
        Until (bReaded = 0) or (bWrited <> bReaded);
        CloseFile(File_src);

        Progress.Caption:= 'Merging archive...';
        ProgressBar.Position:= 0;
        PauseMe;
        AssignFile(File_src, Slash(GetTempDir)+'ws.tmp');
        Reset(File_src);
        ProgressBar.Max:= FileSize(File_src);
        Repeat
         BlockRead(File_src, Buffer, SizeOf(Buffer), bReaded);
         BlockWrite(File_dest, Buffer, bReaded, bWrited);
         ProgressBar.StepBy(bReaded);
        Until (bReaded = 0) or (bWrited <> bReaded);
        CloseFile(File_src);
        Erase(File_src);
        CloseFile(File_dest);

        CloseButton.Enabled:= True;
        AboutButton.Enabled:= True;
        Notebook.ActivePage:= 'Finish';
       End;
        TitleCaption.Caption:= 'Done';
        CloseButton.Caption:= 'Exit';
        CloseButton.Tag:= 1;
     End;
 End;
 end;

procedure TMainForm.BrowseButtonClick(Sender: TObject);
begin
  if OpenZipDialog.Execute then
    SourceName.Text:= OpenZipDialog.FileName;
end;

procedure TMainForm.BrowseDestinationButtonClick(Sender: TObject);
begin
  if SaveExeDialog.Execute then
    DestinationName.Text:= SaveExeDialog.FileName;
end;

procedure TMainForm.ExecuteButtonClick(Sender: TObject);
begin
  WinExec(PChar(DestinationName.Text), Sw_ShowNormal);
end;

procedure TMainForm.NewButtonClick(Sender: TObject);
begin
  TitleCaption.Caption:= 'Web Store Wizard - Welcome';
  Notebook.ActivePage:= 'Welcome';
  ForwardButton.Enabled:= True;
  CloseButton.Caption:= 'Cancel';
  CloseButton.Tag:= 0;
  Tab:= 0;
  DestinationName.Text:= '';
  SourceName.Text:= '';
  DirectoryName.Text:= '';
  ForwardButton.SetFocus;
end;

procedure TMainForm.ExploreDestButtonClick(Sender: TObject);
begin
  WinExec('EXPLORER.EXE', Sw_ShowNormal);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not CloseButton.Enabled then
    CanClose:= False
  else
    if CloseButton.Tag = 0 then
      if MessageBox(MainForm.Handle, 'Are you sure you want to quit?', 'Quit', MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) = IDNO then
        CanClose:= False
      else
        CanClose:= True;
end;

procedure TMainForm.AboutButtonClick(Sender: TObject);
begin
  Application.CreateForm(TAboutForm, AboutForm);
  AboutForm.ShowModal;
  AboutForm.Free;
end;

procedure TMainForm.DirectoryButtonClick(Sender: TObject);
begin
  DirectoryName.Text:= Execute(Self);
end;

procedure TMainForm.ZipMasterProgress(Sender: TObject;
  details: TZMProgressDetails);
begin
   if details.Order = NewFile then
   begin
      Progress.Caption:= 'Compressing file: ' + details.ItemName+ '...';
      with ProgressBar do
      begin
         min:=1;
         max:=10;
         step:=1;
         position:=min;

         if (details.ItemSize div 32768) > 1 then
            Max := details.ItemSize div 32768
         else
            Max := 1;
         if (details.ItemSize < 32768) then
            StepIt;
      end;
   end;

   if details.Order = ProgressUpdate then
   begin
      with ProgressBar do
         if position < Max then
            StepIt;
   end;

   if details.Order = EndOfBatch then
   begin
      Progress.Caption:= '';
      with ProgressBar do
      begin
         min:=1;
         max:=10;
         step:=1;
         position:=min;
      end;
   end;
   Application.ProcessMessages;
end;

end.
