unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, xsuperobject;

type
  TMain = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TMyClass = class
  private
    FAge: integer;
  public
    constructor Create();
    property Age: integer read FAge write FAge;
  end;

var
  Main: TMain;

implementation

{$R *.dfm}

uses
  uCache;

procedure TMain.Button1Click(Sender: TObject);
var
  cl, cl2: TMyClass; //
  obj: TObject;
  s: string;
  cache: TFileSystemCache<string, TMyClass>;
begin
  cache := TFileSystemCache<string, TMyClass>.Create();
  try
    cl := TMyClass.Create();
    cl.Age := 21;
    try
      cache.Add('hash1', cl);
    finally
      cl.Free();
    end;

    cl2 := cache.Get('hash1');

  finally
    cache.Free();
  end;

end;

{ TMyClass }

constructor TMyClass.Create;
begin
  FAge := 123;
end;

end.

