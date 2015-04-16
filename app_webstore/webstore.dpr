{
  Web Store Wizard
  (c) 2002-2015 Rafa³ Toborek
  http://toborek.info
  http://github.com/clash82/WebStore
}

program WebStore;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  About in 'About.pas' {AboutForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
