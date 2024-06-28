unit Nest4D.Attributes;

interface

type
  N4DController = Class(TCustomAttribute)
  private
    FPath: String;
  public
    property Path: String Read FPath;
    constructor Create(APath: String);
  End;

  TN4DMethod = (Get, Post, Put, Patch, Delete);

  N4DRoute = Class(TCustomAttribute)
  private
    FPath  : String;
    FMethod: TN4DMethod;
  public
    property Path  : String Read FPath;
    property Method: TN4DMethod Read FMethod;
    constructor Create(AMethod: TN4DMethod; APath: String);
  End;

implementation

{ Controller }

constructor N4DController.Create(APath: String);
begin
  FPath := APath;
end;

{ Route }

constructor N4DRoute.Create(AMethod: TN4DMethod; APath: String);
begin
  FMethod := AMethod;
  FPath   := APath;
end;

end.
