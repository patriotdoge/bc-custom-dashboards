// ============================================================
// Page 60010 — OTD Drill-Down
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Temporary-table list page — populated by the caller via
// LoadOnTimeLines(), LoadLateLines(), or LoadAllLines()
// before Run() is called. Using a temp table allows filtering
// on Shipment Date ≤ Requested Delivery Date, which cannot be
// expressed as a SetFilter on a live table.
// ============================================================

page 60010 "LOG OTD Drill-Down"
{
    PageType             = List;
    Caption              = 'OTD — Shipment Line Detail';
    SourceTable          = "Sales Shipment Line";
    SourceTableTemporary = true;
    Editable             = false;
    UsageCategory        = None;
    ApplicationArea      = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption         = 'Shipment No.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption         = 'Item No.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = All;
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = All;
                }
                field(OnTimeFlag; GetOnTimeLabel(Rec."Shipment Date", Rec."Requested Delivery Date"))
                {
                    ApplicationArea = All;
                    Caption         = 'On Time?';
                    StyleExpr       = OnTimeFlagStyle;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption         = 'Customer No.';
                }
                field(CustomerNameField; CustomerName)
                {
                    ApplicationArea = All;
                    Caption         = 'Customer Name';
                }
            }
        }

        area(FactBoxes)
        {
            part(LateOpenLinesPart; "LOG Late Open Order Lines Part")
            {
                ApplicationArea = All;
                Caption         = 'Late Open Sales Order Lines';
                Visible         = ShowLateOpenPart;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if ShowLateOpenPart and (FilterStartDate <> 0D) and (FilterEndDate <> 0D) then
            CurrPage.LateOpenLinesPart.Page.SetLateFilter(FilterStartDate, FilterEndDate);
    end;

    var
        OnTimeFlagStyle: Text;
        CustomerName: Text[100];
        FilterStartDate: Date;
        FilterEndDate: Date;
        ShowLateOpenPart: Boolean;

    procedure LoadOnTimeLines(StartDate: Date; EndDate: Date)
    begin
        ShowLateOpenPart := false;
        LoadLines(StartDate, EndDate, true, false);
    end;

    procedure LoadLateLines(StartDate: Date; EndDate: Date)
    begin
        ShowLateOpenPart := false;
        LoadLines(StartDate, EndDate, false, true);
    end;

    procedure LoadAllLines(StartDate: Date; EndDate: Date)
    begin
        ShowLateOpenPart := true;
        LoadLines(StartDate, EndDate, false, false);
    end;

    local procedure LoadLines(StartDate: Date; EndDate: Date; OnTimeOnly: Boolean; LateOnly: Boolean)
    var
        ShipLine: Record "Sales Shipment Line";
        IsOnTime: Boolean;
    begin
        FilterStartDate := StartDate;
        FilterEndDate   := EndDate;

        Rec.Reset();
        Rec.DeleteAll();

        ShipLine.SetFilter("No.", 'AE*|AA*');
        ShipLine.SetFilter(Type, '%1', ShipLine.Type::Item);
        ShipLine.SetFilter("Requested Delivery Date", '%1..%2', StartDate, EndDate);

        if ShipLine.FindSet() then
            repeat
                IsOnTime := (ShipLine."Shipment Date" <> 0D) and
                            (ShipLine."Shipment Date" <= ShipLine."Requested Delivery Date");

                if (not OnTimeOnly or IsOnTime) and (not LateOnly or not IsOnTime) then begin
                    Rec := ShipLine;
                    Rec.Insert();
                end;
            until ShipLine.Next() = 0;
    end;

    trigger OnAfterGetRecord()
    var
        Customer: Record Customer;
    begin
        if (Rec."Shipment Date" = 0D) or (Rec."Requested Delivery Date" = 0D) then
            OnTimeFlagStyle := ''
        else if Rec."Shipment Date" <= Rec."Requested Delivery Date" then
            OnTimeFlagStyle := 'Favorable'
        else
            OnTimeFlagStyle := 'Unfavorable';

        if Customer.Get(Rec."Sell-to Customer No.") then
            CustomerName := Customer.Name
        else
            CustomerName := '';
    end;

    local procedure GetOnTimeLabel(ShipDate: Date; ReqDate: Date): Text
    begin
        if (ShipDate = 0D) or (ReqDate = 0D) then
            exit('—');
        if ShipDate <= ReqDate then
            exit('Yes')
        else
            exit('No — Late');
    end;
}
