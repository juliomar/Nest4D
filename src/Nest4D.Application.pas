unit Nest4D.Application;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.RTTI,
  Spring.Container,
  Spring.Services,
  Spring.Reflection;

type
  TMethod = record
    &type: TRttiType;
    method: String;
  End;

  TNest4DApplication = Class
  private
    FAppModule        : TClass;
    FCallback         : TProc<TNest4DApplication>;
    FMethodsDictionary: TDictionary<String, TMethod>;

    procedure InternalStart();
    procedure RegisterModule(AModule: TClass);
    procedure RegisterDependencies(AType: TRttiType);
    procedure RegisterService(AService: TClass);
    procedure RegisterController(AController: TClass);

    constructor Create(AAppModule: TClass; ACallback: TProc<TNest4DApplication>);
  public

    procedure Start(APort: Integer = 3030; ACallback: TProc = nil);
    class procedure NewApplication(AAppModule: TClass; ACallback: TProc<TNest4DApplication>);
    destructor Destroy; override;
  End;

implementation

uses
  System.Diagnostics,
  System.JSON,
  Horse,
  Spring,
  Nest4D.Interfaces,
  Nest4D.Attributes;

{ TNest4DApplication }

constructor TNest4DApplication.Create(AAppModule: TClass; ACallback: TProc<TNest4DApplication>);
begin
  Self.FAppModule    := AAppModule;
  Self.FCallback     := ACallback;
  FMethodsDictionary := TDictionary<String, TMethod>.Create;
  InternalStart();
end;

destructor TNest4DApplication.Destroy;
begin
  FMethodsDictionary.DisposeOf;
  inherited;
end;

procedure TNest4DApplication.InternalStart;
var
  moduleStopwatch: TStopwatch;
begin
  try
    moduleStopwatch := TStopwatch.StartNew;
    moduleStopwatch.Start;
    try
      RegisterModule(FAppModule);
    finally
      Write(Format('Total load time: %d ms', [moduleStopwatch.ElapsedMilliseconds]));
    end;

    GlobalContainer.Build;

    if Assigned(FCallback) then
      FCallback(Self);
  except
    on E: Exception do
      writeln(E.Message);
  end;
end;

class procedure TNest4DApplication.NewApplication(AAppModule: TClass; ACallback: TProc<TNest4DApplication>);
begin
  TNest4DApplication.Create(AAppModule, ACallback);
end;

procedure MakeResponse(method: TRttiMethod; res: THorseResponse; result: TValue);
var
  ResultType: TRttiType;
begin
  ResultType := method.ReturnType;

  if result.IsType<TJSONObject>() then
  begin
    res.ContentType('application/json').Send(result.AsType<TJSONObject>.ToJSON);
    exit;
  end;

  if result.IsString then
  begin
    res.Send(result.AsString);
    exit;
  end;
end;

procedure TNest4DApplication.RegisterController(AController: TClass);
var
  ctx           : TRttiContext;
  typ           : TRttiType;
  controllerAttr: TCustomAttribute;
  method        : TRttiMethod;
  routeAttr     : TCustomAttribute;

  methodRecordItem: TMethod;
  routePath       : String;
begin
  ctx := TRttiContext.Create;
  try
    typ            := ctx.GetType(AController);
    controllerAttr := typ.GetCustomAttribute(N4DController);
    if Assigned(controllerAttr) then
    begin
      // Register the controller itself
      GlobalContainer.RegisterType(typ.Handle);

      for method in typ.GetMethods do
      begin
        for routeAttr in method.GetAttributes do
        begin
          if routeAttr is N4DRoute then
          begin
            case N4DRoute(routeAttr).method of
              Get:
                begin
                  routePath               := 'GET-' + N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path;
                  methodRecordItem.&type  := typ;
                  methodRecordItem.method := method.Name;
                  FMethodsDictionary.Add(routePath, methodRecordItem);

                  THorse.Get(N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path,
                      procedure(req: THorseRequest; res: THorseResponse)
                    var
                      instance: TObject;
                      methodResult: TValue;
                      mtd: TRttiMethod;
                      Path: String;
                    begin
                      Path := 'GET-' + req.PathInfo;

                      instance := GlobalContainer.Resolve(FMethodsDictionary.Items[Path].&type.Handle).AsObject;
                      mtd := FMethodsDictionary.Items[Path].&type.GetMethod(FMethodsDictionary.Items[Path].method);
                      methodResult := mtd.Invoke(instance, []);
//                      res.Send(methodResult.AsString);
                      MakeResponse(mtd, res, methodResult);
                    end);

                  writeln(' **** Route:', '[', typ.Handle.Name, ']', ' GET ', N4DController(controllerAttr).Path +
                    N4DRoute(routeAttr).Path);
                end;
              Post:
                begin
                  routePath               := 'POST-' + N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path;
                  methodRecordItem.&type  := typ;
                  methodRecordItem.method := method.Name;

                  FMethodsDictionary.Add(routePath, methodRecordItem);

                  THorse.Post(N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path,
                    procedure(req: THorseRequest; res: THorseResponse)
                    var
                      instance: TObject;
                      methodResult: TValue;
                      mtd: TRttiMethod;
                      Path: String;
                    begin
                      Path := 'POST-' + req.PathInfo;
                      instance := GlobalContainer.Resolve(FMethodsDictionary.Items[Path].&type.Handle).AsObject;
                      mtd := FMethodsDictionary.Items[Path].&type.GetMethod(FMethodsDictionary.Items[Path].method);
                      methodResult := mtd.Invoke(instance, [req.Body]);
                      res.Send(methodResult.AsString);
                    end);

                  writeln(' **** Route:', '[', typ.Handle.Name, ']', ' POST ', N4DController(controllerAttr).Path +
                    N4DRoute(routeAttr).Path);
                end;

              Put:
                begin
                  routePath               := 'PUT-' + N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path;
                  methodRecordItem.&type  := typ;
                  methodRecordItem.method := method.Name;

                  FMethodsDictionary.Add(routePath, methodRecordItem);

                  THorse.Put(N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path,
                    procedure(req: THorseRequest; res: THorseResponse)
                    var
                      instance: TObject;
                      methodResult: TValue;
                      mtd: TRttiMethod;
                      Path: String;
                    begin
                      Path := 'PUT-' + req.PathInfo;
                      instance := GlobalContainer.Resolve(FMethodsDictionary.Items[Path].&type.Handle).AsObject;
                      mtd := FMethodsDictionary.Items[Path].&type.GetMethod(FMethodsDictionary.Items[Path].method);
                      methodResult := mtd.Invoke(instance, [req.Body]);
                      res.Send(methodResult.AsString);
                    end);

                  writeln(' **** Route:', '[', typ.Handle.Name, ']', ' PUT ', N4DController(controllerAttr).Path +
                    N4DRoute(routeAttr).Path);
                end;

              Patch:
                begin
                  routePath               := 'PATCH-' + N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path;
                  methodRecordItem.&type  := typ;
                  methodRecordItem.method := method.Name;

                  FMethodsDictionary.Add(routePath, methodRecordItem);

                  THorse.Patch(N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path,
                    procedure(req: THorseRequest; res: THorseResponse)
                    var
                      instance: TObject;
                      methodResult: TValue;
                      mtd: TRttiMethod;
                      Path: String;
                    begin
                      Path := 'PATCH-' + req.PathInfo;
                      instance := GlobalContainer.Resolve(FMethodsDictionary.Items[Path].&type.Handle).AsObject;
                      mtd := FMethodsDictionary.Items[Path].&type.GetMethod(FMethodsDictionary.Items[Path].method);
                      methodResult := mtd.Invoke(instance, [req.Body]);
                      res.Send(methodResult.AsString);
                    end);

                  writeln(' **** Route:', '[', typ.Handle.Name, ']', ' PATCH ', N4DController(controllerAttr).Path +
                    N4DRoute(routeAttr).Path);
                end;

              Delete:
                begin
                  routePath               := 'DELETE-' + N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path;
                  methodRecordItem.&type  := typ;
                  methodRecordItem.method := method.Name;

                  FMethodsDictionary.Add(routePath, methodRecordItem);

                  THorse.Delete(N4DController(controllerAttr).Path + N4DRoute(routeAttr).Path,
                    procedure(req: THorseRequest; res: THorseResponse)
                    var
                      instance: TObject;
                      methodResult: TValue;
                      mtd: TRttiMethod;
                      Path: String;
                    begin
                      Path := 'DELETE-' + req.PathInfo;
                      instance := GlobalContainer.Resolve(FMethodsDictionary.Items[Path].&type.Handle).AsObject;
                      mtd := FMethodsDictionary.Items[Path].&type.GetMethod(FMethodsDictionary.Items[Path].method);
                      methodResult := mtd.Invoke(instance, [req.Body]);
                      res.Send(methodResult.AsString);
                    end);

                  writeln(' **** Route:', '[', typ.Handle.Name, ']', ' DELETE ', N4DController(controllerAttr).Path +
                    N4DRoute(routeAttr).Path);
                end;
            end;
          end;
        end;
      end;
    end;
  finally
    ctx.Free;
  end;
end;

procedure TNest4DApplication.RegisterDependencies(AType: TRttiType);
var
  ctx    : TRttiContext;
  method : TRttiMethod;
  param  : TRttiParameter;
  depType: TRttiType;
begin
  for method in AType.GetMethods do
  begin
    if method.IsConstructor then
    begin
      for param in method.GetParameters do
      begin
        depType := ctx.GetType(param.ParamType.Handle);

        writeln(' ** Dependency mapped: ', AType.Name);
        GlobalContainer.RegisterType(depType.Handle).asTransient;
        RegisterDependencies(depType);
      end;
    end;
  end;
end;

procedure TNest4DApplication.RegisterModule(AModule: TClass);
var
  import             : TClass;
  entryModule        : IN4DModule;
  service            : TClass;
  Controller         : TClass;
  ServiceStopwatch   : TStopwatch;
  ControllerStopwatch: TStopwatch;
begin
  if not Supports(AModule.Create, IN4DModule, entryModule) then
    raise Exception.CreateFmt('Module %s not implements IModule', [AModule.ClassName]);

  writeln(' * Module map start: ', AModule.ClassName);

  ServiceStopwatch := TStopwatch.StartNew;
  for service in entryModule.Services do
  begin
    ServiceStopwatch.Start;
    RegisterService(service);
    ServiceStopwatch.Stop;
    writeln(Format(' ** Service mapped: %s (+ %d ms)', [service.ClassName, ServiceStopwatch.ElapsedMilliseconds]));
    ServiceStopwatch.Reset;
  end;

  ControllerStopwatch := TStopwatch.StartNew;
  for Controller in entryModule.Controllers do
  begin
    ControllerStopwatch.Start;

    RegisterController(Controller);

    ControllerStopwatch.Stop;
    writeln(Format(' ** Controller mapped: %s (+ %d ms)', [Controller.ClassName,
        ControllerStopwatch.ElapsedMilliseconds]));
    ControllerStopwatch.Reset;
  end;

  for import in entryModule.Imports do
  begin
    RegisterModule(import);
  end;
end;

procedure TNest4DApplication.RegisterService(AService: TClass);
var
  ctx: TRttiContext;
  typ: TRttiType;
begin
  ctx := TRttiContext.Create;
  try
    typ := ctx.GetType(AService);

    // Register the controller itself
    try
      GlobalContainer.RegisterType(typ.Handle);
    except
      on E: Exception do
        writeln(E.Message);
    end;
    // Register dependencies recursively
    RegisterDependencies(typ);
  finally
    ctx.Free;
  end;
end;

procedure TNest4DApplication.Start(APort: Integer = 3030; ACallback: TProc = nil);
begin
  if not Assigned(ACallback) then
  begin
    THorse.Listen(APort,
      procedure()
      begin
        writeln(#10#13, 'App started on port: ', APort)
      end);
    Exit;
  end;
  THorse.Listen(APort, ACallback);
end;

end.
