// ============================================================
// Table 60000 — Logistics KPI Buffer  (temporary, in-memory)
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Holds computed KPI values to drive the Role Center cues.
// TableType = Temporary — never persists to the database.
// Populated on demand via the Refresh() method.
// ============================================================

table 60000 "LOG Logistics KPI Buffer"
{
    Caption           = 'Logistics KPI Buffer';
    TableType         = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }

        // ── Date range ──────────────────────────────────────
        field(10; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(11; "End Date"; Date)
        {
            Caption = 'End Date';
        }

        // ── R001: OTD ───────────────────────────────────────
        field(20; "OTD Pct"; Decimal)
        {
            Caption       = 'On-Time Delivery (%)';
            DecimalPlaces = 2 : 2;
            MinValue      = 0;
            MaxValue      = 100;
        }
        field(21; "OTD On-Time Lines"; Integer)
        {
            Caption = 'Lines Shipped On Time';
        }
        field(22; "OTD Open Late Lines"; Integer)
        {
            Caption = 'Open / Late Order Lines';
        }
        field(23; "OTD Late Shipment Lines"; Integer)
        {
            Caption = 'Shipments Delivered Late';
        }

        // ── R002: Average Storage Time ───────────────────────
        field(30; "Avg Storage Days"; Decimal)
        {
            Caption       = 'Average Storage Time (Days)';
            DecimalPlaces = 0 : 1;
            MinValue      = 0;
        }
        field(31; "Opening Stock Value"; Decimal)
        {
            Caption        = 'Opening Stock Value (€)';
            DecimalPlaces  = 2 : 2;
            AutoFormatType = 1;
        }
        field(32; "Closing Stock Value"; Decimal)
        {
            Caption        = 'Closing Stock Value (€)';
            DecimalPlaces  = 2 : 2;
            AutoFormatType = 1;
        }
        field(33; "Avg Stock Value"; Decimal)
        {
            Caption        = 'Average Stock Value (€)';
            DecimalPlaces  = 2 : 2;
            AutoFormatType = 1;
        }
        field(34; "COGS"; Decimal)
        {
            Caption        = 'Cost of Goods Sold (€)';
            DecimalPlaces  = 2 : 2;
            AutoFormatType = 1;
        }
        field(35; "Inventory Turnover Rate Pct"; Decimal)
        {
            Caption       = 'Inventory Turnover Rate (%)';
            DecimalPlaces = 2 : 2;
        }
        field(36; "Period Days"; Integer)
        {
            Caption = 'Period Days';
        }

        // ── Metadata ────────────────────────────────────────
        field(90; "Last Calculated At"; DateTime)
        {
            Caption = 'Last Calculated';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    // ----------------------------------------------------------
    // Refresh: calls both codeunits and populates all fields
    // ----------------------------------------------------------
    procedure Refresh(StartDate: Date; EndDate: Date)
    var
        OTDCalc: Codeunit "LOG OTD Calculation";
        StorageCalc: Codeunit "LOG Avg Storage Time Calc";
        OnTime: Integer;
        OpenLate: Integer;
        LateOpenForOTD: Integer;
        OpenStock: Decimal;
        CloseStock: Decimal;
        COGS: Decimal;
        TurnoverPct: Decimal;
    begin
        if not Get('KPI') then begin
            Init();
            "Primary Key" := 'KPI';
            Insert();
        end;

        "Start Date"  := StartDate;
        "End Date"    := EndDate;
        "Period Days" := EndDate - StartDate + 1;

        // R001
        OTDCalc.GetOTDBreakdown(StartDate, EndDate, OnTime, OpenLate, "OTD Late Shipment Lines", LateOpenForOTD);
        "OTD On-Time Lines"   := OnTime;
        "OTD Open Late Lines" := OpenLate;
        if (OnTime + "OTD Late Shipment Lines" + LateOpenForOTD) > 0 then
            "OTD Pct" := Round((OnTime / (OnTime + "OTD Late Shipment Lines" + LateOpenForOTD)) * 100, 0.01)
        else
            "OTD Pct" := 0;

        // R002
        StorageCalc.GetStorageBreakdown(StartDate, EndDate,
                                         OpenStock, CloseStock, COGS, TurnoverPct);
        "Opening Stock Value"         := OpenStock;
        "Closing Stock Value"         := CloseStock;
        "Avg Stock Value"             := (OpenStock + CloseStock) / 2;
        "COGS"                        := COGS;
        "Inventory Turnover Rate Pct" := TurnoverPct;
        if ("Avg Stock Value" <> 0) and (COGS <> 0) and ("Period Days" <> 0) then
            "Avg Storage Days" := Round("Period Days" / (COGS / "Avg Stock Value"), 1)
        else
            "Avg Storage Days" := 0;

        "Last Calculated At" := CurrentDateTime();
        Modify();
    end;
}
