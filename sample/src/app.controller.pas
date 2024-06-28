unit app.controller;

interface

uses
  System.Json,
  Nest4D.Attributes,
  app.service;

type
  [N4DController('/api')]
  TAppController = Class
  private
    FAppService: TAppService;
  public
    [N4DRoute(Get, '')]
    function getApi: TJsonObject;

    constructor Create(AAppService: TAppService);
  End;
                       
implementation

{ TAppController }

constructor TAppController.Create(AAppService: TAppService);
begin
  FAppService := AAppService;
end;

function TAppController.getApi: TJsonObject;
begin
  Result := TJSONObject.Create.AddPair('message', 'Hello, World!');
end;

end.
