program SberbankTest;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {Main},
  uCache in 'uCache.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
