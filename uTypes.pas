unit uTypes;
{$MODE DELPHIUNICODE}
{$CODEPAGE UTF8}

interface

type
  TCountry = record
    Country: string;
    Capital: string;
    Area: Double;
    Population: Int64;
  end;

  TCountryArray = array of TCountry;
implementation

end.
