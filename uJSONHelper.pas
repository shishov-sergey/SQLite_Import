unit uJSONHelper;
{$MODE DELPHIUNICODE}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, Classes, fpjson, jsonparser, uTypes;

type
  TJSONHelper = class
  public
    class procedure ExportToFile(const FileName: string; const Data: TCountryArray);
    class function ImportFromFile(const FileName: string): TCountryArray;
  end;

implementation

class procedure TJSONHelper.ExportToFile(const FileName: string; const Data: TCountryArray);
var
  JA: TJSONArray;
  JO: TJSONObject;
  I: Integer;
  SL: TStringList;
begin
  JA := TJSONArray.Create;
  try
    for I := 0 to High(Data) do
    begin
      JO := TJSONObject.Create;
      JO.Add('country', TJSONString.Create(Data[I].Country));
      JO.Add('capital', TJSONString.Create(Data[I].Capital));
      JO.Add('area', TJSONFloatNumber.Create(Data[I].Area));
      JO.Add('population', TJSONIntegerNumber.Create(Data[I].Population));
      JA.Add(JO);
    end;
    SL := TStringList.Create;
    try
      SL.Text := JA.AsJSON;
      SL.SaveToFile(FileName);
    finally
      SL.Free;
    end;
  finally
    JA.Free;
  end;
end;

class function TJSONHelper.ImportFromFile(const FileName: string): TCountryArray;
var
  SL: TStringList;
  JA: TJSONArray;
  JO: TJSONObject;
  I: Integer;
  Data: TJSONData;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName);
    Data := GetJSON(SL.Text);
    if not (Data is TJSONArray) then Exit;
    JA := TJSONArray(Data);
  
    SetLength(Result, JA.Count);
    try
     for I := 0 to JA.Count - 1 do
        begin
          JO := JA.Items[I] as TJSONObject;
          Result[I].Country := JO.Strings['country'];
          Result[I].Capital := JO.Strings['capital'];
          Result[I].Area := JO.Floats['area'];
          Result[I].Population := JO.Integers['population'];
      end;
    finally
         JA.Free;
    end;
  finally
    SL.Free;
  end;
end;

end.
