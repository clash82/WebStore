{
  Web Store
  (c) 2002-2015 Rafa³ Toborek
  http://toborek.info
  http://github.com/clash82/WebStore
}

program HEADER;

uses
  Forms,
  MAIN in 'MAIN.PAS' {MainForm},
  ABOUT in 'ABOUT.PAS' {AboutForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Web Store';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
