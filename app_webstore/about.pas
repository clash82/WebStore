unit About;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, ShellAPI, jpeg;

type
  TAboutForm = class(TForm)
    CloseButton: TButton;
    TitlePanel: TPanel;
    Bevel: TBevel;
    TitleCaption: TLabel;
    Logo: TImage;
    CopyName: TLabel;
    UrlCaption: TLabel;
    Memo: TMemo;
    GitHubLabel: TLabel;
    CopyrightLabel: TLabel;
    ComponentsLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure UrlCaptionClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.DFM}

procedure TAboutForm.FormCreate(Sender: TObject);
begin
  if FileExists(ChangeFileExt(ParamStr(0), '.txt')) then
    Memo.Lines.LoadFromFile(ChangeFileExt(ParamStr(0), '.txt'))
  else
    Memo.Text:= 'File not found: '+LowerCase(ChangeFileExt(ParamStr(0), '.txt'));
end;

procedure TAboutForm.UrlCaptionClick(Sender: TObject);
begin
  ShellExecute(AboutForm.Handle, nil, PChar((Sender as TLabel).Caption), nil, nil, Sw_ShowNormal);
end;

end.
