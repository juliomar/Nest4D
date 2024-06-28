program Nest4DSample;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Nest4D.Application in '..\src\Nest4D.Application.pas',
  Nest4D.Attributes in '..\src\Nest4D.Attributes.pas',
  Nest4D.Interfaces in '..\src\Nest4D.Interfaces.pas',
  app.module in 'src\app.module.pas',
  app.service in 'src\app.service.pas',
  app.controller in 'src\app.controller.pas';

begin
  try
    TNest4DApplication.NewApplication(TAppModule,
      procedure(app: TNest4DApplication)
      begin
        app.Start();
      end);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
