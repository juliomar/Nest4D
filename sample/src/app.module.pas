unit app.module;

interface

uses
  Nest4D.Interfaces;

type
  TAppModule = Class(TInterfacedObject, IN4DModule)
  public
    function Imports: TArray<TClass>;
    function Services: TArray<TClass>;
    function Controllers: TArray<TClass>;
  End;

implementation

uses
  app.controller,
  app.service;

{ TAppModule }

function TAppModule.Controllers: TArray<TClass>;
begin
  Result := [TAppController];
end;

function TAppModule.Imports: TArray<TClass>;
begin
  Result := [];
end;

function TAppModule.Services: TArray<TClass>;
begin
  Result := [TAppService];
end;

end.
