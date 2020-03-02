unit uCache;

interface

uses
  System.Generics.Collections, superobject, xsuperjson, xsuperobject, Vcl.Forms, System.IOUtils, Rtti, DBXJSONReflect, System.Json;

type
  {Key here will be a hash of object, V here will be a link to object on heap, for example}
  TMemoryCache<K, V> = class
  private
    FSize: Int64;
    FCollection: TDictionary<K, V>;
    function GetSize: Int64;
    function IsValueAnObject(aValue: V): Boolean;
    function Clone(aValue: V): V;
  public
    constructor Create();
    destructor Destroy; override;
    procedure Add(aKey: K; aValue: V); virtual;
    function Get(aKey: K): V; virtual;
    procedure Remove(aKey: K); virtual;
    procedure Clear(); virtual;
  end;

  TSerializer<V> = class
  public
    function Serialize(aValue: V): string; virtual; abstract;
    function DeSerialize(aJsonString: string): V; virtual; abstract;
  end;

  TSimpleDBXJsonReflectSerializer<V: class> = class(TSerializer<V>)
  public
    function Serialize(aValue: V): string; override;
    function DeSerialize(aJson: string): V; override;
  end;

  TSimpleSuperobjectSerializer<V> = class(TSerializer<V>)
  public
    function Serialize(aValue: V): string; override;
    function DeSerialize(aJson: string): V; override;
  end;

  TFileSystemCache<K, V> = class(TMemoryCache<K, V>)
  private
    FAbsDirectory: string;
    FSerializer: TSerializer<V>;
    function Serialize(aValue: V): string;
    function Deserialize(aKey: K): V;
    function KeyToFilePath(aKey: K): string;
    function CreateInstance(): V;
    procedure CloneFieldsFromJson(aInstance: V; aJson: string);
  public
    constructor Create(aAbsDirectory: string = '');
    procedure Add(aKey: K; aValue: V); override;
    function Get(aKey: K): V; override;
    procedure Remove(aKey: K); override;
    procedure Clear(); override;
  end;

implementation

uses
  System.Classes, System.SysUtils, System.TypInfo;

{ TCache<K, V> }

procedure TMemoryCache<K, V>.Clear;
begin
  FCollection.Clear();
end;

function TMemoryCache<K, V>.Clone(aValue: V): V;
begin
  // create instance and clone fields using rtti
end;

constructor TMemoryCache<K, V>.Create;
begin
  FCollection := TDictionary<K, V>.Create();
end;

destructor TMemoryCache<K, V>.Destroy;
var
  i: integer;
  key: K;
  obj: TObject;
  item: V;
begin
  for key in FCollection.Keys do
  begin
    item := FCollection[key];
    PObject(@item)^.Free()
  end;


//   PObject(@Result)^

  FCollection.Free();
  inherited;
end;

function TMemoryCache<K, V>.Get(aKey: K): V;
begin
  Result := FCollection[aKey];
end;

procedure TMemoryCache<K, V>.Add(aKey: K; aValue: V);
var
  cloneOfObject: V;
begin
  if not IsValueAnObject(aValue) then
    raise Exception.Create('value not an object');

  cloneOfObject := Clone(aValue);

  FSize := FSize + PObject(@cloneOfObject)^.InstanceSize;
  FCollection.Add(aKey, cloneOfObject);
end;

procedure TMemoryCache<K, V>.Remove(aKey: K);
begin
  FCollection.Remove(aKey);
end;

function TMemoryCache<K, V>.GetSize: Int64;
begin
  Result := FSize;
end;

function TMemoryCache<K, V>.IsValueAnObject(aValue: V): Boolean;
begin
  Result := PTypeInfo(TypeInfo(V))^.Kind = tkClass;
end;

{ TFileSystemCache<K, V> }

procedure TFileSystemCache<K, V>.Add(aKey: K; aValue: V);
var
  serialized: string;
  ss: TStringStream;
begin
  serialized := Serialize(aValue);

  ss := TStringStream.Create(serialized);
  try
    ss.SaveToFile(KeyToFilePath(aKey));
    FSize := FSize + ss.Size;
    FCollection.Add(aKey, aValue);
  finally
    ss.Free();
  end;
end;

procedure TFileSystemCache<K, V>.Clear;
begin
  TDirectory.Delete(FAbsDirectory, true);
  FCollection.Clear();
end;

procedure TFileSystemCache<K, V>.CloneFieldsFromJson(aInstance: V; aJson: string);
var
  aValue, afieldValue: TValue;
  ctx: TRttiContext;
  rType: TRttiType;
  AMethCreate: TRttiMethod;
  instanceType: TRttiInstanceType;
  fields: Tarray<System.Rtti.TRttiField>;
  field: System.Rtti.TRttiField;
  obj: TObject;
begin
//      fields := rType.GetFields();
//      for field in fields do
//      begin
//        if field.Name = 'FAge' then
//          field.SetValue((obj), afieldValue.FromVariant(20));
//      end;

//  ctx := TRttiContext.Create;
//  rType := ctx.GetType(TypeInfo(V));
//  for AMethCreate in rType.GetMethods do
//  begin
//    if (AMethCreate.IsConstructor) and (Length(AMethCreate.GetParameters) = 0) then
//    begin
//      instanceType := rType.AsInstance;
//      aValue := (AMethCreate.Invoke(instanceType.MetaclassType, []));
//      obj := aValue.AsObject;
//
//      Result := aValue.AsType<V>;
//      Break;
//    end;
//  end;

end;

constructor TFileSystemCache<K, V>.Create(aAbsDirectory: string);
begin
  inherited Create;

  if aAbsDirectory = '' then
    FAbsDirectory := Format('%s\%s', [ExtractFileDir(Application.ExeName), 'files']);

  if not TDirectory.Exists(FAbsDirectory) then
    TDirectory.CreateDirectory(FAbsDirectory);
end;

type
  PValue = ^TValue;

function TFileSystemCache<K, V>.CreateInstance(): V;
var
  aValue, afieldValue: TValue;
  ctx: TRttiContext;
  rType: TRttiType;
  AMethCreate: TRttiMethod;
  instanceType: TRttiInstanceType;
  fields: Tarray<System.Rtti.TRttiField>;
  field: System.Rtti.TRttiField;
  obj: TObject;
begin
  ctx := TRttiContext.Create;
  rType := ctx.GetType(TypeInfo(V));
  for AMethCreate in rType.GetMethods do
  begin
    if (AMethCreate.IsConstructor) and (Length(AMethCreate.GetParameters) = 0) then
    begin
      instanceType := rType.AsInstance;
      aValue := (AMethCreate.Invoke(instanceType.MetaclassType, []));
      obj := aValue.AsObject;

      Result := aValue.AsType<V>;
      Break;
    end;
  end;
end;

function TFileSystemCache<K, V>.Deserialize(aKey: K): V;
begin

end;

function TFileSystemCache<K, V>.Get(aKey: K): V;
begin
  if FCollection.ContainsKey(aKey) then
  begin
    FCollection[aKey] := Deserialize(aKey);
    Result := FCollection[aKey];
  end
  else
    raise Exception.Create('object not found in fileSystemCache');
end;

function TFileSystemCache<K, V>.KeyToFilePath(aKey: K): string;
begin
  if (TypeInfo(K) = TypeInfo(string)) then
    Result := Format('%s\%s', [FAbsDirectory, PString(@aKey)^])
  else if (TypeInfo(K) = TypeInfo(Integer)) then
    Result := Format('%s\%s', [FAbsDirectory, PInteger(@aKey)^.ToString()])
  else
    raise Exception.Create('Unkown type of Key, unable to define a path of file');
end;

procedure TFileSystemCache<K, V>.Remove(aKey: K);
var
  filePath: string;
begin
  if FCollection.ContainsKey(aKey) then
  begin
    filePath := KeyToFilePath(aKey);

    if TFile.Exists(filePath) then
      TFIle.Delete(filePath);

    FCollection.Remove(aKey);
  end;
end;

function TFileSystemCache<K, V>.Serialize(aValue: V): string;
begin
//  FSerializer.
end;

{ TSimpleSerializer<V> }

function TSimpleDBXJsonReflectSerializer<V>.DeSerialize(aJson: string): V;
var
  unMar: TJSONUnMarshal;
  jo: TJSONObject;
  jv: TJSONValue;
begin
  unMar := TJSONUnMarshal.Create();
  try
    jv := TJSONObject.ParseJSONValue(aJson, false) as TJSONValue;
    Result := V (unMar.Unmarshal(jv));
  finally
    unMar.Free();
  end;
end;

function TSimpleDBXJsonReflectSerializer<V>.Serialize(aValue: V): string;
var
  mar: TJSONMarshal;
  jo: TJSONObject;
begin
  mar := TJSONMarshal.Create(TJSONConverter.Create);
  try
    jo := mar.Marshal(PObject(@aValue)^) as TJSONObject;
    Result := jo.ToString();
  finally
    mar.Free();
  end;
end;

{ TSimpleSuperobjectSerializer }

function TSimpleSuperobjectSerializer.DeSerialize(aJson: string): V;
var
  filePath: string;
  ss: TStringStream;
  jsonString: string;
begin
//  filePath := KeyToFilePath(aKey);

//  ss := TStringStream.Create();
//  try
//    ss.LoadFromFile(filePath);
//    jsonString := ss.DataString;
//  finally
//    ss.Free();
//  end;

//  Result := CreateInstance();
//  CloneFieldsFromJson(Result, jsonString);

    // fill the fields through rtti...
//  Result := obj;

//  cl := PTypeInfo(TypeInfo(V))^.TypeData.ClassType;

//  PObject(@Result)^ := cl.FromJSON(jsonString);    //obj.FromJSON(jsonString); //PObject(@Result)^.ClassType.FromJSON(jsonString);
end;

function TSimpleSuperobjectSerializer.Serialize(aValue: V): string;
begin
  Result := PObject(@aValue)^.AsJSON(false, false);
end;

end.

