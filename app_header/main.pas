{_$Define UseJPG}

{compiling without _ before definition prevents from displaying JPEG images
 - it's because of error appearing in older Delphi versions}

unit MAIN;

interface

uses
  Windows, Messages, SysUtils, Forms, StdCtrls, ShellAPI, Menus, LiteSubs, Clipbrd,
  ImgList, ToolWin, ComCtrls, ExtCtrls, Controls, Classes, Dialogs, HTMLLite;

type
  TMainForm = class(TForm)
    Status: TStatusBar;
    ZIPDirList: TListBox;
    FindDialog: TFindDialog;
    HtmlPanel: TPanel;
    HTMLView: THtmlLite;
    ToolBar: TToolBar;
    LoadIndex: TToolButton;
    FindInOpened: TToolButton;
    ShowZipList: TToolButton;
    ToolBarSeparator: TToolButton;
    AboutButton: TToolButton;
    Splitter: TSplitter;
    PopupMenu: TPopupMenu;
    CopyMenu: TMenuItem;
    SelectMenu: TMenuItem;
    SaveMenu: TMenuItem;
    SaveTextDialog: TSaveDialog;
    MenuSeparator2: TMenuItem;
    EnabledButton: TImageList;
    DisabledButtons: TImageList;
    MenuSeparator1: TMenuItem;
    NewMenu: TMenuItem;
    CopyImgMenu: TMenuItem;
    SaveImgMenu: TMenuItem;
    SaveImgDialog: TSaveDialog;
    BackButton: TToolButton;
    ForwardButton: TToolButton;
    ToolButton3: TToolButton;
    ToolButton1: TToolButton;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HTMLViewHotSpotCovered(Sender: TObject; const SRC: string);
    procedure HTMLViewHotSpotClick(Sender: TObject; const SRC: string;
      var Handled: Boolean);
    procedure ZIPDirListDblClick(Sender: TObject);
    procedure HTMLViewImageRequest(Sender: TObject; const SRC: string;
      var Stream: TMemoryStream);
    procedure LoadIndexClick(Sender: TObject);
    procedure ShowZIPListClick(Sender: TObject);
    procedure FindInOpenedClick(Sender: TObject);
    procedure FindDialogFind(Sender: TObject);
    procedure AboutButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CopyMenuClick(Sender: TObject);
    procedure SelectMenuClick(Sender: TObject);
    procedure PopupMenuPopup(Sender: TObject);
    procedure SaveMenuClick(Sender: TObject);
    procedure NewMenuClick(Sender: TObject);
    procedure HTMLViewRightClick(Sender: TObject;
      Parameters: TRightClickParameters);
    procedure CopyImgMenuClick(Sender: TObject);
    procedure SaveImgMenuClick(Sender: TObject);
    procedure BackButtonClick(Sender: TObject);
    procedure ForwardButtonClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FoundObject: TImageObj;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  Param: String;
  DefaultTopic: String = '';
  sStatusURL: string = '';
  MyStream: TMemoryStream;
  WasPicture: boolean = false;

  {output (compressed with UPX) file size in bytes, remember to update it in production!}
  SfxSize: Integer = 422400;

implementation

{$R *.DFM}

uses
  About,
  Unzip, // compression methods with my modifications
  zipread // zip structure reader with my modifications
  {$IfDef UseJPG}, MyJPG;{$EndIf};

type
  bigArr = array[0..$FFFFFF]of char;

var
  AbsoluteInZIPPath: string = ''; // currently opened directory
  zipFName, // current file location in archive
  zipIndex // startup page location (index.htm or index.html)
  {$IfDef UseJPG},
  tmpPath // temporary directory path
  {$EndIf}: string;
  IDXList: TStringList; // useful list for storing name and location of every file in archive

{
Procedura konwertuj¹ca znaki z ISO-8859-2 na Windows-coœ_tam potrzebne aby poprawnie
wyœwietlaæ PLiterki pod Windows'em.

Parametry wejœciowe:
  bufPointer - wskaŸnik na bufor przechowywuj¹cy dane do konwersji,
  bufSize    - rozmiar bufora (zapis poza buforem w 90% spowoduje dziwne zachowanie programu,
               pad Window's itp.)
}
procedure ConvertPL(bufPoint: pointer; bufSize: integer);
var
  cnt1, cnt2: integer;
const
  CharSet: array[0..1, 0..5]of char = ((#177, #182, #188, #161, #166, #172),(#185, #156, #159, #165, #140, #143));
begin
  for cnt1 := 0 to bufSize - 1 do
    if bigArr(bufPoint^)[cnt1] > #126 then
      for cnt2 := 0 to 5 do
        If bigArr(bufPoint^)[cnt1] = CharSet[0, cnt2] then
          begin
            bigArr(bufPoint^)[cnt1] := CharSet[1, cnt2];
            Break;
          end;
end;

{
Funkcja poprawiaj¹ca adres po³o¿enia plików HTML tak ¿eby program z nim sobie radzi³ np.:
../../files/back.bmp na my/files/back.bmp, itp.

Parametry wejœciowe:
  inAddr   - adres wejœciowy
  absPath  - sciezka absolutna dostepu do pliku (przydatna przy konwersji
             ../../files na my/files)
Parametry wyjœciowe:
  result   - adres wejsciowy po korekcie
}
function CorrectAddres(inAddr, absPath: string): string;
begin
  if (inAddr <> '') and (inAddr[1] <> '#') and (ansilowercase(copy(inAddr, 1, 5)) <> 'http:') and (ansilowercase(copy(inAddr, 1, 7)) <> 'mailto:') then
  begin
    while pos('/', inAddr) <> 0 do
    begin
      insert('\', inAddr, pos('/', inAddr));
      delete(inAddr, pos('/', inAddr), 1);
    end;

    if (absPath <> '') and (copy(inAddr, 1, 3) = '..\') then
    begin
      absPath := '\' + copy(absPath, 1, length(absPath) - 1);
      while copy(inAddr, 1, 3) = '..\' do
      begin
        if StrRScan(pchar(absPath), '\') <> nil then
        absPath := copy(absPath, 1, length(absPath) - length(StrRScan(pchar(absPath), '\')));
        delete(inAddr, 1, 3);
      end;
    end;

    result := absPath + inAddr;
  end else result := inAddr;
end;

procedure showButtons;
begin
  if MainForm.ZipDirList.Items.Count > 0 then
    begin
      if MainForm.HtmlView.Tag = MainForm.HtmlView.History.Count-1 then
        MainForm.ForwardButton.Enabled:= false
      else
        MainForm.ForwardButton.Enabled:= true;
      if (MainForm.HtmlView.Tag = 0) and (WasPicture <> true) then
        MainForm.BackButton.Enabled:= false
      else
        MainForm.BackButton.Enabled:= true;
    end
  else
    begin
      MainForm.BackButton.Enabled:= false;
      MainForm.ForwardButton.Enabled:= false;
    end;
end;

procedure clearHistory;
var
  Counter: Integer;
begin
  If MainForm.HtmlView.Tag = MainForm.HtmlView.History.Count-1 Then Exit;
  For Counter:= MainForm.HtmlView.Tag+1 To MainForm.HtmlView.History.Count-1 Do
    MainForm.HTMLView.History.Delete(MainForm.HtmlView.History.Count-1);
end;

{
Funkcja rozpakuj¹co/pokazuj¹ca wybrany plik w komponencie THTMLite
Parametry wejœciowe:
  fName       - nazwa pliku który ma zostaæ wyœwietlony
  CorrectPath - czy przeprowadziæ korekcjê katalogu w archiwum
Parametry wyjœciowe:
  result      - true jeœli wszystko siê powiod³o i false jeœli nie
}

function showFile(fName: string; CorrectPath: boolean): boolean;
var
  MemStream: TMemoryStream;
  buf_size, cnt, tmpLI: LongInt;
  tmpStr, Topic: string;
begin
  result := false;

  MainForm.Status.SimpleText:= 'Trwa ³adowanie strony...';
  if fName <> '' then
    // Jeœli pierwszy znak fName = '#' to odnoœnik znajduje siê w pliku otwartym w THTMLLite,
    // nie trzeba go prze³adowywaæ, wystarczy do nie go skoczyæ :-)
    if fName[1] = '#' then
    begin
      MainForm.HTMLView.PositionTo(fName);
      result := true;
    end else begin
      screen.Cursor := crHourGlass;
      MainForm.HTMLView.enabled := false;
      MainForm.ZIPDirList.enabled := false;
      MainForm.BackButton.Enabled:= false;
      MainForm.ForwardButton.Enabled:= false;
      MainForm.LoadIndex.Enabled:= False;
      try
        // Zmiana fName na ma³e litery aby uproœciæ przeszukiwanie archiwum
        fName := ansilowercase(fName);

        // Sprawdzenie czy fName zawiera oprócz nazwy pliku nazwê tematu
        if pos('#', fName) <> 0 then
          begin
            Topic := copy(fName, pos('#', fName), length(fName));
            fName := copy(fName, 1, pos('#', fName) - 1);
          end
        else
          Topic := '';

        // z jakiegos powodu trzeba w D7 dokonac takiej konwersji (najprawdopodobniej wina HTMLLITE)
        fName:= StringReplace(fName, '/', '\', [rfReplaceAll]);

        // Przeszukanie index'u na obecnoœæ pliku do rozpakowania
        for cnt := 0 to IDXList.count - 1 do
          if ansilowercase(copy(IDXList[cnt], 1, pos('|', IDXList[cnt]) - 1)) = fName then
          begin
            // Korekcja aktualnego katalog w archiwum
            if not CorrectPath then
            begin
              if pos('\', fName) <> 0 then AbsoluteInZIPPath := copy(fName, 1, length(fName) - length(StrRScan(pchar(fName), '\')) + 1) else AbsoluteInZIPPath := '';
            end else if (AbsoluteInZIPPath = '') and (pos('\', fName) <> 0) then AbsoluteInZIPPath := copy(fName, 1, length(fName) - length(StrRScan(pchar(fName), '\')) + 1);
            // Utworzenie tymczasowego strumienia dla rozpakowanego pliku
            MemStream := TMemoryStream.create;

            // Pobranie informacji o tym ile zajmuje rozpakowany plik
            buf_size := 0;
            if unzipfiletomemory(pchar(zipFName), nil, buf_size, strtoint(copy(IDXList[cnt], pos('|', IDXList[cnt]) + 1, length(IDXList[cnt]))), 0, 0) = Zip_OK then
            begin
              // Ustawienie wielkoœci strumienia na rozmiar pliku do rozpakowania
              MemStream.SetSize(buf_size);

              // Rozpakowanie pliku do strumienia
              if unzipfiletomemory(pchar(zipFName), MemStream.Memory, buf_size, strtoint(copy(IDXList[cnt], pos('|', IDXList[cnt]) + 1, length(IDXList[cnt]))), 0, 0) = Zip_OK then
              begin
                tmpLI := buf_size;
                if tmpLI > 999 then tmpLI := 999;
                setlength(tmpStr, tmpLI);
                move(MemStream.Memory^, tmpStr[1], tmpLI);

                // Jeœli sdt. kodowania to ISO-8859-2, program przeprowadzi konwersjê
                if pos('ISO-8859-2', ansiuppercase(tmpStr)) <> 0 then ConvertPL(MemStream.Memory, buf_size);

                // Za³adowanie rozpakowanego pliku do THTMLLite
                MainForm.HTMLView.LoadFromStream(MemStream, '');
                MyStream.LoadFromStream(MemStream);

                // Podœwietl wybrany plik w ZIPDirList'cie
                if MainForm.ZIPDirList.Items.IndexOf(fName) <> -1 then
                  MainForm.ZIPDirList.ItemIndex := MainForm.ZIPDirList.Items.IndexOf(fName);

                // Jak Temat <> '' to skocz do tematu
                if Topic <> '' then
                  MainForm.HTMLView.PositionTo(Topic)
                  else
                  MainForm.HTMLView.Position := 0;
                // Zmiana tytu³u okienka na tytu³ wczytanego pliku
                if MainForm.HTMLView.DocumentTitle <> '' then MainForm.caption := MainForm.HTMLView.DocumentTitle + ' — Web Store' else MainForm.caption:= 'Brak tytu³u — Web Store';
                Application.Title:= MainForm.Caption;

                result := true;
              end;
            end;

            // Zwolnienie tymczasowego strumienia
            MemStream.free;
            break;
          end;
      finally
        showButtons;
        MainForm.ZIPDirList.enabled := MainForm.ZIPDirList.items.count <> 0;
        MainForm.LoadIndex.Enabled:= MainForm.ZIPDirList.items.count <> 0;
        MainForm.HTMLView.enabled := true;
        MainForm.FindInOpened.Enabled := MainForm.FindInOpened.Enabled or result;
        screen.Cursor := crDefault;
      end;
    end;
  MainForm.Status.SimpleText:= '';
end;

{
Funkcja rozpakuj¹co/³aduj¹ca wybran¹ grafikê do TMemoryStream (dzia³a podobnie do ShowFile)
Parametry wejœciowe:
  fName     - nazwa pliku który ma zostaæ za³adowany
  MemStream - strumieñ do którego ma zostaæ za³adowana grafika
Parametry wyjœciowe:
  result    - true jeœli wszystko siê powiod³o i false jeœli nie
}
function loadGfxFile(fName: string; var MemStream: TMemoryStream): boolean;
var
  buf_size, cnt: LongInt;
begin
  result := false;

  // Zmiana fName na ma³e litery aby uproœciæ przeszukiwanie archiwum
  fName := ansilowercase(fName);

  // Przeszukanie index'u na obecnoœæ pliku do rozpakowania
  for cnt := 0 to IDXList.count - 1 do
    if ansilowercase(copy(IDXList[cnt], 1, pos('|', IDXList[cnt]) - 1)) = fName then
    begin
      // Utworzenie strumienia dla rozpakowanego pliku
      MemStream := TMemoryStream.create;

      // Pobranie informacji o tym ile zajmuje rozpakowany plik
      buf_size := 0;
      if unzipfiletomemory(pchar(zipFName), nil, buf_size, strtoint(copy(IDXList[cnt], pos('|', IDXList[cnt]) + 1, length(IDXList[cnt]))), 0, 0) = Zip_OK then
      begin
        // Ustawienie wielkoœci strumienia na rozmiar pliku do rozpakowania
        MemStream.SetSize(buf_size);

        // Rozpakowanie pliku do strumienia
        if unzipfiletomemory(pchar(zipFName), MemStream.Memory, buf_size, strtoint(copy(IDXList[cnt], pos('|', IDXList[cnt]) + 1, length(IDXList[cnt]))), 0, 0) = Zip_OK then result := true;
      end;

      // Zwolnienie strumienia jeœli wyst¹pi³ b³¹d
      if not result then MemStream.free;
    break;
  end;
end;

procedure TMainForm.FormActivate(Sender: TObject);
var
  ZIPRec: tPackRec;
  res, LBHSB: integer;
  lpSize: tSize;
begin
  // Nazwa pliku z archiwum powinna wskazywaæ na nasz¹ aplikacjê (paramstr(0)) jeœli archiwum
  // znajduje siê na jego koñcu
  zipFName := paramstr(0);

  // Tworzenie listy index'u.
  IDXList := TStringList.create;

  // Zmienna która bêdzie przechowywaæ wartoœæ o któr¹ bêdzie mo¿na przesuwaæ ListBox'a
  // wyœwietlaj¹cego Listê plików znajduj¹cych siê w archiwum w poziomie (niestety
  // ListBox'y nie umo¿liwiaj¹ automatyczne dzia³anie poziomego paska przesuwu wiêc trzeba
  // to zrobiæ rêcznie)
  LBHSB := 0;
  zipIndex := '';

  // Odczyt zawartoœci archiwum i za³adowanie listy plików HTML do ZIPDirList'y
  if fileexists(zipFName) then
  try
    res := GetFirstInZip(pchar(zipFName),  SFXSize, ZIPRec);
    while res = zip_ok do
    begin
      res := pos('.htm', ansilowercase(ZIPRec.FileName));
      if (res<>0) and ((res = length(ansilowercase(ZIPRec.FileName))-3) or (res = length(ansilowercase(ZIPRec.FileName))-4)) then
      begin
        ZIPDirList.items.add(ZIPRec.FileName);
        GetTextExtentPoint(ZIPDirList.canvas.handle, ZIPRec.FileName, length(ZIPRec.FileName), lpSize);
        inc(lpSize.cx, 5);
        if lpSize.cx > LBHSB then LBHSB := lpSize.cx;

        if ((zipIndex = '') or ((pos('\', zipIndex) <> 0) and (pos('\', ZIPRec.FileName) = 0))) and (pos('index', ansilowercase(ZIPRec.FileName)) <> 0) then zipIndex := ZIPRec.FileName;
      end;
      IDXList.add(string(ZIPRec.FileName) + '|' + inttostr(ZIPRec.headeroffset));
      res := GetNextInZip(ZIPRec)
    end;
  finally
    closezipfile(ZIPRec);

    // Gdy ZIPDirList'a jest pusta to zostanie wy³¹czona
    ZIPDirList.enabled := ZIPDirList.items.count <> 0;
    BackButton.Enabled:= ZIPDirList.items.count <> 0;
    ForwardButton.Enabled:= ZIPDirList.items.count <> 0;
    LoadIndex.Enabled:= ZIPDirList.items.count <> 0;
    
    // Posortowanie zawartoœci ZIPDirList'y
    ZIPDirList.sorted := true;

    // Ustawienie poziomego paska przesuwu ZIPDirList'y
    sendmessage(ZIPDirList.handle, LB_SETHORIZONTALEXTENT, LBHSB, 0);
  end;

  // Próba odczytu pliku z index'em
  If (DefaultTopic = '') and (Param = '') Then
    Begin
     if ShowFile('index.htm', false) then zipIndex := 'index.htm' else
    if ShowFile('index.html', false) then zipIndex := 'index.html' else
      if zipIndex <> '' then if not ShowFile(zipIndex, false) then zipIndex := '';

     if zipindex <> '' Then
      begin
       htmlview.history.Add(zipindex);
       htmlview.tag:= 0;
      end;
    End;

  If Param <> '' Then
   Begin
   If ShowFile(Param, False) Then
    Begin
     htmlview.tag:= 0;
     htmlview.history.add(param);
     DefaultTopic:= '';
    End;
    Param:= '';
   End;

  If DefaultTopic <> '' Then
   Begin
   If ShowFile(DefaultTopic, False) Then
    Begin
     htmlview.tag:= 0;
     htmlview.history.add(defaulttopic);
     DefaultTopic:= '';
    End;
   End;

  LoadIndex.enabled := zipIndex <> '';
  OnActivate := nil;
  showButtons;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.Width:= Screen.Width-70;
  MainForm.Height:= Screen.Height-70;
  ZipDirList.Visible:= False;
  Splitter.Visible:= False;
  MyStream:= TMemoryStream.Create;
  Param:= ParamStr(1);
end;

procedure TMainForm.HTMLViewHotSpotCovered(Sender: TObject;
  const SRC: string);
begin
  Status.SimpleText := CorrectAddres(SRC, AbsoluteInZIPPath);
  if SRC <> '' then
    sStatusURL:= CorrectAddres(SRC, AbsoluteInZIPPath);
end;

procedure TMainForm.HTMLViewHotSpotClick(Sender: TObject; const SRC: string;
  var Handled: Boolean);
  var TmpStr,s,AbsoluteInZipPath2: String;
  AddToHistory: Boolean;
begin
   AddToHistory:= True;
   AbsoluteInZipPath2:= AbsoluteInZIPPath;
  // Jak klikniêto na linku, skocz do odpowiedniego pliku/tematu

  // Sprawdzamy czy odsy³acz prowadzi bezpoœrednio do obrazka, jeœli
  // tak to tworzymy bufor, a nastêpnie stronê tymczasow¹ z odwo³aniem
  // do pliku. Znak '###' w tytule oznacza, ¿e ta strona ma zablokowane menu

  if (AnsiPos('.gif', LowerCase(src)) <> 0) or (AnsiPos('.jpg', LowerCase(src)) <> 0) or (AnsiPos('.jpeg', LowerCase(src)) <> 0) or (AnsiPos('.jpe', LowerCase(src)) <> 0) or (AnsiPos('.bmp', LowerCase(src)) <> 0) Then
   begin
    tmpstr:= '<html><title>###</title><img src="'+src+'" alt="'+extractfilename(src)+'"></html>';
    HtmlView.LoadFromString(tmpstr, '');
    MainForm.Caption:= extractfilename(src)+' — Web Store';
    AddToHistory:= False;
    WasPicture:= true;
   end else

    begin
  if not ShowFile(CorrectAddres(SRC, AbsoluteInZIPPath), true) then
   Begin
    AddToHistory:= False;
    If MessageBox(Handle, PChar('File not found:'#13#13+CorrectAddres(SRC, AbsoluteInZIPPath)+#13#13+'Do you want to try call this addres by your system environment?'), 'File not found', MB_YESNO or MB_ICONWARNING or MB_DEFBUTTON2) = IDYES Then
      ShellExecute(Handle, nil, PChar(CorrectAddres(SRC, AbsoluteInZIPPath)), '', '', Sw_ShowNormal);
   End;
  End;

  If AddToHistory Then
   Begin
    HtmlView.Tag:= HtmlView.Tag+1;
    s:= CorrectAddres(SRC, AbsoluteInZipPath2);
    HtmlView.History.Insert(HtmlView.Tag, s);
   End;

  ClearHistory;
  showButtons;
  Handled := true
end;

procedure TMainForm.ZIPDirListDblClick(Sender: TObject);
begin
  ShowFile(ZIPDirList.items[ZIPDirList.ItemIndex], false);
  HtmlView.Tag:= HtmlView.Tag+1;
  HtmlView.History.Insert(HtmlView.Tag, ZIPDirList.items[ZIPDirList.ItemIndex]);
  ClearHistory;
  showButtons;
end;

procedure TMainForm.HTMLViewImageRequest(Sender: TObject; const SRC: string; var Stream: TMemoryStream);
begin
  Status.SimpleText:= 'Loading image '+SRC+'...';
  LoadGfxFile(CorrectAddres(SRC, AbsoluteInZIPPath), Stream);
  Status.SimpleText:= '';
end;

procedure TMainForm.LoadIndexClick(Sender: TObject);
begin
  ShowFile(zipIndex, false);
  HtmlView.Tag:= HtmlView.Tag+1;
  HtmlView.History.Insert(HtmlView.Tag, zipindex);
  ClearHistory;
  showButtons;
end;

procedure TMainForm.ShowZIPListClick(Sender: TObject);
begin
  if Not ZipDirList.Visible then
    begin
      Splitter.Visible:= True;
      ZIPDirList.Visible:= True;
      ShowZipList.Down:= True;
    end
  else
    begin
      Splitter.Visible:= False;
      ZIPDirList.Visible:= False;
      ShowZipList.Down:= False;
    end;
end;

procedure TMainForm.FindInOpenedClick(Sender: TObject);
begin
  FindDialog.Execute;
end;

procedure TMainForm.FindDialogFind(Sender: TObject);
begin
  if not HTMLView.Find(FindDialog.findtext, frMatchCase in FindDialog.options) then messagebox(FindDialog.handle, 'Searching is completed', 'Find', MB_ICONINFORMATION);
end;

procedure TMainForm.AboutButtonClick(Sender: TObject);
begin
  Application.CreateForm(TAboutForm, AboutForm);
  AboutForm.ShowModal;
  AboutForm.Free;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MyStream.Free;
  IDXList.free;
  Action:= caFree;
end;

procedure TMainForm.CopyMenuClick(Sender: TObject);
begin
  HtmlView.CopyToClipboard;
end;

procedure TMainForm.SelectMenuClick(Sender: TObject);
begin
  HtmlView.SelectAll;
end;

procedure TMainForm.PopupMenuPopup(Sender: TObject);
begin
  If HtmlView.SelLength = 0 Then CopyMenu.Enabled:= False Else CopyMenu.Enabled:= True;
  If Status.SimpleText = '' Then
    Begin
      NewMenu.Enabled:= False;
      MenuSeparator1.Enabled:= False;
    End
  Else
    Begin
      NewMenu.Enabled:= True;
      MenuSeparator1.Enabled:= True;
    End;

  If (ZipDirList.ItemIndex = -1) or (HtmlView.DocumentTitle = '###') Then
    Begin
      SelectMenu.Enabled:= False;
      SaveMenu.Enabled:= False;
    End
  Else
    Begin
      SelectMenu.Enabled:= True;
      SaveMenu.Enabled:= True;
    End;
end;

procedure TMainForm.SaveMenuClick(Sender: TObject);
var
  s: string;
begin
  s:= StringReplace(HtmlView.DocumentTitle, '"', '', [rfReplaceAll]);
  s:= StringReplace(s, ':', '', [rfReplaceAll]);
  s:= StringReplace(s, ';', '', [rfReplaceAll]);
  s:= StringReplace(s, '?', '', [rfReplaceAll]);
  s:= StringReplace(s, '*', '', [rfReplaceAll]);
  s:= StringReplace(s, '/', '', [rfReplaceAll]);
  s:= StringReplace(s, '\', '', [rfReplaceAll]);
  s:= StringReplace(s, '<', '', [rfReplaceAll]);
  s:= StringReplace(s, '>', '', [rfReplaceAll]);
  SaveTextDialog.FileName:= s+'.html';
  If SaveTextDialog.Execute Then
    MyStream.SaveToFile(SaveTextDialog.FileName);
end;

procedure TMainForm.NewMenuClick(Sender: TObject);
begin
  WinExec(PAnsiChar(ParamStr(0)+' "'+sStatusURL+'"'), SW_SHOWNORMAL);
end;

procedure TMainForm.HTMLViewRightClick(Sender: TObject; Parameters: TRightClickParameters);
begin
  with Parameters do
    begin
      FoundObject := Image;
      CopyImgMenu.Enabled := (FoundObject <> Nil) and (FoundObject.Bitmap <> Nil);
      SaveImgMenu.Enabled := (FoundObject <> Nil) and (FoundObject.Bitmap <> Nil);
    end;
end;

procedure TMainForm.CopyImgMenuClick(Sender: TObject);
begin
  Clipboard.Assign(FoundObject.Bitmap);
end;

procedure TMainForm.SaveImgMenuClick(Sender: TObject);
begin
  SaveImgDialog.FileName:= Copy(FoundObject.Source, 0, AnsiPos('.', FoundObject.Source)-1)+'.bmp';
  If SaveImgDialog.Execute Then
    FoundObject.Bitmap.SaveToFile(SaveImgDialog.FileName);
end;

procedure TMainForm.BackButtonClick(Sender: TObject);
begin
  If HtmlView.Tag > -1 Then
    begin
      if waspicture Then
        begin
          ShowFile(HtmlView.History.Strings[HtmlView.Tag], False);
          WasPicture:= false;
          showButtons;
        end
      else
        begin
          If htmlview.tag = 0 then exit;
          HtmlView.Tag:= HtmlView.Tag-1;
          ShowFile(HtmlView.History.Strings[HtmlView.Tag], false);
        end;
    end;
end;

procedure TMainForm.ForwardButtonClick(Sender: TObject);
begin
  If (HtmlView.Tag = HtmlView.History.Count-1) or (htmlview.tag = -1) Then Exit;
  HtmlView.Tag:= HtmlView.Tag+1;
  ShowFile(HtmlView.History.Strings[HtmlView.Tag], False);
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Case Key Of
    VK_F12: AboutButton.Click;
    VK_BACK: If BackButton.Enabled Then BackButton.Click;
    VK_RIGHT: If (ssAlt in Shift) Then If ForwardButton.Enabled Then ForwardButton.Click;
    VK_HOME: If (ssAlt in Shift) Then If LoadINdex.Enabled Then LoadIndex.Click;
    Word('F'): If FindInOpened.Enabled Then FindInOpened.Click;
    Word('L'): If (ssCtrl in Shift) Then ShowZipList.Click;
  End;
end;

end.
