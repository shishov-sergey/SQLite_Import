unit uCSVHelper;
{$MODE DELPHIUNICODE}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, Classes, Types, uTypes;

type
  TCSVHelper = class
  public
    class procedure ExportToFile(const FileName: string; const Data: TCountryArray);
    class function ImportFromFile(const FileName: string): TCountryArray;
  private
    class function EscapeCSV(const S: string): string; static;
    class function UnescapeCSV(const S: string): string; static;
  end;

implementation

class function TCSVHelper.EscapeCSV(const S: string): string;
begin
  if (Pos(',', S) > 0) or (Pos('"', S) > 0) or (Pos(#10, S) > 0) or (Pos(#13, S) > 0) then
    Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"'
  else
    Result := S;
end;

class function TCSVHelper.UnescapeCSV(const S: string): string;
var
  Temp: string;
begin
  Temp := Trim(S);
  if (Length(Temp) >= 2) and (Temp[1] = '"') and (Temp[Length(Temp)] = '"') then
  begin
    Temp := Copy(Temp, 2, Length(Temp) - 2);
    Result := StringReplace(Temp, '""', '"', [rfReplaceAll]);
  end
  else
    Result := Temp;
end;

class procedure TCSVHelper.ExportToFile(const FileName: string; const Data: TCountryArray);
var
  SL: TStringList;
  I: Integer;
  Line: string;
begin
  SL := TStringList.Create;
  try
    SL.Add('country,capital,area,population');
    for I := 0 to High(Data) do
    begin
      Line := Format('%s,%s,%g,%d', [
        EscapeCSV(Data[I].Country),
        EscapeCSV(Data[I].Capital),
        Data[I].Area,
        Data[I].Population
      ]);
      SL.Add(Line);
    end;
    SL.SaveToFile(FileName);
  finally
    SL.Free;
  end;
end;

class function TCSVHelper.ImportFromFile(const FileName: string): TCountryArray;
var
  SL: TStringList;
  I: Integer;
  Line, Field: string;
  P: Integer;
  function ExtractField(var S: string): string;
  begin
    P := Pos(',', S);
    if P > 0 then
    begin
      Result := Copy(S, 1, P - 1);
      Delete(S, 1, P);
    end
    else
    begin
      Result := S;
      S := '';
    end;
    Result := UnescapeCSV(Result);
  end;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName);
    if SL.Count <= 1 then Exit;
    SetLength(Result, SL.Count - 1);

    for I := 1 to SL.Count - 1 do
    begin
      Line := SL[I];
      Result[I-1].Country := ExtractField(Line);
      Result[I-1].Capital := ExtractField(Line);
      Field := ExtractField(Line);
      Result[I-1].Area := StrToFloatDef(Field, 0);
      Field := ExtractField(Line);
      Result[I-1].Population := StrToInt64Def(Field, 0);
    end;
  finally
    SL.Free;
  end;
end;

end.
