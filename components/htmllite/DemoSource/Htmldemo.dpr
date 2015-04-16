program Htmldemo;
{A program to demonstrate the ThtmlLite component}

uses
  Forms,
  demounit in 'demounit.pas' {Form1},
  LiteAbt in 'LiteAbt.pas' {AboutBox},
  ImgForm in 'ImgForm.pas' {ImageForm},
  FontDlgL in 'FontDlgL.pas' {FontForm},
  Submit in 'Submit.pas' {SubmitForm};

{$R htmldemo.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TSubmitForm, SubmitForm);
  Application.Run;
end.
